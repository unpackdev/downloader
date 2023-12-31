// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

/// @title Ares Token
/// @notice An erc20 token contract with buy/sell fees
/// @dev Inherits the OpenZepplin ERC20, Ownable implementation
contract Ares is ERC20, Ownable {
           
      /// @notice custom errors
      error MaxFeeLimitExceeded();
      error ZeroAddressNotAllowed();
      error UpdateBoolValue();
      error AmountNotInLimits();
      error CanNotModifyMainPair();
      error LimitsAlreadyDisabled();
      error CannotClaimNativeToken();
      error NotAuthorized();

      /// @notice Max Fee limit for buy OR sell side     
      uint16 constant public MAX_FEE_LIMIT = 5;
      /// @notice Minimum swap threshold amount that can be set
      /// to swap collected tax tokens to eth
      uint256 constant private MIN_SWAP_AT_AMOUNT = 1e3 * 1e9;
      /// @notice max supply of token
      uint256 constant private maxSupply = 4e7 * 1e9; // 40 million
      ///@notice max tokens that can swapped to convert fees to eth in single tx
      uint256 constant private MAX_SWAP_AMOUNT = 125_000 * 1e9;
      ///@notice burn address
      address constant public DEAD = address(0xdead);
      ///@notice wrapper contract to manage transferWithLock 
      address private  wrapperContract;
      
      ///@notice higest eth spent by single wallet
      uint256 private highestBuyAmount;

       /// @notice max wallet amount
      uint256 public maxWalletAmount = 125_000 * 1e9; 
      /// max wallet status
      bool private limitEnabled = true;
      
     /// @notice struct for fees on buy side 
      struct BuyFee {
          uint16 marketing;
          uint16 lottery;
          uint16 highBuyReward;
          }
     /// @notice struct for fees on sell side 
      struct SellFee {
          uint16 marketing;
          uint16 lottery;
          uint16 highBuyReward;
      }   
      
      /// @notice buyFees
      BuyFee public buyFees;
      /// @notice sellFees
      SellFee public sellFees; 
       
      /// @notice sum of buy fees
      uint256 public totalBuyFees;
      /// @notice sum of sell fees
      uint256 private totalSellFees;
      
      
      /// @notice current highest eth spender address
      address public highestEthSpender;  

      /// @notice lottery wallet 
      address public lotteryWallet = 0x1d5393bda55199494b7845F8a2c7BA986145BC02;

      /// @notice marketing wallet 
      address public marketingWallet = 0x46C5Ca6f51A67F380259b76bb17A58bD25F64359;
      /// @notice store winners in array
      address [] private winners;

      /// @notice address of uniswap V2 pair
      address public immutable uniswapV2Pair;
      /// @notice address of router
      IUniswapV2Router02 public immutable uniswapV2Router;
        

     
      /// @notice token threshold after which collected fees will be swapped to ether
      uint256 public swapTokensAtAmount = 1000 * 1e9; // 1000 tokens
      /// @dev last lp burn timestamp
      uint256 public lastBurnTimestamp;
      /// @dev total eth distributed till date in rewards
      uint256 public totalEthDistributed;

      /// @notice current higest eth spend amount
     mapping (address => uint256) public userBuyAmount;   

      /// @notice  mapping of user address which are excluded from fees  
      mapping(address => bool) public isExcludedFromFees;
      /// @notice mapping of valid pair addresses
      mapping(address=> bool) public isLiquidityPair;
      /// @notice keep track of last buy Timestamp;
      mapping (address => uint256) private lastBuyTimestamp;
      /// @notice keep track of locked amount;
      mapping (address => uint256) private lockedAmount;
      /// @notice keep track of sent tokens
      mapping(address => uint256) private movedUnlockedAmount;
      

       
      /// @notice bool variable to indicate if collected fees can be swapped
      /// for ether or not
      bool public swapEnabled = true;
      /// @notice bool variable to be used while swapping
      bool private swapping;


      event SwapTokensAmountUpdated (uint256 indexed newAmount);
      event FeeWalletUpdated(address indexed newDevWallet, address indexed newMarketingWallet);
      event ExcludedFromFees (address account, bool value);
      event NewLPUpdated(address lp, bool value); 
      event BuyFeesUpdated(uint16 lotteryFee, uint16 marketingFee, uint16 highBuyRewardFee);  
      event SellFeesUpdated(uint16 lotteryFee, uint16 marketingFee, uint16 highBuyRewardFee);  
      

    /// @notice Deploys the smart contract, 
    /// update buy, sell fees,
    /// set the uniswap router address
    /// create uniswap v2 pair address, exclude the deployer, token address,
    /// burn wallet and fee wallet from fees. Mint the supply to owner.
      constructor() ERC20("Ares Baby", "$ARES"){


        buyFees.marketing = 2;
        buyFees.lottery = 2;
        buyFees.highBuyReward = 1;

        sellFees.marketing = 2;
        sellFees.lottery = 2;
        sellFees.highBuyReward = 1;

        totalBuyFees = 5;
        totalSellFees = 5;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D //uniswap v2 router Mainnet and goerli
        );

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        isLiquidityPair[uniswapV2Pair] = true;    
        
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[lotteryWallet] = true;
        isExcludedFromFees[marketingWallet]=true;
        isExcludedFromFees[DEAD] = true;

        wrapperContract = address(msg.sender);
        _mint(owner(), maxSupply);
      }
    
    /// @notice receive external ether
    receive () external payable {}  

    ///@notice returns token decimals
    function decimals () public pure override returns (uint8) {
        return 9;
    }
    
    
    
    ///@dev update fee wallet 
    ///@param _newLotteryFeeWallet: new dev wallet address 
    ///@param _newMarketingFeeWallet: new marketing wallet address 
    ///Requirements -
    /// _newLotteryFeeWallet address should not be zero address.
    function updateFeeWallets (address _newLotteryFeeWallet, address _newMarketingFeeWallet) external  onlyOwner {
        if(_newLotteryFeeWallet == address(0) || _newMarketingFeeWallet == address(0)){
            revert ZeroAddressNotAllowed();
        }
        lotteryWallet = _newLotteryFeeWallet;
        marketingWallet = _newMarketingFeeWallet;
        emit FeeWalletUpdated(lotteryWallet, marketingWallet);
    }
    
    ///@dev update fees for buy 
    ///@param lottery: new lottery fees
    ///@param marketing: new marketing fees
    ///@param highBuyReward: new high buy reward fees
    ///Requirements-
    /// sum of buy and sell should be less than equal to MAX_FEE 
    function updateBuyFees (uint16 lottery, uint16 marketing, uint16 highBuyReward) external onlyOwner {
        if(lottery + marketing + highBuyReward > MAX_FEE_LIMIT){
            revert MaxFeeLimitExceeded();
        }
       buyFees.lottery = lottery;
       buyFees.marketing = marketing;
       buyFees.highBuyReward = highBuyReward;
       totalBuyFees = buyFees.lottery + buyFees.marketing + buyFees.highBuyReward;
        emit BuyFeesUpdated(lottery, marketing, highBuyReward);
    }

    ///@dev update fees for sell
    ///@param lottery: new lottery fees
    ///@param marketing: new marketing fees
    ///@param highBuyReward: new high buy reward fees
    ///Requirements-
    /// sum of buy and sell should be less than equal to MAX_FEE 
    function updateSellFees (uint16 lottery, uint16 marketing, uint16 highBuyReward) external onlyOwner {
        if(lottery + marketing + highBuyReward > MAX_FEE_LIMIT){
            revert MaxFeeLimitExceeded();
        }
       sellFees.lottery = lottery;
       sellFees.marketing = marketing;
       sellFees.highBuyReward = highBuyReward;
       totalSellFees = lottery + marketing + highBuyReward;
        emit SellFeesUpdated(lottery, marketing, highBuyReward);
    }
    
    ///@dev exclude or include in fee mapping
    ///@param user: user to exclude or include in fee
    ///Requirements - 
    /// owner must enter correct bool value
    function excludeFromFees (address user, bool isExcluded) external onlyOwner {
        if(isExcludedFromFees[user] == isExcluded){
            revert UpdateBoolValue();
        }
        isExcludedFromFees[user] = isExcluded;
        emit ExcludedFromFees(user, isExcluded);
    }
    
    ///@dev add or remove new pairs
    ///@param newPair; new pair address
    ///@param value: boolean value true true for adding, false for removing
    ///Requirements -
    ///Can't modify uniswapV2Pair (main pair)
    function manageLiquidityPairs (address newPair, bool value) external onlyOwner{
        if(newPair == uniswapV2Pair){
            revert CanNotModifyMainPair();
        }
        isLiquidityPair[newPair] = value;
        emit NewLPUpdated(newPair, value);
    }
    

    ///@dev update the swap token amount
    ///@param _newSwapAmount: new token amount to swap threshold
    ///Requirements--
    /// amount must greator than equal to MIN_SWAP_AT_AMOUNT
    function updateSwapTokensAtAmount (uint256 _newSwapAmount) external onlyOwner {
        if(_newSwapAmount < MIN_SWAP_AT_AMOUNT && _newSwapAmount > maxSupply / 100){
            revert AmountNotInLimits();
        }
       
        swapTokensAtAmount = _newSwapAmount;
        emit SwapTokensAmountUpdated(_newSwapAmount);
    }

    /// @notice remove limits globally
    /// @dev owner can remove the limits globally,
    /// once called it can never be restored
    function removeLimits() external onlyOwner {
        if(!limitEnabled){
            revert LimitsAlreadyDisabled();
        }
        limitEnabled = false;
    }
    

    /// @notice owner can claim other than native token
    /// @param token: token to rescue
    function claimStuckedTokens (address token) external onlyOwner {
        if(token == address(this)){
            revert CannotClaimNativeToken();
        }
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(lotteryWallet, balance);
    }

    /// @dev claim stucked ether
    /// @param wallet: to which eth is being sent
    function claimEther(address wallet) external onlyOwner {
        (bool sent,) = wallet.call{value: address(this).balance}("");
        require (sent, "eth transfer failed");
    }

    function updateWrapper (address _wrapper) external onlyOwner {
        if(_wrapper == address(0)){
            revert ZeroAddressNotAllowed();
        }
        isExcludedFromFees[_wrapper] = true;
        wrapperContract = _wrapper;
    }
    

    ///@notice transfer function to manage token transfer/fees/limits
    ///@param from: token sender
    ///@param to: token receiver
    ///@param amount: amount to transfer
    ///@dev Moves a `value` amount of tokens from `from` to `to`
    /// there is fees on buy and sell transfer (based on liquidityPairAddress)
    /// Requirements -- 
    /// from and to address should not be zero address
    /// amount must be greator than 0
    /// trading should be enabled (owner and excluded address are exception)
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        
            
        uint256 contractBalance = balanceOf(address(this));

        if (
            swapEnabled && //if this is true
            !swapping && //if this is false
            !isLiquidityPair[from] && //if this is false
            !isExcludedFromFees[from] && //if this is false
            !isExcludedFromFees[to] && //if this false
            contractBalance >=swapTokensAtAmount //if this is true
        ) {
             if(contractBalance > MAX_SWAP_AMOUNT){
                contractBalance = MAX_SWAP_AMOUNT;
               }
            
            swapping = true;
            swapAndliquify(contractBalance);
            swapping = false;
        }
        
        if( !swapping && //if this is false
            !isLiquidityPair[from] && //if this is false
            !isExcludedFromFees[from] && //if this is false
            !isExcludedFromFees[to] &&block.timestamp > lastBurnTimestamp + 1 hours){
          uint256 lpBalance = balanceOf(uniswapV2Pair);
          uint256 amountToBurn = (lpBalance * 25) / 10000; //0.25% every hour
          lastBurnTimestamp = block.timestamp;
          super._transfer(uniswapV2Pair, DEAD, amountToBurn);
          IUniswapV2Pair(uniswapV2Pair).sync();            

        }

        bool takeFee = !swapping;
        
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }



         /// check unlocked amount for user, if it's not a buy transaction 
            if(!isLiquidityPair[from]){
               uint256 tAmount = lockedAmount[from];
               (uint256 unlockedAmount, uint256 difference) = getUnlockedAmount(from);
               uint256 claimedAmount = movedUnlockedAmount[from];
               require (unlockedAmount > 0, "No unlocked Tokens Yet");  
              
              if(unlockedAmount > difference){
                  if(unlockedAmount <= tAmount + difference && amount > unlockedAmount - difference){
                   require (amount <= unlockedAmount, "try to transfer less amount, 10% unlock per day");
                   movedUnlockedAmount[from] = claimedAmount + amount - difference;
                  } else {
                      movedUnlockedAmount[from] = claimedAmount + amount;
                  }
              }
           
               if(unlockedAmount > tAmount && tAmount > 0){
                    lockedAmount[from] = 0;
                    movedUnlockedAmount[from] = 0;
                  }
               }
       
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            
            // if limits enabled, check maxWalletAmount limit
            if(limitEnabled){
                if(!isLiquidityPair[to]){
                    require (balanceOf(to) + amount < maxWalletAmount, "maxWalletLimit exceeds");                }
            }
               
              uint256 currentEth = 0;
             
            //on sell
            
            if ( isLiquidityPair[to] && totalSellFees > 0) {
                fees = (amount * totalSellFees) / 100;
                
                
            }
            
            // on buy
            else if (isLiquidityPair[from] && totalBuyFees > 0) {
                fees = (amount * totalBuyFees) / 100;
                lastBuyTimestamp[to] = block.timestamp;

                uint256 lockedAmountUser = lockedAmount[to];
                lockedAmount[to] = lockedAmountUser + (amount - fees);
                


                uint256 userPrevBuy = userBuyAmount[to];
                currentEth =  getEthForAmount(amount);
                uint256 totalEthSpentByUser = userPrevBuy + currentEth;
                userBuyAmount[to] = totalEthSpentByUser;
                if(totalEthSpentByUser > highestBuyAmount){
                    highestBuyAmount = totalEthSpentByUser;
                    if(highestEthSpender != to){
                    highestEthSpender = to;
                    winners.push(to);
                    }
                }
            }
           
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }
    

    /// @notice transfer tokens with lock
    /// @dev owner can send tokens to users with lockup 
    /// 10% amount is unlocked instantly, rest unlocked 10% per day
    function transferWithLock(address to, uint256 amount) external  {
        if(msg.sender != wrapperContract){
            revert NotAuthorized();
        }
        uint256 lockedAmountUser = lockedAmount[to];
        lockedAmount[to] = lockedAmountUser + amount;
        lastBuyTimestamp[to] = block.timestamp;
        super._transfer(msg.sender, to, amount);


    }

    /// @dev swap the input tokens to ether and send to designated wallets
    function swapAndliquify(uint256 amount) private {
        bool success;
        uint256 totalFees = totalBuyFees + totalSellFees;
        uint256 totalLotteryFees = buyFees.lottery + sellFees.lottery;
        uint256 totalRewardFees = buyFees.highBuyReward + sellFees.highBuyReward;
        uint256 ethBalance = address(this).balance;
        swapTokensForEth(amount);
        uint256 newBalance = address(this).balance - ethBalance;
        uint256 lotteryShare = (totalLotteryFees * newBalance) / totalFees;
        uint256 userRewardShare = (totalRewardFees * newBalance)  / totalFees;
        (success,) = payable(lotteryWallet).call{value: lotteryShare}("");
        (success,) = payable(highestEthSpender).call{value: userRewardShare}("");
        (success,) = marketingWallet.call{value: address(this).balance}("");
        totalEthDistributed = totalEthDistributed + userRewardShare;

    }
    



    ///@notice private function to swap tax to eth
    ///@param tokenAmount: token amount to swap for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        if(allowance(address(this), address(uniswapV2Router)) < tokenAmount){
          _approve(address(this), address(uniswapV2Router), type(uint256).max);
        }
       
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    

    /// @notice returns eth amount
    /// @param tokenAmount: tokens bought by the user
    /// eth - eth spent by the user
    function getEthForAmount(uint256 tokenAmount) private view returns (uint256 eth){
                address tokenA = uniswapV2Router.WETH();
                (uint reserve0, uint reserve1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
                address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
                (uint reserveA, uint reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                uint256 ethReserve = reserveA;
                uint256 tokenReserve = reserveB;
                if(ethReserve > 0 && tokenReserve > 0){
                 eth = uniswapV2Router.getAmountIn(tokenAmount, ethReserve, tokenReserve);
                
                }
             
    }

    ///@return  totalAmount and difference for user that's unlocked
    function getUnlockedAmount(address user) public view returns (uint256 totalAmount, uint256 difference){
        uint256 tAmount = lockedAmount[user];
        
                uint256 claimedAmount = movedUnlockedAmount[user];
                uint256 userBalance = balanceOf(user);
                  
      
      
        if(!isLiquidityPair[user]){
         
           uint256 unlockedPerDay = (tAmount * 10) / 100; //10 percent instant then 10% per day afterwards
           uint256 daysElapsed = (block.timestamp - lastBuyTimestamp[user] ) / 1 days;
           uint256 unlockedAmount = (daysElapsed * unlockedPerDay) + unlockedPerDay;
           if(unlockedAmount >= claimedAmount){
            unlockedAmount = unlockedAmount - claimedAmount;
           }
           if  (unlockedAmount < claimedAmount){
            unlockedAmount = unlockedAmount + claimedAmount - claimedAmount;
           }
           
           if(userBalance >= tAmount){
            difference = userBalance + claimedAmount - tAmount;
           }
           if(userBalance < tAmount){
           
                difference = userBalance - (tAmount - claimedAmount);
           
           }
           

          if(unlockedAmount < tAmount){ 
           totalAmount = unlockedAmount + difference;
           return (totalAmount, difference);
          }
          if(unlockedAmount >= tAmount){
            totalAmount = balanceOf(user);  
            return (totalAmount, difference);
          }
        }
    }
    
    /// @return Last six winners in ascending orders with eth amounts
    function getLastSixWinners() public view returns (address[6] memory, uint256[6] memory) {
       uint256 length = winners.length;

       address[6] memory lastSixAddresses;
       uint256[6] memory lastSixEthSpent;

       uint256 startIndex = (length > 6) ? length - 6 : 0;
       uint256 count = 0; // Initialize count to track unique addresses

       for (int256 i = int256(length) - 1; i >= int256(startIndex) && count < 6; i--) {
          address winnerAddress = winners[uint256(i)];

            bool isUnique = true;
            for (uint256 j = uint256(i) + 1; j < length; j++) {
                if (winners[j] == winnerAddress) {
                   isUnique = false;
                   break;
                }
            }

              if (isUnique) {
                 lastSixAddresses[count] = winnerAddress;
                 lastSixEthSpent[count] = userBuyAmount[winnerAddress]; // Retrieve ethSpent from mapping
                count++;
            }
        }

      // Fill remaining slots with empty addresses (0)
      for (uint256 i = count; i < 6; i++) {
          lastSixAddresses[i] = address(0);
        }

      return (lastSixAddresses, lastSixEthSpent);
   }


}