// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/*
******************************************************
*    ███████╗██████╗ ██╗     ██╗████████╗██╗  ██╗    *
*    ██╔════╝██╔══██╗██║     ██║╚══██╔══╝╚██╗██╔╝    *
*    ███████╗██████╔╝██║     ██║   ██║    ╚███╔╝     *
*    ╚════██║██╔═══╝ ██║     ██║   ██║    ██╔██╗     *
*    ███████║██║     ███████╗██║   ██║   ██╔╝ ██╗    *
*    ╚══════╝╚═╝     ╚══════╝╚═╝   ╚═╝   ╚═╝  ╚═╝    *
******************************************************

Docs: https://splitx.gitbook.io/project-overview/
Telegram: https://t.me/SplitX_Portal
Website: https://www.splitx.finance/
App: https://app.splitx.finance/
Twitter: https://twitter.com/splitXFinance
*/

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract SplitX is ERC20("Splitx", "SPLT"), Ownable {

    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;

    uint256 constant TOTAL_SUPPLY = 1_000_000_000 ether;
    uint256 public tradingOpenedOnBlock;

    bool private swapping;

    address public treasuryWallet;

    bool public limitsInEffect = true;
    bool public tradingActive;
    bool public swapEnabled;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;
    uint256 public tokenSwapThreshold;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    uint256 public taxedTokens;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    constructor(){

        _mint(msg.sender, TOTAL_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), ~uint256(0));

        _excludeFromMaxTransaction(address(UNISWAP_ROUTER), true);

    
        UNISWAP_V2_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxBuyAmount = (totalSupply() * 15) / 1_000;
        maxSellAmount = (totalSupply() * 15) / 1_000;
        maxWalletAmount = (totalSupply() * 15) / 1_000;
        tokenSwapThreshold = (totalSupply() * 50) / 10_000; // 0.5% swapToEth threshold 

        treasuryWallet = msg.sender;

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
            "Cannot set max buy amount lower than 0.1%"
        );
        maxBuyAmount = newNum;
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "Cannot set max sell amount lower than 0.1%"
        );
        maxSellAmount = newNum;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1_000),
            "Cannot set max wallet amount lower than 0.3%"
        );
        maxWalletAmount = newNum;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100_000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
    
        tokenSwapThreshold = newAmount;
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }


    function _excludeFromMaxTransaction(
        address updAds,
        bool isExcluded
    ) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }


    function updateTaxRates(
        uint256 _newBuyFee,
        uint256 _newSellFee
    ) external onlyOwner {
        buyTotalFees = _newBuyFee;
        sellTotalFees = _newSellFee;
    }

    function openTrading() public onlyOwner {
        require(tradingOpenedOnBlock == 0, "Token state is already live !");
        tradingOpenedOnBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
    }


    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(_treasuryWallet != address(0), "_treasuryWallet address cannot be 0");
        treasuryWallet = payable(_treasuryWallet);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
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
                    require(from == owner(), "Trading is enabled");
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


    function swapTokensForEth(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

        // make the swap
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
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

        (success, ) = address(treasuryWallet).call{value: address(this).balance}("");
    }


    function withdrawStuckToken(address _token) external onlyOwner{
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }


    function withdrawStuckEth() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "failed to withdraw funds");
    }
    
}