// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";


library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}


contract PEIPEI is ERC20, Ownable{
    using Address for address payable;
        
    mapping (address user => bool status) public isExcludedFromFees;
    IRouter public router;
    address public pair;

    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;
    
    uint256 public maxSupply = 289_520_200_999_888 * 10**18; //TOTAL SUPPLY
    uint256 public maxWallet = maxSupply * 50/10000; //0.5%
    uint256 public maxTx = maxSupply * 50/10000; //0.5%
    uint256 private swapThreshold;
    address private UniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //uniswapV2
    address private taxWallet = 0x9b09cCFb85FdF6f121ac1b40c362C6387A7B88c8;

    struct Taxes {
        uint256 buy; 
        uint256 sell;
        uint256 transfer;
    }

    Taxes public taxes = Taxes(0,2,0);

    modifier mutexLock() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
  
constructor() ERC20("PEIPEI", "PEIPEI") {
        _mint(msg.sender, maxSupply);
        router = IRouter(UniswapRouter);
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[taxWallet] = true;
        swapThreshold = maxWallet;
        _approve(address(this), address(router), type(uint256).max);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount >= 0, "Transfer amount must be greater or equal than zero");

        if (swapping || isExcludedFromFees[sender] || isExcludedFromFees[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }

        else{
            require(tradingEnabled, "Trading not enabled");
            if(sender == pair){ 
                require(amount <= maxTx, "MaxTx limit exceeded");
            }

            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWallet, "Wallet limit exceeded");
            }
        }
        uint256 fees;

        if(recipient == pair) fees = amount * taxes.sell / 100;
        else if(sender == pair) fees = amount * taxes.buy / 100;
        else if(sender != pair && recipient != pair) fees = amount * taxes.transfer / 100; 

        if (swapEnabled && recipient == pair && !swapping) swapFees();

        super._transfer(sender, recipient, amount - fees);
        if(fees > 0){
            super._transfer(sender, address(this), fees);
        }
    }

    function swapFees() private mutexLock {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
            uint256 amountToSwap = swapThreshold;
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(amountToSwap);
            uint256 deltaBalance = address(this).balance - initialBalance;
            payable(taxWallet).sendValue(deltaBalance);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function setSwapEnabled(bool status) external onlyOwner { 
        swapEnabled = status;
    }

    function setSwapTreshhold(uint256 amount) external onlyOwner {
        swapThreshold = amount;
    }
    
    function setTaxes(uint256 _buyTax, uint256 _sellTax, uint256 _transferTax) external onlyOwner {
        taxes = Taxes(_buyTax, _sellTax, _transferTax);
    }
    
    function setPair(address _pair) external onlyOwner{
        pair = _pair;
    }
    
    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Already enabled");
        tradingEnabled = true;
        swapEnabled = true;
        taxes.transfer = 0;
    }
 
    function removeLimits() external onlyOwner{
        maxTx = totalSupply(); 
        maxWallet = totalSupply();
        taxes.transfer = 0;
    }

    function setLimits(uint256 _maxTx, uint256 _maxWallet) external onlyOwner{
        maxTx = _maxTx; 
        maxWallet = _maxWallet;
    }
    
    function setIsExcludedFromFees(address _address, bool state) external onlyOwner {
        isExcludedFromFees[_address] = state;
        
    }

    function rescueETH(uint256 weiAmount) external  {
        require(msg.sender == taxWallet, "Require tax wallet.");
        payable(taxWallet).sendValue(weiAmount);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external {
        require(msg.sender == taxWallet, "Require tax wallet.");
        uint256 ERC20amount = amount ;
        IERC20(tokenAdd).transfer(taxWallet, ERC20amount);
    }

    receive() external payable {}

}