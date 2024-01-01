// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/*
                                    %%%#############%%%                                  
              %              @%%#######%%%%%%%%%%%%%#######%%              %              
            %#**#%      @%%#####%%                      @%%#####%%      @%#**#%          
          %#*#%%#*#%  %##*##%                                @%%#*##%  %#*#%%#*#%        
        %#*#%    %#*##*#%%                                      @%%#*##*#%    %#*#%      
        %#*#%    %#*##%                                            @%##*#%    %#*#%      
          %#*#%%#**#%                                                  %#*#%%#*#%        
            %#**##%                      @%%%%%%%                        %#**#%          
            %#*#%                    @%##****#****##%                    @%#*#%          
          @#**%                    @%#**#%%    @%%#**#%                    @%#*#%        
        @%#*#%                    @%**#%          @%#**%                    @%#*#%        
        @#*#%                    @%**#%            @%#*#%                    @%#*#%      
        #*#%                      #**%              @%**#                      %#*#%      
      @%*#%                      @#**%              @%**#%                      %#*#      
      %**%                        #**%              @%**#%                      @%**%    
      #*#%                        #**%              @%**#%                        #*#%    
    @%**%                        @#**%              @%**#%                        %**%    
    @#*#%                  @%####******#############******####%                  @%#*#    
    @#*#%                @%#**##%%%%%%%%%%%%%%%%%%%%%%%%%%%##**#%                  #*#%  
    @#*#%                @%**#%                            @%#**%                  %*#%  
    %#*#%                @%**#%                            @%#**%                  %*#%  
    @#*#%                @%**#%          %##***#%%          %#**%                  %*#%  
    @#*#%                @%**#%        @%#**#%#**#%        @%#**%                  #*#%  
    @%**%                @%**#%        @%***%%%**#%        @%#**%                @%#*%    
    @%**#                @%**#%          %#*****#%          %#**%                @%**%    
      #*#%                %**#%            %#*#%            %#**%                %#*#    
      %#*#                %**#%            %#*#%            %#**%                #**%    
      @%**%              @%**#%            %#*#%            %#**%              @%**%      
        %**%              %**#%                            @%#**%              %**#      
        @%**%            @%**#%                            @%#**%            @%#*#        
          %**#            %#**#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#**#%            %**%        
          @%#*#%            %#******************************##%%          @%#**%          
            %#*#%                                                        @%#*#%          
          @%#****#%                                                    @%#*#**#%          
        @%#*##%@%#*#%                                                @%#*#%  ##*#%        
        #**#%    @%**##%                                          @%%#**#%    @#**#      
        @#**#%  %#**###*#%%                                    @%%#**##**#%  @#**#%      
          %##*##*##%  @%##*##%%                            @%%##*##%  @%#*###**#%          
            @#*##%        @%##*###%%                  @%%###*##%%        @#**#%           
                              @%%####*####################%%                              
                                      @%%%%%%%%%%%%%                                      

https://x.com/vaultedfinance
https://vaulted.finance/ 
https://dapp.vaulted.finance/ 
https://t.me/VaultedChat

THE SAFE AND SIMPLE LIQUIDITY LOCKER.

