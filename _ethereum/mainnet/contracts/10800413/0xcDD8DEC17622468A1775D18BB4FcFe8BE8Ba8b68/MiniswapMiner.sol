// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

import "./IMiniswapMiner.sol";
import "./TransferHelper.sol";
import "./IMiniswapPair.sol";
import "./MiniswapLibrary.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IMini.sol";

contract MiniswapMiner is IMiniswapMiner{
    using SafeMath for uint;
    
    address public override owner;
    address public override feeder;

    mapping(address=>bool) public override whitelistMap;
    mapping(uint256=>uint256) public override mineInfo; // day=>issueAmount
    mapping(address=>uint256) private balances;
    
    uint256 public override minFee;

    uint256 firstTxHeight;
    address MINI;
    address USDT;
    mapping (uint=>mapping(address=>bool)) rewardMap;
    mapping (uint=>uint) rewardAmountByRoundMap;

    constructor(uint256 _minFee,address _mini,address _usdt,address _feeder) public {
        owner = msg.sender;
        minFee = _minFee;
        MINI = _mini;
        USDT = _usdt;
        feeder = _feeder;
        firstTxHeight = block.number;
    }

    modifier isOwner(){
        require(msg.sender == owner,"forbidden:owner");
        _;
    }

    modifier isWhiteAddress(){
        require(whitelistMap[msg.sender] == true,"forbidden:whitelist");
        _;
    }

    function getToken(address token,address to) public isOwner() {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to,balance);
    }

    function changeMinFee(uint256 _minFee) override public isOwner() {
        minFee = _minFee;
    }

    function addWhitelist(address pair) override public isOwner() {
        whitelistMap[pair] = true;
    }

    function addWhitelistByTokens(address factory ,address token0,address token1) override public isOwner() {
        address pair = MiniswapLibrary.pairFor(factory, token0, token1);
        addWhitelist(pair);
    }

    function removeWhitelist(address pair) override public isOwner() {
        whitelistMap[pair] = false;
    }

    function removeWhitelistByTokens(address factory ,address token0,address token1) override public isOwner() {
        address pair = MiniswapLibrary.pairFor(factory, token0, token1);
        removeWhitelist(pair);
    }

    function mining(address factory,address feeTemp,address originSender,address token,uint amount) override public isWhiteAddress(){
        TransferHelper.safeTransferFrom(token,msg.sender,address(this),amount);
        uint issueAmount;
        uint miniAmount;
        if (token == MINI){
            //send half of increment to address0,the other send to feeder
            issueAmount = amount;
            miniAmount = amount;
        } else if (token == USDT) {
            //get price from token-USDT-MINI
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = MINI;
            uint256[] memory amountsOut = MiniswapLibrary.getAmountsOut(factory,amount,path); //[USDTAmountOut,MINIAmountOut]
            issueAmount = amountsOut[1];
            //only mine when usdtout more than minFee
            if(issueAmount<= minFee)
                return;
            miniAmount = swapMini(factory,USDT,issueAmount,amountsOut[0]); //usdt-->mini
        } else {
         //get price from token-USDT-MINI
            address[] memory path = new address[](3);
            path[0] = token;
            path[1] = USDT;
            path[2] = MINI;
            uint256[] memory amountsOut = MiniswapLibrary.getAmountsOut(factory,amount,path); //[tokenAmountOut,USDTAmountOut,MINIAmountOut]
            issueAmount = amountsOut[2];
            //only mine when usdtout more than minFee
            if(issueAmount<= minFee)
                return;
            uint usdtAmount = swapUsdt(factory,token,amountsOut[1],amount); //token-->usdt
            miniAmount = swapMini(factory,USDT,issueAmount,usdtAmount); //usdt-->mini
        }
        //send half of increment to address0,the other half send to feeder
        TransferHelper.safeTransfer(MINI,address(0x1111111111111111111111111111111111111111), miniAmount.div(2));
        TransferHelper.safeTransfer(MINI,feeder, miniAmount.div(2));
        issueMini(issueAmount,feeTemp,originSender);
    }

    function swapUsdt(address factory, address token,uint usdtAmount,uint amount) internal returns(uint){
        uint256 balance0 = IERC20(USDT).balanceOf(address(this));
        (address token0,address token1) = MiniswapLibrary.sortTokens(token,USDT);
        address pair_token_usdt = MiniswapLibrary.pairFor(factory,token0,token1);
        (uint amount0Out ,uint amount1Out) = token0==token ? (uint(0),usdtAmount):(usdtAmount,uint(0));
        TransferHelper.safeTransfer(token,pair_token_usdt,amount); //send token to pair
        IMiniswapPair(pair_token_usdt).swap(
                amount0Out, amount1Out, address(this), address(this),new bytes(0)
            );
        return IERC20(USDT).balanceOf(address(this)).sub(balance0);
    }

    function swapMini(address factory, address token,uint issueAmount,uint amount) internal returns(uint){
        uint256 balance0 = IERC20(MINI).balanceOf(address(this));
        (address token0,address token1) = MiniswapLibrary.sortTokens(token,MINI);
        address pair_token_mini = MiniswapLibrary.pairFor(factory,token0,token1);
        (uint amount0Out ,uint amount1Out) = token0==token ? (uint(0),issueAmount):(issueAmount,uint(0));
        TransferHelper.safeTransfer(token,pair_token_mini,amount); //send token to pair
        IMiniswapPair(pair_token_mini).swap(
                amount0Out, amount1Out, address(this),address(this),new bytes(0)
            );
        return IERC20(MINI).balanceOf(address(this)).sub(balance0);
    }

    function issueMini(uint256 issueAmount,address feeTemp,address originSender) internal {
        ///////The 6000 block height is one day, 30 day is one month
        uint durationDay = (block.number.sub(firstTxHeight)).div(6000);
        uint256 issueAmountLimit = MiniswapLibrary.getIssueAmountLimit(durationDay);
        //issue mini to liquilidity && user
        if( mineInfo[durationDay].add(issueAmount).add(issueAmount) > issueAmountLimit){
            issueAmount = issueAmountLimit.sub( mineInfo[durationDay]).div(2);
        }
        if(issueAmount > 0){
            IMini(MINI).issueTo(originSender,issueAmount);
            IMini(MINI).issueTo(feeTemp,issueAmount);
            mineInfo[durationDay] = mineInfo[durationDay].add(issueAmount).add(issueAmount);
        }
    }
}