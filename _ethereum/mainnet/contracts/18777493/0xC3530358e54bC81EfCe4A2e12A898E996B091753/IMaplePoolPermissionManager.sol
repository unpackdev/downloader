// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./INonTransparentProxied.sol";

import "./IMaplePoolPermissionManagerStorage.sol";

interface IMaplePoolPermissionManager is IMaplePoolPermissionManagerStorage, INonTransparentProxied {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when the lender allowlist is updated.
     *  @param poolManager Address of the pool manager.
     *  @param lenders     List of lender addresses to set the allowlist for.
     *  @param booleans    List of boolean values.
     */
    event LenderAllowlistSet(address indexed poolManager, address[] lenders, bool[] booleans);

    /**
     *  @dev   Emitted when lender bitmaps are updated.
     *  @param lenders List of lender addresses to set the bitmaps for.
     *  @param bitmaps List of permission bitmaps.
     */
    event LenderBitmapsSet(address[] lenders, uint256[] bitmaps);

    /**
     *  @dev   Emitted when a permission admin has been updated.
     *  @param account Address of the updated account.
     *  @param isAdmin `true` if the account is a permission admin, `false` if not.
     */
    event PermissionAdminSet(address indexed account, bool isAdmin);

    /**
     *  @dev   Emitted when pool bitmaps are updated.
     *  @param poolManager Address of the pool manager.
     *  @param functionIds List of function identifiers to set the bitmaps for.
     *  @param bitmaps     List of permission bitmaps.
     */
    event PoolBitmapsSet(address indexed poolManager, bytes32[] functionIds, uint256[] bitmaps);

    /**
     *  @dev   Emitted when the permission level of a pool is updated.
     *  @param poolManager     Address of the pool manager.
     *  @param permissionLevel Pool permission level.
     */
    event PoolPermissionLevelSet(address indexed poolManager, uint256 permissionLevel);

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Configures the permissions of a pool.
     *  @param poolManager     Address of the pool manager.
     *  @param permissionLevel Permission level of the pool.
     *  @param functionIds     List of function identifiers to set the bitmaps for.
     *  @param poolBitmaps     List of permission bitmaps.
     */
    function configurePool(
        address poolManager,
        uint256 permissionLevel,
        bytes32[] calldata functionIds,
        uint256[] calldata poolBitmaps
    ) external;

    /**
     *  @dev    Checks if the lender has permission to interact with a pool.
     *          The function identifier defines the function to check the permission for.
     *  @param  poolManager   Address of the pool manager.
     *  @param  lender        Address of the lender.
     *  @param  functionId    Function identifier.
     *  @return hasPermission `true` if the lender has permission, `false` if not.
     */
    function hasPermission(address poolManager, address lender, bytes32 functionId) external view returns (bool hasPermission);

    /**
     *  @dev    Checks if one or more lenders have permission to interact with a pool.
     *          The function identifier defines the function to check the permission for.
     *  @param  poolManager   Address of the pool manager.
     *  @param  lenders       List of lender addresses.
     *  @param  functionId    Function identifier.
     *  @return hasPermission `true` if all lenders have permission, `false` if not.
     */
    function hasPermission(address poolManager, address[] calldata lenders, bytes32 functionId) external view returns (bool hasPermission);

    /**
     *  @dev   Sets the allowlist status of one or more lenders.
     *  @param poolManager Address of the pool manager.
     *  @param lenders     List of lender addresses to set the allowlist for.
     *  @param booleans    List of boolean values.
     */
    function setLenderAllowlist(address poolManager, address[] calldata lenders, bool[] calldata booleans) external;

    /**
     *  @dev   Sets the permission bitmaps of one or more lenders.
     *  @param lenders List of lender addresses to set the bitmaps for.
     *  @param bitmaps List of permission bitmaps.
     */
    function setLenderBitmaps(address[] calldata lenders, uint256[] calldata bitmaps) external;

    /**
     *  @dev   Sets the permission admin status of an account.
     *  @param account           Address of the account.
     *  @param isPermissionAdmin `true` if the account is a permission admin, `false` if not.
     */
    function setPermissionAdmin(address account, bool isPermissionAdmin) external;

    /**
     *  @dev   Sets the permission bitmaps of a pool.
     *  @param poolManager Address of the pool manager.
     *  @param functionIds List of function identifiers to set the bitmaps for.
     *  @param bitmaps     List of permission bitmaps.
     */
    function setPoolBitmaps(address poolManager, bytes32[] calldata functionIds, uint256[] calldata bitmaps) external;

    /**
     *  @dev    Sets the permission level of a pool.
     *          Permission levels: private (0), function-level (1), pool-level (2), public (3)
     *          NOTE: Bitmaps must be set before setting the permission level to function-level (1) or pool-level (2).
     *                Otherwise, the pool will be permissionless by default to un-set lenders.
     *  @param  poolManager     Address of the pool manager.
     *  @param  permissionLevel Pool permission level.
     */
    function setPoolPermissionLevel(address poolManager, uint256 permissionLevel) external;

}
