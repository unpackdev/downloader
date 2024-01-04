//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract TestaToken is ERC20("Testa", "TESTA"), Ownable {
    constructor(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}
