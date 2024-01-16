// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";

contract SavlPrivateToken is ERC20('Savl Private', 'SAVLP', 2), ERC20Mintable, ERC20Burnable {
    mapping(address => bool) private transferToWhileList;

    event AddedWhiteList(address _account);
    event RemovedWhiteList(address _account);

    function isTransferToWhitelisted(address account) public view returns (bool) {
        return transferToWhileList[account];
    }

    function updateTransferToWhitelist(address[] memory addresses, bool[] memory sentences) onlyOwner public {
        require(addresses.length == sentences.length, "Invalid update list entries length");

        for (uint256 i = 0; i < addresses.length; i++) {
          if (sentences[i] == true && !isTransferToWhitelisted(addresses[i])) {
            emit AddedWhiteList(addresses[i]);
            transferToWhileList[addresses[i]] = true;
          }
          if (sentences[i] == false && isTransferToWhitelisted(addresses[i])) {
            emit RemovedWhiteList(addresses[i]);
            transferToWhileList[addresses[i]] = false;
          }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(isTransferToWhitelisted(to), "Transfer only accessible to whitelist addresses");
    }
}
