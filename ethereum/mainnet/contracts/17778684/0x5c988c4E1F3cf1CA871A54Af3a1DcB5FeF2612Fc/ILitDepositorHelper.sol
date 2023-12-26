// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ILitDepositorHelper {
    function deposit(
        uint256 _amount,
        uint256 _minOut,
        bool _lock,
        address _stakeAddress
    ) external returns (uint256 bptOut);

    function depositFor(
        address _for,
        uint256 _amount,
        uint256 _minOut,
        bool _lock,
        address _stakeAddress
    ) external returns (uint256 bptOut);

    function convertLitToBpt(uint256 _amount, uint256 _minOut) external returns (uint256 bptOut);
}
