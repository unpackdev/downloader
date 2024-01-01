// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ICoinFlipUsa {
    struct CoinFlipInfo {
        address playerAddress;
        uint128 betAmount;
        uint32 timestamp;
        uint96 requestId;
        uint8 playerChoice; // 1 for heads, 0 for tails
        FlipResult result;
    }

    enum FlipResult {
        NONE, // 0
        AWAITINGRESOLUTION, // 1
        PLAYERWINS, // 2
        HOUSEWINS, // 3
        REFUNDED // 4
    }

    event CoinFlipResolved(uint256 indexed gameIndex, FlipResult result, uint256 randomValue, uint256 winAmount);

    event TokenWithdrawn(address indexed tokenAddress, uint256 amount);

    event MinimumBetSizeUpdated(uint256 _minimumBetSize);

    event WinMultiplierEdgeUpdated(uint256 _winMultiplierEdge);

    event FlippingCoin(uint256 indexed gameIndex, address indexed playerAddress, uint256 betAmount, uint8 playerChoice);

    event CoinFlipRefunded(uint256 indexed gameIndex, address indexed playerAddress, uint256 betAmount);

    event MaxGweiFlipUpdated(uint256 _maxGweiFlip);
}
