// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";

/*
    Approve and Ban Contracts to interact with pools.
    (All contracts are approved by default, unless banned)
*/
contract BannedContractList is Initializable, OwnableUpgradeSafe {
    mapping(address => bool) banned;

    function initialize() public initializer {
        __Ownable_init();
    }

    function isApproved(address toCheck) external view returns (bool) {
        return !banned[toCheck];
    }

    function isBanned(address toCheck) external view returns (bool) {
        return banned[toCheck];
    }

    function approveContract(address toApprove) external onlyOwner {
        banned[toApprove] = false;
    }

    function banContract(address toBan) external onlyOwner {
        banned[toBan] = true;
    }
}
