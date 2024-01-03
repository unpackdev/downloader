// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

library Lib {

    struct ProductCount {
        uint256 buyCount;
        uint256 miningCount;
        uint256 withdrawSum;
        uint256 withdrawCount;
        uint256 redeemedCount;
    }

    struct ProductMintItem {
        address minter;
        uint256 beginTime;
        uint256 withdrawTime;
        uint256 endTime;
        uint256 totalValue;
    }

    struct ProductTokenDetail {
        uint256 id;
        bool mining;
        uint256 totalTime;
        uint256 totalValue;
        uint256 propA;
        uint256 propB;
        uint256 propC;
        ProductMintItem currMining;
    }

    function random(uint256 min, uint256 max) internal view returns (uint256) {
        uint256 gl = gasleft();
        uint256 seed = uint256(keccak256(abi.encodePacked(
                block.timestamp + block.difficulty +
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                block.gaslimit + gl +
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                block.number
            )));
        return min + (seed - ((seed / (max - min)) * (max - min)));
    }

}