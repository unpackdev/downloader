// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IFrxEthMinter {
    function submitAndDeposit(address recipient) external payable returns (uint256 shares);
}
