#!/usr/bin/env python3
"""
generate_xcodeproj.py — генерирует LUMINA.xcodeproj из исходников.

Использование:
    cd ios-lumina
    python3 scripts/generate_xcodeproj.py

Этот скрипт — автономная замена XcodeGen для случая, когда у пользователя
не установлен `xcodegen`. Если у вас есть `xcodegen`, проще использовать:
    brew install xcodegen
    xcodegen generate
(скрипт читает project.yml и выдаст идентичный проект).

Сгенерированный проект ОДИНАКОВО открывается в Xcode 15+ / 16+ / 26+.
"""

from __future__ import annotations
import os
import sys
import uuid
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # ios-lumina/
APP_DIR = ROOT / "LUMINA"
TEST_DIR = ROOT / "LUMINATest"
UITEST_DIR = ROOT / "LUMINAUITests"
ASSETS = APP_DIR / "Assets.xcassets"
INFO_PLIST = APP_DIR / "Info.plist"
XCODEPROJ = ROOT / "LUMINA.xcodeproj"
PBXPROJ = XCODEPROJ / "project.pbxproj"
WORKSPACE_DATA = XCODEPROJ / "project.xcworkspace" / "contents.xcworkspacedata"


# ---------- helpers ----------

def _id_for(seed: str) -> str:
    """Детерминированный 24-символьный hex-ID на основе строки-семени."""
    h = hashlib.sha1(seed.encode("utf-8")).hexdigest()[:24].upper()
    return h


class O:
    """Простая обёртка для сериализации pbxproj-объекта."""
    def __init__(self, id_: str, body: str):
        self.id = id_
        self.body = body

    def __str__(self):
        return f"{self.id} = {self.body};"


class P:
    """Просто пара (key, value)."""
    def __init__(self, key: str, value: str):
        self.key = key
        self.value = value

    def __str__(self):
        return f"\t\t{self.key} = {self.value};"


def collect_swift_files(base: Path) -> list[Path]:
    if not base.exists():
        return []
    return sorted([p for p in base.rglob("*.swift")])


# ---------- IDs ----------

# Project-level
PROJ_ID = _id_for("PBXProject")
MAIN_GROUP_ID = _id_for("PBXGroup::Main")
PRODUCTS_GROUP_ID = _id_for("PBXGroup::Products")
APP_GROUP_ID = _id_for("PBXGroup::LUMINA")
TEST_GROUP_ID = _id_for("PBXGroup::LUMINATest")
UITEST_GROUP_ID = _id_for("PBXGroup::LUMINAUITests")
APP_SUBGROUPS = {
    "Components": _id_for("PBXGroup::LUMINA/Components"),
    "Core": _id_for("PBXGroup::LUMINA/Core"),
    "Features": _id_for("PBXGroup::LUMINA/Features"),
    "Views": _id_for("PBXGroup::LUMINA/Views"),
}

APP_TARGET_ID = _id_for("PBXNativeTarget::LUMINA")
TEST_TARGET_ID = _id_for("PBXNativeTarget::LUMINATest")
UITEST_TARGET_ID = _id_for("PBXNativeTarget::LUMINAUITests")

APP_BUNDLE_PROD_ID = _id_for("PBXFileReference::LUMINA.app")
TEST_BUNDLE_PROD_ID = _id_for("PBXFileReference::LUMINATest.xctest")
UITEST_BUNDLE_PROD_ID = _id_for("PBXFileReference::LUMINAUITests.xctest")

APP_BUILD_FILE_ASSETS_ID = _id_for("PBXBuildFile::Assets.xcassets")
APP_BUILD_FILE_INFO_PLIST_ID = _id_for("PBXFileReference::Info.plist")

# Config lists
APP_CONFIG_LIST_ID = _id_for("XCConfigurationList::LUMINA")
TEST_CONFIG_LIST_ID = _id_for("XCConfigurationList::LUMINATest")
UITEST_CONFIG_LIST_ID = _id_for("XCConfigurationList::LUMINAUITests")
PROJECT_CONFIG_LIST_ID = _id_for("XCConfigurationList::Project")