*/

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract VAULTED is ERC20("Vaulted Finance", "VAULTED"), Ownable {

    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;
    address constant BURN_ADDRESS = address(0xdead);

    address public devWallet;

    uint256 constant TOTAL_SUPPLY = 1_000_000_000 ether;
    uint256 public tradingOpenedOnBlock;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    uint256 public buyTaxRate;
    uint256 public sellTaxRate;

    uint256 public tokenSwapThreshold;

    bool public limitsInEffect = true;
    bool public fetchFees = true;
    bool private swapping;
    bool public tradingActive;
    bool public swapEnabled;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isAdminAddress;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;


    constructor(){

        _mint(msg.sender, TOTAL_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), ~uint256(0));

        _excludeFromMaxTransaction(address(UNISWAP_ROUTER), true);
    
        UNISWAP_V2_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxBuyAmount = (totalSupply() * 10) / 1_000; // 1% max buy
        maxSellAmount = (totalSupply() * 5) / 1_000; // 0.5% max sell
        maxWalletAmount = (totalSupply() * 20) / 1_000; // 2% max holdings
        tokenSwapThreshold = (totalSupply() * 60) / 10_000; // 0.6% swapToEth threshold 

        devWallet = msg.sender;

        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
    }

    receive() external payable {}


    /**
     * @dev Sets/updates max buy transaction amount
     * 
     * functionality:
     * - edits max amount a holder can buy while limitsInEffect is active
     */
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "cannot set max buy amount lower than 0.1%"
        );
        maxBuyAmount = newNum;
    }

    /**
     * @dev Sets/updates max sell transaction amount
     * 
     * functionality:
     * - edits max amount a holder can sell while limitsInEffect is active
     */
    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "cannot set max sell amount lower than 0.1%"
        );
        maxSellAmount = newNum;
    }


    /**
     * @dev Sets/updates max wallet balance per holder while limitsInEffect is active
     * 
     * functionality:
     * - edits max wallet balance for individual holders
     */
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1_000),
            "cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newNum;
    }

    /**
     * @dev Sets/updates swap token threshold
     * 
     * functionality:
     * - edits threshold at which tokens are swapped to Eth
     */
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100_000,
            "swap amount cannot be lower than 0.001% total supply."
        );
    
        tokenSwapThreshold = newAmount;
    }


    /**
     * @dev Removes security restrictions
     * 
     * functionality:
     * - disables security limits and restrictions (only called by contract owner)
     */
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }


    /**
     * @dev Provides admin status
     * 
     * functionality:
     * - grants admin status for a wallet (only called by contract owner)
     */
    function setAdminAddress(address account, bool status) external onlyOwner {
        _isAdminAddress[account] = status;
        _isExcludedFromFees[account] = status;
        _isExcludedMaxTransactionAmount[account] = status;
    }

    /**
     * @dev Provides admin status to multiple addresses
     * 
     * functionality:
     * - grants admin status for all wallets passed in calldata (only called by contract owner)
     */
    function setMultipleAdminAddresses(
        address[] calldata addresses,
        bool status
    ) external onlyOwner {
        for (uint256 i; i < addresses.length; ) {
            _isAdminAddress[addresses[i]] = status;
            _isExcludedFromFees[addresses[i]] = status;
            _isExcludedMaxTransactionAmount[addresses[i]] = status;
            unchecked {
                i++;
            }
        }
    }


    /**
     * @dev Exclude address from transaction limit
     * 
     * functionality:
     * - whitelists/excludes an address from a max transfer limit (only called by contract owner)
     */
    function _excludeFromMaxTransaction(
        address account,
        bool isExcluded
    ) private {
        _isExcludedMaxTransactionAmount[account] = isExcluded;
    }


    /**
     * @dev Exclude address from fees
     * 
     * functionality:
     * - whitelists/excludes an address from tax fees
     */
    function excludeFromFees(
        address account,
        bool excluded
    ) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }


    /**
     * @dev Launch blocks protection
     * 
     * functionality:
     * - enforces buy/sell tax rate to provide saftey during first few blocks
     */
    function getFees() internal {
        
        require(
            tradingOpenedOnBlock > 0,
            "Trading not live"
        );

        uint256 currentBlock = block.number;
        uint256 lastTierOneBlock = tradingOpenedOnBlock + 6;
        uint256 lastTierTwoBlock = tradingOpenedOnBlock + 14;

        if(currentBlock <= lastTierOneBlock) {
            buyTaxRate = 15;
            sellTaxRate = 30;
        } else if(currentBlock > lastTierOneBlock && currentBlock <= lastTierTwoBlock) {
            buyTaxRate = 3;
            sellTaxRate = 20;
        } else {
            buyTaxRate = 3;
            sellTaxRate = 3;
            fetchFees = false;
        }
    }

    /**
     * @dev Opens transfers / DEX trading
     * 
     * functionality:
     * - enables free transfering/trading, can never be turned off
     */
    function openTrading() public onlyOwner {
        require(tradingOpenedOnBlock == 0, "token state is already live");
        tradingOpenedOnBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
    }

    /**
     * @dev Set new devWallet
     * 
     * functionality:
     * - edit current devWallet (only called by contract owner)
     */
    function setDevWallet(address _newDevWallet) external onlyOwner {
        require(_newDevWallet != address(0), "address cannot be 0");
        devWallet = payable(_newDevWallet);
    }

    /**
     * @dev Transfer tokens / Trading logic
     * 
     * functionality:
     * - governs transfers with trading logic and security restrictions
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedMaxTransactionAmount[from] ||
                            _isExcludedMaxTransactionAmount[to],
                        "Trading is not active."
                    );
                    require(_isAdminAddress[from], "Only admins at this stage");
                }

                //when buy
                if (
                    from == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxBuyAmount,
                        "Buy transfer amount exceeds the max buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Cannot Exceed max wallet"
                    );
                }
                //when sell
                else if (
                    to == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxSellAmount,
                        "Sell transfer amount exceeds the max sell."
                    );
                } else if (
                    !_isExcludedMaxTransactionAmount[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Cannot Exceed max wallet"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= tokenSwapThreshold;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !(from == UNISWAP_V2_PAIR) &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            
            if(fetchFees){
               getFees(); 
            }
            
            if (to == UNISWAP_V2_PAIR && sellTaxRate > 0) {
                fees = (amount * sellTaxRate) / 100;
            }
            else if (from == UNISWAP_V2_PAIR && buyTaxRate > 0) {
                fees = (amount * buyTaxRate) / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    /**
     * @dev Executes Uniswap function to liquify
     * 
     * functionality:
     * - calls Uniswaps swap function to liquify tokens for Eth to be later handled
     */
    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Execute swap & liquify procedure  
     * 
     * functionality:
     * - swaps tokens for Eth and handles payout
     */
    function swapBack() private {

        bool success;

        swapTokensForEth(tokenSwapThreshold);

        (success, ) = address(devWallet).call{value: address(this).balance}("");
    }

    /**
     * @dev Clears stuck tokens
     * 
     * functionality:
     * - calls back Tokens stuck within the contract address to clear in an emergency scenario
     */
    function rescueTokens(address _token, uint256 amount) external {
        require(
            msg.sender == owner() || msg.sender == devWallet,
            "this address is not authorized to call this function"
        );
        IERC20(_token).transfer(devWallet, amount);
    }

    /**
     * @dev Burn tokens
     * 
     * functionality:
     * - burns amount of tokens inputted as parameter
     */
    function burn(uint256 amount) external {
        super._burn(_msgSender(), amount);
    }


}