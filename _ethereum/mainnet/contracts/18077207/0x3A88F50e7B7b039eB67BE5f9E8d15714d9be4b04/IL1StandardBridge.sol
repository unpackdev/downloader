// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IL1StandardBridge {
    receive() external payable;
    function depositETH(uint32 _minGasLimit, bytes calldata _extraData) external payable;

    function depositETHTo(address _to, uint32 _minGasLimit, bytes calldata _extraData) external payable;

    function depositERC20(
        address _l1Token,
        address _l2Token,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;

    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;

    function finalizeETHWithdrawal(address _from, address _to, uint256 _amount, bytes calldata _extraData)
        external
        payable;

    function finalizeERC20Withdrawal(
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _extraData
    ) external;

    function l2TokenBridge() external view returns (address);
}