# Build configs
APP_DEBUG_CFG_ID = _id_for("XCBuildConfiguration::LUMINA::Debug")
APP_RELEASE_CFG_ID = _id_for("XCBuildConfiguration::LUMINA::Release")
TEST_DEBUG_CFG_ID = _id_for("XCBuildConfiguration::LUMINATest::Debug")
UITEST_DEBUG_CFG_ID = _id_for("XCBuildConfiguration::LUMINAUITests::Debug")
PROJ_DEBUG_CFG_ID = _id_for("XCBuildConfiguration::Project::Debug")
PROJ_RELEASE_CFG_ID = _id_for("XCBuildConfiguration::Project::Release")

# Build phases
APP_SOURCES_PHASE_ID = _id_for("PBXSourcesBuildPhase::LUMINA")
APP_FRAMEWORKS_PHASE_ID = _id_for("PBXFrameworksBuildPhase::LUMINA")
APP_RESOURCES_PHASE_ID = _id_for("PBXResourcesBuildPhase::LUMINA")
TEST_SOURCES_PHASE_ID = _id_for("PBXSourcesBuildPhase::LUMINATest")
TEST_FRAMEWORKS_PHASE_ID = _id_for("PBXFrameworksBuildPhase::LUMINATest")
UITEST_SOURCES_PHASE_ID = _id_for("PBXSourcesBuildPhase::LUMINAUITests")
UITEST_FRAMEWORKS_PHASE_ID = _id_for("PBXFrameworksBuildPhase::LUMINAUITests")

# Dependencies
APP_TARGET_DEP_TEST_ID = _id_for("PBXTargetDependency::LUMINATest")
APP_TARGET_DEP_UITEST_ID = _id_for("PBXTargetDependency::LUMINAUITests")
TEST_CONTAINER_PROXY_ID = _id_for("PBXContainerItemProxy::LUMINATest")
UITEST_CONTAINER_PROXY_ID = _id_for("PBXContainerItemProxy::LUMINAUITests")


# ---------- Generate file refs + build files for swift sources ----------

file_refs: list[O] = []
build_files: list[O] = []
group_children: dict[str, list[str]] = {APP_GROUP_ID: []}

# LUMINA.app's Info.plist is a FileReference (not built)
info_plist_ref_id = APP_BUILD_FILE_INFO_PLIST_ID  # we just need a ref

def add_file_ref(rel_path: str, group_id: str, *, is_source: bool, last_known_file_type: str = "sourcecode.swift") -> tuple[str, str | None]:
    """Создаёт PBXFileReference и (опционально) PBXBuildFile, возвращает (ref_id, build_file_id|None)."""
    seed = f"PBXFileReference::{rel_path}"
    ref_id = _id_for(seed)
    name = os.path.basename(rel_path)
    # path relative to group root
    rel = rel_path
    body = (
        "{\n"
        f"\t\t\tisa = PBXFileReference;\n"
        f"\t\t\tlastKnownFileType = {last_known_file_type};\n"
        f"\t\t\tname = {name};\n"
        f"\t\t\tpath = \"{rel}\";\n"
        f"\t\t\tsourceTree = \"<group>\";\n"
        "\t\t}"
    )
    file_refs.append(O(ref_id, body))
    group_children.setdefault(group_id, []).append(ref_id)

    build_file_id = None
    if is_source:
        bf_seed = f"PBXBuildFile::{rel_path}"
        build_file_id = _id_for(bf_seed)
        body = (
            "{\n"
            "\t\t\tisa = PBXBuildFile;\n"
            f"\t\t\tfileRef = {ref_id};\n"
            "\t\t}"
        )
        build_files.append(O(build_file_id, body))
    return ref_id, build_file_id


# Walk LUMINA/ and emit file refs grouped by top-level subdir
def group_for_path(rel_path: str) -> str:
    """Return group ID for a file inside LUMINA/."""
    parts = rel_path.split("/", 1)
    if len(parts) == 1:
        # top-level file directly under LUMINA/
        return APP_GROUP_ID
    top = parts[0]
    return APP_SUBGROUPS.get(top, APP_GROUP_ID)


# Collect app swift files (relative to LUMINA/)
app_swift_paths = collect_swift_files(APP_DIR)
app_source_build_file_ids: list[str] = []
for swift in app_swift_paths:
    rel = str(swift.relative_to(APP_DIR))
    _, bf_id = add_file_ref(rel, group_for_path(rel), is_source=True)
    assert bf_id is not None
    app_source_build_file_ids.append(bf_id)

# Add Info.plist as a non-source FileReference (so Xcode shows it in the group)
add_file_ref("Info.plist", APP_GROUP_ID, is_source=False, last_known_file_type="text.plist.xml")

