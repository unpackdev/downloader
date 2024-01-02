/* For the 16 years, nobody could stop TURBO Trotter's amazing run. (if you don´t know, check YouTube - Retarded running horse)) Now, he's not just running in a straight line, 
he's sprinting towards up to a BILION dolars in Market Cap! When you're as unstoppable as TURBO, the very essence of victory courses through your veins. 
Keep trotting, keep holding, and watch the market cap climb! Trot on, TURBO! (LG)

Telegram: https://t.me/+S1aq_i8m2FpkMDk8
Twitter: https://twitter.com/RTRDHorse_TURBO
*/


// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;



import "./ERC20.sol"; 
import "./Ownable.sol"; 
import "./IUniswapV2Router02.sol"; 
import "./IUniswapV2Factory.sol"; 
import "./SafeMath.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

contract RetardedRunningHorse_TURBO is ERC20, Ownable { 
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private _uniswapV2Pair;
    
    uint256 public maxHoldings;
    uint256 public feeTokenThreshold;
    bool public feesDisabled;
        
    bool private _inSwap;
    uint256 private _swapFee = 3;
    uint256 private _tokensForFee;
    address private _feeAddr;

    mapping (address => bool) private _excludedLimits;

    // much like onlyOwner() but used for the feeAddr so that once renounced fees and maxholdings can still be disabled
    modifier onlyFeeAddr() {
        require(_feeAddr == _msgSender(), "Caller is not the _feeAddr address.");
        _;
    }

constructor(address feeAddr) ERC20("Retarded Running Horse_TURBO", "RTRDH") payable Ownable(feeAddr) {
        uint256 totalSupply = 69420000000000000000000000000000;
        uint256 totalLiquidity = totalSupply * 90 / 100; // 90%

        maxHoldings = totalSupply * 3 / 100; // 3%
        feeTokenThreshold = totalSupply * 1 / 100; // 1%

        _feeAddr = feeAddr;

        // exclution from fees and limits
        _excludedLimits[owner()] = true;
        _excludedLimits[address(this)] = true;
        _excludedLimits[address(0xdead)] = true;

        // mint lp tokens to the contract and remaning to deployer
        _mint(address(this), totalLiquidity);
        _mint(msg.sender, totalSupply.sub(totalLiquidity));
    }

    function createV2LP() external onlyOwner {
        // create pair
        _uniswapV2Pair = IUniswapV2Factory(
            _uniswapV2Router.factory()).createPair(address(this), 
            _uniswapV2Router.WETH()
        );

        // add lp to pair
        _addLiquidity(
            balanceOf(address(this)), 
            address(this).balance
        );
    }

    // updates the amount of tokens that needs to be reached before fee is swapped
    function updateFeeTokenThreshold(uint256 newThreshold) external onlyFeeAddr {        
  	    require(newThreshold >= totalSupply() * 1 / 100000, "Swap threshold cannot be lower than 0.001% total supply.");
  	    require(newThreshold <= totalSupply() * 5 / 1000, "Swap threshold cannot be higher than 0.5% total supply.");
  	    feeTokenThreshold = newThreshold;
  	}

   function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override  {
        require(from != address(0), "Transfer from the zero address not allowed.");
        require(to != address(0), "Transfer to the zero address not allowed.");

        // no reason to waste gas
        bool isBuy = from == _uniswapV2Pair;
        bool exluded = _excludedLimits[from] || _excludedLimits[to];

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // if pair has not yet been created
        if (_uniswapV2Pair == address(0)) {
            require(exluded, "Please wait for the LP pair to be created.");
            return;
        }

        // max holding check
        if (maxHoldings > 0 && isBuy && to != owner() && to != address(this))
            require(super.balanceOf(to) + amount <= maxHoldings, "Balance exceeds max holdings amount, consider using a second wallet.");
        
        // take fees if they haven't been perm disabled
        if (!feesDisabled) {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= feeTokenThreshold;
            if (
                canSwap &&
                !_inSwap &&
                !isBuy &&
                !_excludedLimits[from] &&
                !_excludedLimits[to]
            ) {
                _inSwap = true;
                swapFee();
                _inSwap = false;
            }


            // check if we should be taking the fee
            bool takeFee = !_inSwap;
            if (exluded || !isBuy && to != _uniswapV2Pair) takeFee = false;
            
            if (takeFee) {
                uint256 fees = amount.mul(_swapFee).div(100);
                _tokensForFee = amount.mul(_swapFee).div(100);
                
                if (fees > 0)
                    super._transfer(from, address(this), fees);
                
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    // swaps tokens to eth
    function _swapTokensForEth(uint256 tokenAmount) internal {
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

    // does what it says
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _feeAddr,
            block.timestamp
        );
    }

    // swaps fee from tokens to eth
    function swapFee() internal {
        uint256 contractBal = balanceOf(address(this));
        uint256 tokensForLiq = _tokensForFee.div(3); // 2% fee is lp
        uint256 tokensForFee = _tokensForFee.sub(tokensForLiq); // remaning 3% is marketing/cex/development
        
        if (contractBal == 0 || _tokensForFee == 0) return;
        if (contractBal > feeTokenThreshold) contractBal = feeTokenThreshold;
        
        // Halve the amount of liquidity tokens
        uint256 liqTokens = contractBal * tokensForLiq / _tokensForFee / 3;
        uint256 amountToSwapForETH = contractBal.sub(liqTokens);
        
        uint256 initETHBal = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);
        
        uint256 ethBalance = address(this).balance.sub(initETHBal);
        uint256 ethFee = ethBalance.mul(tokensForFee).div(_tokensForFee);
        uint256 ethLiq = ethBalance - ethFee;
        
        _tokensForFee = 0;

        payable(_feeAddr).transfer(ethFee);
                
        if (liqTokens > 0 && ethLiq > 0) 
            _addLiquidity(liqTokens, ethLiq);
    }

    // perm disable fees
    function disableFees() external onlyFeeAddr {
        feesDisabled = true;
    }

    // perm disable max holdings
    function disableHoldingLimit() external onlyFeeAddr {
        maxHoldings = 0;
    }

    // transfers any stuck eth from contract to feeAddr
    function transferStuckETH() external {
        payable(_feeAddr).transfer(address(this).balance);
    }

    receive() external payable {}
}
