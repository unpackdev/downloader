// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Base64.sol";

contract TerralootSrc {
    string internal constant OUTFIT = "Outfit";
    string internal constant TOOL = "Tool";
    string internal constant HANDHELD = "Handheld Gadget";
    string internal constant WEARABLE = "Wearable Gadget";
    string internal constant SHOULDER = "Shoulder Gadget";
    string internal constant BACKPACK = "Backpack";
    string internal constant EXTERNAL = "External Gadget";
    string internal constant RIG = "Rig";

    string[] public outfits = [
        "Recon Suit",
        "Tool Harness",
        "Opticamo",
        "Envirosuit",
        "Wingsuit",
        "Nanosuit",
        "Z Series",
        "Tough Gear",
        "Thermafoil",
        "Jumpsuit",
        "Exosuit",
        "Rockbuster"
    ];

    string[] public tools = [
        "Optical Drill",
        "Ore Laser",
        "Arc Welder",
        "Vibrahammer",
        "Nano Saw",
        "Plasma Cutter",
        "Thermal Lance",
        "Shatter Beam",
        "Pulsecaster",
        "Shovel"
    ];

    string[] public handheldGadgets = [
        "Shaped Charge",
        "Multitool",
        "Geomorpher",
        "Ascender",
        "Flare Launcher",
        "Sampling Probe",
        "Holo Scanner",
        "Zero Point Shifter"
    ];

    string[] public externalGadgets = [
        "UAV",
        "UGV",
        "Speedwheel",
        "Scootbike",
        "Lab Kit",
        "Ground Radar",
        "Duneboard",
        "Glider"
    ];

    string[] public wearableGadgets = [
        "Spectrograph",
        "Utility Belt",
        "Transponder",
        "Magtool",
        "Grip Gloves",
        "Landing Absorbers",
        "Line Launcher",
        "Rappel Belt"
    ];

    string[] public shoulderGadgets = [
        "SuperCam",
        "Soundbar",
        "LIDAR System",
        "Imaging Sonar",
        "Holo Projector",
        "Beam Designator",
        "Hook Launcher",
        "Floodlight"
    ];

    string[] public backpacks = [
        "Faraday Shield",
        "Satlink",
        "Charge Pack",
        "Booster",
        "Big Box",
        "Parachute",
        "Solar Array",
        "Power Arm"
    ];

    string[] public rigs = [
        "Polymer Web",
        "Turbofan",
        "Ore Breaker",
        "Area Shield",
        "Meshnet Node",
        "Ground Station",
        "Power Core",
        "Tesla Coil",
        "Balloon",
        "Replicator",
        "Drill Stack",
        "Modular Reactor"
    ];

    string[] public suffixes = [
        hex"E29AA1EFB88F",
        hex"F09F8EB2",
        hex"F09F9BB8",
        hex"F09F8C8E",
        hex"F09FAA90",
        hex"F09FA78A",
        hex"F09F948B",
        hex"F09F928E",
        hex"E29CA8",
        hex"F09FA7B2",
        hex"F09FA6BE",
        hex"F09F93A1",
        hex"F09F9BA1",
        hex"F09F9BA0",
        hex"E28FB1",
        hex"F09F9BB0"
    ];

    string[] public bonuses = [
        "Titanium",
        "Platinum",
        "Graphene",
        "Diamond",
        "Fission",
        "Entropy",
        "Alkali",
        "Plasma",
        "Fusion",
        "Prime",
        "Alpha",
        "Earth",
        "Polar",
        "Beta",
        "Acid",
        "Mass",
        "Ion"
    ];

    string[] public prefixes = [
        "Magnetized",
        "Galvanized",
        "Calibrated",
        "Serialized",
        "Converted",
        "Magnified",
        "Certified",
        "Activated",
        "Energized",
        "Regulated",
        "Refitted",
        "Enhanced",
        "Oxidized",
        "Adjusted",
        "Upgraded",
        "Modified",
        "Charged",
        "Plated",
        "Tuned"
    ];

    function getOutfit(bytes32 _rand) public view returns (string memory) {
        return format(getOutfitComponents(_rand), outfits);
    }

    function getOutfitComponents(bytes32 _rand)
        public
        view
        returns (uint256[4] memory)
    {
        return pluck(random(OUTFIT, _rand), outfits);
    }

    function getTool(bytes32 _rand) public view returns (string memory) {
        return format(getToolComponents(_rand), tools);
    }

    function getToolComponents(bytes32 _rand)
        public
        view
        returns (uint256[4] memory)
    {
        return pluck(random(TOOL, _rand), tools);
    }

    function getHandheld(bytes32 _rand) public view returns (string memory) {
        return format(getHandheldComponents(_rand), handheldGadgets);
    }

    function getHandheldComponents(bytes32 _rand)
        public
        view
        returns (uint256[4] memory)
    {
        return pluck(random(HANDHELD, _rand), handheldGadgets);
    }

    function getWearable(bytes32 _rand) public view returns (string memory) {
        return format(getWearableComponents(_rand), wearableGadgets);
    }

    function getWearableComponents(bytes32 _rand)
        public
        view
        returns (uint256[4] memory)
    {
        return pluck(random(WEARABLE, _rand), wearableGadgets);
    }

    function getShoulder(bytes32 _rand) public view returns (string memory) {
        return format(getShoulderComponents(_rand), shoulderGadgets);
    }

    function getShoulderComponents(bytes32 _rand)
        public
        view
        returns (uint256[4] memory)
    {
        return pluck(random(SHOULDER, _rand), shoulderGadgets);
    }

    function getExternal(bytes32 _rand) public view returns (string memory) {
        return format(getExternalComponents(_rand), externalGadgets);
    }

    function getExternalComponents(bytes32 _rand)
        public
        view
        returns (uint256[4] memory)
    {
        return pluck(random(EXTERNAL, _rand), externalGadgets);
    }

    function getBackpack(bytes32 _rand) public view returns (string memory) {
        return format(getBackpackComponents(_rand), backpacks);
    }

    function getBackpackComponents(bytes32 _rand)
        public
        view
        returns (uint256[4] memory)
    {
        return pluck(random(BACKPACK, _rand), backpacks);
    }

    function getRig(bytes32 _rand) public view returns (string memory) {
        return format(getRigComponents(_rand), rigs);
    }

    function getRigComponents(bytes32 _rand)
        public
        view
        returns (uint256[4] memory)
    {
        return pluck(random(RIG, _rand), rigs);
    }

    function pluck(uint256 _rand, string[] memory _xs)
        internal
        view
        returns (uint256[4] memory components)
    {
        components[0] = _rand % _xs.length;

        uint256 greatness = _rand % 21;

        uint256 bump = uint256(
            keccak256(abi.encodePacked(components[0], greatness, _rand))
        );

        if (greatness >= 15) {
            components[1] = (bump % prefixes.length) + 1;
        }
        if (greatness >= 18) {
            components[2] = (bump % bonuses.length) + 1;
        }
        if (greatness >= 20) {
            components[3] = (bump % suffixes.length) + 1;
        }
    }

    function random(string memory _tag, bytes32 _rand)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_tag, _rand)));
    }

    function format(uint256[4] memory _components, string[] memory _xs)
        internal
        view
        returns (string memory)
    {
        string memory prefix = _components[2] > 0
            ? string(
                abi.encodePacked(
                    unicode"“",
                    bonuses[_components[2] - 1],
                    " ",
                    prefixes[_components[1] - 1],
                    unicode"” "
                )
            )
            : _components[1] > 0
            ? string(
                abi.encodePacked(
                    unicode"“",
                    prefixes[_components[1] - 1],
                    unicode"” "
                )
            )
            : "";

        string memory suffix = _components[3] > 0
            ? string(abi.encodePacked(" ", suffixes[_components[3] - 1]))
            : "";

        return string(abi.encodePacked(prefix, _xs[_components[0]], suffix));
    }

    function build(bytes calldata _name, bytes32 _rand)
        public
        view
        returns (string memory)
    {
        string[8] memory loot = [
            getOutfit(_rand),
            getTool(_rand),
            getHandheld(_rand),
            getWearable(_rand),
            getShoulder(_rand),
            getBackpack(_rand),
            getExternal(_rand),
            getRig(_rand)
        ];

        bytes memory attrs = abi.encodePacked(
            makeAttr(OUTFIT, loot[0]),
            ",",
            makeAttr(TOOL, loot[1]),
            ",",
            makeAttr(HANDHELD, loot[2]),
            ",",
            makeAttr(WEARABLE, loot[3]),
            ",",
            makeAttr(SHOULDER, loot[4]),
            ",",
            makeAttr(BACKPACK, loot[5]),
            ",",
            makeAttr(EXTERNAL, loot[6]),
            ",",
            makeAttr(RIG, loot[7])
        );

        bytes memory svg = makeSvg(_name, loot);

        return makeJson(_name, svg, attrs);
    }

    function makeJson(
        bytes calldata _name,
        bytes memory _svg,
        bytes memory _attrs
    ) internal pure returns (string memory) {
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "Mars has a future. Acquire the tools to take part.", "image": "data:image/svg+xml;base64,',
                Base64.encode(_svg),
                '", "attributes": [',
                _attrs,
                "]}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function textTag(string memory _txt, string memory _yPos)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked('<text x="8" y="', _yPos, '">', _txt, "</text>");
    }

    function makeAttr(string memory _k, string memory _v)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked('{"trait_type": "', _k, '", "value": "', _v, '"}');
    }

    function makeSvg(bytes calldata _name, string[8] memory _loot)
        internal
        pure
        returns (bytes memory)
    {
        string
            memory head = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><defs><clipPath id="clp"><rect width="100%" height="100%"/></clipPath></defs><style>text{fill:#fff;font-family:Source Code Pro;font-size:13px}.tag{font-size:24px}ellipse{clip-path:url(#clp)}</style><rect width="100%" height="100%" fill="#000020"/><ellipse cx="320" cy="320" rx="130" ry="130" fill="#c32205"/>';

        bytes memory loots = abi.encodePacked(
            textTag(_loot[0], "20"),
            textTag(_loot[1], "43"),
            textTag(_loot[2], "66"),
            textTag(_loot[3], "89"),
            textTag(_loot[4], "112"),
            textTag(_loot[5], "135"),
            textTag(_loot[6], "158"),
            textTag(_loot[7], "181")
        );

        return
            abi.encodePacked(
                head,
                abi.encodePacked(
                    '<text x="240" y="335" class="tag">',
                    _name,
                    "</text>"
                ),
                loots,
                "</svg>"
            );
    }
}
