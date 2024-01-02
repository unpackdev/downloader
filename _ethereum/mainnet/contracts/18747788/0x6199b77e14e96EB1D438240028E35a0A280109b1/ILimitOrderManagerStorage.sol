// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IAccessControl.sol";

import "./IPrimexDNS.sol";
import "./ITraderBalanceVault.sol";
import "./IPositionManager.sol";
import "./ISwapManager.sol";

interface ILimitOrderManagerStorage {
    function ordersId() external view returns (uint256);

    function orderIndexes(uint256) external view returns (uint256);

    function traderOrderIndexes(uint256) external view returns (uint256);

    function traderOrderIds(address _trader, uint256 _index) external view returns (uint256);

    function bucketOrderIndexes(uint256) external view returns (uint256);

    function bucketOrderIds(address _bucket, uint256 _index) external view returns (uint256);

    function registry() external view returns (IAccessControl);

    function traderBalanceVault() external view returns (ITraderBalanceVault);

    function primexDNS() external view returns (IPrimexDNS);

    function pm() external view returns (IPositionManager);

    function swapManager() external view returns (ISwapManager);
}
