// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./BytesLib.sol";

library FightInfo {
    enum Types { Regular, Money }

    struct Details {
        uint dragon1Id;
        uint dragon2Id;
        Types fightType;
        uint betAmount;
    }

    function getValue(Details calldata info) internal pure returns (uint) {
        uint result = uint(info.dragon1Id);
        result |= info.dragon2Id << 32;
        result |= uint(info.fightType) << 64;
        result |= info.betAmount << 72;
        return result;
    }

    function readDetailsFromToken(bytes calldata fightToken) internal pure returns (uint, Details memory) {
        uint value = BytesLib.toUint256(fightToken, 0);
        return (value, getDetails(value));
    }

    function getDetails(uint value) internal pure returns (Details memory) {
        return Details (
            {
                dragon1Id: uint256(uint32(value)),
                dragon2Id: uint256(uint32(value >> 32)),
                fightType: Types(uint8(value >> 64)),
                betAmount: uint256(uint184(value >> 72))
            }
        );
    }
}