# Add Assets.xcassets as a FileReference + BuildFile (resource)
assets_rel = "Assets.xcassets"
assets_ref_seed = "PBXFileReference::Assets.xcassets"
assets_ref_id = _id_for(assets_ref_seed)
file_refs.append(O(assets_ref_id,
    "{\n"
    "\t\t\tisa = PBXFileReference;\n"
    "\t\t\tlastKnownFileType = folder.assetcatalog;\n"
    f"\t\t\tname = {assets_rel};\n"
    f"\t\t\tpath = \"{assets_rel}\";\n"
    "\t\t\tsourceTree = \"<group>\";\n"
    "\t\t}"
))
group_children.setdefault(APP_GROUP_ID, []).append(assets_ref_id)

assets_bf_body = (
    "{\n"
    "\t\t\tisa = PBXBuildFile;\n"
    f"\t\t\tfileRef = {assets_ref_id};\n"
    "\t\t}"
)
build_files.append(O(APP_BUILD_FILE_ASSETS_ID, assets_bf_body))

# Test sources (no subgroups, flat)
test_swift_paths = collect_swift_files(TEST_DIR)
test_source_build_file_ids: list[str] = []
for swift in test_swift_paths:
    rel = str(swift.relative_to(TEST_DIR))
    _, bf_id = add_file_ref(rel, TEST_GROUP_ID, is_source=True)
    if bf_id:
        test_source_build_file_ids.append(bf_id)

# UI test sources
uitest_swift_paths = collect_swift_files(UITEST_DIR)
uitest_source_build_file_ids: list[str] = []
for swift in uitest_swift_paths:
    rel = str(swift.relative_to(UITEST_DIR))
    _, bf_id = add_file_ref(rel, UITEST_GROUP_ID, is_source=True)
    if bf_id:
        uitest_source_build_file_ids.append(bf_id)


# ---------- Build phase contents ----------

app_sources_phase_body = (
    "{\n"
    "\t\t\tisa = PBXSourcesBuildPhase;\n"
    "\t\t\tbuildActionMask = 2147483647;\n"
    "\t\t\tfiles = (\n"
    + "".join(f"\t\t\t\t{bf},\n" for bf in app_source_build_file_ids)
    + "\t\t\t);\n"
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
    "\t\t}"
)
app_frameworks_phase_body = (
    "{\n"
    "\t\t\tisa = PBXFrameworksBuildPhase;\n"
    "\t\t\tbuildActionMask = 2147483647;\n"
    "\t\t\tfiles = (\n"
    "\t\t\t);\n"
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
    "\t\t}"
)
app_resources_phase_body = (
    "{\n"
    "\t\t\tisa = PBXResourcesBuildPhase;\n"
    "\t\t\tbuildActionMask = 2147483647;\n"
    "\t\t\tfiles = (\n"
    f"\t\t\t\t{APP_BUILD_FILE_ASSETS_ID},\n"
    "\t\t\t);\n"
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
    "\t\t}"
)
test_sources_phase_body = (
    "{\n"
    "\t\t\tisa = PBXSourcesBuildPhase;\n"
    "\t\t\tbuildActionMask = 2147483647;\n"
    "\t\t\tfiles = (\n"
    + "".join(f"\t\t\t\t{bf},\n" for bf in test_source_build_file_ids)
    + "\t\t\t);\n"
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
    "\t\t}"
)
test_frameworks_phase_body = (
    "{\n"
    "\t\t\tisa = PBXFrameworksBuildPhase;\n"
    "\t\t\tbuildActionMask = 2147483647;\n"
    "\t\t\tfiles = (\n"
    "\t\t\t);\n"
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
    "\t\t}"
)
uitest_sources_phase_body = (
    "{\n"
    "\t\t\tisa = PBXSourcesBuildPhase;\n"
    "\t\t\tbuildActionMask = 2147483647;\n"
    "\t\t\tfiles = (\n"
    + "".join(f"\t\t\t\t{bf},\n" for bf in uitest_source_build_file_ids)
    + "\t\t\t);\n"
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
    "\t\t}"
)
uitest_frameworks_phase_body = (
    "{\n"
    "\t\t\tisa = PBXFrameworksBuildPhase;\n"
    "\t\t\tbuildActionMask = 2147483647;\n"
    "\t\t\tfiles = (\n"
    "\t\t\t);\n"
    "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
    "\t\t}"
)


