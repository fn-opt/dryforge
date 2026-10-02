#!/usr/bin/env python3
"""Verify that the repository is internally consistent and reproducible."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


AGENT_PLUGIN_SCHEMA = "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
ANTIGRAVITY_SCHEMA = "https://antigravity.google/schemas/v1/plugin.json"
ANTIGRAVITY_FIELDS = {"$schema", "name", "description"}
VERSIONED_MANIFESTS = (
    Path("platform/claude/plugin.json"),
    Path("platform/codex/plugin.json"),
    Path("platform/grok/plugin.json"),
    Path("platform/agent-plugin/plugin.json"),
    Path("claude/.claude-plugin/plugin.json"),
    Path("codex/plugin/.codex-plugin/plugin.json"),
    Path("grok/plugin.json"),
    Path("agent-plugin/plugin.json"),
)
AGENT_PLUGIN_FIELDS = {
    "$schema",
    "name",
    "version",
    "description",
    "author",
    "homepage",
    "repository",
    "license",
    "keywords",
    "extensions",
}
SKILL_FIELDS = {
    "name",
    "description",
    "license",
    "compatibility",
    "metadata",
    "allowed-tools",
    "disable-model-invocation",
}
MARKETPLACE_TARGETS = {
    Path(".claude-plugin/marketplace.json"): Path("claude"),
    Path(".agents/plugins/marketplace.json"): Path("codex/plugin"),
    Path(".grok-plugin/marketplace.json"): Path("grok"),
    Path(".github/plugin/marketplace.json"): Path("agent-plugin"),
}


class VerificationError(RuntimeError):
    pass


def run(command: list[str], cwd: Path, *, capture: bool = False) -> str:
    result = subprocess.run(
        command,
        cwd=cwd,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if result.returncode != 0:
        detail = (result.stdout or "") + (result.stderr or "")
        raise VerificationError(
            f"command failed ({' '.join(command)})" + (f"\n{detail.strip()}" if detail.strip() else "")
        )
    return (result.stdout or "").strip()


def load_json(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise VerificationError(f"invalid JSON: {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise VerificationError(f"JSON root must be an object: {path}")
    return value


def changelog_version(root: Path) -> str:
    match = re.search(r"^##\s+v([^\s(]+)", (root / "CHANGELOG.md").read_text(encoding="utf-8"), re.MULTILINE)
    if not match:
        raise VerificationError("CHANGELOG.md has no version heading")
    return match.group(1)


def manifest_versions(root: Path) -> dict[Path, str]:
    versions: dict[Path, str] = {}
    for relative in VERSIONED_MANIFESTS:
        path = root / relative
        if not path.is_file():
            raise VerificationError(f"missing versioned manifest: {relative}")
        data = load_json(path)
        version = data.get("version")
        if not isinstance(version, str) or not version.strip():
            raise VerificationError(f"missing version: {path.relative_to(root)}")
        versions[path.relative_to(root)] = version
    return versions


def validate_json_files(root: Path) -> None:
    candidates = set(root.glob("**/plugin.json")) | set(root.glob("**/marketplace.json"))
    for path in sorted(candidates):
        load_json(path)
    print(f"OK JSON manifests ({len(candidates)})")


def validate_versions(root: Path, tag: str | None) -> None:
    versions = manifest_versions(root)
    unique = set(versions.values())
    if len(unique) != 1:
        detail = "\n".join(f"  {path}: {version}" for path, version in versions.items())
        raise VerificationError(f"manifest version mismatch:\n{detail}")
    version = unique.pop()
    changelog = changelog_version(root)
    if version != changelog:
        raise VerificationError(f"manifest version {version} != CHANGELOG version {changelog}")
    if tag is not None:
        if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", tag):
            raise VerificationError(f"release tag must be vX.Y.Z: {tag}")
        if tag != f"v{version}":
            raise VerificationError(f"tag {tag} != manifest version v{version}")
    print(f"OK version {version}" + (f" and tag {tag}" if tag else ""))


def marketplace_source(entry: dict) -> str | None:
    source = entry.get("source")
    if isinstance(source, str):
        return source
    if isinstance(source, dict) and source.get("source") == "local":
        value = source.get("path")
        return value if isinstance(value, str) else None
    return None


def validate_marketplaces(root: Path) -> None:
    versions = set(manifest_versions(root).values())
    if len(versions) != 1:
        raise VerificationError("manifest versions must match before marketplace validation")
    version = versions.pop()
    for manifest, expected_target in MARKETPLACE_TARGETS.items():
        data = load_json(root / manifest)
        plugins = data.get("plugins")
        if not isinstance(plugins, list) or len(plugins) != 1 or not isinstance(plugins[0], dict):
            raise VerificationError(f"expected one plugin entry: {manifest}")
        entry = plugins[0]
        if entry.get("name") != "dryforge":
            raise VerificationError(f"unexpected plugin name: {manifest}")
        entry_version = entry.get("version")
        if entry_version is not None and entry_version != version:
            raise VerificationError(f"marketplace version {entry_version} != manifest version {version}: {manifest}")
        source = marketplace_source(entry)
        normalized = source.removeprefix("./") if source else None
        if normalized != expected_target.as_posix():
            raise VerificationError(f"unexpected marketplace source {source!r}: {manifest}")
        target = (root / normalized).resolve()
        if not target.is_relative_to(root.resolve()) or not target.is_dir():
            raise VerificationError(f"marketplace source is not a package directory: {manifest}")
    print(f"OK marketplace targets ({len(MARKETPLACE_TARGETS)})")


def frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        raise VerificationError(f"missing YAML frontmatter: {path}")
    values: dict[str, str] = {}
    for line in match.group(1).splitlines():
        field = re.match(r"^([A-Za-z0-9-]+):(?:\s*(.*))?$", line)
        if field:
            values[field.group(1)] = (field.group(2) or "").strip()
    return values


def validate_agent_plugin(root: Path) -> None:
    package = root / "agent-plugin"
    manifest = load_json(package / "plugin.json")
    unknown = set(manifest) - AGENT_PLUGIN_FIELDS
    if unknown:
        raise VerificationError(f"unknown Agent Plugin manifest fields: {', '.join(sorted(unknown))}")
    if manifest.get("$schema") != AGENT_PLUGIN_SCHEMA:
        raise VerificationError("Agent Plugin schema is missing or unsupported")
    name = manifest.get("name")
    if not isinstance(name, str) or not re.fullmatch(r"[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?", name):
        raise VerificationError("invalid Agent Plugin name")
    if "--" in name or ".." in name or len(name) > 64:
        raise VerificationError("invalid Agent Plugin name")
    skills = package / "skills"
    if not skills.is_dir():
        raise VerificationError("Agent Plugin skills directory is missing")
    discovered = sorted(path for path in skills.iterdir() if path.is_dir())
    if not discovered:
        raise VerificationError("Agent Plugin has no skills")
    for skill in discovered:
        skill_file = skill / "SKILL.md"
        if not skill_file.is_file():
            raise VerificationError(f"Agent Plugin skill has no SKILL.md: {skill.name}")
        values = frontmatter(skill_file)
        unknown_skill_fields = set(values) - SKILL_FIELDS
        if unknown_skill_fields:
            raise VerificationError(
                f"unknown Agent Plugin skill fields in {skill.name}: {', '.join(sorted(unknown_skill_fields))}"
            )
        if values.get("name") != skill.name:
            raise VerificationError(f"Agent Plugin skill name does not match directory: {skill.name}")
        if not values.get("description"):
            raise VerificationError(f"Agent Plugin skill description is missing: {skill.name}")
        if values.get("disable-model-invocation") != "true":
            raise VerificationError(f"Agent Plugin skill is not manual-only: {skill.name}")
        if "allowed-tools" in values:
            raise VerificationError(f"platform-specific allowed-tools leaked into Agent Plugin: {skill.name}")
    print(f"OK Agent Plugins 1.0 package ({len(discovered)} skills)")


def validate_grok_package(root: Path) -> None:
    skills = root / "grok/skills"
    discovered = sorted(path for path in skills.iterdir() if path.is_dir()) if skills.is_dir() else []
    if not discovered:
        raise VerificationError("Grok package has no skills")
    for skill in discovered:
        values = frontmatter(skill / "SKILL.md")
        if values.get("name") != skill.name:
            raise VerificationError(f"Grok skill name does not match directory: {skill.name}")
        if values.get("disable-model-invocation") != "true":
            raise VerificationError(f"Grok skill is not manual-only: {skill.name}")
        if "allowed-tools" in values:
            raise VerificationError(f"Claude allowed-tools leaked into Grok: {skill.name}")
    print(f"OK Grok package ({len(discovered)} skills)")


def validate_antigravity_package(root: Path) -> None:
    package = root / "antigravity"
    manifest = load_json(package / "plugin.json")
    unknown = set(manifest) - ANTIGRAVITY_FIELDS
    if unknown:
        raise VerificationError(f"unknown Antigravity manifest fields: {', '.join(sorted(unknown))}")
    if manifest.get("$schema") != ANTIGRAVITY_SCHEMA:
        raise VerificationError("Antigravity schema is missing or unsupported")
    if manifest.get("name") != "dryforge":
        raise VerificationError("unexpected Antigravity plugin name")
    if not isinstance(manifest.get("description"), str) or not manifest["description"].strip():
        raise VerificationError("Antigravity description is missing")

    source_skills = root / "src/skills"
    generated_skills = package / "skills"
    source_names = sorted(path.name for path in source_skills.iterdir() if path.is_dir())
    generated_names = sorted(path.name for path in generated_skills.iterdir() if path.is_dir())
    source_files = {
        path.relative_to(source_skills): path.read_bytes()
        for path in source_skills.rglob("*")
        if path.is_file() and path.name != ".DS_Store"
    }
    generated_files = {
        path.relative_to(generated_skills): path.read_bytes()
        for path in generated_skills.rglob("*")
        if path.is_file() and path.name != ".DS_Store"
    }
    if not source_names or generated_names != source_names or generated_files != source_files:
        raise VerificationError("Antigravity skills do not match src/skills")
    for name in source_names:
        generated = generated_skills / name / "SKILL.md"
        if frontmatter(generated).get("name") != name:
            raise VerificationError(f"Antigravity skill name does not match directory: {name}")

    rule = package / "rules/invocation.md"
    if not rule.is_file():
        raise VerificationError("Antigravity invocation rule is missing")
    rule_text = rule.read_text(encoding="utf-8")
    source_rule = root / "platform/antigravity/rules/invocation.md"
    if not source_rule.is_file() or source_rule.read_bytes() != rule.read_bytes():
        raise VerificationError("Antigravity invocation rule differs from platform source")
    required_phrases = (
        "Only invoke a dryforge skill when the user explicitly enters",
        "Do not select or invoke dryforge from semantic similarity",
        "Without an explicit dryforge slash command",
    )
    if any(phrase not in rule_text for phrase in required_phrases):
        raise VerificationError("Antigravity invocation rule is missing the manual-only contract")
    print(f"OK Antigravity package ({len(generated_names)} skills + invocation rule)")


def git_status(root: Path) -> str:
    top = Path(run(["git", "rev-parse", "--show-toplevel"], root, capture=True)).resolve()
    relative = root.resolve().relative_to(top)
    pathspec = "." if relative == Path(".") else relative.as_posix()
    return run(["git", "status", "--porcelain", "--untracked-files=all", "--", pathspec], top, capture=True)


def validate_reproducible_build(root: Path) -> None:
    before = git_status(root)
    if before:
        raise VerificationError(f"verification requires a clean tree:\n{before}")
    run(["bash", "-n", "build/build.sh"], root)
    run(["bash", "build/build.sh"], root)
    after = git_status(root)
    if after:
        raise VerificationError(f"generated outputs are stale or uncommitted:\n{after}")
    print("OK reproducible build")


def validate_codex_invocation(root: Path) -> None:
    skills = sorted(path.name for path in (root / "src/skills").iterdir() if path.is_dir())
    pattern = re.compile(r"^policy:\n  allow_implicit_invocation: false$", re.MULTILINE)
    for name in skills:
        overlay = root / "codex/plugin/skills" / name / "agents/openai.yaml"
        if not overlay.is_file() or not pattern.search(overlay.read_text(encoding="utf-8")):
            raise VerificationError(f"Codex implicit invocation is not disabled for skill: {name}")
    print(f"OK Codex manual-only invocation ({len(skills)} skills)")


def validate_licenses(root: Path) -> None:
    canonical = (root / "LICENSE").read_bytes()
    if b"Apache License" not in canonical or b"Version 2.0, January 2004" not in canonical:
        raise VerificationError("LICENSE is not the Apache License 2.0 text")
    copies = sorted(path for path in root.rglob("LICENSE") if ".git" not in path.parts)
    for path in copies:
        if path.read_bytes() != canonical:
            raise VerificationError(f"LICENSE differs from the root LICENSE: {path.relative_to(root)}")
    print(f"OK license copies ({len(copies)})")


def validate_decision_record_source_fidelity(root: Path) -> None:
    # Static prompt-contract regressions, not model executions. The paired transcripts and
    # expected/rejected behavior in the fixture can also be used for a future behavioral eval.
    fixture = root / "ci/fixtures/decision-record-source-fidelity.json"
    cases = json.loads(fixture.read_text(encoding="utf-8"))
    failures: list[str] = []
    for case in cases:
        for filename, clauses in case["required_contract"].items():
            skills = ("go",) if filename == "orchestration.md" else ("go", "migration")
            for skill in skills:
                relative = Path("src/skills") / skill / "references" / filename
                text = " ".join((root / relative).read_text(encoding="utf-8").split())
                for clause in clauses:
                    if clause not in text:
                        failures.append(f"{case['name']}: {relative}: missing {clause!r}")
    if failures:
        raise VerificationError("decision-record source-fidelity contract:\n" + "\n".join(failures))
    print(f"OK decision-record source-fidelity contracts ({len(cases)} paired cases; static)")


def verify(root: Path, tag: str | None = None) -> None:
    required = [
        "CHANGELOG.md",
        "build/build.sh",
        "src/skills",
        "platform/claude/plugin.json",
        "platform/codex/plugin.json",
        "platform/grok/plugin.json",
        "platform/agent-plugin/plugin.json",
        "platform/antigravity/plugin.json",
        "platform/antigravity/rules/invocation.md",
        ".claude-plugin/marketplace.json",
        ".agents/plugins/marketplace.json",
        ".grok-plugin/marketplace.json",
        ".github/plugin/marketplace.json",
        "LICENSE",
    ]
    missing = [item for item in required if not (root / item).exists()]
    if missing:
        raise VerificationError(f"missing required paths: {', '.join(missing)}")
    validate_json_files(root)
    validate_versions(root, tag)
    validate_marketplaces(root)
    validate_agent_plugin(root)
    validate_grok_package(root)
    validate_antigravity_package(root)
    validate_codex_invocation(root)
    validate_licenses(root)
    validate_decision_record_source_fidelity(root)
    validate_reproducible_build(root)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--tag", help="Validate a release tag such as v1.2.0")
    args = parser.parse_args()
    try:
        verify(args.root.resolve(), args.tag)
    except (VerificationError, OSError, ValueError) as exc:
        print(f"FAILED: {exc}", file=sys.stderr)
        return 1
    print("Repository verification passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
