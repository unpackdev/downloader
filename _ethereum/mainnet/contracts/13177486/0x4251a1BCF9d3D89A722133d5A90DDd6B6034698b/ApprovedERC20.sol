// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Configurable.sol";
import "./ERC20UpgradeSafe.sol";

contract ApprovedERC20 is ERC20UpgradeSafe, Configurable {
    address public operator;

    function __ApprovedERC20_init_unchained(address operator_) public governance {
        operator = operator_;
    }

    function setNameAndSymbol(string memory newName, string memory newSymbol) external governance {
        updateNameAndSymbol(newName, newSymbol);
    }

    modifier onlyOperator {
        require(msg.sender == operator, 'called only by operator');
        _;
    }

    function transferFrom_(address sender, address recipient, uint256 amount) external onlyOperator returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
}
