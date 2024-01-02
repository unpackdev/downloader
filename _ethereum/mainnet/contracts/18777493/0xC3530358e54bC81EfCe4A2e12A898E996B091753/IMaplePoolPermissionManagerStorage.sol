// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IMaplePoolPermissionManagerStorage {

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the address of the `MapleGlobals` contract.
     *  @return globals Address of the `MapleGlobals` contract.
     */
    function globals() external view returns (address globals);

    /**
     *  @dev    Checks if a pool has allowlisted a lender.
     *  @param  poolManager   Address of the pool manager.
     *  @param  lender        Address of the lender.
     *  @return isAllowlisted `true` if the lender is allowlisted, `false` if not.
     */
    function lenderAllowlist(address poolManager, address lender) external view returns (bool isAllowlisted);

    /**
     *  @dev    Returns the permission bitmap of a lender.
     *  @param  lender Address of the lender.
     *  @return bitmap Permission bitmap of the lender.
     */
    function lenderBitmaps(address lender) external view returns (uint256 bitmap);

    /**
     *  @dev    Checks if the account is a permission admin.
     *  @param  account Address of the account.
     *  @return isAdmin `true` if the account is a permission admin, `false` if not.
     */
    function permissionAdmins(address account) external view returns (bool isAdmin);

    /**
     *  @dev    Returns the permission level of a pool.
     *          Permission levels: private (0), function-level (1), pool-level (2), public (3)
     *  @param  poolManager     Address of the pool manager.
     *  @return permissionLevel Permission level of the pool.
     */
    function permissionLevels(address poolManager) external view returns (uint256 permissionLevel);

    /**
     *  @dev    Returns a function-specific pool permission bitmap.
                Return the pool-level permission bitmap if the function identifier is zero.
     *  @param  poolManager Address of the pool manager.
     *  @param  functionId  Identifier of the function (zero if none).
     *  @return bitmap      Permission bitmap of the pool.
     */
    function poolBitmaps(address poolManager, bytes32 functionId) external view returns (uint256 bitmap);

}
