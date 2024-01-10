//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice Three rarities available
/// @dev Using enums for rarities
enum Rarity {
    BLUE,
    RED,
    GOLD,
    UNREVEALED
}

/// @notice Tokens will increase their level while holding them
/// @dev Using enums for levels
enum Level {
    COLLECTOR,
    BELIEVER,
    SUPPORTER,
    FAN
}

/// @title Twinesis Strings
/// @author Nicolás Acosta (nicoacosta.eth) - @0xnico_ - linktr.ee/nicoacosta.eth
/// @notice Get strings from Enum and Level types
library TwinesisStrings {
    /// @notice Rarity string
    /// @param rarity Some rarity
    /// @return String Rarity string
    function toString(Rarity rarity) internal pure returns (string memory) {
        if (rarity == Rarity.GOLD) return "gold";
        if (rarity == Rarity.RED) return "red";
        if (rarity == Rarity.BLUE) return "blue";
        if (rarity == Rarity.UNREVEALED) return "unrevealed";
    }

    /// @notice Level string
    /// @param level Some level
    /// @return String Level string
    function toString(Level level) internal pure returns (string memory) {
        if (level == Level.COLLECTOR) return "collector";
        if (level == Level.BELIEVER) return "believer";
        if (level == Level.SUPPORTER) return "supporter";
        if (level == Level.FAN) return "fan";
    }
}
