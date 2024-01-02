// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/*
 _   _ _   _____________  ___   ______ _   _____________  ___  
| | | | | | | ___ \ ___ \/ _ \  | ___ \ | | | ___ \ ___ \/ _ \ 
| |_| | | | | |_/ / |_/ / /_\ \ | |_/ / | | | |_/ / |_/ / /_\ \
|  _  | | | | ___ \ ___ \  _  | | ___ \ | | | ___ \ ___ \  _  |
| | | | |_| | |_/ / |_/ / | | | | |_/ / |_| | |_/ / |_/ / | | |
\_| |_/\___/\____/\____/\_| |_/ \____/ \___/\____/\____/\_| |_/
                                                               
Telegram: https://t.me/HubbaBubbaCoin
Website: https://www.hubbabubbatoken.xyz/
Twitter: https://twitter.com/HubbaBubbaCoin
*/

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract HubbaBubba is ERC20("Hubba Bubba", "GUM"), Ownable {

    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;

    uint256 constant TOTAL_SUPPLY = 1_000_000_000 ether;

    uint256 public launchBlock;

    uint256 public maxTxAmount;
    uint256 public maxBalanceAmount;
    uint256 public swapTokensAtAmount;

    address public treasuryWallet;

    bool public limitsActive = true;
    bool public tradingActive;
    bool public swapEnabled;
    bool private swapping;

    uint256 public totalBuyFees;
    uint256 public totalSellFees;

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

        maxTxAmount = (totalSupply() * 6) / 1_000; // 0.6%
        maxBalanceAmount = (totalSupply() * 15) / 1_000; // 1.5%
        swapTokensAtAmount = (totalSupply() * 50) / 10_000; // 0.5%

        treasuryWallet = msg.sender;

        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
    }

    receive() external payable {}


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
        totalBuyFees = _newBuyFee;
        totalSellFees = _newSellFee;
    }

    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        require(_newTreasuryWallet != address(0), "address cannot be 0");
        treasuryWallet = payable(_newTreasuryWallet);
    }

    function setRestrictionSettings(
        uint256 _newMaxTx,
        uint256 _newMaxBalance,
        uint256 _newThreshold
    ) external onlyOwner{
        maxTxAmount = (totalSupply() * _newMaxTx) / 1_000;
        maxBalanceAmount = (totalSupply() * _newMaxBalance) / 1_000;
        swapTokensAtAmount = (totalSupply() * _newThreshold) / 10_000;
    }

    function openTrading() public onlyOwner {
        require(launchBlock == 0, "trading status is already live");
        launchBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
    }

    function removeLimits() external onlyOwner {
        limitsActive = false;
    }


    // Trading Logic
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "transfer from the zero address !");
        require(to != address(0), "transfer to the zero address !");
        require(amount > 0, "Amount must be greater than 0 !");

        if (limitsActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedMaxTransactionAmount[from] || _isExcludedMaxTransactionAmount[to],
                        "Trading is not active !"
                    );
                    require(from == owner(), "Trading is active !");
                }
                //when buy
                if (
                    from == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "Buy amount limit exceeded !"
                    );
                    require(
                        amount + balanceOf(to) <= maxBalanceAmount,
                        "Max wallet amount exceeded !"
                    );
                }
                //when sell
                else if (
                    to == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "Sale amount limit exceeded !"
                    );
                } else if (
                    !_isExcludedMaxTransactionAmount[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxBalanceAmount,
                        "Max wallet amount exceeded !"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool swapCriteriaMet = contractTokenBalance >= swapTokensAtAmount;

        if (
            swapCriteriaMet &&
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
            // on sell
            if (to == UNISWAP_V2_PAIR && totalSellFees > 0) {
                fees = (amount * totalSellFees) / 100;
            }
            // on buy
            else if (from == UNISWAP_V2_PAIR && totalBuyFees > 0) {
                fees = (amount * totalBuyFees) / 100;
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

        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function swapBack() private {

        bool success;

        swapTokensForEth(swapTokensAtAmount);

        uint256 ethContractBalance = address(this).balance;

        (success, ) = address(treasuryWallet).call{value: ethContractBalance}("");
    }


    function rescueTokens(IERC20 _token, uint256 _amount) external {

        require(msg.sender  == owner() || msg.sender == treasuryWallet);

        require(
            _token.balanceOf(address(this)) >= _amount,
            "ERROR: Insufficient balance to complete txn !"
        );

        _token.transfer(msg.sender, _amount);
    }

    function rescueEth(uint256 _amount) external onlyOwner {

        require(
            address(this).balance >= _amount,
            "insufficient balance to complete txn !"
        );

        payable(msg.sender).transfer(_amount);
    }


}