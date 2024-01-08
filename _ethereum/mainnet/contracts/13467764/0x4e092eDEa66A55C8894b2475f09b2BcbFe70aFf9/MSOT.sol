// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract MSOT is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {

    uint8 public constant deci = 18;
    uint256 public constant _totalSupply = 18 * (10 ** 8) * (10 ** uint256(deci));

    function initialize() public initializer{
        __ERC20_init("BTour Chain", "MSOT");
        __Ownable_init();
        _mint(msg.sender, _totalSupply);

    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{} 

    function burn(address account, uint amount) public {
        _burn(account, amount);
    }
}

