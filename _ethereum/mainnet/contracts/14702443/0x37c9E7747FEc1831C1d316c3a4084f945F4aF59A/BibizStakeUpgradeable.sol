// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./StakeBaseUpgradeable.sol";

/**
@title Bibiz Upgradeable Staking Contract
@author @KfishNFT
@notice Based on the Habibiz upgradeable staking contract using UUPSUpgradeable Proxy
*/
contract BibizStakeUpgradeable is StakeBaseUpgradeable {
    /**
    @notice Initializer function
    @param stakingContract_ The contract that Bibiz will be staked in
    @param tokenContract_ The Bibiz contract
    @param oilContract_ The $OIL contract
    */
    function initialize(
        address stakingContract_,
        address tokenContract_,
        address oilContract_
    ) public initializer {
        address _stakingContract = stakingContract_ == address(0) ? address(this) : stakingContract_;
        __StakeBaseUpgradeable_init(_stakingContract, tokenContract_, oilContract_);
    }
}