# ---------- Product file references ----------

products = [
    O(APP_BUNDLE_PROD_ID, (
        "{\n"
        "\t\t\tisa = PBXFileReference;\n"
        "\t\t\texplicitFileType = wrapper.application;\n"
        "\t\t\tincludeInIndex = 0;\n"
        "\t\t\tpath = LUMINA.app;\n"
        "\t\t\tsourceTree = BUILT_PRODUCTS_DIR;\n"
        "\t\t}"
    )),
    O(TEST_BUNDLE_PROD_ID, (
        "{\n"
        "\t\t\tisa = PBXFileReference;\n"
        "\t\t\texplicitFileType = wrapper.cfbundle;\n"
        "\t\t\tincludeInIndex = 0;\n"
        "\t\t\tpath = LUMINATest.xctest;\n"
        "\t\t\tsourceTree = BUILT_PRODUCTS_DIR;\n"
        "\t\t}"
    )),
    O(UITEST_BUNDLE_PROD_ID, (
        "{\n"
        "\t\t\tisa = PBXFileReference;\n"
        "\t\t\texplicitFileType = wrapper.cfbundle;\n"
        "\t\t\tincludeInIndex = 0;\n"
        "\t\t\tpath = LUMINAUITests.xctest;\n"
        "\t\t\tsourceTree = BUILT_PRODUCTS_DIR;\n"
        "\t\t}"
    )),
]


# ---------- Groups ----------

# Subgroups of LUMINA/: Components, Core, Features, Views
# Core has Models/Services/Utilities/ViewModels sub-dirs; Features has Admin/Auth/Chat/Settings.
# To keep things simple, we collapse the deeper nesting into a flat subgroup listing per top-level dir,
# but still show them under their proper parent groups.

def group_body(name: str, children_ids: list[str], path: str | None = None, source_tree: str = "<group>") -> str:
    path_line = f'\t\t\tpath = "{path}";\n' if path else ""
    return (
        "{\n"
        + "\t\t\tisa = PBXGroup;\n"
        + "\t\t\tchildren = (\n"
        + "".join(f"\t\t\t\t{c},\n" for c in children_ids)
        + "\t\t\t);\n"
        + f"\t\t\tname = {name};\n"
        + path_line
        + f"\t\t\tsourceTree = {source_tree};\n"
        + "\t\t}"
    )


# For each top-level subgroup, collect children files that belong to it (by path prefix)
def collect_subgroup(top: str) -> list[str]:
    """All file refs whose rel_path starts with `top/`."""
    ids: list[str] = []
    for o in file_refs:
        # We stored group via group_for_path; re-derive from id->path is hard.
        # Easier: regenerate from file list.
        pass
    return ids


# Rebuild group_children properly using file paths we've recorded.
# To do this cleanly, track an aux map: ref_id -> rel_path
ref_id_to_path: dict[str, str] = {}
# We didn't keep this map, so rebuild by re-walking and recomputing IDs.
for swift in app_swift_paths:
    rel = str(swift.relative_to(APP_DIR))
    ref_id = _id_for(f"PBXFileReference::{rel}")
    ref_id_to_path[ref_id] = rel
# Info.plist
ref_id_to_path[_id_for("PBXFileReference::Info.plist")] = "Info.plist"
# Assets
ref_id_to_path[_id_for("PBXFileReference::Assets.xcassets")] = "Assets.xcassets"

# Now assign each ref to its proper subgroup
group_children = {APP_GROUP_ID: [], TEST_GROUP_ID: [], UITEST_GROUP_ID: []}
for top, gid in APP_SUBGROUPS.items():
    group_children[gid] = []

for ref_id, rel in ref_id_to_path.items():
    parts = rel.split("/", 1)
    if len(parts) == 1:
        group_children[APP_GROUP_ID].append(ref_id)
    else:
        top = parts[0]
        gid = APP_SUBGROUPS.get(top, APP_GROUP_ID)
        group_children[gid].append(ref_id)

# Test/UITest groups: flat
for swift in test_swift_paths:
    rel = str(swift.relative_to(TEST_DIR))
    ref_id = _id_for(f"PBXFileReference::{rel}")
    group_children[TEST_GROUP_ID].append(ref_id)
