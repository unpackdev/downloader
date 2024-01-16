// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./WithOwnerUpgradeable.sol";
import "./WithSuperOperators.sol";
import "./ERC20BasicApproveExtension.sol";
import "./BytesUtil.sol";

contract MT2 is Initializable, ERC20Upgradeable, ERC20BasicApproveExtension, WithOwnerUpgradeable, WithSuperOperators {

    mapping(address => bool) internal _whiteList;

    function initialize(address owner,uint256 amount) external initializer {
        __ERC20_init("Matic Test 2", "MT2");
        __WithOwner_init(owner);
        _mint(owner,amount);
    }

    function _addAllowanceIfNeeded(
        address owner,
        address spender,
        uint256 amountNeeded
    ) internal virtual override {
        if (amountNeeded > 0) {
            uint256 currentAllowance = allowance(owner,spender);
            if (currentAllowance < amountNeeded) {
                _approve(owner, spender, amountNeeded);
            }
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool success) {
        require(_superOperators[_msgSender()] || _msgSender() == _owner || isWhiteList(_msgSender()), "NOT_AUTHORIZED");
        if (_msgSender() != from && !_superOperators[_msgSender()] && _msgSender() != _owner) {
            address spender = _msgSender();
            _spendAllowance(from, spender, amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(_superOperators[_msgSender()] || _msgSender() == _owner || isWhiteList(_msgSender()), "NOT_AUTHORIZED");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function setWhiteListForTransfer(address[] memory whitelists, bool enabled) external onlyOwner {
        uint whitelistsLegth = whitelists.length;
        for (uint i=0; i<whitelistsLegth; i++) {
            _whiteList[whitelists[i]] = enabled;
        }
    }

    function isWhiteList(address who) public view returns (bool) {
        return _whiteList[who];
    }
}
