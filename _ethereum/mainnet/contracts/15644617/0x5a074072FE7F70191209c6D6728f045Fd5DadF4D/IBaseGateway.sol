// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseGateway {

    function setNftData(address _nft, address _poolA, address _poolB, address _poolC, bool _increaseable, uint256 _delta) external;

    function deposit(uint256 _tokenId, uint256 _amount) external payable;

    function batchDeposit(uint256 _idFrom, uint256 _offset) external payable;

    function depositWithERC20(uint256 _tokenId, uint256 _amount, address _depositToken, uint256 _depositTokenAmounts) external;

    function batchDepositWithERC20(uint256 _idFrom, uint256 _offset, address _depositToken, uint256 _depositTokenAmounts) external;

    function baseValue(address _nft, uint256 _tokenId, uint256 _amount) external view returns (uint256, uint256);

    function redeem(address _nft, uint256 _tokenId, uint256 _amount) external;

    function withdraw(address _to) external;

    function withdrawWithERC20(address _token, address _to) external;
}