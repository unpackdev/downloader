pragma solidity ^0.7.0;

import "./math.sol";
import "./stores.sol";
import "./interfaces.sol";

abstract contract Helpers is DSMath, Stores {
    /**
     * @dev CETH Interface
     */
    CETHInterface constant internal ceth = CETHInterface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    /**
     * @dev Compound Comptroller
     */
    ComptrollerInterface constant internal troller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /**
     * @dev Compound Mapping
     */
    CompoundMappingInterface internal constant compMapping = CompoundMappingInterface(0xA8F9D4aA7319C54C04404765117ddBf9448E2082); // Update the address

    /**
     * @dev enter compound market
     */
    function enterMarkets(address[] memory cErc20) internal {
        troller.enterMarkets(cErc20);
    }
}
