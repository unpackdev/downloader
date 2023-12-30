// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Initializable.sol";
import "./ERC20PresetMinterPauser.sol";
import "./Ownable.sol";

contract CrToken is Initializable, ERC20PresetMinterPauserUpgradeSafe {
    uint256 private _totalSupply;

    function initialize() public initializer {
        ERC20PresetMinterPauserUpgradeSafe.initialize("Cryptomind", "CR");
        _setupDecimals(8);
        _totalSupply = totalSupply();

        _mint(msg.sender, 2000000000 * (10**8));
    }
}
