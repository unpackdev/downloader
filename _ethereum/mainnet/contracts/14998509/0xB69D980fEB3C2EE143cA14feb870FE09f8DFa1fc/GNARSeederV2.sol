// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./IGNARSeederV2.sol";
import "./IGNARDescriptorV2.sol";

contract GNARSeederV2 is IGnarSeederV2 {
    function generateSeed(uint256 gnarId, IGnarDescriptorV2 descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), gnarId)));

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 glassesCount = descriptor.glassesCount();
        require(backgroundCount > 0, "background is missing");
        require(bodyCount > 0, "body is missing");
        require(accessoryCount > 0, "accessories is missing");
        require(headCount > 0, "head is missing");
        require(glassesCount > 0, "glasses is missing");

        return
            Seed({
                background: uint48(uint48(pseudorandomness) % backgroundCount),
                body: uint48(uint48(pseudorandomness >> 48) % bodyCount),
                accessory: uint48(uint48(pseudorandomness >> 96) % accessoryCount),
                head: uint48(uint48(pseudorandomness >> 144) % headCount),
                glasses: uint48(uint48(pseudorandomness >> 192) % glassesCount)
            });
    }
}