for swift in uitest_swift_paths:
    rel = str(swift.relative_to(UITEST_DIR))
    ref_id = _id_for(f"PBXFileReference::{rel}")
    group_children[UITEST_GROUP_ID].append(ref_id)


# Sub-subgroups under Core/Features: collapse for simplicity — all files under Core/* go to one Core group,
# but we'll create proper hierarchy with Core/Models, Core/Services etc. for nicer UX.

CORE_SUB = {
    "Models": _id_for("PBXGroup::LUMINA/Core/Models"),
    "Services": _id_for("PBXGroup::LUMINA/Core/Services"),
    "Utilities": _id_for("PBXGroup::LUMINA/Core/Utilities"),
    "ViewModels": _id_for("PBXGroup::LUMINA/Core/ViewModels"),
}
FEAT_SUB = {
    "Admin": _id_for("PBXGroup::LUMINA/Features/Admin"),
    "Auth": _id_for("PBXGroup::LUMINA/Features/Auth"),
    "Chat": _id_for("PBXGroup::LUMINA/Features/Chat"),
    "Settings": _id_for("PBXGroup::LUMINA/Features/Settings"),
}

core_children: dict[str, list[str]] = {gid: [] for gid in CORE_SUB.values()}
feat_children: dict[str, list[str]] = {gid: [] for gid in FEAT_SUB.values()}

for ref_id, rel in ref_id_to_path.items():
    parts = rel.split("/", 2)
    if len(parts) >= 3:
        top, sub, _ = parts
        if top == "Core" and sub in CORE_SUB:
            core_children[CORE_SUB[sub]].append(ref_id)
            # remove from parent Core group
            if ref_id in group_children[APP_SUBGROUPS["Core"]]:
                group_children[APP_SUBGROUPS["Core"]].remove(ref_id)
        elif top == "Features" and sub in FEAT_SUB:
            feat_children[FEAT_SUB[sub]].append(ref_id)
            if ref_id in group_children[APP_SUBGROUPS["Features"]]:
                group_children[APP_SUBGROUPS["Features"]].remove(ref_id)

# Core group children = subgroup IDs
group_children[APP_SUBGROUPS["Core"]].extend(CORE_SUB.values())
# Features group children = subgroup IDs
group_children[APP_SUBGROUPS["Features"]].extend(FEAT_SUB.values())

# Build all group objects
groups: list[O] = []
groups.append(O(MAIN_GROUP_ID, group_body("Main", [
    APP_GROUP_ID, TEST_GROUP_ID, UITEST_GROUP_ID, PRODUCTS_GROUP_ID,
])))
groups.append(O(PRODUCTS_GROUP_ID, group_body("Products", [
    APP_BUNDLE_PROD_ID, TEST_BUNDLE_PROD_ID, UITEST_BUNDLE_PROD_ID,
])))
groups.append(O(APP_GROUP_ID, group_body("LUMINA", group_children[APP_GROUP_ID], path="LUMINA")))
groups.append(O(TEST_GROUP_ID, group_body("LUMINATest", group_children[TEST_GROUP_ID], path="LUMINATest")))
groups.append(O(UITEST_GROUP_ID, group_body("LUMINAUITests", group_children[UITEST_GROUP_ID], path="LUMINAUITests")))
for top, gid in APP_SUBGROUPS.items():
    if top in ("Core", "Features"):
        continue
    groups.append(O(gid, group_body(top, group_children[gid], path=f"LUMINA/{top}")))
groups.append(O(APP_SUBGROUPS["Core"], group_body("Core", list(CORE_SUB.values()), path="LUMINA/Core")))
groups.append(O(APP_SUBGROUPS["Features"], group_body("Features", list(FEAT_SUB.values()), path="LUMINA/Features")))
for sub, gid in CORE_SUB.items():
    groups.append(O(gid, group_body(sub, core_children[gid], path=f"LUMINA/Core/{sub}")))
for sub, gid in FEAT_SUB.items():
    groups.append(O(gid, group_body(sub, feat_children[gid], path=f"LUMINA/Features/{sub}")))


# ---------- Build configs ----------

proj_debug_body = """{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_PRECOMPILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.9;
\t\t\t};
\t\t\tname = Debug;
\t\t}"""

proj_release_body = """{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_VERSION = 5.9;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t};
\t\t\tname = Release;
\t\t}"""

