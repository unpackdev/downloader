// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/*

⠀⠀⠀⠀⠀⣀⣤⣤⣤⠤⢤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⡤⣤⣤⡀⠀⠀⠀⠀
⠀⠀⢀⡴⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⠛⠁⠀⣀⠀⠈⠙⢷⡄⠀⠀
⠀⣴⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡾⠁⠀⣴⠟⠉⠛⢷⡀⠀⠹⣆⠀
⣸⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠁⠀⣾⠃⠀⠀⠀⠀⢻⡄⠀⢻⡄
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢸⡇⠀⠀⠀⠀⠀⠈⣧⠀⠈⣧
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢸⡇⠀⠀⠀⠀⠀⠀⣿⠀⠀⣿
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⢸⡇⠀⠀⠀⠀⠀⠀⣿⠀⠀⣿
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠘⣧⠀⠀⠀⠀⠀⢰⡇⠀⢸⡇
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣆⠀⠙⣧⡀⠀⠀⣠⠟⠀⢀⡿⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠹⣦⡀⠈⠛⠶⠛⠉⠀⣠⡞⠁⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣇⣀⣈⣿⣦⣤⣄⣤⣴⠞⠋⠀⠀⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡏⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠉⠉⠉⠉⠛⠛⠛⠛⠉⠛⠛⠛⠛⠛⠛⠛⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

Website: https://toiletpapertoken.wtf
Telegram: https://t.me/ToiletPaper_WTF
Twitter: https://twitter.com/ToiletPaper_WTF

*/

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ToiletPaperToken is ERC20, Ownable {
    using Address for address payable;
    using SafeMath for uint;

    address public constant deadAddress = address(0xdead);

    struct TaxAllocation {
        uint marketing;
        uint liquidity;
        uint burn;
    }

    IUniswapV2Router02 private router;
    address private immutable WETH;
    address private marketingWallet;
    address private liquidityWallet;

    uint8 private _decimals = 18;
    uint private _initialSupply = 2_020_002_020 * 10**_decimals;
    uint private _maxSwapThreshold = _initialSupply / 200; // 0.5% of the supply
    uint private constant TAX_DECLINE_PER_BLOCK = 10;
    uint private constant TAX_DENOMINATOR = 1000;

    mapping (address => bool) private _isExcluded;

    address public pair;
    uint public taxCollected;
    uint public initialTaxPercentage = 350; // 35.0%
    uint public finalTaxPercentage = 20; // 2.0%
    uint public delayBlocks = 10;
    uint public startBlock;

    TaxAllocation public taxAllocation = TaxAllocation(400, 300, 300);

    constructor () ERC20("Toilet Paper Token", "COVID") {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();

        _isExcluded[_msgSender()] = true;
        _isExcluded[address(this)] = true;

        _mint(_msgSender(), _initialSupply);
    }

    /** ERC20 OVERRIDES */

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address from, 
        address to, 
        uint amount
    ) internal override {
        require (amount > 0, "Amount must be gt 0");

        if (from != pair &&
            to != pair
        ) {
            super._transfer(from, to, amount);
            return;
        }

        if (from == pair) {
            // buy
            require (startBlock > 0, "Trading is not open yet");

            uint tax = amount.mul(taxPercentage()).div(TAX_DENOMINATOR);
            taxCollected = taxCollected.add(tax);

            super._transfer(from, address(this), tax);
            super._transfer(from, to, amount.sub(tax));
            return;
        }

        if (to == pair) {
            // sell
            if (_isExcluded[from]) {
                super._transfer(from, to, amount);
                return;
            }

            uint tax = amount.mul(taxPercentage()).div(TAX_DENOMINATOR);
            taxCollected = taxCollected.add(tax);

            super._transfer(from, address(this), tax);
            swapFromTokens(taxCollected);
            super._transfer(from, to, amount.sub(tax));
            return;
        }
    }

    /** VIEW FUNCTIONS */

    function taxPercentage() public view returns (uint) {
        if (block.number <= startBlock.add(delayBlocks)) {
            return initialTaxPercentage;
        } else {
            uint blockDifference = block.number.sub(startBlock.add(delayBlocks));
            uint taxDecline = blockDifference.mul(TAX_DECLINE_PER_BLOCK);
            if (taxDecline >= initialTaxPercentage.sub(finalTaxPercentage)) {
                return finalTaxPercentage;
            } else {
                return initialTaxPercentage.sub(taxDecline);
            }
        }
    }

    function getCirculatingSupply() public view returns (uint) {
        return totalSupply() - balanceOf(address(0xdead));
    }

    /** INTERNAL FUNCTIONS */

    function swapFromTokens(uint amount) internal {
        uint balance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        if (amount > _maxSwapThreshold) amount = _maxSwapThreshold;
        if (amount > balance) amount = balance;
        if (amount > 0) {
            taxCollected = taxCollected.sub(amount);
            uint burnAmount = amount.mul(taxAllocation.burn).div(TAX_DENOMINATOR);
            super._transfer(address(this), deadAddress, burnAmount);

            uint initialEthBalance = address(this).balance;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount.sub(burnAmount), 
                0, 
                path, 
                address(this), 
                block.timestamp + 30 seconds
            );

            uint deltaBalance = address(this).balance.sub(initialEthBalance);

            uint marketingAmount = deltaBalance.mul(taxAllocation.marketing).div(taxAllocation.marketing.add(taxAllocation.liquidity));
            payable(marketingWallet).sendValue(marketingAmount);

            uint liquidityAmount = deltaBalance.sub(marketingAmount);
            payable(liquidityWallet).sendValue(liquidityAmount);
        }
    }

    /** RESTRICTED FUNCTIONS */

    function initPair() external onlyOwner {
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            WETH
        );

        IERC20(WETH).approve(address(router), type(uint).max);
        _approve(address(this), address(router), type(uint).max);
        _approve(address(this), address(this), type(uint).max);
    }

    function initLiquidity() external payable onlyOwner {
        uint liquidityTokens = balanceOf(_msgSender()) * 90 / 100;
        _approve(_msgSender(), address(this), liquidityTokens);
        _transfer(_msgSender(), address(this), liquidityTokens);

        router.addLiquidityETH{value: msg.value}(
            address(this),
            liquidityTokens,
            0,
            0,
            _msgSender(),
            block.timestamp + 30 seconds
        );
    }

    function initTrading() external onlyOwner {
        require(startBlock == 0, "Trading is already open");
        startBlock = block.number;
    }

    function setWallets(address _marketingWallet, address _liquidityWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
    }

    function rescueETH() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }
 
    function rescueTokens(address _token) external onlyOwner {
        require(_token != address(this), "Can not rescue own token");
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
 
    receive() external payable {}
}