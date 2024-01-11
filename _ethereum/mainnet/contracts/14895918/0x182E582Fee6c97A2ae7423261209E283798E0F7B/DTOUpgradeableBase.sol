pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
contract DTOUpgradeableBase is
    Initializable, 
    UUPSUpgradeable,
    OwnableUpgradeable
{
    function __DTOUpgradeableBase_initialize() internal initializer {
        __Ownable_init();
    }

    /* ========== CONSTRUCTOR ========== */
        /// @custom:oz-upgrades-unsafe-allow constructor
   constructor() initializer {}
   function _authorizeUpgrade(address) internal override onlyOwner {}
}