//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./math.sol";
import "./basic.sol";
import "./interfaces.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {

    address internal constant CRV_USD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    /**
     * @dev ControllerFactory Interface
     */
    IControllerFactory internal constant CONTROLLER_FACTORY =
        IControllerFactory(0xC9332fdCB1C491Dcc683bAe86Fe3cb70360738BC);

    /**
     * @dev Get controller address by given collateral asset
     */
    function getController(address collateral, uint256 i) internal view returns(IController controller) {
        controller = IController(CONTROLLER_FACTORY.get_controller(collateral, i));
    }
}