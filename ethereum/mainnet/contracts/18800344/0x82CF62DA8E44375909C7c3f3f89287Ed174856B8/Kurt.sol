/*
    https://kurterc.com/
    https://t.me/KurtERC20
    https://twitter.com/KurtERC20
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.20;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract Kurt {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    string public constant name = "KURT";  
    string public constant symbol = "KURT";  
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1e9 * 10**decimals;
    address public owner;

    struct TradingFees {
        uint256 buyFee;
        uint256 sellFee;
    }
    TradingFees fees = TradingFees(5,15);

    uint256 constant swapLimit = totalSupply / 125;
    uint256 constant maxWallet = 2 * totalSupply / 100;

    bool tradingOpened = false;
    bool swapping;

    address immutable pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;    
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    constructor() {
        owner = msg.sender;
        pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), ETH);
        allowance[msg.sender][routerAddress] = type(uint256).max;
        allowance[address(this)][routerAddress] = type(uint256).max;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) external returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool){
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool){
        allowance[from][msg.sender] -= amount;        
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool){        
        balanceOf[from] -= amount;

        //if renounced, then skip taxes, contract swaps and limits
        bool renounced = owner == address(0);
        if(!renounced){
            if(from != owner)
                require(tradingOpened);
            if(to != pair && to != address(0))
                require(balanceOf[to] + amount <= maxWallet);

            if (to == pair && !swapping && balanceOf[address(this)] >= swapLimit){
                swapping = true;
                uint256 swapAmount = amount < swapLimit ? amount : swapLimit;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                payable(owner).transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 taxAmount = amount * (from == pair ? fees.buyFee : fees.sellFee) / 100;
                if(taxAmount > 0){
                    amount -= taxAmount;
                    balanceOf[address(this)] += taxAmount;
                    emit Transfer(from, address(this), taxAmount);
                }
            }
        }

        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function openTrading() external onlyOwner {
        tradingOpened = true;
    }

    function renounceOwnership() external onlyOwner {
        //burn contract tokens, if any
        if(balanceOf[address(this)] > 0)
            _transfer(address(this), address(0), balanceOf[address(this)]);    
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

    function setFees(uint256 newBuyFee, uint256 newSellFee) external onlyOwner {
        fees = TradingFees(newBuyFee, newSellFee);
    }
}