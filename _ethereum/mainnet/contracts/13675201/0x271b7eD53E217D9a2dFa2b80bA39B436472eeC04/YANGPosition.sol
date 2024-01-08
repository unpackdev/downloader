// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

library YANGPosition {
    // info stored for each user's position
    struct Info {
        uint256 shares;
    }

    function get(
        mapping(bytes32 => Info) storage self,
        uint256 yangId,
        uint256 chiId
    ) internal view returns (YANGPosition.Info storage position) {
        position = self[keccak256(abi.encodePacked(yangId, chiId))];
    }
}
