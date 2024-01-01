//SPDX-License-Identifier: UNLICENSED

/*
██╗░░██╗░█████╗░███████╗██████╗░██╗░░░██╗  ██╗███╗░░██╗██╗██╗
░█████╗░░█████╗░██████╗░████████╗███╗░░░███╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝████╗░████║██╔══██╗████╗░██║
██║░░╚═╝███████║██████╔╝░░░██║░░░██╔████╔██║███████║██╔██╗██║
██║░░██╗██╔══██║██╔══██╗░░░██║░░░██║╚██╔╝██║██╔══██║██║╚████║
╚█████╔╝██║░░██║██║░░██║░░░██║░░░██║░╚═╝░██║██║░░██║██║░╚███║
░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝

TG: https://t.me/cartmancoin
Twitter: https://twitter.com/Cartman_ERC20
Website: https://cartman.club/

elon musk tweet: https://x.com/elonmusk/status/1719633597064188219?s=46&t=Yt1bwL9_vfXxzxIBMvI14A

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

pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferforOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function TransferThisOwnerships(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferforOwnership(newOwner);
    }

    function _transferforOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract CARTMAN is ERC20, Ownable {
    constructor() ERC20("CARTMAN", "CARTMAN") {
        _mint(msg.sender, 420000000 * 10 ** decimals());
    }
}