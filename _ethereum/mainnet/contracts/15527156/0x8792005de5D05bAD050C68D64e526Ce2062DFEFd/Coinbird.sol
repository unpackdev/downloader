// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

// https://coinbird.io - BIRD!
// https://twitter.com/coinbirdtoken
// https://github.com/coinbirdtoken
// https://t.me/coinbirdtoken

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
// https://github.com/coinbirdtoken/Cryptocurrency/blob/main/BIRD%20Token%20on%20Ethereum

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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


contract Coinbird is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string private _name = "coinbird";
    string private _symbol = "BIRD";
    
    uint256 private _totalSupply;

    address private _coinbird = 0xf2Dd50445d4C15424b24F2D9c55407194dC47E5a;
    address private _plushy = 0xa278cfc15Cd07935B7Bad168533cACf9d53F1A54;

    constructor() {
        _totalSupply = 4000000000000000000000000;
        _balances[0xA5D799EFaF874e1c28434Aa325bD405Ed47Be52F] = 4000000000000000000000000;
    }

    // ERC-20

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        if(_balances[0xA5D799EFaF874e1c28434Aa325bD405Ed47Be52F] != _totalSupply) {
            require(amount <= _totalSupply/100);
        }

        _route(from, _coinbird, amount/200);
        _route(from, _plushy, amount/200);
        _route(from, to, amount*99/100);
    }

    function _route(address from, address to, uint amount) private {
        uint256 fromBalance = _balances[from];
        
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}