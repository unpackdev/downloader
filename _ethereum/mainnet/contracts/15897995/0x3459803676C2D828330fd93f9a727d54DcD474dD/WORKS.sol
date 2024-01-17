// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract WORKS is Initializable, ERC20Upgradeable, OwnableUpgradeable   {

    struct TokenTransactionDetails {
        string id;
        string transaction_type;
        uint256 token_withdrawn;
    }

    event TokenWithdrawalEvent(string id, address wallet_address);
    event TokenTransactionEvent(string id, string transaction_type, uint256 token_withdrawn);

    function initialize(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        _mint(_msgSender(), initialSupply);
        __Ownable_init();
    }

    function transferWithDetails(address to, uint256 amount, string memory id, TokenTransactionDetails[] memory transactionDetails) public virtual onlyOwner returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);

        emit TokenWithdrawalEvent(id, to);
        for (uint256 i = 0; i < transactionDetails.length; i++) {
            emit TokenTransactionEvent(transactionDetails[i].id, transactionDetails[i].transaction_type, transactionDetails[i].token_withdrawn);
        }
        return true;
    }
}
