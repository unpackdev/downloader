// SPDX-License-Identifier: UNLICENSED

/*                                                                                    
TG: https://t.me/gyatt45
X: https://x.com/gyatt45
Website: https://gyattcoin.fun
*/

pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract Gyatt is ERC20 ("Gyatt Coin", "Gyatt"), Ownable {

    // Uniswap variables
    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;

    uint256 constant TOTAL_SUPPLY = 10_000_000_000_00 ether;
    uint256 public tradingOpenedOnBlock;

    bool private swapping;

    address public gyattWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public fetchFees = true;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;
    uint256 public tokenSwapThreshold;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    uint256 public taxedTokens;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public whitelisted;

    event EnabledTrading(bool tradingActive);
    event RemovedLimits();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedMaxBuyAmount(uint256 newAmount);
    event UpdatedMaxSellAmount(uint256 newAmount);
    event UpdatedMaxWalletAmount(uint256 newAmount);
    event UpdatedgyattWallet(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(){

        _mint(msg.sender, TOTAL_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), ~uint256(0));

        _excludeFromMaxTransaction(address(UNISWAP_ROUTER), true);

    
        UNISWAP_V2_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxBuyAmount = (totalSupply() * 15) / 1_000; // 1.5%
        maxSellAmount = (totalSupply() * 6) / 1_000; // 0.6%
        maxWalletAmount = (totalSupply() * 20) / 1_000; // 2%
        tokenSwapThreshold = (totalSupply() * 65) / 10_000; // 0.65%

        gyattWallet = msg.sender;

        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
    }

    receive() external payable {}


    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "ERROR: max buy amount is lower than 0.1%"
        );
        maxBuyAmount = newNum;
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "ERROR: max sell amount is lower than 0.1%"
        );
        maxSellAmount = newNum;
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1_000),
            "ERROR: max wallet amount is lower than 0.3%"
        );
        maxWalletAmount = newNum;
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100_000,
            "ERROR: Swap amount cannot be lower than 0.001% total supply."
        );
    
        tokenSwapThreshold = newAmount;
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function _excludeFromMaxTransaction(
        address updAds,
        bool isExcluded
    ) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setNewFees(uint256 newBuyFees, uint256 newSellFees) external onlyOwner {
    buyTotalFees = newBuyFees;
    sellTotalFees = newSellFees;
    }

    function openTrading() public onlyOwner {
        require(tradingOpenedOnBlock == 0, "Token state is already live !");
        tradingOpenedOnBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
        emit EnabledTrading(tradingActive);
    }


    function setgyattWallet(address _gyattWallet) external onlyOwner {
        require(_gyattWallet != address(0), "ERROR: _gyattWallet address cannot be 0");
        gyattWallet = payable(_gyattWallet);
        emit UpdatedgyattWallet(_gyattWallet);
    }

    function getFees() internal {
        require(
            tradingOpenedOnBlock > 0, "Trading not live"
        );
        uint256 currentBlock = block.number;
        uint256 lastTierOneBlock = tradingOpenedOnBlock + 8;
        if(currentBlock <= lastTierOneBlock) {
            buyTotalFees = 20;
            sellTotalFees = 30;
        } else {
            buyTotalFees = 12;
            sellTotalFees = 20;
            fetchFees = false;
        } 
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "amt should be > than 0");

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
                    require(from == owner(), "Trading is enabled");
                }

                //when buy
                if (
                    from == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxBuyAmount,
                        "ERROR: Buy transfer amount exceeds the max buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "ERROR: Cannot go past max wallet"
                    );
                }
                //when sell
                else if (
                    to == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxSellAmount,
                        "ERROR: Sell transfer amount exceeds the max sell."
                    );
                } else if (
                    !_isExcludedMaxTransactionAmount[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "ERROR: Cannot Exceed max wallet"
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

            // Sell
            if (to == UNISWAP_V2_PAIR && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                taxedTokens += fees;
            }
            // Buy
            else if (from == UNISWAP_V2_PAIR && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                taxedTokens += fees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

     function initialAirdrop(
        address[] calldata recipients,
        uint256[] calldata values
    ) external onlyOwner {
        require(recipients.length == values.length);
        for (uint256 i; i < recipients.length; ) {
            _transfer(msg.sender, recipients[i], values[i]);

            unchecked {
                i++;
            }
        }
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {

      
        uint256 contractBalance = balanceOf(address(this));

        uint256 totalTokensToSwap =  taxedTokens;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > tokenSwapThreshold) {
            contractBalance = tokenSwapThreshold;
        }

        bool success;
    
        swapTokensForEth(contractBalance);

        (success, ) = address(gyattWallet).call{value: address(this).balance}("");
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
    require(weiAmount > 0, "Amount must be greater than 0");
    payable(owner()).transfer(weiAmount);
}

function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
    require(tokenAdd != address(0), "Invalid token address");
    require(amount > 0, "Amount must be greater than 0");

    IERC20(tokenAdd).transfer(owner(), amount);
}
    


}