app_debug_body = """{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentBlue;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = LUMINA/Info.plist;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";
\t\t\t\tMARKETING_VERSION = 11.96;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.lumina.LUMINA;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t};
\t\t\tname = Debug;
\t\t}"""

app_release_body = app_debug_body.replace('name = Debug;', 'name = Release;')

test_debug_body = """{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.lumina.LUMINATest;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/LUMINA.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/LUMINA";
\t\t\t};
\t\t\tname = Debug;
\t\t}"""

uitest_debug_body = """{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.lumina.LUMINAUITests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_TARGET_NAME = LUMINA;
\t\t\t};
\t\t\tname = Debug;
\t\t}"""


# ---------- Targets ----------

app_target_body = (
    "{\n"
    "\t\t\tisa = PBXNativeTarget;\n"
    "\t\t\tbuildConfigurationList = " + APP_CONFIG_LIST_ID + ";\n"
    "\t\t\tbuildPhases = (\n"
    f"\t\t\t\t{APP_SOURCES_PHASE_ID},\n"
    f"\t\t\t\t{APP_FRAMEWORKS_PHASE_ID},\n"
    f"\t\t\t\t{APP_RESOURCES_PHASE_ID},\n"
    "\t\t\t);\n"
    "\t\t\tbuildRules = (\n"
    "\t\t\t);\n"
    "\t\t\tdependencies = (\n"
    "\t\t\t);\n"
    "\t\t\tname = LUMINA;\n"
    f"\t\t\tproductName = LUMINA;\n"
    f"\t\t\tproductReference = {APP_BUNDLE_PROD_ID};\n"
    "\t\t\tproductType = \"com.apple.product-type.application\";\n"
    "\t\t}"
)

test_target_body = (
    "{\n"
    "\t\t\tisa = PBXNativeTarget;\n"
    "\t\t\tbuildConfigurationList = " + TEST_CONFIG_LIST_ID + ";\n"
    "\t\t\tbuildPhases = (\n"
    f"\t\t\t\t{TEST_SOURCES_PHASE_ID},\n"
    f"\t\t\t\t{TEST_FRAMEWORKS_PHASE_ID},\n"
    "\t\t\t);\n"
    "\t\t\tbuildRules = (\n"
    "\t\t\t);\n"
    "\t\t\tdependencies = (\n"
    f"\t\t\t\t{APP_TARGET_DEP_TEST_ID},\n"
    "\t\t\t);\n"
    "\t\t\tname = LUMINATest;\n"
    "\t\t\tproductName = LUMINATest;\n"
    f"\t\t\tproductReference = {TEST_BUNDLE_PROD_ID};\n"
    "\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";\n"
    "\t\t}"
)

uitest_target_body = (
    "{\n"
    "\t\t\tisa = PBXNativeTarget;\n"
    "\t\t\tbuildConfigurationList = " + UITEST_CONFIG_LIST_ID + ";\n"
    "\t\t\tbuildPhases = (\n"
    f"\t\t\t\t{UITEST_SOURCES_PHASE_ID},\n"
    f"\t\t\t\t{UITEST_FRAMEWORKS_PHASE_ID},\n"
    "\t\t\t);\n"
    "\t\t\tbuildRules = (\n"
    "\t\t\t);\n"
    "\t\t\tdependencies = (\n"
    f"\t\t\t\t{APP_TARGET_DEP_UITEST_ID},\n"
    "\t\t\t);\n"
    "\t\t\tname = LUMINAUITests;\n"
    "\t\t\tproductName = LUMINAUITests;\n"
    f"\t\t\tproductReference = {UITEST_BUNDLE_PROD_ID};\n"
    "\t\t\tproductType = \"com.apple.product-type.bundle.ui-testing\";\n"
    "\t\t}"
)

# Container item proxies
test_proxy_body = (
    "{\n"
    "\t\t\tisa = PBXContainerItemProxy;\n"
    "\t\t\tcontainerPortal = " + PROJ_ID + ";\n"
    "\t\t\tproxyType = 1;\n"
    f"\t\t\tremoteGlobalIDString = {APP_TARGET_ID};\n"
    "\t\t\tremoteInfo = LUMINA;\n"
    "\t\t}"
)
uitest_proxy_body = test_proxy_body.replace(TEST_CONTAINER_PROXY_ID, UITEST_CONTAINER_PROXY_ID)

