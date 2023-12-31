// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Tree {
    address public anaAddress;
    address public reLockAddress;
    address public ownerAddress;
    uint256 public anaAmount = 10**10;
    uint256 public swapTimesLimit;
    mapping(uint256 => uint256) public swapLimitMap;

    struct tokenInfo {
        address tokenAddress;
        uint256 currentBlock;
        uint256 currentPrice;
        uint256 swapTimes;
        uint256 deployTime;
    }
    uint256 public tokenN;
    mapping(uint256 => tokenInfo) public tokenList;
    mapping(address => tokenInfo) public tokenListTempMap;
    
    constructor(address addr1,address addr2, uint256[] memory swapLimitList) {
        anaAddress = addr1;
        reLockAddress = addr2;
        for(uint256 i=0;i<swapLimitList.length;i++) swapLimitMap[i+1] = swapLimitList[i];
    }
    function scyncData() public {
        (bool success, bytes memory data) = anaAddress.call(abi.encodeWithSignature("ownerAddress()"));
        require(success, "syncData failed");
        ownerAddress = abi.decode(data, (address));

        ( success, data) = anaAddress.call(abi.encodeWithSignature("highPrice10000()"));
        require(success, "syncData failed 2");
        uint256 highPrice10000 = abi.decode(data, (uint256));

        swapTimesLimit = 0;
        uint256 paramMax = highPrice10000 < 10000 ? 0 : (highPrice10000 - 6000)/4000;
        for(uint256 param = 1; param <= paramMax; param++) swapTimesLimit += swapLimitMap[param];
    }
    function claimANA() public{
        (bool success, ) = anaAddress.call(abi.encodeWithSignature("claim()"));
        require(success, "claim failed 1");
        (success, ) = reLockAddress.call(abi.encodeWithSignature("claim()"));
        require(success, "claim failed 2");
    }
    function claimToken(uint256 _n, uint256 amount) checkOwner public {
        tokenInfo memory t = tokenList[_n];
        require(block.number > t.deployTime + 7200 * 365 * 3, "wait 3 years");
        (bool success, bytes memory data) = t.tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", ownerAddress, amount));
        require(success && abi.decode(data, (bool)), "transfer failed");
    }

    modifier checkOwner{
        require(msg.sender == ownerAddress, "not owner");
        _;
    }

    function newToken_1(address tokenAddress, uint256 currentPrice) checkOwner public {
        tokenListTempMap[tokenAddress] = tokenInfo(tokenAddress, block.number, currentPrice, 0, block.number);
    }
    function newToken_2(address tokenAddress) checkOwner public {
        require(tokenListTempMap[tokenAddress].currentPrice > 0, "set tokenListTempMap first");
        tokenList[++tokenN] = tokenListTempMap[tokenAddress];
        tokenListTempMap[tokenAddress].currentPrice = 0;
    }

    function swap(uint256 _n) public {
        tokenInfo memory t = tokenList[_n];
        require(block.number > t.currentBlock + 3600, "wait 12 hours");
        require(t.swapTimes < swapTimesLimit, "swapTimesLimit");

        uint256 diff = block.number - t.currentBlock - 3600;
        uint256 price = diff < 300 ? t.currentPrice * 2 : (diff >= 1200 ? t.currentPrice / 2 : t.currentPrice * (1200-diff) / 600);
        uint256 tokAmount = anaAmount * price / 10**18;

        (bool success, bytes memory data) = t.tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), tokAmount));
        require(success && abi.decode(data, (bool)), "transferFrom failed");
        (success, data) = anaAddress.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, anaAmount));
        require(success && abi.decode(data, (bool)), "transfer failed");
        
        tokenList[_n].currentBlock = block.number;
        tokenList[_n].currentPrice = price;
        tokenList[_n].swapTimes ++;
    }
}