// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

/**
 * @title IFinaWhitelist
 * @author Enjinstarter
 */
interface IFinaWhitelist {
    function addWhitelisted(address account, uint256 amount) external;

    function removeWhitelisted(address account) external;

    function addWhitelistedBatch(
        address[] memory accounts,
        uint256[] memory amounts
    ) external;

    function removeWhitelistedBatch(address[] memory accounts) external;

    function setGovernanceAccount(address account) external;

    function setWhitelistAdmin(address account) external;

    function isWhitelisted(address account)
        external
        view
        returns (bool isWhitelisted_);

    function whitelistedAmountFor(address account)
        external
        view
        returns (uint256 whitelistedAmount);

    event WhitelistedAdded(address indexed account, uint256 amount);
    event WhitelistedRemoved(address indexed account);
}
