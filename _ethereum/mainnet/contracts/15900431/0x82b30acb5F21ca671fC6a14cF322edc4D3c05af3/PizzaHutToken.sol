// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

pragma solidity ^0.8.0;

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address _uniswapV2PairAddress);
}

pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PizzaHutToken is ERC20, Ownable {
    using SafeMath for uint256;     

    bool private swapBackOnOff;     
    bool private _swapping;     
    bool private _earlyBuyEnabled = true;

    uint256 private _swapTokensThreshold;       
    uint256 private maxBuyWallet;       
    
    uint256 public fee;     
    uint256 public penalityFee;     

    uint256 private _tokensForFee;      

    uint256 private _addLiqBlock;      

    address payable private _feeAddress;        
    address private immutable _uniswapV2PairAddress;        
    address private constant ZERO = 0x0000000000000000000000000000000000000000;     
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;     

    IUniswapV2Router private immutable _uniswapV2Router;     

    mapping (address => bool) private _isExcludedFromFees;      
    mapping (address => bool) private _earlyBuyers;      

    mapping (address => bool) private _automatedMarketMakerPairs;       

    constructor(address address1, address address2, address address3, address address4, address[] memory accounts) ERC20("Pizza Hut Token", "PHT") payable {
        uint256 tSupply = 1e6 * (10**18);       

        maxBuyWallet = tSupply * 15 / 1000;      // 1.5%
        _swapTokensThreshold = tSupply * 5 / 10000;      // 0.05%

        fee = 3;         // 3%
        penalityFee = 17;         // 17%

        _feeAddress = payable(address4);     

        _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);     
        _approve(address(this), address(_uniswapV2Router), type(uint).max);      
        _uniswapV2PairAddress = IUniswapFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());       
        _approve(address(this), address(_uniswapV2PairAddress), type(uint).max);        
        IERC20(_uniswapV2PairAddress).approve(address(_uniswapV2Router), type(uint).max);        

        _automatedMarketMakerPairs[address(_uniswapV2PairAddress)] = true;      

        _isExcludedFromFees[owner()] = true;        
        _isExcludedFromFees[address(this)] = true;      
        _isExcludedFromFees[DEAD] = true;       
        _isExcludedFromFees[address(_uniswapV2Router)] = true;       
        _isExcludedFromFees[_feeAddress] = true;     

        _earlyBuyers[owner()] = true;        
        _earlyBuyers[address(this)] = true;      
        _earlyBuyers[DEAD] = true;       
        _earlyBuyers[address(_uniswapV2Router)] = true;       
        _earlyBuyers[_feeAddress] = true;       

        _mint(owner(), tSupply);        

        super._transfer(owner(), address(this), (tSupply * 90 / 100));      
        super._transfer(owner(), address1, (tSupply * 15 / 1000));      
        super._transfer(owner(), address2, (tSupply * 15 / 1000));      
        super._transfer(owner(), address3, (tSupply * 15 / 1000));      

        for (uint i = 0; i < accounts.length; i++) {    
            _earlyBuyers[accounts[i]] = true;   
        }   
    }

    function addLiq() public onlyOwner {
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );      
        swapBackOnOff = true;       
        _addLiqBlock = block.timestamp;
    }

    function setSwapBackOnOff(bool isEnabled) public onlyOwner {
        swapBackOnOff = isEnabled;      
    }

    function openTrading() public onlyOwner {
        _earlyBuyEnabled = false;
    }
    
    function setSwapTokensAtAmnt(uint256 newAmnt) public onlyOwner {
  	    require(newAmnt >= totalSupply() * 1 / 100000, "Swap tokens at amount cannot be lower than 0.001% total supply.");      
  	    require(newAmnt <= totalSupply() * 1 / 1000, "Swap tokens at amount cannot be higher than 0.1% total supply.");       
  	    _swapTokensThreshold = newAmnt;     
  	}
    
    function setMaxBuyWallet(uint256 newAmnt) public onlyOwner {
  	    require(newAmnt >= totalSupply() * 1 / 1000, "Max buy wallet cannot be lower than 0.1% total supply.");     
  	    maxBuyWallet = newAmnt;     
  	}

    function excludeFromFee(address wallet, bool isExcluded) public onlyOwner {
        _isExcludedFromFees[wallet] = isExcluded;       
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;       
        (success,) = address(_msgSender()).call{value: address(this).balance}("");      
    }

    function withdrawStuckTokens(address tokenAddress) public onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "No tokens");        
        uint amount = IERC20(tokenAddress).balanceOf(address(this));        
        IERC20(tokenAddress).transfer(_msgSender(), amount);        
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != ZERO, "ERC20: Transfer from the zero address");     
        require(to != ZERO, "ERC20: Transfer to the zero address");     
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");        

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            super._transfer(from, to, amount);      
            return;     
        }

        if(_earlyBuyEnabled) {
            require(_earlyBuyers[from] || _earlyBuyers[to], "Trading is not allowed yet.");
        }

        uint256 fees = 0;       
        if (_automatedMarketMakerPairs[to] && fee > 0) { // sell
            if (block.timestamp < _addLiqBlock + 12 hours) {
                fees = amount * penalityFee / 100;      
                _tokensForFee += fees * penalityFee / penalityFee;      
            } else {
                fees = amount * fee / 100;      
                _tokensForFee += fees * fee / fee;      
            }
        } else if(_automatedMarketMakerPairs[from] && fee > 0) { // buy
            require((balanceOf(to) + amount) <= maxBuyWallet);      
        	fees = amount * fee / 100;      
            _tokensForFee += fees * fee / fee;      
        }

        uint256 contractBalance = balanceOf(address(this));     
        bool shouldSwap = contractBalance >= _swapTokensThreshold;     

        if(shouldSwap && swapBackOnOff && !_swapping && _automatedMarketMakerPairs[to]) {
            _swapping = true;       
            _swapBackETH(contractBalance);      
            _swapping = false;      
        }

        if(fees > 0)
            super._transfer(from, address(this), fees);     
        	
        amount -= fees;     

        super._transfer(from, to, amount);      
    }

    function _swapBackETH(uint256 contractBalance) internal {
        bool success;       
        
        if(_tokensForFee == 0)
            return;     

        if(contractBalance > _swapTokensThreshold * 5)
            contractBalance = _swapTokensThreshold * 5;     
    
        _swapTokensForETH(contractBalance);     

        _tokensForFee = 0;      

        uint256 ethBalance = address(this).balance;     

        if(ethBalance > 0)
            (success, ) = _feeAddress.call{value: ethBalance}("");      
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
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

    receive() external payable {}
    fallback() external payable {}
}