# Target dependencies
test_dep_body = (
    "{\n"
    "\t\t\tisa = PBXTargetDependency;\n"
    f"\t\t\ttarget = {APP_TARGET_ID};\n"
    f"\t\t\ttargetProxy = {TEST_CONTAINER_PROXY_ID};\n"
    "\t\t}"
)
uitest_dep_body = (
    "{\n"
    "\t\t\tisa = PBXTargetDependency;\n"
    f"\t\t\ttarget = {APP_TARGET_ID};\n"
    f"\t\t\ttargetProxy = {UITEST_CONTAINER_PROXY_ID};\n"
    "\t\t}"
)


# ---------- XCConfigurationLists ----------

def config_list_body(config_ids: list[str], default_cfg_name: str) -> str:
    return (
        "{\n"
        "\t\t\tisa = XCConfigurationList;\n"
        "\t\t\tbuildConfigurations = (\n"
        + "".join(f"\t\t\t\t{c},\n" for c in config_ids)
        + "\t\t\t);\n"
        f"\t\t\tdefaultConfiguration = {default_cfg_name};\n"
        "\t\t\tdefaultConfigurationName = Default;\n"
        "\t\t}"
    )

project_cfg_list_body = config_list_body([PROJ_DEBUG_CFG_ID, PROJ_RELEASE_CFG_ID], "Release")
app_cfg_list_body = config_list_body([APP_DEBUG_CFG_ID, APP_RELEASE_CFG_ID], "Release")
test_cfg_list_body = config_list_body([TEST_DEBUG_CFG_ID], "Debug")
uitest_cfg_list_body = config_list_body([UITEST_DEBUG_CFG_ID], "Debug")


# ---------- PBXProject ----------

project_body = (
    "{\n"
    "\t\t\tisa = PBXProject;\n"
    f"\t\t\tbuildConfigurationList = {PROJECT_CONFIG_LIST_ID};\n"
    "\t\t\tcompatibilityVersion = \"Xcode 14.0\";\n"
    "\t\t\tdevelopmentRegion = ru;\n"
    "\t\t\thasScannedForEncodings = 0;\n"
    "\t\t\tknownRegions = (ru, Base, en);\n"
    "\t\t\tmainGroup = " + MAIN_GROUP_ID + ";\n"
    f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID};\n"
    "\t\t\tprojectDirPath = \"\";\n"
    "\t\t\tprojectRoot = \"\";\n"
    "\t\t\ttargets = (\n"
    f"\t\t\t\t{APP_TARGET_ID},\n"
    f"\t\t\t\t{TEST_TARGET_ID},\n"
    f"\t\t\t\t{UITEST_TARGET_ID},\n"
    "\t\t\t);\n"
    "\t\t}"
)


# ---------- Serialize ----------

XCODEPROJ.mkdir(exist_ok=True)
(WORKSPACE_DATA).parent.mkdir(parents=True, exist_ok=True)

# workspace data
WORKSPACE_DATA.write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<Workspace version = "1.0">\n'
    f'\t<FileRef location = "self:LUMINA.xcodeproj"></FileRef>\n'
    '</Workspace>\n',
    encoding="utf-8",
)

# pbxproj
sections = []

# PBXBuildFile
sections.append("/* Begin PBXBuildFile section */")
for o in build_files:
    sections.append(f"\t\t{o}")
sections.append("/* End PBXBuildFile section */")

# PBXFileReference
sections.append("/* Begin PBXFileReference section */")
for o in file_refs:
    sections.append(f"\t\t{o}")
for o in products:
    sections.append(f"\t\t{o}")
sections.append("/* End PBXFileReference section */")

# PBXFrameworksBuildPhase
sections.append("/* Begin PBXFrameworksBuildPhase section */")
sections.append(f"\t\t{O(APP_FRAMEWORKS_PHASE_ID, app_frameworks_phase_body)}")
sections.append(f"\t\t{O(TEST_FRAMEWORKS_PHASE_ID, test_frameworks_phase_body)}")
sections.append(f"\t\t{O(UITEST_FRAMEWORKS_PHASE_ID, uitest_frameworks_phase_body)}")
sections.append("/* End PBXFrameworksBuildPhase section */")

# PBXGroup
sections.append("/* Begin PBXGroup section */")
for o in groups:
    sections.append(f"\t\t{o}")
sections.append("/* End PBXGroup section */")

