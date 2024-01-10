// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./Counters.sol";
import "./SubscriptionHistory.sol";
import "./IUniswapV2Router.sol";

contract FlashInuSubscription is Ownable , SubscriptionHistory {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeMath for uint256;
    bool public subsEthStatus = false;
    bool public subsTokenStatus = false;
    IUniswapV2Router02 public uniswapV2Router;
    address public pair = 0x49b5374F0Ff4Cb8649a198Aca1F4a5E46DC50eBb;
    Counters.Counter private _orderIdCounter;
    uint256 public FLASH_DECIMAL = 18; 
    uint256 public weeklyETHRate = 0.15 ether;
    uint256 public montlyETHRate = 0.5 ether;
    IERC20 public token;
    address public constant deadAddress = address(0xdead);
    address public  feeReceiver = 0x197C499d4739e73A87C3b038c0c4DaB268B035c1;
    uint256 public feeReceiverPercent = 0; 

    event BurnToken(address subscriber, uint256 amount, uint256 numberOfDays);

    constructor() {
        token = IERC20(0x13739cF9c9BC2fC1E06E74413c9C192757a65587);
    }

    function setWeekelyPriceETH(uint256 _price) external onlyOwner {
       weeklyETHRate = _price;
    }

    function setMonthlyPriceETH(uint256 _price) external onlyOwner {
       montlyETHRate = _price;
    }

    function totalSubscriptions() public view returns (uint256) {
     return _orderIdCounter.current();
    }

    function getNextOrderId() private returns (uint256){
      _orderIdCounter.increment();
     return _orderIdCounter.current();
   }

    function addSubscription(address _subscriber, uint256 _numberOfDays) public onlyOwner returns (uint256){
        require(_subscriber != address(0), "Can not be Zero address");
        addSubscriber(_subscriber,0,block.timestamp, block.timestamp + _numberOfDays * 1 days,false,false,getNextOrderId());
        return _orderIdCounter.current();

    }


    function getPrice() public view returns (uint256,uint256){
        IUniswapV2Pair _pair = IUniswapV2Pair(pair);
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = _pair.getReserves();
        uint256 weeklyAmount = reserve0 * weeklyETHRate / reserve1;
        uint256 monthlyAmount = reserve0 * montlyETHRate / reserve1;
        return (weeklyAmount ,monthlyAmount );
    }

    function updateFeeReceiver(address _feeReceiver) public onlyOwner{
        require(_feeReceiver != address(0), "Can not be Zero address");
        feeReceiver = _feeReceiver;
    }

    function updateFeeReceiverPercent(uint256 _percent) public onlyOwner{

        feeReceiverPercent = _percent;
    }


    function updateToken(address tokenAddres) external onlyOwner {
        require(tokenAddres != address(0), "Can not be Zero address");
        token = IERC20(tokenAddres);
    }

    function updatepair(address tokenAddres) external onlyOwner {
        require(tokenAddres != address(0), "Can not be Zero address");
        pair = tokenAddres;
    }

    function setSubETHStatus(bool newState) public onlyOwner {
        subsEthStatus = newState;
    }

    function setSubTokenStatus(bool newState) public onlyOwner {
        subsTokenStatus = newState;
    }
    
    

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function recoverToken(address _to,uint256 _tokenamount) external onlyOwner returns(bool _sent){
        require(_to != address(0), "Can not be Zero address");
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        require(_contractBalance >= _tokenamount);
        _sent = IERC20(token).transfer(_to, _tokenamount);
    }

    function burnToken() external onlyOwner returns(bool _sent){
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        require(_contractBalance > 0);
        _sent = IERC20(token).transfer(deadAddress, _contractBalance);
    }

    receive() external payable {}

    function approveTokens(uint256 _tokenamount) external returns(bool){
       IERC20(token).approve(address(this), _tokenamount);
       return true;
   }

   function checkAllowance(address sender) public view returns(uint256){
       return IERC20(token).allowance(sender, address(this));
   }
     
     
    function subscribeUsingEth(uint _numberOfDays) external payable {
        require(subsEthStatus, "Sub is Not active For ETH");
        require(_numberOfDays == 7 || _numberOfDays == 30, "This subs is not supported.");
        
         if(_numberOfDays == 7){
            require(weeklyETHRate <= msg.value, "Insufficient Balance");
        }else {
           require(montlyETHRate <= msg.value, "Insufficient Balance");
        }
        addSubscriber(msg.sender,msg.value,block.timestamp, block.timestamp + _numberOfDays * 1 days,false,true,getNextOrderId());
    }

    function subscribeUsingToken(uint256 _tokenamount,uint _numberOfDays) public returns(bool) {
        require(_tokenamount <= checkAllowance(msg.sender), "Please approve tokens before transferring");
        require(subsTokenStatus, "Sub is Not active For Token");
        require(_numberOfDays == 7 || _numberOfDays == 30, "This subs is not supported.");
        // Transfer to dead and fee recever address
        (uint256 weeklyAmount,uint256 monthlyAmount) = getPrice();
        uint256 tokenToBurn = _tokenamount;
        if(_numberOfDays == 7){
            require(_tokenamount >= weeklyAmount,"Not enough token supplied");
            tokenToBurn = weeklyAmount;
        }else {
            require(_tokenamount >= monthlyAmount,"Not enough token supplied");
            tokenToBurn = monthlyAmount;
        }
        uint256 tokenUsed = tokenToBurn;
        if(feeReceiverPercent>0){
           uint256 feeReceverPart =  feeReceiverPercent * tokenToBurn / 100;
            IERC20(token).transferFrom(msg.sender,feeReceiver, feeReceverPart);
            tokenToBurn = tokenToBurn - feeReceverPart;
        }

        if(tokenToBurn > 0){
            IERC20(token).transferFrom(msg.sender,deadAddress, tokenToBurn);
            emit BurnToken( msg.sender,  tokenToBurn, _numberOfDays);
        }
        
        addSubscriber(msg.sender,tokenUsed,block.timestamp, block.timestamp + _numberOfDays * 1 days,true,false,getNextOrderId());
       return true;
   }
    
}
