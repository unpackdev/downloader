// contracts/State.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./ContributorStructs.sol";

contract ContributorEvents {
    event EventSaleInit (
        uint256 saleId
    );

    event EventContribute (
        uint256 saleId,
        uint256 tokenIndex,
        uint256 amount
    );

    event EventAttestContribution (
        uint256 saleId
    );

    event EventSaleSealed (
        uint256 saleId
    );

    event EventClaimAllocation (
        uint256 saleId,
        uint256 tokenIndex,
        uint256 amount
    );

    event EventClaimRefund (
        uint256 saleId,
        uint256 tokenIndex,
        uint256 amount
    );

    event EventClaimExcessContribution (
        uint256 saleId,
        uint256 tokenIndex,
        uint256 amount
    );
}

contract ContributorStorage {
    struct Provider {
        uint16 chainId;
        uint16 conductorChainId;
        bytes32 conductorContract;
        address payable wormhole;
        address tokenBridge;
    }

    struct State {
        Provider provider;

        /// deployer of the contracts
        address owner;
        /// number of confirmations for wormhole messages
        uint8 consistencyLevel;

        /// mapping of initialized implementations
        mapping(address => bool) initializedImplementations;

        /// mapping of Sales
        mapping(uint256 => ContributorStructs.Sale) sales;

        /// sale id > token id > contributor > contribution
        mapping(uint256 => mapping(uint256 => mapping(address => uint256))) contributions;

        /// sale id > token id > contribution
        mapping(uint256 => mapping(uint256 => uint256)) totalContributions;

        /// sale id > token id > contributor > isClaimed
        mapping(uint256 => mapping(uint256 => mapping(address => bool))) allocationIsClaimed;

        /// sale id > [token id > contributor > isClaimed
        mapping(uint256 => mapping(uint256 => mapping(address => bool))) refundIsClaimed;

        /// sale id > [token id > contributor > isClaimed
        mapping(uint256 => mapping(uint256 => mapping(address => bool))) excessContributionIsClaimed;
    }
}

contract ContributorState {
    ContributorStorage.State _state;
}