// SPDX-License-Identifier: UNCLICENSED
pragma solidity ^0.7.6;

interface GandhijiMain {
    function buy(address _referredBy)  external payable returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens)  external;
    function myDividends(bool _includeReferralBonus) external returns (uint256);
    function calculateTokensReceived(uint256 _ethereumToSpend)  external returns (uint256);
}

contract Floor {
    GandhijiMain public GandhijiMainContract = GandhijiMain(0x167cB3F2446F829eb327344b66E271D1a7eFeC9A);
    address public distributeContract = 0x0D34cf81Db1F84EE6A0e7cC4A7ca6DB5F782474A;
    uint256 public dividendsToTransfer;
    uint256 public floorDividends;

    receive() external payable { msg.value; }
    
    function buy() public payable {
        GandhijiMainContract.buy{value: address(this).balance}(msg.sender);
    }
 
    function transferDividends() public
    {
        getTokenAmount(); 
        GandhijiMainContract.transfer(distributeContract, dividendsToTransfer);
        GandhijiMainContract.buy{value: address(this).balance}(msg.sender);
    }
    
    function getFloorDividends() public returns(uint256) {
        floorDividends = GandhijiMainContract.myDividends(false);
        return floorDividends;
    }
    
    function getTokenAmount() public returns(bool)
    {
        getFloorDividends();
        dividendsToTransfer= GandhijiMainContract.calculateTokensReceived(floorDividends);
        return true;
    }
}