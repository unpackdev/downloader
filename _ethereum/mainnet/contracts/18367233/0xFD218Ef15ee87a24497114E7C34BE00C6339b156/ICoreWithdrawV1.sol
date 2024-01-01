// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreWithdrawV1 {
    event Withdrawal(address indexed erc20Token, uint256 amount, address indexed recipient);

    function withdrawAll(address[] calldata tokens) external returns (bool);

    function withdrawAllTo(address[] calldata tokens, address to) external returns (bool);

    function supportsNativeAssets() external pure returns (bool);

    function withdraw(uint256 amount, address erc20Token) external returns (bool);
}
