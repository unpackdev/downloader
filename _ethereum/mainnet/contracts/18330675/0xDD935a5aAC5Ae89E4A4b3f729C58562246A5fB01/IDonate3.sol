// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDonate3 {

    function donate(
        address _token,
        uint256 _amountInDesired,
        address _to,
        bytes calldata _message,
        bytes32[] calldata _merkleProof
    ) external payable;

    function withDrawToken(address to, uint256 amount) external;

    function withDrawERC20(
        address token,
        string calldata symbol,
        address to,
        uint256 amount
    ) external;

    function withDrawERC20List(
        address[] calldata tokens,
        string[] calldata symbols,
        address to,
        uint256[] calldata amounts
    ) external;
}
