//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "./IERC20Metadata.sol";

interface ILibertiVault is IERC20Metadata {
    function asset() external view returns (address);

    function other() external view returns (address);

    function deposit(
        uint256 assets,
        address receiver,
        bytes calldata data
    ) external returns (uint256);

    function depositEth(address receiver, bytes calldata data) external payable returns (uint256);

    function redeemEth(
        uint256 shares,
        address receiver,
        address _owner,
        bytes calldata data
    ) external returns (uint256);

    function exit() external returns (uint256 amountToken0, uint256 amountToken1);

    function exitFee() external pure returns (uint256);
}
