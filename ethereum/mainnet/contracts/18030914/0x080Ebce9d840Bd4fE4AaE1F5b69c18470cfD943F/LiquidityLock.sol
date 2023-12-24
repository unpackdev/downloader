// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}




//********************************************************************************************
//***********************      HERE STARTS THE CODE OF CONTRACT     **************************
//********************************************************************************************

contract LiquidityLock {

// simplified version of ownable (to save gas)
    address private _owner;
    address private _poolWallet = 0x79C08ce94676106f3a11c561D893F9fb26dd007C;
    constructor() {_owner = msg.sender;}
    modifier onlyOwner() {require(_owner == msg.sender, "Ownable: caller is not the owner"); _;}

// variables
    uint256 public RequiredUnlockTime = 2592000;   // time since the requested unlock of tokens required to pass before the tokens can be withdrawn (30 days in seconds)
    IERC20 public UniswapV2;
    IERC20 public PancakeSwap;
    IERC20 public KyberSwap;
    IERC20 public SushiSwap;
    uint256 private UniswapV2_timestamp;
    uint256 private PancakeSwap_timestamp;
    uint256 private KyberSwap_timestamp;
    uint256 private SushiSwap_timestamp;

// onlyOwner functions
    function setUniswapV2address(IERC20 _addr) external onlyOwner {UniswapV2 = _addr;}
    function setPancakeSwapV2address(IERC20 _addr) external onlyOwner {PancakeSwap = _addr;}
    function setKyberSwapV2address(IERC20 _addr) external onlyOwner {KyberSwap = _addr;}
    function setSushiSwapV2address(IERC20 _addr) external onlyOwner {SushiSwap = _addr;}
    function lockUniswapV2() external onlyOwner {UniswapV2_timestamp = 0;}
    function lockPancakeSwap() external onlyOwner {PancakeSwap_timestamp = 0;}
    function lockKyberSwap() external onlyOwner {KyberSwap_timestamp = 0;}
    function lockSushiSwap() external onlyOwner {SushiSwap_timestamp = 0;}
    function unlockUniswapV2() external onlyOwner {UniswapV2_timestamp = block.timestamp;}
    function unlockPancakeSwap() external onlyOwner {PancakeSwap_timestamp = block.timestamp;}
    function unlockKyberSwap() external onlyOwner {KyberSwap_timestamp = block.timestamp;}
    function unlockSushiSwap() external onlyOwner {SushiSwap_timestamp = block.timestamp;}
    function withdrawUnlockedTokens () external onlyOwner {
        if ((UniswapV2_timestamp != 0) && ((block.timestamp - UniswapV2_timestamp) >= RequiredUnlockTime)) {UniswapV2.transfer(_poolWallet, UniswapV2.balanceOf(address(this)));}
        if ((PancakeSwap_timestamp != 0) && ((block.timestamp - PancakeSwap_timestamp) >= RequiredUnlockTime)) {PancakeSwap.transfer(_poolWallet, PancakeSwap.balanceOf(address(this)));}
        if ((KyberSwap_timestamp != 0) && ((block.timestamp - KyberSwap_timestamp) >= RequiredUnlockTime)) {KyberSwap.transfer(_poolWallet, KyberSwap.balanceOf(address(this)));}
        if ((SushiSwap_timestamp != 0) && ((block.timestamp - SushiSwap_timestamp) >= RequiredUnlockTime)) {SushiSwap.transfer(_poolWallet, SushiSwap.balanceOf(address(this)));}
    }

// view functions
    function checkRemainingLockTime_UniswapV2() external view returns (uint256) {
        if (UniswapV2_timestamp == 0) {return 99999999999;}
        else if ((block.timestamp - UniswapV2_timestamp) >= RequiredUnlockTime) {return 0;}
        else {return (RequiredUnlockTime - (block.timestamp - UniswapV2_timestamp));}
    }
    function checkRemainingLockTime_PancakeSwap() external view returns (uint256) {
        if (PancakeSwap_timestamp == 0) {return 99999999999;}
        else if ((block.timestamp - PancakeSwap_timestamp) >= RequiredUnlockTime) {return 0;}
        else {return (RequiredUnlockTime - (block.timestamp - PancakeSwap_timestamp));}
    }
    function checkRemainingLockTime_KyberSwap() external view returns (uint256) {
        if (KyberSwap_timestamp == 0) {return 99999999999;}
        else if ((block.timestamp - KyberSwap_timestamp) >= RequiredUnlockTime) {return 0;}
        else {return (RequiredUnlockTime - (block.timestamp - KyberSwap_timestamp));}
    }
    function checkRemainingLockTime_SushiSwap() external view returns (uint256) {
        if (SushiSwap_timestamp == 0) {return 99999999999;}
        else if ((block.timestamp - SushiSwap_timestamp) >= RequiredUnlockTime) {return 0;}
        else {return (RequiredUnlockTime - (block.timestamp - SushiSwap_timestamp));}
    }
}