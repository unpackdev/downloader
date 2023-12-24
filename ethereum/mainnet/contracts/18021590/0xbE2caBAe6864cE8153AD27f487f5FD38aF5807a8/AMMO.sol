// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
   function factory() external pure returns (address);
   function WETH() external pure returns (address);
   function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
   function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract AMMO is ERC20, Ownable {

	address public taxWallet;
	address private pair;
	
	uint256 private initialBuyFee;
	uint256 private initialSellFee;
	uint256 private finalBuyFee;
	uint256 private finalSellFee;
	uint256 private buyCount;
	uint256 private reduceBuyFeeAt;
    uint256 private reduceSellFeeAt;
    uint256 private preventSwapBefore;
	
	uint256 public swapThreshold;
	uint256 public maxTokenPerWallet;
	uint256 public maxTokenPerTxn;
	
	bool private swapping;
	bool private tradingEnabled;
    bool private swapEnabled;
	bool public transferDelayEnabled;
	
	IDEXRouter public router;
    
	mapping(address => bool) private isExcludedFromFees;
	mapping(address => bool) public isBot;
	mapping(address => uint256) private holderLastTransferTimestamp;
	
    constructor(address owner) ERC20("AMMO", "AMMO") {
	   taxWallet = address(owner);
	   
	   initialBuyFee = 20;
	   initialSellFee = 20;
	   finalBuyFee = 1;
	   finalSellFee = 1;
	   reduceBuyFeeAt = 20;
       reduceSellFeeAt = 40;
       preventSwapBefore = 40;
	   
	   transferDelayEnabled = true;
	   
	   isExcludedFromFees[address(this)] = true;
	   isExcludedFromFees[address(owner)] = true;
	   isExcludedFromFees[address(taxWallet)] = true;
	   
	   swapThreshold = 840000000000 * (10**18);
	   maxTokenPerWallet = 5600000000000 * (10**18);
	   maxTokenPerTxn = 2800000000000 * (10**18);
	   
       _mint(address(owner), 280000000000000 * (10**18));
	   _transferOwnership(address(owner));
    }
	
	receive() external payable {}
	
	function startTrading() external onlyOwner {
	   require(!tradingEnabled, "Trading already started");
	   
	   router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
	   
	   _approve(address(this), address(router), totalSupply());
       router.addLiquidityETH{value: address(this).balance}(
		 address(this),
		 balanceOf(address(this)),
		 0, 
		 0,
		 owner(),
		 block.timestamp
       );
	   
       tradingEnabled = true;
       swapEnabled = true;
    }
	
	function removeLimits() external onlyOwner {
	   require(transferDelayEnabled, "Limit already removed");
	   
	   maxTokenPerWallet = totalSupply();
	   maxTokenPerTxn = totalSupply();	
       transferDelayEnabled = false;
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20) {      
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
		
		uint256 fees;
		uint256 taxApplicable;
		if(sender != owner() && recipient != owner())
		{
		    require(!isBot[sender] && !isBot[recipient], "transfer:: Bot transaction detected");
			
			taxApplicable = buyCount > reduceBuyFeeAt ? finalBuyFee : initialBuyFee;
			fees = ((amount * taxApplicable) / 100);
			
			if(transferDelayEnabled && sender != address(router) && recipient != address(pair)) 
			{
			   require(holderLastTransferTimestamp[tx.origin] < block.number, "transfer:: Transfer Delay enabled. Only one purchase per block allowed.");
               holderLastTransferTimestamp[tx.origin] = block.number;
            }
			if(sender == address(pair) && recipient != address(router) && !isExcludedFromFees[recipient]) 
			{
			    require(amount <= maxTokenPerTxn, "Buy transfer amount exceeds the maxTokenPerTxn.");
			    require(amount + balanceOf(recipient) <= maxTokenPerWallet, "maxTokenPerWallet exceeded");
			    buyCount++;
			}
			if(recipient == address(pair) && sender != address(this))
			{
                taxApplicable = buyCount > reduceSellFeeAt ? finalSellFee : initialSellFee;
			    fees = ((amount * taxApplicable) / 100);
            }
		}
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapThreshold;
		
		if(!swapping && canSwap && recipient == address(pair) && buyCount > preventSwapBefore) 
		{
			swapping = true;
			
			swapTokensForETH(min(amount, swapThreshold));
			uint256 ethBalance = address(this).balance;
			payable(taxWallet).transfer(ethBalance);
			
			swapping = false; 
		}
		if(fees > 0) 
		{
		   super._transfer(sender, address(this), fees);
		}
		super._transfer(sender, recipient, amount - fees);
    }
	
	function min(uint256 a, uint256 b) private pure returns (uint256){
        return (a > b) ? b : a;
    }
	
	function swapTokensForETH(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
		
        _approve(address(this), address(router), amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
	function manualSwap() external {
        require(address(msg.sender)== taxWallet, 'Incorrect request');
		
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0)
		{
           swapTokensForETH(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0)
		{
           payable(taxWallet).transfer(ethBalance);
        }
    }
	
	function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) 
		{
           isBot[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
       for (uint i = 0; i < notbot.length; i++) 
	   {
          isBot[notbot[i]] = false;
       }
    }
}