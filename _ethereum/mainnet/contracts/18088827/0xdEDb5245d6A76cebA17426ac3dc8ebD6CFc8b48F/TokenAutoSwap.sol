// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Pair {
    function sync() external;
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Kuromi is ERC20 {
    using SafeMath for uint256;

    address _gov;

    IUniswapV2Router02 private _uniswapV2Router;
    address private uniswapV2Pair;
    address private token0;

    mapping(address => bool) _isFeeExempt;
    mapping(address => uint) _buyBlock;

    bool inSwap;
    bool swapEnabled;
    bool pausedTransfer;

    constructor() ERC20("Kuromi", "KOMI") {
        uint256 _tTotal = 100_000_000 * 10 ** decimals();
        _mint(address(this), _tTotal);
        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // UNI-V2 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D PCS-V2 0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        _gov = _msgSender();
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[_msgSender()] = true;
    }

    modifier onlyOwner() {
        require(_msgSender() == _gov, "Ownable: caller is not the owner");
        _;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool excludedAccount = _isFeeExempt[sender] || _isFeeExempt[recipient];
        bool isBot = _buyBlock[sender].add(5) >= block.number;
        uint finalAmt = amount;
        uint _tax;
        if(pausedTransfer) require(excludedAccount, "Transfer Paused");

        if(!excludedAccount && sender == uniswapV2Pair) {
            _buyBlock[recipient] = block.number;
            _tax = amount.mul(2).div(100);
            finalAmt = amount.sub(_tax);
        }
        if(!excludedAccount && recipient == uniswapV2Pair) {
            if(isBot) {
                _tax = amount.mul(20).div(100);
                finalAmt = amount.sub(_tax);
            } else {
                _tax = amount.mul(5).div(100);
                finalAmt = amount.sub(_tax);
            }
            // if(!inSwap) swapTokensForEth(amount);
        }
        if(_tax > 0) {
            super._transfer(sender, address(this), _tax);
        }
        super._transfer(sender, recipient, finalAmt);
    }

    function openTrading() external onlyOwner {
        _approve(address(this), address(_uniswapV2Router), totalSupply());
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        uint liqAmt = balanceOf(address(this)).mul(90).div(100);
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            liqAmt,
            0,
            0,
            _gov,
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(
            address(_uniswapV2Router),
            type(uint).max
        );
        // swapEnabled = true;
    }

    function swapTokensForEth(uint256 tokenAmount) private swapping {
        if(!swapEnabled) return;
        if(tokenAmount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _gov,
            block.timestamp
        );
    }

    function sendETHToFee() public onlyOwner {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            payable(_msgSender()).transfer(address(this).balance);
        }
    }

    function manualSwap() external onlyOwner {
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0 && uniswapV2Pair != address(0)) {
            swapTokensForEth(tokenBalance);
        }
        sendETHToFee();
    }

    function setSwapEnabled(bool _toggle) external onlyOwner {
        swapEnabled = _toggle;
    }

    function setPausedTransfer(bool _toggle) external onlyOwner {
        pausedTransfer = _toggle;
    }

    function withdrawStuckTokens(address ERC20_token) external onlyOwner {
        require(ERC20_token != address(this), "Owner cannot claim native tokens");

        uint256 tokenBalance = IERC20(ERC20_token).balanceOf(address(this));
        require(tokenBalance > 0, "No tokens available to withdraw");

        bool success = IERC20(ERC20_token).transfer(msg.sender, tokenBalance);
        require(success, "transferring tokens failed!");
    }

    receive() external payable {}
}