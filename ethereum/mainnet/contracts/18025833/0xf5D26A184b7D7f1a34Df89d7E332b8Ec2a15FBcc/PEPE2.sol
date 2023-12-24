// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣴⣶⣶⣾⣿⣿⣿⣿⣿⣷⣶⣶⣦⣤⣄⣀⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⣿⣿⣿⣿⣿⣿⠿⣟⣛⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀
⠀⠀⠀⠀⢰⠶⣶⣶⣶⣦⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠟⠋⠉⡇⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠋⠉⠀⠀⠀
⠀⠀⠀⠀⢸⣷⣄⣙⣿⣿⣿⣿⣿⣿⣿⣫⣭⠿⣭⣝⢿⣿⣦⣄⡇⣿⣿⣿⣿⣿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣫⠟⠁⠀⠀⠀⠈⢷⢻⣿⣿⣿⣿⣿⣿⣿⣥⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣾⡟⣷⢻⣿⣿⣿⣿⠃⠀⠀⣠⣤⡀⠀⠘⣟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣿⠀⢸⣏⣿⣿⣿⡏⠀⠀⠀⣿⣿⣇⠀⠀⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀
⠀⠀⠀⠀⠀⢹⠀⠀⣿⣿⣿⡟⠀⠀⠀⠀⣿⣿⣿⠀⠀⣿⣿⠇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀
⠀⠀⠀⠀⠀⣸⣄⡀⢻⣿⠉⠀⠀⠀⠀⠀⠹⠿⠏⠀⣸⣿⣿⡀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀
⠀⠀⠀⠀⠀⢿⣿⣿⣷⡖⠒⠦⢄⣀⣀⣀⣀⠤⠒⢉⣀⡀⠀⠙⣿⣿⣿⣿⣟⠛⠉⠉⠉⠉⠛⠛⠻⢿⣷⠀
⠀⠀⠀⠀⠀⠀⠉⠻⡛⠁⠀⠀⠀⠀⠈⠀⠀⠀⠀⢀⡸⠻⠀⢰⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠈⠂
⠀⠀⠀⠀⠀⠀⠀⠀⠙⠲⣄⠀⠀⠀⠀⠀⠠⠒⠚⠉⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠬⠵⣦⠤⣤⠀⠀⣀⣤⣤⣶⣿⠟⠛⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣠⡞⢀⡔⠒⣼⡞⢁⡔⠂⠉⠉⠉⠛⠧⣄⢀⠟⠛⠻⢿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⠘⠷⠤⢷⡀⠈⠳⠼⡀⠀⠀⠀⠀⠀⢀⠈⢿⣧⠀⠀⠀⠉⠻⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⡠⠓⢦⡤⠔⠛⠲⠤⠤⠵⢴⠀⠀⡄⢰⠈⣇⣿⣿⣧⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠘⠦⠤⠟⣆⠀⠀⠀⠀⠀⠀⢦⣀⣴⣠⣧⣼⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⢦⣤⣀⣠⣤⣾⣿⣿⣿⡇⠀⠀⠈⠙⠻⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⠻⣿⣿⡏⠻⢿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⡏⠀⢹⣿⣿⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⡔⠒⢋⣿⣿⣿⡒⢬⣿⣿⡧⠤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠧⠀⠈⠉⢉⡟⠉⢥⣿⣿⠿⠒⠀⢹⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⡸⢄⠀⠀⠀⠀⢣⡀⠀⠀⠀⠀⠀⠀⡸⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣤⣾⣿⡦⠀⠙⢶⣶⣤⣼⠀⠀⠀⠀⠀⠀⠀⠀⣨⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣠⣶⣿⠿⠋⣡⣴⣷⡀⠈⣿⣿⣿⣷⣦⣤⣤⠄⠀⠒⠚⠻⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣼⡿⢋⣡⣴⣿⣿⣿⣿⡇⠀⢻⣿⣿⣿⣿⡿⠁⣠⣾⠘⣷⣦⢹⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠘⢿⣾⣿⣿⣿⣿⣿⣿⡿⠧⠤⠚⠛⠉⢿⣿⠃⣸⣿⣿⡀⠹⣿⣧⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣄⣿⣿⣿⣧⠀⢻⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣇⢸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⢿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
HarryPotterObamaSonic10Inu (PEPE2)
Telegram: http://t.me/HPOS10I
Website:  https://hpos10i.com/PEPE2
Twitter:  https://twitter.com/hpos10iETH
**/

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor() {
        _name = "HarryPotterObamaSonic10InuPepe2.0";
        _symbol = "PEPE2";
        uint256 tokenSupply = 1000000000 * (10**decimals());

        _totalSupply = tokenSupply;
        _balances[msg.sender] = tokenSupply;
        emit Transfer(address(0), msg.sender, tokenSupply);
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
