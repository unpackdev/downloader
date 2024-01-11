pragma solidity ^0.5.16;

import "./CToken.sol";
import "./ComptrollerStorage.sol";
import "./Unitroller.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 * @dev This contract should not to be deployed alone; instead, deploy `Unitroller` (proxy contract) on top of this `Comptroller` (logic/implementation contract).
 */
contract ComptrollerTempTokenMigration is ComptrollerV3Storage {
    function _become(Unitroller unitroller, address oldUnderlying, address newUnderlying) public {
        require((msg.sender == address(fuseAdmin) && unitroller.fuseAdminHasRights()) || (msg.sender == unitroller.admin() && unitroller.adminHasRights()), "only unitroller admin can change brains");

        uint changeStatus = unitroller._acceptImplementation();
        require(changeStatus == 0, "change not authorized");

        ComptrollerTempTokenMigration(address(unitroller))._becomeImplementation(oldUnderlying, newUnderlying);
    }

    function _becomeImplementation(address oldUnderlying, address newUnderlying) external {
        require(msg.sender == comptrollerImplementation, "only implementation may call _becomeImplementation");

        if (address(cTokensByUnderlying[oldUnderlying]) != address(0) && address(cTokensByUnderlying[newUnderlying]) == address(0)) {
            CToken cToken = cTokensByUnderlying[oldUnderlying];
            cTokensByUnderlying[oldUnderlying] = CToken(address(0));
            cTokensByUnderlying[newUnderlying] = cToken;
        }
    }
}
