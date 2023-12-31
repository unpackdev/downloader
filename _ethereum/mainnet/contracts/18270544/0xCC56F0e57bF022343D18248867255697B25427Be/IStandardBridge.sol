// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStandardBridge {
    // deposits
    // Legacy but DAI and some other bridges only support this
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;

    // withdrawals
    // legacy but DAI and some other bridges only support this
    function withdrawTo(address _l2Token, address _to, uint256 _amount, uint32 _l1Gas, bytes calldata _data) external payable;

    // both
    function bridgeETHTo(address _to, uint32 _minGasLimit, bytes calldata _extraData) external payable;
    // disabled because we prefer
    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external payable;
}
