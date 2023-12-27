// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface MetaDukeStructsErrors {
    error InvalidRound();

    error InvalidStartTokenId();

    error InvalidStart();

    error InvalidEnd();

    error InvalidSupply();

    error InvalidCap();

    error InactiveRound();

    error NotStartRound();

    error EndedRound();

    error ExceedMaxSupply();

    error ExceedRoundSupply();

    error ExceedRoundLimit();

    error ExceedMarketMintSupply();

    error NotWhitelist();

    error ExceedWhitelistLimit();

    error MintZeroAmount();

    error FailWithdraw();

    error FailRefund();

    error InsufficientBalance();

    struct Round {
        uint256 id;
        bool isActive;
        uint256 start;
        uint256 end;
        uint256 price;
        uint256 limit;
        uint256 supply;
        uint256 cap;
    }
}