# PBXNativeTarget
sections.append("/* Begin PBXNativeTarget section */")
sections.append(f"\t\t{O(APP_TARGET_ID, app_target_body)}")
sections.append(f"\t\t{O(TEST_TARGET_ID, test_target_body)}")
sections.append(f"\t\t{O(UITEST_TARGET_ID, uitest_target_body)}")
sections.append("/* End PBXNativeTarget section */")

# PBXProject
sections.append("/* Begin PBXProject section */")
sections.append(f"\t\t{O(PROJ_ID, project_body)}")
sections.append("/* End PBXProject section */")

# PBXResourcesBuildPhase
sections.append("/* Begin PBXResourcesBuildPhase section */")
sections.append(f"\t\t{O(APP_RESOURCES_PHASE_ID, app_resources_phase_body)}")
sections.append("/* End PBXResourcesBuildPhase section */")

# PBXSourcesBuildPhase
sections.append("/* Begin PBXSourcesBuildPhase section */")
sections.append(f"\t\t{O(APP_SOURCES_PHASE_ID, app_sources_phase_body)}")
sections.append(f"\t\t{O(TEST_SOURCES_PHASE_ID, test_sources_phase_body)}")
sections.append(f"\t\t{O(UITEST_SOURCES_PHASE_ID, uitest_sources_phase_body)}")
sections.append("/* End PBXSourcesBuildPhase section */")

# PBXTargetDependency
sections.append("/* Begin PBXTargetDependency section */")
sections.append(f"\t\t{O(APP_TARGET_DEP_TEST_ID, test_dep_body)}")
sections.append(f"\t\t{O(APP_TARGET_DEP_UITEST_ID, uitest_dep_body)}")
sections.append("/* End PBXTargetDependency section */")

# PBXContainerItemProxy
sections.append("/* Begin PBXContainerItemProxy section */")
sections.append(f"\t\t{O(TEST_CONTAINER_PROXY_ID, test_proxy_body)}")
sections.append(f"\t\t{O(UITEST_CONTAINER_PROXY_ID, uitest_proxy_body)}")
sections.append("/* End PBXContainerItemProxy section */")

# XCBuildConfiguration
sections.append("/* Begin XCBuildConfiguration section */")
sections.append(f"\t\t{O(PROJ_DEBUG_CFG_ID, proj_debug_body)}")
sections.append(f"\t\t{O(PROJ_RELEASE_CFG_ID, proj_release_body)}")
sections.append(f"\t\t{O(APP_DEBUG_CFG_ID, app_debug_body)}")
sections.append(f"\t\t{O(APP_RELEASE_CFG_ID, app_release_body)}")
sections.append(f"\t\t{O(TEST_DEBUG_CFG_ID, test_debug_body)}")
sections.append(f"\t\t{O(UITEST_DEBUG_CFG_ID, uitest_debug_body)}")
sections.append("/* End XCBuildConfiguration section */")

# XCConfigurationList
sections.append("/* Begin XCConfigurationList section */")
sections.append(f"\t\t{O(PROJECT_CONFIG_LIST_ID, project_cfg_list_body)}")
sections.append(f"\t\t{O(APP_CONFIG_LIST_ID, app_cfg_list_body)}")
sections.append(f"\t\t{O(TEST_CONFIG_LIST_ID, test_cfg_list_body)}")
sections.append(f"\t\t{O(UITEST_CONFIG_LIST_ID, uitest_cfg_list_body)}")
sections.append("/* End XCConfigurationList section */")

content = (
    "// !$*UTF8*$!\n"
    "{\n"
    "\tarchiveVersion = 1;\n"
    "\tclasses = {\n"
    "\t};\n"
    "\tobjectVersion = 56;\n"
    "\tobjects = {\n"
    + "\n".join(sections)
    + "\n\t};\n"
    "\trootObject = " + PROJ_ID + ";\n"
    "}\n"
)

PBXPROJ.write_text(content, encoding="utf-8")
print(f"✅ Сгенерирован {XCODEPROJ.relative_to(ROOT)}")
print(f"   Файлов swift (app): {len(app_swift_paths)}")
print(f"   Файлов swift (test): {len(test_swift_paths)}")
print(f"   Файлов swift (uitest): {len(uitest_swift_paths)}")
print(f"   Build files: {len(build_files)}")
print(f"   File refs: {len(file_refs) + len(products)}")
print(f"   Размер pbxproj: {PBXPROJ.stat().st_size} байт")
