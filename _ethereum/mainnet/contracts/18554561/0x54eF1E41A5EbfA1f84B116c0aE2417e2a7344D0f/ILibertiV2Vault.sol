//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IERC20Metadata.sol";
import "./IERC20Permit.sol";

interface ILibertiV2Vault is IERC20Metadata, IERC20Permit {
    function deposit(
        uint256[] calldata _maxAmountsIn,
        address _receiver
    ) external returns (uint256 amountOut, uint256[] memory amountsIn);

    function withdraw(
        uint256 _amountIn,
        address _receiver,
        address _owner
    ) external returns (uint256[] memory amountsOut);

    function getTokens() external view returns (address[] memory);

    function getAmountsOut(uint256 _amountIn) external view returns (uint256[] memory amountsOut);

    function isBoundTokens(address) external view returns (bool);
}
