//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./Initializable.sol";

contract Quack is ERC20PresetMinterPauserUpgradeable {
    function burnFrom(address from, uint256 amount) public override {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to burnFrom");
        _burn(from, amount);
    }
}