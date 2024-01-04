//SPDX-License-Identifier: UNLICENSED


import "./SafeERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./TokenTimelock.sol";
import "./Ownable.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

pragma solidity ^0.7.3;


contract FontsPresale is Context, ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //===============================================//
    //          Contract Variables: Mainnet          //
    //===============================================//

    uint256 public MIN_CONTRIBUTION = 0.1 ether;
    uint256 public MAX_CONTRIBUTION = 6 ether;

    uint256 public HARD_CAP = 180 ether; //@change for testing 

    uint256 constant FONTS_PER_ETH_PRESALE = 1111;
    uint256 constant FONTS_PER_ETH_UNISWAP = 700;

    uint256 public UNI_LP_ETH = 86 ether;
    uint256 public UNI_LP_FONT;

    uint256 public constant UNLOCK_PERCENT_PRESALE_INITIAL = 50; //For presale buyers instant release
    uint256 public constant UNLOCK_PERCENT_PRESALE_SECOND = 30; //For presale buyers after 30 days
    uint256 public constant UNLOCK_PERCENT_PRESALE_FINAL = 20; //For presale buyers after 60 days

    uint256 public DURATION_REFUND = 7 days;
    uint256 public DURATION_LIQUIDITY_LOCK = 365 days;

    uint256 public DURATION_TOKEN_DISTRIBUTION_ROUND_2 = 30 days;
    uint256 public DURATION_TOKEN_DISTRIBUTION_ROUND_3 = 60 days;    

    address FONT_TOKEN_ADDRESS = 0x4C25Bdf026Ea05F32713F00f73Ca55857Fbf6342; //FONT Token address

    IUniswapV2Router02 constant UNISWAP_V2_ADDRESS =  IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory constant uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 


    //General variables

    IERC20 public FONT_ERC20; //Font token address

    address public ERC20_uniswapV2Pair; //Uniswap Pair address

    TokenTimelock public UniLPTimeLock;

    
    uint256 public tokensBought; //Total tokens bought
    uint256 public tokensWithdrawn;  //Total tokens withdrawn by buyers

    bool public isStopped = false;
    bool public presaleStarted = false;
    bool public uniPairCreated = false;
    bool public liquidityLocked = false;
    bool public bulkRefunded = false;

    bool public isFontDistributedR1 = false;
    bool public isFontDistributedR2 = false;
    bool public isFontDistributedR3 = false;



    uint256 public roundTwoUnlockTime; 
    uint256 public roundThreeUnlockTime; 
    
    bool liquidityAdded = false;

    address payable contract_owner;
    
    
    uint256 public liquidityUnlockTime;
    
    uint256 public ethSent; //ETH Received
    
    uint256 public lockedLiquidityAmount;
    uint256 public refundTime; 

    mapping(address => uint) ethSpent;
    mapping(address => uint) fontBought;
    mapping(address => uint) fontHolding;
    address[] public contributors;

    

    constructor() {
        contract_owner = _msgSender(); 
        //ChangeSettingsForTestnet();
        UNI_LP_FONT = UNI_LP_ETH.mul(FONTS_PER_ETH_UNISWAP);
        FONT_ERC20 = IERC20(FONT_TOKEN_ADDRESS);
    }


    //@done
    receive() external payable {   
        buyTokens();
    }
    


    //@done
    function allowRefunds() external onlyOwner nonReentrant {

        isStopped = true;
    }

    //@done
    function buyTokens() public payable nonReentrant {
        require(_msgSender() == tx.origin);
        require(presaleStarted == true, "Presale is paused");
        require(msg.value >= MIN_CONTRIBUTION, "Less than 0.1 ETH");
        require(msg.value <= MAX_CONTRIBUTION, "More than 6 ETH");
        require(ethSent < HARD_CAP, "Hardcap reached");        
        require(msg.value.add(ethSent) <= HARD_CAP, "Hardcap will reached");
        require(ethSpent[_msgSender()].add(msg.value) <= MAX_CONTRIBUTION, "> 6 ETH");

        require(!isStopped, "Presale stopped"); //@todo

        
        uint256 tokens = msg.value.mul(FONTS_PER_ETH_PRESALE);
        require(FONT_ERC20.balanceOf(address(this)) >= tokens, "Not enough tokens"); //@tod

        if(ethSpent[_msgSender()] == 0) {
            contributors.push(_msgSender()); //Create list of contributors    
        }
        
        ethSpent[_msgSender()] = ethSpent[_msgSender()].add(msg.value);

        tokensBought = tokensBought.add(tokens);
        ethSent = ethSent.add(msg.value);

        fontBought[_msgSender()] = fontBought[_msgSender()].add(tokens); //Add fonts bought by contributor

        fontHolding[_msgSender()] = fontHolding[_msgSender()].add(tokens); //Add fonts Holding by contributor

    }

    //@done, create unipair first. 
    function createUniPair() external onlyOwner {
        require(!liquidityAdded, "liquidity Already added");
        require(!uniPairCreated, "Already Created Unipair");

        ERC20_uniswapV2Pair = uniswapFactory.createPair(address(FONT_ERC20), UNISWAP_V2_ADDRESS.WETH());

        uniPairCreated = true;
    }


   
    //@done
    function addLiquidity() external onlyOwner {
        require(!liquidityAdded, "liquidity Already added");
        require(ethSent >= HARD_CAP, "Hard cap not reached");   
        require(uniPairCreated, "Uniswap pair not created");


        FONT_ERC20.approve(address(UNISWAP_V2_ADDRESS), UNI_LP_FONT);
        
        UNISWAP_V2_ADDRESS.addLiquidityETH{ value: UNI_LP_ETH } (
            address(FONT_ERC20),
            UNI_LP_FONT,
            UNI_LP_FONT,
            UNI_LP_ETH,
            address(contract_owner),
            block.timestamp
        );
       
        liquidityAdded = true;
       
        if(!isStopped)
            isStopped = true;

        //Set duration for FONT distribution 
        roundTwoUnlockTime = block.timestamp.add(DURATION_TOKEN_DISTRIBUTION_ROUND_2); 
        roundThreeUnlockTime = block.timestamp.add(DURATION_TOKEN_DISTRIBUTION_ROUND_3); 
    }

    //Lock the liquidity 
    function lockLiquidity() external onlyOwner {
        require(liquidityAdded, "Add Liquidity");
        require(!liquidityLocked, "Already Locked");
        //Lock the Liquidity 
        IERC20 liquidityTokens = IERC20(ERC20_uniswapV2Pair); //Get the Uni LP token
        if(liquidityUnlockTime <= block.timestamp) {
            liquidityUnlockTime = block.timestamp.add(DURATION_LIQUIDITY_LOCK);
        }
        UniLPTimeLock = new TokenTimelock(liquidityTokens, contract_owner, liquidityUnlockTime);
        liquidityLocked = true;
        lockedLiquidityAmount = liquidityTokens.balanceOf(contract_owner);
    }
    
    //Unlock it after 1 year
    function unlockLiquidity() external onlyOwner  {      
        UniLPTimeLock.release();
    }

    //Check when Uniswap V2 tokens are unlocked
    function unlockLiquidityTime() external view returns(uint256) {      
        return UniLPTimeLock.releaseTime();
    }    

    /*
    //FONT can be claim by investors after sale success, It is optional 
    //@done
    function claimFontRoundOne() external nonReentrant {
        require(liquidityAdded,"FontsCrowdsale: can only claim after listing in UNI");  
        require(fontHolding[_msgSender()] > 0, "FontsCrowdsale: No FONT token available for this address to claim");       
        uint256 tokenAmount_ = fontBought[_msgSender()];

        tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_INITIAL).div(100);
        fontHolding[_msgSender()] = fontHolding[_msgSender()].sub(tokenAmount_);

        // Transfer the $FONTs to the beneficiary
        FONT_ERC20.safeTransfer(_msgSender(), tokenAmount_);
        tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
    }

    //30% of FONT can be claim by investors after 30 days from unilisting
    //@done

    function claimFontRoundTwo() external nonReentrant {
        require(liquidityAdded,"Claimble after UNI list");  
        require(fontHolding[_msgSender()] > 0, "0 FONT");
        require(block.timestamp >= roundTwoUnlockTime, "Timelocked");

        uint256 tokenAmount_ = fontBought[_msgSender()];

        tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_SECOND).div(100);
        fontHolding[_msgSender()] = fontHolding[_msgSender()].sub(tokenAmount_);

        // Transfer the $FONTs to the beneficiary
        FONT_ERC20.safeTransfer(_msgSender(), tokenAmount_);
        tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
    }

    //20% of FONT can be claim by investors after 20 days from unilisting
    //@done
    function claimFontRoundThree() external nonReentrant {
        require(liquidityAdded,"Claimble after UNI list");  
        require(fontHolding[_msgSender()] > 0, "0 FONT");
        require(block.timestamp >= roundThreeUnlockTime, "Timelocked");

        uint256 tokenAmount_ = fontBought[_msgSender()];

        tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_FINAL).div(100);
        fontHolding[_msgSender()] = fontHolding[_msgSender()].sub(tokenAmount_);

        // Transfer the $FONTs to the beneficiary
        FONT_ERC20.safeTransfer(_msgSender(), tokenAmount_);
        tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
    }
    */
    
    //@done distribute first round of tokens
    function distributeTokensRoundOne() external onlyOwner {
        require(liquidityAdded, "Add Uni Liquidity");        
        require(!isFontDistributedR1, "Round 1 done");
        for (uint i=0; i<contributors.length; i++) {          
            if(fontHolding[contributors[i]] > 0) {
                uint256 tokenAmount_ = fontBought[contributors[i]];
                tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_INITIAL).div(100);
                fontHolding[contributors[i]] = fontHolding[contributors[i]].sub(tokenAmount_);
                // Transfer the $FONTs to the beneficiary
                FONT_ERC20.safeTransfer(contributors[i], tokenAmount_);
                tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
            }
        }
        isFontDistributedR1 = true;
    }

    //Let any one call next 30% of distribution
    //@done
    function distributeTokensRoundTwo() external nonReentrant{
        require(liquidityAdded, "Add Uni Liquidity"); 
        require(isFontDistributedR1, "Do Round 1");
        require(block.timestamp >= roundTwoUnlockTime, "Timelocked");
        require(!isFontDistributedR2, "Round 2 done");

        for (uint i=0; i<contributors.length; i++) {
            if(fontHolding[contributors[i]] > 0) {
                uint256 tokenAmount_ = fontBought[contributors[i]];
                tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_SECOND).div(100);
                fontHolding[contributors[i]] = fontHolding[contributors[i]].sub(tokenAmount_);
                // Transfer the $FONTs to the beneficiary
                FONT_ERC20.safeTransfer(contributors[i], tokenAmount_);
                tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
            }
        }
        isFontDistributedR2 = true;
    }

    //Let any one call final 20% of distribution
    //@done
    function distributeTokensRoundThree() external nonReentrant{
        require(liquidityAdded, "Add Uni Liquidity"); 
        require(isFontDistributedR2, "Do Round 2");
        require(block.timestamp >= roundThreeUnlockTime, "Timelocked");
        require(!isFontDistributedR3, "Round 3 done");

        for (uint i=0; i<contributors.length; i++) {
            if(fontHolding[contributors[i]] > 0) {
                uint256 tokenAmount_ = fontBought[contributors[i]];
                tokenAmount_ = tokenAmount_.mul(UNLOCK_PERCENT_PRESALE_FINAL).div(100);
                fontHolding[contributors[i]] = fontHolding[contributors[i]].sub(tokenAmount_);
                // Transfer the $FONTs to the beneficiary
                FONT_ERC20.safeTransfer(contributors[i], tokenAmount_);
                tokensWithdrawn = tokensWithdrawn.add(tokenAmount_);
            }
        }
        isFontDistributedR3 = true;
    }
    


    //@done
    //Withdraw the collected remaining eth
    function withdrawEth(uint amount) external onlyOwner returns(bool){
        require(liquidityAdded,"After UNI LP");        
        require(amount <= address(this).balance);
        contract_owner.transfer(amount);
        return true;
    }    

    //@done
    //Allow admin to withdraw any pending FONT after everyone withdraw, 60 days
    function withdrawFont(uint amount) external onlyOwner returns(bool){
        require(liquidityAdded,"After UNI LP");
        require(isFontDistributedR3, "After distribute to buyers");
        FONT_ERC20.safeTransfer(_msgSender(), amount);
        return true;
    }

    //@done
    function userFontBalance(address user) external view returns (uint256) {
        return fontHolding[user];
    }

    //@done
    function userFontBought(address user) external view returns (uint256) {
        return fontBought[user];
    }

    //@done
    function userEthContribution(address user) external view returns (uint256) {
        return ethSpent[user];
    }    

    //@done
    function getRefund() external nonReentrant {
        require(_msgSender() == tx.origin);
        require(isStopped, "Should be stopped");
        require(!liquidityAdded);
        // To get refund it not reached hard cap and 7 days had passed 
        require(ethSent < HARD_CAP && block.timestamp >= refundTime, "Cannot refund");
        uint256 amount = ethSpent[_msgSender()];
        require(amount > 0, "No ETH");
        address payable user = _msgSender();
        
        ethSpent[user] = 0;
        fontBought[user] = 0;
        fontHolding[user] = 0;
        user.transfer(amount);
    }

    //@done let anyone call it
    function bulkRefund() external nonReentrant {
        require(!liquidityAdded);
        require(!bulkRefunded, "Already refunded");
        require(isStopped, "Should be stopped");
        // To get refund it not reached hard cap and 7 days had passed 
        require(ethSent < HARD_CAP && block.timestamp >= refundTime, "Cannot refund");
        for (uint i=0; i<contributors.length; i++) {
            address payable user = payable(contributors[i]);
            uint256 amount = ethSpent[user];
            if(amount > 0) {
                ethSpent[user] = 0;
                fontBought[user] = 0;
                fontHolding[user] = 0;                
                user.transfer(amount);
            }
        }        
        bulkRefunded = true;
    }    
    
    //@done Call this to kickstart fundraise
    function startPresale() external onlyOwner { 
        liquidityUnlockTime = block.timestamp.add(DURATION_LIQUIDITY_LOCK);
        refundTime = block.timestamp.add(DURATION_REFUND);        
        presaleStarted = true;
    }
    
    //@done
    function pausePresale() external onlyOwner { 
        presaleStarted = false;
    }


}
