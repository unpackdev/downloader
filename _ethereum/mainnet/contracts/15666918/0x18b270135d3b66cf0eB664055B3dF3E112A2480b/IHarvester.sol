// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import "./IVault.sol";

import "./IERC20Metadata.sol";

interface IHarvester {
    function crv() external view returns (IERC20);

    function cvx() external view returns (IERC20);

    function vault() external view returns (IVault);

    function positionHandler() external view returns (address);

    function setPositionHandler(address _addr) external;

    function setSlippage(uint256 _slippage) external;

    // Swap tokens to wantToken
    function harvest() external;

    function sweep(address _token) external;

    function rewardTokens() external view returns (address[] memory);
}
