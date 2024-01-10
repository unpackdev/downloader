//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
import "./Utils.sol";

// Primary library for storing all core constants and rendering data.
library WatchData {
    /* CONSTANTS */
    uint256 public constant WATCH_SIZE = 360;
    uint256 public constant CENTER = 180;
    uint256 public constant OUTER_BEZEL_RADIUS = 180;
    uint256 public constant INNER_BEZEL_RADIUS = 152;
    uint256 public constant FACE_RADIUS = 144; // OUTER_BEZEL_RADIUS * 0.8
    uint8 public constant GLOW_IN_THE_DARK_ID = 99;

    /* IDs */
    enum MaterialId {
        Pearl,
        Copper,
        Onyx,
        Quartz,
        Emerald,
        Ruby,
        Sapphire,
        Amber,
        Amethyst,
        Obsidian,
        Gold,
        Diamond
    }

    enum MoodId {
        Surprised,
        Happy,
        Relaxed,
        Excited,
        Speechless,
        Chilling,
        Annoyed,
        Sleepy,
        Unimpressed,
        Meditating,
        Relieved,
        Cheeky,
        Sus
    }

    enum GlassesId {
        None,
        LeftMonocle,
        RightMonocle,
        Flip,
        Valentine,
        Shutters,
        ThreeD,
        Ski,
        Monolens
    }

    /* TRAIT STRUCTS */
    struct Material {
        MaterialId id;
        string name;
        string[2] vals;
        uint256 supply;
    }

    struct Glasses {
        GlassesId id;
        string name;
        uint256 supply;
    }

    struct Mood {
        MoodId id;
        string name;
        uint256 supply;
    }

    struct GlowInTheDarkData {
        // contains the light mode colors
        string[2] light;
        // contains the dark mode colors
        string[2] dark;
        string name;
    }

    /* DATA RETRIEVAL */
    function getGlowInTheDarkData()
        internal
        pure
        returns (GlowInTheDarkData memory)
    {
        return
            GlowInTheDarkData(
                ["#fbfffc", "#d7ffd7"],
                ["#052925", "#a4ffa1"],
                "Glow In The Dark"
            );
    }

    function getMaterial(uint256 _materialId)
        internal
        pure
        returns (Material memory)
    {
        Material[12] memory materials = [
            Material(
                MaterialId.Pearl,
                "Ocean Pearl",
                ["#ffffff", "#f6e6ff"],
                840
            ),
            Material(
                MaterialId.Copper,
                "Resistor Copper",
                ["#f7d1bf", "#5a2c1d"],
                840
            ),
            Material(
                MaterialId.Onyx,
                "Ocean Pearl",
                ["#615c5c", "#0f0f0f"],
                840
            ),
            Material(
                MaterialId.Quartz,
                "Block Quartz",
                ["#ffb4be", "#81004e"],
                840
            ),
            Material(
                MaterialId.Emerald,
                "Matrix Emerald",
                ["#97ff47", "#011601"],
                840
            ),
            Material(MaterialId.Ruby, "404 Ruby", ["#fe3d4a", "#460008"], 840),
            Material(
                MaterialId.Sapphire,
                "Hyperlink Sapphire",
                ["#4668ff", "#000281"],
                840
            ),
            Material(
                MaterialId.Amber,
                "Sunset Amber",
                ["#ffa641", "#30031f"],
                840
            ),
            Material(
                MaterialId.Amethyst,
                "Candy Amethyst",
                ["#f7dfff", "#3671ca"],
                840
            ),
            Material(
                MaterialId.Obsidian,
                "Nether Obsidian",
                ["#6f00ff", "#2b003b"],
                840
            ),
            Material(
                MaterialId.Gold,
                "Electric Gold",
                ["#fcba7d", "#864800"],
                840
            ),
            Material(
                MaterialId.Diamond,
                "Ethereal Diamond",
                ["#b5f9ff", "#30c2c2"],
                840
            )
        ];

        return materials[_materialId];
    }

    function getMood(uint256 _moodId) internal pure returns (Mood memory) {
        Mood[13] memory moods = [
            Mood(MoodId.Surprised, "Surprised", 840),
            Mood(MoodId.Happy, "Happy", 840),
            Mood(MoodId.Relaxed, "Relaxed", 840),
            Mood(MoodId.Excited, "Excited", 840),
            Mood(MoodId.Speechless, "Speechless", 25),
            Mood(MoodId.Chilling, "Chilling", 840),
            Mood(MoodId.Annoyed, "Annoyed", 840),
            Mood(MoodId.Sleepy, "Sleepy", 840),
            Mood(MoodId.Unimpressed, "Unimpressed", 840),
            Mood(MoodId.Meditating, "Meditating", 840),
            Mood(MoodId.Relieved, "Relieved", 840),
            Mood(MoodId.Cheeky, "Cheeky", 840),
            Mood(MoodId.Sus, "Sus", 840)
        ];

        return moods[_moodId];
    }

    function getGlasses(uint256 _glassesId)
        internal
        pure
        returns (Glasses memory)
    {
        Glasses[9] memory glasses = [
            Glasses(GlassesId.None, "None", 840),
            Glasses(GlassesId.LeftMonocle, "Left Monocle", 840),
            Glasses(GlassesId.RightMonocle, "Right Monocle", 840),
            Glasses(GlassesId.Flip, "Flip", 840),
            Glasses(GlassesId.Valentine, "Valentine", 840),
            Glasses(GlassesId.Shutters, "Shutters", 840),
            Glasses(GlassesId.ThreeD, "3D", 840),
            Glasses(GlassesId.Ski, "Ski", 840),
            Glasses(GlassesId.Monolens, "Monolens", 840)
        ];

        return glasses[_glassesId];
    }

    /* UTILS */
    // used to determine proper accent colors.
    function isLightMaterial(MaterialId _id) internal pure returns (bool) {
        return _id == MaterialId.Pearl || _id == MaterialId.Diamond;
    }

    function getMaterialAccentColor(MaterialId _id)
        internal
        pure
        returns (string memory)
    {
        if (isLightMaterial(_id)) {
            return utils.getCssVar("black");
        }

        return utils.getCssVar("white");
    }

    function getMaterialShadow(MaterialId _id)
        internal
        pure
        returns (string memory)
    {
        if (isLightMaterial(_id)) {
            return utils.black_a(85);
        }

        return utils.white_a(85);
    }
}
