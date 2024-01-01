// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./OwnableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./IAuthority.sol";

/**
 * @title Authority Whitelist smart contract
 * @notice this contract manages a whitelists for all the admins, borrowers and lenders
 */
abstract contract AuthorityAware is OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    IAuthority public authority;

    bytes32[50] private __gaps;

    modifier onlyOwnerOrAdmin() {
        _onlyOwnerOrAdmin();
        _;
    }

    function _onlyOwnerOrAdmin() internal view {
        require(
            owner() == msg.sender || authority.isAdmin(msg.sender),
            "AA:OA" // "AuthorityAware: caller is not the owner or admin"
        );
    }

    modifier onlyLender() { // only whitelisted lender
        require(
            authority.isWhitelistedLender(msg.sender),
            "AA:L" // "AuthorityAware: caller is not a whitelisted lender"
        );
        _;
    }

    modifier onlyWhitelisted() {
        _onlyWhitelisted();
        _;
    }

    function _onlyWhitelisted() internal view {
        require(
            owner() == msg.sender ||
                authority.isWhitelistedBorrower(msg.sender) ||
                authority.isWhitelistedLender(msg.sender) ||
                authority.isAdmin(msg.sender),
            "AA:W" // "AuthorityAware: caller is not a whitelisted borrower or lender"
        );
    }

    function __AuthorityAware__init(address _authority) internal {
        authority = IAuthority(_authority);
    }
}
