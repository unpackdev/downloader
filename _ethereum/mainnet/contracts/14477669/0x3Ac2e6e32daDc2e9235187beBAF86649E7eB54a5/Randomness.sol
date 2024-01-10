// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Ownable.sol";

contract Randomness is Ownable {
    uint256 public seed;

    function setSeed(uint256 _seed) public onlyOwner {
        seed = _seed;
    }

    function shuffle(uint32 size) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](size);
        // init
        for (uint256 i = 0; i < size; i++) {
            res[i] = i + 1;
        }

        // shuffle
        for (uint256 i = 0; i < size; i++) {
            uint256 n = (uint256(keccak256(abi.encodePacked(seed, i, i))) % size);
            if (i == n) {
                continue;
            }
            uint256 temp = res[n];
            res[n] = res[i];
            res[i] = temp;
        }
        return res;
    }
}
