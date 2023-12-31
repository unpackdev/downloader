// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IOpenEditionMint {
    ///@notice Emitted when price of mint was updated
    event PriceUpdated(uint256 price);

    ///@notice Emitted when mint happened
    event Purchase(address indexed buyer, uint256 tokenId);

    ///@notice Emitted when contract was unpaused and duration increased by pause time
    event MintDurationIncreasedByPause(uint256 pastPauseDelay);

    ///@notice Thrown when payment is insufficient
    error WrongPayment();

    ///@notice Thrown when max mint is reached
    error MaxMintReached();

    ///@notice Thrown when mint closed
    error MintClosed();

    function mintMultiple(uint256 quantity) external payable;

    function airdrop(address[] memory addresses, uint256[] memory amounts) external;

    function maxMint() external view returns (uint256);

    function price() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function startTime() external view returns (uint256);

    function duration() external view returns (uint256);
}
