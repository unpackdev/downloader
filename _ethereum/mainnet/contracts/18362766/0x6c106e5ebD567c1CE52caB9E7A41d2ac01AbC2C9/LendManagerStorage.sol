// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title MetaLend's Lend Manager proxy storage contract
 * @author MetaLend
 * @notice defines storage layout for proxy contract
 * @dev this should be inherited by `LendManager` so that implementation and proxy have same layouts
 */
abstract contract LendManagerProxyStorage {
    /// @notice Indicator that this is a LendManager contract (for inspection)
    /// @return bool true this is lend manager
    bool public constant IS_LEND_MANAGER = true;

    /// @notice implementaiton for proxy
    /// @return address of the implementation manager contract
    address public implementation;

    /// @notice MetaLend admin
    /// @return address of the MetaLend admin for this manager
    address public admin;
}

/**
 * @title MetaLend's Lend Manager storage contract
 * @author MetaLend
 * @notice defines storage layout for manager contracts
 * @dev use for both proxy and implementation contracts
 */
abstract contract LendManagerStorage {
    /// @notice global implementation for all mediator contracts
    /// @return address of the mediator implementation contract
    address public lendMediatorImplementation;

    /// @notice signer of offers
    /// @return address of the offer signer
    address public offerSigner;

    /// @notice if royalties are implemented, this is the receiver
    /// @return address of the royalties receiver
    address payable public royaltiesReceiver;

    /// @notice scale 0 <=> 10000, 1% = 100
    /// @return uint256 the percentage
    uint256 public royaltiesPercentage;

    /// @notice mapping from user address to own userLendMediator
    /// @return address of the mediator contract for given address of the user
    mapping(address => address) public userLendMediator;
}
