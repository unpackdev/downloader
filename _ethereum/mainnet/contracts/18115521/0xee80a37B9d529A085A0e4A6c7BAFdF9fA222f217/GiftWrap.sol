// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC1155.sol";
import "./LibString.sol";

contract GiftWrap is Ownable, ERC1155 {
    address public immutable TARGET;
    ERC20 immutable token;
    uint16 public constant MAX_WALLET = 25;
    bool public unlocked = false;
    mapping(address => uint16) public stack;
    mapping(address => bool) public maxWalletExceptions;

    event Unlocked(uint256 when);
    event MaxWalletException(address indexed account, bool status);

    constructor(address target) {
        TARGET = target;
        token = ERC20(target);
        stack[address(0)] = 1000;
        maxWalletExceptions[msg.sender] = true;
        _initializeOwner(msg.sender);
        _mint(msg.sender, 0, 1, "");
    }

    function wrap(uint permille, uint qty) public {
        require(
            permille > 0 && permille * qty < 1000,
            "a permille is one-thousandth"
        );
        require(qty > 0, "silly");
        uint amountToWrap = qty * _pToAmt(permille);
        token.transferFrom(msg.sender, address(this), amountToWrap);
        _mint(msg.sender, permille, qty, "");
    }

    function unwrap(uint permille, uint qty) public {
        if (msg.sender != owner()) require(unlocked, "not yet");
        require(qty > 0, "silly");
        _burn(address(0), msg.sender, permille, qty);
        uint unwrappedAmount = qty * _pToAmt(permille);
        token.transfer(msg.sender, unwrappedAmount);
    }

    function combine(
        uint[] memory permilles,
        uint[] memory amounts
    ) public returns (uint) {
        uint combinedPermille = 0;
        uint p;
        uint amt;
        for (uint256 i; i < permilles.length; ++i) {
            p = permilles[i];
            amt = amounts[i];
            if (amt > 0) {
                _burn(address(0), msg.sender, p, amt);
            }
            combinedPermille += p * amt;
        }
        _mint(msg.sender, combinedPermille, 1, "");
        return combinedPermille;
    }

    function equivalentBalanceOf(address account) public view returns (uint) {
        if (account == address(0)) return 0;
        return _pToAmt(stack[account]);
    }

    function unlock() public onlyOwner returns (bool) {
        require(!unlocked, "can only unlock once");
        unlocked = true;
        emit Unlocked(block.timestamp);
        return unlocked;
    }

    function grantException(
        address account,
        bool onOff
    ) public onlyOwner returns (bool) {
        maxWalletExceptions[account] = onOff;
        emit MaxWalletException(account, onOff);
        return onOff;
    }

    // to%
    function uri(
        uint256 i
    ) public view virtual override returns (string memory) {
        uint256 leftOfDecimal = i / 10;
        uint256 rightOfDecimal = i % 10;
        string memory s;
        if (rightOfDecimal > 0) {
            s = string(
                abi.encodePacked(".", LibString.toString(rightOfDecimal))
            );
        }
        s = string(abi.encodePacked(LibString.toString(leftOfDecimal), s, "%"));
        return s;
    }

    function _pToAmt(uint permille) public view returns (uint) {
        return (permille * token.totalSupply()) / 1000;
    }

    function _useBeforeTokenTransfer()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return !unlocked && (maxWalletExceptions[msg.sender] ? false : true);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        uint16 newBal = stack[to];
        for (uint256 i; i < ids.length; ++i) {
            newBal += uint16(ids[i] * amounts[i]);
        }
        require(newBal <= MAX_WALLET, "greedy");
    }

    function _useAfterTokenTransfer()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return true;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        uint16 qty = 0;
        for (uint256 i; i < ids.length; ++i) {
            qty += uint16(ids[i] * amounts[i]);
        }
        stack[from] -= qty;
        stack[to] += qty;
    }
}
