// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ContextUpgradeable.sol";
import "./IERC223.sol";
import "./IERC223Recipient.sol";
import "./Address.sol";

contract RoboToken is Initializable, ContextUpgradeable, IERC20, IERC20Metadata, IERC223 {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _locked;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _lockedSupply;

    address private _robo_addr;

    error Unauthorized();

    constructor() initializer {}

    function name() public view virtual override(IERC20Metadata, IERC223) returns (string memory) {
        return "Robotoken";
    }

    function symbol() public view virtual override(IERC20Metadata, IERC223) returns (string memory) {
        return "ROBO";
    }

    function decimals() public view virtual override(IERC20Metadata, IERC223) returns (uint8) {
        return 18;
    }

    function standard() public view virtual override returns (string memory) {
        return "erc223";
    }

    function roboAddr() public view returns (address) {
        return _robo_addr;
    }

    function totalSupply() public view virtual override(IERC20, IERC223) returns (uint256) {
        return _totalSupply;
    }

    function lockedSupply() public view returns (uint256) {
        return _lockedSupply;
    }

    function balanceOf(address account) public view virtual override(IERC20, IERC223) returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function locked(address account) public view returns (uint256) {
        return _locked[account];
    }

    function transfer(address to, uint256 amount) public virtual override(IERC20, IERC223) returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        bytes memory empty = hex"00000000";
        if (Address.isContract(to)) {
            IERC223Recipient(to).tokenReceived(owner, amount, empty);
        }
        emit TransferData(empty);
        return true;
    }

    function transfer(address to, uint amount, bytes calldata data) public virtual override returns (bool success) {
        address owner = _msgSender();
        _transfer(owner, to, amount);        
        if (Address.isContract(to)) {
            IERC223Recipient(to).tokenReceived(owner, amount, data);
        }
        emit TransferData(data);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        emit TransferData(hex"00000000");
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "NEGATIVE_ALLOWANCE");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function moveBalance(address from, address to) public returns (bool) {
        if (_msgSender() != _robo_addr) {
            revert Unauthorized();
        }

        uint256 b = _balances[to];
        uint256 l = _locked[to];

        _balances[to] = _balances[from];
        _locked[to] = _locked[from];

        _balances[from] = b;
        _locked[from] = l;

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "TX_FROM_0_ADDR");
        require(to != address(0), "TX_TO_0_ADDR");
        // _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        if (to == _robo_addr) {
            require(fromBalance >= amount, "INSUFFICIENT_BALANCE");
        } else {
            uint256 availableBalance = _locked[from] < fromBalance ? fromBalance - _locked[from] : 0;
            require(availableBalance >= amount, "INSUFFICIENT_UNLOCKED_BALANCE");
        }
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        // _afterTokenTransfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "APPROVE_FROM_0_ADDR");
        require(spender != address(0), "APPROVE_TO_0_ADDR");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
