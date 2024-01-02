// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                        888
//                        888
//                        888
// 88888b.d88b.   .d88b.  888888 888d888 .d88b.
// 888 "888 "88b d8P  Y8b 888    888P"  d88""88b
// 888  888  888 88888888 888    888    888  888
// 888  888  888 Y8b.     Y88b.  888    Y88..88P
// 888  888  888  "Y8888   "Y888 888     "Y88P"

// 888                    d8b          888                          888
// 888                    Y8P          888                          888
// 888                                 888                          888
// 88888b.  888  888      888 88888b.  888888       8888b.  888d888 888888
// 888 "88b 888  888      888 888 "88b 888             "88b 888P"   888
// 888  888 888  888      888 888  888 888         .d888888 888     888
// 888 d88P Y88b 888      888 888  888 Y88b.       888  888 888     Y88b.
// 88888P"   "Y88888      888 888  888  "Y888      "Y888888 888      "Y888
//               888
//          Y8b d88P
//           "Y88P"

import "./Ownable.sol";
import "./IMetroThemeStorageV2.sol";

contract MetroThemeStorageV2 is Ownable, IMetroThemeStorageV2 {
    error InvalidThemeIndex();

    MetroThemeV2[] public themes;

    constructor() {
        themes.push(getBaseTheme(0));
        themes.push(getBaseTheme(1));
        themes.push(getBaseTheme(2));
        themes.push(getBaseTheme(3));
        themes.push(getBaseTheme(4));
        themes.push(getBaseTheme(5));
        themes.push(getBaseTheme(6));
        themes.push(getBaseTheme(7));
        themes.push(getBaseTheme(8));
        themes.push(getBaseTheme(9));
        themes.push(getBaseTheme(10));
        themes.push(getBaseTheme(11));
        themes.push(getBaseTheme(12));
    }

    function updateTheme(
        MetroThemeV2 calldata theme,
        uint256 at
    ) public onlyOwner {
        themes[at] = theme;
    }

    function addTheme(MetroThemeV2 calldata theme) public onlyOwner {
        themes.push(theme);
    }

    function getRandomTheme(
        bytes32 seed,
        uint256 tokenId,
        bool shouldFilterByDate,
        uint256 beforeDate
    ) public view override returns (MetroThemeV2 memory) {
        unchecked {
            MetroThemeV2[] memory filteredThemes;

            if (shouldFilterByDate) {
                filteredThemes = getFilteredThemes(beforeDate);
            } else {
                filteredThemes = themes;
            }

            uint256 randomsiedSeed = uint256(
                keccak256(abi.encodePacked(seed, tokenId))
            );

            uint256 length = filteredThemes.length;
            for (uint256 i; i < length; i++) {
                uint256 n = i + (randomsiedSeed % (length - i));
                MetroThemeV2 memory temp = filteredThemes[n];
                filteredThemes[n] = filteredThemes[i];
                filteredThemes[i] = temp;
            }

            uint256 themeChance = randomsiedSeed % 10;
            for (uint256 i; i < length; i++) {
                if (themeChance >= filteredThemes[i].pickChance) {
                    return filteredThemes[i];
                }
            }
            return filteredThemes[0];
        }
    }

    function getFilteredThemes(
        uint256 beforeDate
    ) public view returns (MetroThemeV2[] memory) {
        MetroThemeV2[] memory currentThemes = themes;
        MetroThemeV2[] memory filteredThemes = new MetroThemeV2[](
            currentThemes.length
        );

        uint256 count;
        for (uint256 i; i < currentThemes.length; i++) {
            if (currentThemes[i].addedDate <= beforeDate) {
                filteredThemes[count] = currentThemes[i];
                count++;
            }
        }

        MetroThemeV2[] memory resultThemes = new MetroThemeV2[](count);

        for (uint256 i; i < count; i++) {
            resultThemes[i] = filteredThemes[i];
        }

        return resultThemes;
    }

    function getBaseTheme(
        uint256 themeIndex
    ) internal pure returns (MetroThemeV2 memory) {
        if (themeIndex == 0) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#92edae";
            theme.mBackgroundColor = "#92edae";
            theme.mBorderColor = "#b9fbc0";
            theme.backgroundColor = "#1d2828";
            theme.stopFillColor = "#FFFFFF";
            theme.stopStrokeColor = "#151d1d";
            theme.lineColors = new bytes[](5);
            theme.wagonColors = new bytes[](5);
            theme.lineColors[0] = "#98f5e1";
            theme.lineColors[1] = "#57cc99";
            theme.lineColors[2] = "#80ed99";
            theme.lineColors[3] = "#b9fbc0";
            theme.lineColors[4] = "#c7f9cc";
            theme.wagonColors[0] = "#1d2828";
            theme.wagonColors[1] = "#1d2828";
            theme.wagonColors[2] = "#1d2828";
            theme.wagonColors[3] = "#1d2828";
            theme.wagonColors[4] = "#1d2828";
            theme.name = "lime";
            theme.creator = "int.art";
            return theme;
        }

        if (themeIndex == 1) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#330843";
            theme.mBackgroundColor = "#e9ecec";
            theme.mBorderColor = "#190520";
            theme.backgroundColor = "#f0eff4";
            theme.stopFillColor = "#FAF5F0";
            theme.stopStrokeColor = "#0d1b2a";
            theme.lineColors = new bytes[](5);
            theme.wagonColors = new bytes[](5);
            theme.lineColors[0] = "#2ec4b6";
            theme.lineColors[1] = "#7371fc";
            theme.lineColors[2] = "#ff7096";
            theme.lineColors[3] = "#de4d86";
            theme.lineColors[4] = "#ff6e63";
            theme.wagonColors[0] = "#1a6760";
            theme.wagonColors[1] = "#5351b8";
            theme.wagonColors[2] = "#7b3649";
            theme.wagonColors[3] = "#7c2b4b";
            theme.wagonColors[4] = "#843a35";
            theme.name = "sweet";
            theme.creator = "int.art";
            return theme;
        }

        if (themeIndex == 2) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#f76a6a";
            theme.mBackgroundColor = "#010514";
            theme.mBorderColor = "#FFA10A";
            theme.backgroundColor = "#020A2B";
            theme.stopFillColor = "#ffffff";
            theme.stopStrokeColor = "#000000";
            theme.lineColors = new bytes[](7);
            theme.wagonColors = new bytes[](7);
            theme.lineColors[0] = "#9b5de5";
            theme.lineColors[1] = "#f15bb5";
            theme.lineColors[2] = "#FEE648";
            theme.lineColors[3] = "#00bbf9";
            theme.lineColors[4] = "#00f5d4";
            theme.lineColors[5] = "#FFA10A";
            theme.lineColors[6] = "#E56161";
            theme.wagonColors[0] = "#DDCEF3";
            theme.wagonColors[1] = "#F6CBE8";
            theme.wagonColors[2] = "#AE9609";
            theme.wagonColors[3] = "#0D7B96";
            theme.wagonColors[4] = "#007A6A";
            theme.wagonColors[5] = "#C25400";
            theme.wagonColors[6] = "#D32222";
            theme.name = "midnight";
            theme.creator = "int.art";
            theme.pickChance = 3;
            return theme;
        }

        if (themeIndex == 3) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#8093f1";
            theme.mBackgroundColor = "#8b77db";
            theme.mBorderColor = "#4a3f72";
            theme.backgroundColor = "#4a3f72";
            theme.stopFillColor = "#ffffff";
            theme.stopStrokeColor = "#332c50";
            theme.lineColors = new bytes[](7);
            theme.wagonColors = new bytes[](7);
            theme.lineColors[0] = "#fdc5f5";
            theme.lineColors[1] = "#f7aef8";
            theme.lineColors[2] = "#b388eb";
            theme.lineColors[3] = "#8093f1";
            theme.lineColors[4] = "#72ddf7";
            theme.lineColors[5] = "#6278BA";
            theme.lineColors[6] = "#D387AB";
            theme.wagonColors[0] = "#4a3f72";
            theme.wagonColors[1] = "#4a3f72";
            theme.wagonColors[2] = "#4a3f72";
            theme.wagonColors[3] = "#4a3f72";
            theme.wagonColors[4] = "#4a3f72";
            theme.wagonColors[5] = "#4a3f72";
            theme.wagonColors[6] = "#4a3f72";
            theme.name = "candy";
            theme.creator = "int.art";
            return theme;
        }

        if (themeIndex == 4) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#393837";
            theme.mBackgroundColor = "#fffaf5";
            theme.mBorderColor = "#4d4c4a";
            theme.backgroundColor = "#FAF5F0";
            theme.stopFillColor = "#FAF5F0";
            theme.stopStrokeColor = "#000000";
            theme.lineColors = new bytes[](7);
            theme.wagonColors = new bytes[](7);
            theme.lineColors[0] = "#ef476f";
            theme.lineColors[1] = "#f78c6b";
            theme.lineColors[2] = "#ffd166";
            theme.lineColors[3] = "#06d6a0";
            theme.lineColors[4] = "#118ab2";
            theme.lineColors[5] = "#073b4c";
            theme.lineColors[6] = "#8a85ea";
            theme.wagonColors[0] = "#922c45";
            theme.wagonColors[1] = "#aa614b";
            theme.wagonColors[2] = "#9c8141";
            theme.wagonColors[3] = "#0f7b5c";
            theme.wagonColors[4] = "#0e4d63";
            theme.wagonColors[5] = "#00a1d0";
            theme.wagonColors[6] = "#605da3";
            theme.name = "classic";
            theme.creator = "int.art";
            return theme;
        }

        if (themeIndex == 5) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#372323";
            theme.mBackgroundColor = "#fdfaeb";
            theme.mBorderColor = "#372323";
            theme.backgroundColor = "#FFF2DE";
            theme.stopFillColor = "#ffffff";
            theme.stopStrokeColor = "#220901";
            theme.lineColors = new bytes[](7);
            theme.wagonColors = new bytes[](7);
            theme.lineColors[0] = "#cc8b86";
            theme.lineColors[1] = "#7d4f50";
            theme.lineColors[2] = "#5e3023";
            theme.lineColors[3] = "#774c60";
            theme.lineColors[4] = "#895737";
            theme.lineColors[5] = "#6F5E53";
            theme.lineColors[6] = "#B09696";
            theme.wagonColors[0] = "#813B36";
            theme.wagonColors[1] = "#3F2728";
            theme.wagonColors[2] = "#1E0F0B";
            theme.wagonColors[3] = "#322028";
            theme.wagonColors[4] = "#3A2517";
            theme.wagonColors[5] = "#B0A196";
            theme.wagonColors[6] = "#3A2C2C";
            theme.name = "coffee";
            theme.creator = "int.art";
            return theme;
        }

        if (themeIndex == 6) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#0a2b36";
            theme.mBackgroundColor = "#f9fdff";
            theme.mBorderColor = "#0a2b36";
            theme.backgroundColor = "#f8f9fa";
            theme.stopFillColor = "#ffffff";
            theme.stopStrokeColor = "#220901";
            theme.lineColors = new bytes[](7);
            theme.wagonColors = new bytes[](7);
            theme.lineColors[0] = "#467799";
            theme.lineColors[1] = "#f72585";
            theme.lineColors[2] = "#11b5e4";
            theme.lineColors[3] = "#00b4d8";
            theme.lineColors[4] = "#0096c7";
            theme.lineColors[5] = "#0077b6";
            theme.lineColors[6] = "#023e8a";
            theme.wagonColors[0] = "#edf8ff";
            theme.wagonColors[1] = "#edf8ff";
            theme.wagonColors[2] = "#edf8ff";
            theme.wagonColors[3] = "#edf8ff";
            theme.wagonColors[4] = "#edf8ff";
            theme.wagonColors[5] = "#edf8ff";
            theme.wagonColors[6] = "#edf8ff";
            theme.name = "frozen";
            theme.creator = "int.art";
            return theme;
        }

        if (themeIndex == 7) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#606060";
            theme.mBackgroundColor = "#1b1b1b";
            theme.mBorderColor = "#606060";
            theme.backgroundColor = "#0d0d0d";
            theme.stopFillColor = "#0d0d0d";
            theme.stopStrokeColor = "#1c1c1c";
            theme.lineColors = new bytes[](1);
            theme.wagonColors = new bytes[](1);
            theme.lineColors[0] = "#212121";
            theme.wagonColors[0] = "#FFFFFF";
            theme.name = "dark";
            theme.creator = "int.art";
            theme.pickChance = 5;
            return theme;
        }

        if (themeIndex == 8) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#2B303D";
            theme.mBackgroundColor = "#fbbb96";
            theme.mBorderColor = "#2B303D";
            theme.backgroundColor = "#fdad75";
            theme.stopFillColor = "#2B303D";
            theme.stopStrokeColor = "#fdad75";
            theme.lineColors = new bytes[](1);
            theme.wagonColors = new bytes[](1);
            theme.lineColors[0] = "#2B303D";
            theme.wagonColors[0] = "#fdad75";
            theme.name = "sunset";
            theme.creator = "int.art";
            theme.pickChance = 2;
            return theme;
        }

        if (themeIndex == 9) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#2d2b29";
            theme.mBackgroundColor = "#e2d9cb";
            theme.mBorderColor = "#2d2b29";
            theme.backgroundColor = "#e2d9cb";
            theme.stopFillColor = "#e2d9cb";
            theme.stopStrokeColor = "#2d2b29";
            theme.lineColors = new bytes[](1);
            theme.wagonColors = new bytes[](1);
            theme.lineColors[0] = "#2d2b29";
            theme.wagonColors[0] = "#e2d9cb";
            theme.name = "sketch";
            theme.creator = "int.art";
            theme.pickChance = 8;
            return theme;
        }

        if (themeIndex == 10) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#00f5d4";
            theme.mBackgroundColor = "#131b2b";
            theme.mBorderColor = "#1a263b";
            theme.backgroundColor = "#000814";
            theme.stopFillColor = "#000814";
            theme.stopStrokeColor = "#1b263b";
            theme.lineColors = new bytes[](5);
            theme.wagonColors = new bytes[](5);
            theme.lineColors[0] = "#1b263b";
            theme.lineColors[1] = "#1b263b";
            theme.lineColors[2] = "#1b263b";
            theme.lineColors[3] = "#1b263b";
            theme.lineColors[4] = "#1b263b";
            theme.wagonColors[0] = "#9b5de5";
            theme.wagonColors[1] = "#f15bb5";
            theme.wagonColors[2] = "#00bbf9";
            theme.wagonColors[3] = "#00f5d4";
            theme.wagonColors[4] = "#ffc300";
            theme.name = "night";
            theme.creator = "int.art";
            theme.pickChance = 7;
            return theme;
        }

        if (themeIndex == 11) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#0c0024";
            theme.mBackgroundColor = "#0c0024";
            theme.pBackgroundColor = "#8534ff";
            theme.mBorderColor = "#0c0024";
            theme.backgroundColor = "#09001b";
            theme.stopFillColor = "#ba6dff";
            theme.stopStrokeColor = "#0c0024";
            theme.lineColors = new bytes[](2);
            theme.wagonColors = new bytes[](2);
            theme.lineColors[0] = "#0c0024";
            theme.lineColors[1] = "#0c0024";
            theme.wagonColors[0] = "#8534ff";
            theme.wagonColors[1] = "#8534ff";
            theme.name = "grid";
            theme.creator = "int.art";
            theme.pickChance = 8;
            return theme;
        }

        if (themeIndex == 12) {
            MetroThemeV2 memory theme;
            theme.mTextColor = "#191656";
            theme.mBackgroundColor = "#b7b3ce";
            theme.mBorderColor = "#2e2d33";
            theme.backgroundColor = "#e6e0ff";
            theme.stopFillColor = "#ffffff";
            theme.lineStrokeColor = "#000000";
            theme.stopStrokeColor = "#0c0024";
            theme.lineColors = new bytes[](6);
            theme.wagonColors = new bytes[](6);
            theme.lineColors[0] = "#29fffb";
            theme.lineColors[1] = "#ffdc40";
            theme.lineColors[2] = "#ff6a0d";
            theme.lineColors[3] = "#4d44fc";
            theme.lineColors[4] = "#ff3de2";
            theme.lineColors[5] = "#4df780";
            theme.wagonColors[0] = "#000000";
            theme.wagonColors[1] = "#000000";
            theme.wagonColors[2] = "#000000";
            theme.wagonColors[3] = "#000000";
            theme.wagonColors[4] = "#000000";
            theme.wagonColors[5] = "#000000";
            theme.name = "toy";
            theme.creator = "int.art";
            theme.pickChance = 2;
            return theme;
        }

        revert InvalidThemeIndex();
    }
}
