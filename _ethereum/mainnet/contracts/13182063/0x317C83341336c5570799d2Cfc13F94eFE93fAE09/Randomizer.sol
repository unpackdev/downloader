
pragma solidity ^0.8.0;

import "./StringUtil.sol";

library Randomizer { 

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, StringUtil.toString(tokenId))));
        return sourceArray[rand % sourceArray.length];
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}