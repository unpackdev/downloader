// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract whiteList {
    address public anaAddress;
    address public reLockAddress;
    address public usdcAddress;
    address public ownerAddress;
    struct investInfo {
        address addr;
        uint256 amountA;
        uint256 createTime;
        bool state;
    }
    uint256 public investN;
    mapping(uint256 => investInfo) public investList;
    mapping(address => uint256) public regionLimit;
    mapping(address => address) public regionMap;
    uint256 public lockTime;
    uint256 public price;

    constructor(address addr1,address addr2,address addr3) {
        anaAddress = addr1;
        reLockAddress = addr2;
        usdcAddress = addr3;
    }
    function scyncData() public {
        (bool success, bytes memory data) = anaAddress.call(abi.encodeWithSignature("ownerAddress()"));
        require(success, "syncData failed");
        ownerAddress = abi.decode(data, (address));
    }
    function claimANA() public{
        (bool success, ) = reLockAddress.call(abi.encodeWithSignature("claim()"));
        require(success, "claim failed 1");
        (success, ) = anaAddress.call(abi.encodeWithSignature("claim()"));
        require(success, "claim failed 2");
    }
    function claimUSDC(uint256 amount) checkOwner public {
        (bool success, bytes memory data) = usdcAddress.call(abi.encodeWithSignature("transfer(address,uint256)", ownerAddress, amount));
        require(success && abi.decode(data, (bool)), "transfer failed");
    }

    modifier checkOwner{
        require(msg.sender == ownerAddress, "not owner");
        _;
    }
    
    function setLockTime(uint256 _lockTime) checkOwner public {
        require(_lockTime >= 7200*365 && _lockTime <= 7200*365*2, "_lockTime wrong");
        lockTime = _lockTime;
    }
    function setPrice(uint256 _price) checkOwner public {
        require(_price <= 50, "_price wrong");
        price = _price;
    }
    function setRegionLimit(address addr, uint256 amount) checkOwner public {
        regionLimit[addr] = amount;
    }
    function regionSetWhite(address addr) public {
        regionMap[addr] = msg.sender;
    }
    
    function invest(uint256 amountU) public {
        require(regionLimit[regionMap[msg.sender]] >= amountU, "out of limit");
        regionLimit[regionMap[msg.sender]] -= amountU;
        (bool success, bytes memory data) = usdcAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amountU));
        require(success && abi.decode(data, (bool)), "transferFrom failed");
        investList[investN++] = investInfo(msg.sender, amountU * price, block.number, true);
    }

    function release(uint256 _n) public {
        investInfo memory i = investList[_n];
        require(block.number >= i.createTime + lockTime, "wait some times");
        require(i.state , "already release");
        investList[_n].state = false;
        (bool success, bytes memory data) = anaAddress.call(abi.encodeWithSignature("transfer(address,uint256)", i.addr, i.amountA));
        require(success && abi.decode(data, (bool)), "transfer failed");
    }
}