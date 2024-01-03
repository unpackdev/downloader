// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import "./ReentrancyGuard.sol";

import "./Balancer.sol";
import "./IERC20Burnable.sol";
import "./IUniswapFactory.sol";

interface ISYNL is IERC20Burnable {
    function uniswapV2Pair() external view returns (address);
    function unlock() external;
    function initPair() external;
    function transferOwnership(address newOwner) external;
}

contract SyntLayerDist is Ownable, ReentrancyGuard{
    using SafeMath for uint;

    uint256 startTime = 0;

    ISYNL public SYNL = ISYNL(address(0));

    IUniswapV2Router02 constant uniswap =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    bool public isStopped = false;
    bool public isRefundEnabled = false;
    bool public distStarted = false;

    uint public tokensBought = 0;

    uint256 public timeWhitelistSale = 15 minutes;

    bool public teamClaimed = false;

    bool justTrigger = false;

    address public pool;

    uint256 constant hardCap = 370 ether;
    uint256 constant minSend = 0.1 ether;
    uint256 constant maxAddrCap = 3 ether;

    uint256 constant tokensPerETH = 602;
    uint256 constant listingPriceTokensPerETH = 542;

    uint256 public ethSent;

    uint256 public lockedLiquidityAmount;
    uint256 public timeTowithdrawTeamTokens;
    uint256 public refundTime;

    mapping(address => uint) ethSpent;
    mapping(address => bool) public PRIVLIST;


    constructor() public {
        //Add refund time to 2 days from now,incase we need to refund
        refundTime = block.timestamp.add(2 days);
        PRIVLIST[msg.sender] = true;
    }


    receive() external payable {
        buyTokens();
    }

    function enableRefunds() external onlyOwner nonReentrant {
        isRefundEnabled = true;
        isStopped = true;
    }

    function batchAddWhitelisted(address[] calldata addrs) public onlyOwner {
        for(uint i=0;i<addrs.length;i++) {
            PRIVLIST[addrs[i]] = true;
        }
    }

    function isPrivsalePhase() public view returns (bool) {
        return block.timestamp < startTime.add(timeWhitelistSale);
    }

    function getRefund() external nonReentrant {
        require(msg.sender == tx.origin);
        require(!justTrigger);
        // Refund should be enabled by the owner OR 7 days passed
        require(isRefundEnabled || block.timestamp >= refundTime,"Cannot refund");
        address payable user = msg.sender;
        uint256 amount = ethSpent[user];
        ethSpent[user] = 0;
        user.transfer(amount);
    }

    function lockLiqIncontract() external onlyOwner  {
        pool = SYNL.uniswapV2Pair();
        IERC20 liquidityTokens = IERC20(pool);
        uint256 liquidityBalance = liquidityTokens.balanceOf(address(this));
        liquidityTokens.transfer(address(SYNL),liquidityBalance);

        lockedLiquidityAmount = lockedLiquidityAmount.add(liquidityBalance);
    }

    function setSYNT( address addr) external onlyOwner nonReentrant {
        require(address(SYNL) == address(0), "You can set the address only once");
        SYNL = ISYNL(addr);
    }

    function setPrivatesaleDuration(uint256 newDuration) public onlyOwner {
        timeWhitelistSale = newDuration;
    }

    function startDistribution() external onlyOwner {
        startTime = block.timestamp;
        distStarted = true;
    }

     function pauseDistribution() external onlyOwner {
        distStarted = false;
    }

    function buyTokens() public payable nonReentrant {
        require(msg.sender == tx.origin,"No contract allowed");
        require(distStarted == true, "!distStarted");
        require(SYNL != ISYNL(address(0)), "!SYNL");
        require(PRIVLIST[msg.sender] || !isPrivsalePhase(), "privsale unauth");
        require(!isStopped, "stopped");
        require(msg.value >= minSend, "<minsend");
        require(msg.value <= maxAddrCap, ">maxaddrcap");
        require(ethSent < hardCap, "Hard cap reaches");
        require (msg.value.add(ethSent) <= hardCap, "Hardcap will be reached");
        require(ethSpent[msg.sender].add(msg.value) <= maxAddrCap, "You cannot buy more");

        uint256 tokens = msg.value.mul(tokensPerETH);
        require(SYNL.balanceOf(address(this)) >= tokens, "Not enough tokens in the contract");

        ethSpent[msg.sender] = ethSpent[msg.sender].add(msg.value);
        tokensBought = tokensBought.add(tokens);
        ethSent = ethSent.add(msg.value);
        SYNL.transfer(msg.sender, tokens);
    }

    function userEthSpenttInDistribution(address user) external view returns (uint) {
        return ethSpent[user];
    }

    function claimTeamFeeAndAddLiquidity() external onlyOwner  {
       require(!teamClaimed);
       uint256 amountETH = address(this).balance.mul(35).div(100);
       payable(owner()).transfer(amountETH);
       teamClaimed = true;

       addLiquidity();
    }

    function addLiquidity() internal {
        uint256 ETH = address(this).balance;
        uint256 tokensForUniswap = ETH.mul(listingPriceTokensPerETH);
        uint256 tokensExcess = SYNL.balanceOf(address(this)).sub(tokensForUniswap);
        SYNL.unlock();
        SYNL.initPair();
        SYNL.approve(address(uniswap), tokensForUniswap);
        uniswap.addLiquidityETH
        { value: ETH }
        (
            address(SYNL),
            tokensForUniswap,
            tokensForUniswap,
            ETH,
            address(SYNL),
            block.timestamp
        );
        //Send what remains to owner
       if (tokensExcess > 0){
           SYNL.transfer(owner(),tokensExcess);
       }

       justTrigger = true;
        if(!isStopped)
            isStopped = true;
        //Transfer ownership to deployer
        SYNL.transferOwnership(owner());
   }

}