// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC20Upgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract UBI is Initializable, ERC20Upgradeable, ERC20PausableUpgradeable, UUPSUpgradeable, OwnableUpgradeable{

    function initialize() external initializer {
        __ERC20_init("UBI", "UBON");
        __ERC20Pausable_init();
        __Ownable_init();
        _mint(_msgSender(),700000000 * 10**18);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override (ERC20Upgradeable, ERC20PausableUpgradeable){
        super._beforeTokenTransfer(from, to, amount);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

}
