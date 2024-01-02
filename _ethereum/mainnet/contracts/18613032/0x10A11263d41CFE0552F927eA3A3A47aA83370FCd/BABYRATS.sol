/**
Telegram：https://t.me/BABYRATSETH
Twitter： https://x.com/babyrats_eth


         ██████╗  █████╗ ██████╗ ██╗   ██╗██████╗  █████╗ ████████╗███████╗
         ██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
         ██████╔╝███████║██████╔╝ ╚████╔╝ ██████╔╝███████║   ██║   ███████╗
         ██╔══██╗██╔══██║██╔══██╗  ╚██╔╝  ██╔══██╗██╔══██║   ██║   ╚════██║
         ██████╔╝██║  ██║██████╔╝   ██║   ██║  ██║██║  ██║   ██║   ███████║
         ╚═════╝ ╚═╝  ╚═╝╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
                                                                  
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}


contract BABYRATS is IERC20{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _decimals;


    mapping(address => bool) public excludeMaxHolder;


    uint256 private _tTotal;
    uint256 public  MaxHoldAmount;

    ISwapRouter public _swapRouter;

    address public _mainPair;


    constructor(
    ) {
        _name = "BABYRATS";
        _symbol = "BABYRATS";
        _decimals = 18;
        _tTotal = 1000000000000*10**_decimals;
        MaxHoldAmount = _tTotal / 100;
        
        _swapRouter = ISwapRouter(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        address ReceiveAddress = address(0x482cfaFED1B8dDBB5B9fF8E98d39110Cd6eF0753);


        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        _mainPair = swapFactory.createPair(address(this),_swapRouter.WETH());

        _balances[ReceiveAddress] = _tTotal;
        emit Transfer(address(0), ReceiveAddress, _tTotal);

        excludeMaxHolder[ReceiveAddress] = true;
        excludeMaxHolder[address(_mainPair)] = true;

       
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }



    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(balanceOf(from) >= amount, "balanceNotEnough");
        if(!excludeMaxHolder[to]){
            require(balanceOf(to) + amount <= MaxHoldAmount, "balanceNotEnough");
        }
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);

    }


    

}