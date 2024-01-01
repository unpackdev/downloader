// SPDX-License-Identifier: MIT
//   |\ | |  ||\ \ /(_~     |~)|_~|\/||_~|\/||~)|_~|~)
//   |~\|_|/\||~\ | ,_)     |~\|__|  ||__|  ||_)|__|~\
//
//       \ //~\| |    |\ |~)|_~    | ||\ ||/~\| ||_~
//        | \_/\_/    |~\|~\|__    \_/| \||\_X\_/|__
// and so is everyone else.. 

pragma solidity ^0.8.21;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

}


abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }


    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

}


contract ERC20 is Context, IERC20, IERC20Metadata {

    address public deployer;

    bool public tradingOpened = false;

    address public uniswapPair;

    bool public renounced = false;


    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;

    string private _symbol;


    constructor(string memory name_, string memory symbol_) {

        _name = name_;

        _symbol = symbol_;

        deployer = _msgSender();


        // Mint 1 billion tokens to the deployer

        _mint(deployer, 1_000_000_000 * 10**decimals());

    }


    function decimals() public view virtual override returns (uint8) {

        return 18;

    }


    function name() public view virtual override returns (string memory) {

        return _name;

    }


    function symbol() public view virtual override returns (string memory) {

        return _symbol;

    }


    function totalSupply() public view virtual override returns (uint256) {

        return _totalSupply;

    }


    function balanceOf(address account) public view virtual override returns (uint256) {

        return _balances[account];

    }


    function transfer(address to, uint256 amount) public virtual override returns (bool) {

        _transfer(_msgSender(), to, amount);

        return true;

    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {

        return _allowances[owner][spender];

    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {

        _approve(_msgSender(), spender, amount);

        return true;

    }


    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {

        _transfer(from, to, amount);

        _approve(from, _msgSender(), _allowances[from][_msgSender()] - amount);

        return true;

    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        return true;

    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);

        return true;

    }


    function _transfer(address from, address to, uint256 amount) internal virtual {

        require(from != address(0), "ERC20: transfer from the zero address");

        require(to != address(0), "ERC20: transfer to the zero address");

        if(!tradingOpened) {

            require(from != uniswapPair, "Selling is not allowed until trading is opened");

        }


        _balances[from] -= amount;

        _balances[to] += amount;

        emit Transfer(from, to, amount);

    }


    function _mint(address account, uint256 amount) internal virtual {

        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply += amount;

        _balances[account] += amount;

        emit Transfer(address(0), account, amount);

    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");


        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }


    function openTrading() external {

        require(msg.sender == deployer, "Only deployer can open trading");

        tradingOpened = true;

    }


    function renounceOwnership() external {

        require(msg.sender == deployer, "Only deployer can renounce ownership");

        renounced = true;

        deployer = address(0);

    }


    function setUniswapPair(address _uniswapPair) external {

        require(!renounced, "Ownership has been renounced");

        require(msg.sender == deployer, "Only deployer can set Uniswap pair");

        require(uniswapPair == address(0), "Uniswap pair is already set");

        uniswapPair = _uniswapPair;

    }

}