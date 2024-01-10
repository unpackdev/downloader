//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract Honor is ERC20Upgradeable, OwnableUpgradeable {
    mapping(address => bool) private _operators;

    function initialize() public initializer {
        __ERC20_init('HONOR', 'HONOR');
        __Ownable_init();

        _operators[_msgSender()] = true;
    }

    modifier onlyOperator() {
        require(_operators[_msgSender()] == true, 'Caller is not the operator');
        _;
    }

    function setOperator(address operatorAddress, bool value) public onlyOwner {
        _operators[operatorAddress] = value;
    }

    function updateBalance(
        address wallet,
        uint256 debit,
        uint256 credit
    ) external onlyOperator {
        if (debit > credit) {
            _mint(wallet, debit - credit);
        } else if (debit < credit) {
            _burn(wallet, credit - debit);
        }
    }

    function burn(address wallet, uint256 amount) external onlyOperator {
        _burn(wallet, amount);
    }

    function mint(address wallet, uint256 amount) external onlyOperator {
        _mint(wallet, amount);
    }

    function pay(
        address sender,
        address recipient,
        uint256 amount
    ) external onlyOperator {
        _transfer(sender, recipient, amount);
    }
}
