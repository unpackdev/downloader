pragma solidity ^0.5.0;

import "./console.sol";

import "./SafeMath.sol";
import "./Ownable.sol";

contract BotGainsProtocolStorage is Ownable{
    using SafeMath for uint256;
    
    //addressstate variable
    address payable botWallet;
    address payable adminFeeWallet;
    address payable managementFeeWallet;
    address payable divsFeeWallet;
    address payable bonusWallet;
    
    uint256 public minETH = 1e17;
    uint256 public maxETH = 1e19;
    uint256 public maxPoolSize = 500e18;
    uint256 public cycleLength;
    
    uint256 private lockTimer;
    uint256 private unlockTimer;
    
    constructor (address payable _tradingWallet,address payable _adminFeeWallet,address payable _managementFeeWallet,address payable _divsFeeWallet, address payable _bonusWallet) public {
        //assign wallet addresses
        botWallet = _tradingWallet;
        adminFeeWallet = _adminFeeWallet;
        managementFeeWallet = _managementFeeWallet;
        divsFeeWallet = _divsFeeWallet;
        bonusWallet = _bonusWallet;
        
        cycleLength = 30;
        
        unlockTimer= 30 minutes;
        lockTimer= 30 minutes;
    }
    
    
    function changeCycleLength(uint256 _days) onlyOwner external {
        require(_days > 1, "must be greater than a single day");
        cycleLength = _days;
    }
    function _cycleLength() public view returns(uint256) {
        return cycleLength;
    }
    

    function changeLockTimer(uint256 _minutes) onlyOwner external {
        lockTimer = _minutes.mul(1 minutes);
    }
    function changeUnlockTimer(uint256 _minutes) onlyOwner external {
        unlockTimer = _minutes.mul(1 minutes);
    }
    function _lockTimer() public view returns(uint256){
        return lockTimer;
    }
    function _unlockTimer() public view returns(uint256){
        return unlockTimer;
    }
    
    function changeMinETH(uint256 amount) onlyOwner external {
        require(amount > 1e14, "Min ETH can be no lower than 0.001 ETH, Make sure to update the minETH in wei");
        minETH = amount;
    }
    function changeMaxETH(uint256 amount) onlyOwner external {
        require(amount > 1e18, "Max ETH can be no lower than 1 ETH, Make sure to update the maxETH in wei");
        maxETH = amount;
    }
    function changeMaxPoolSize(uint256 amount) onlyOwner external {
        require(amount > 1e18, "Max ETH can be no lower than 1 ETH, Make sure to update the maxPoolSize in wei");
        maxPoolSize = amount;
    }
    function _minETH() public view returns(uint256){
        return minETH;
    }
    function _maxETH() public view returns(uint256){
        return maxETH;
    }
    function _maxPoolSize() public view returns(uint256){
        return maxPoolSize;
    }
    
    
    
    
    
    
    function changeAdminFeeWallet(address payable _admin) onlyOwner external{
        adminFeeWallet = _admin;
    }
    function changeManagementFeeWallet(address payable _manage) onlyOwner external{
        managementFeeWallet = _manage;
    }
    function changeDivsFeeWallet(address payable _divs) onlyOwner external{
        divsFeeWallet = _divs;
    }
    function changeBonusWallet(address payable _bonus) onlyOwner external{
        bonusWallet = _bonus;
    }
    function changeTradingWallet(address payable _tradingWallet) onlyOwner external{
        botWallet = _tradingWallet;
    }
    
    
    function _tradingWallet() public view returns(address payable){
        return botWallet;
    }
    function _adminFeeWallet() public view returns(address payable){
        return adminFeeWallet;
    }
    function _managementFeeWallet() public view returns(address payable){
        return managementFeeWallet;
    }
    function _divsFeeWallet() public view returns(address payable){
        return divsFeeWallet;
    }
    function _bonusWallet() public view returns(address payable){
        return bonusWallet;
    }
}