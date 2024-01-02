// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./NonTransparentProxied.sol";

import { IGlobalsLike }                from "./interfaces/Interfaces.sol";
import "./IMaplePoolPermissionManager.sol";

import "./MaplePoolPermissionManagerStorage.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

    ██████╗  ██████╗  ██████╗ ██╗
    ██╔══██╗██╔═══██╗██╔═══██╗██║
    ██████╔╝██║   ██║██║   ██║██║
    ██╔═══╝ ██║   ██║██║   ██║██║
    ██║     ╚██████╔╝╚██████╔╝███████╗
    ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝

    ██████╗ ███████╗██████╗ ███╗   ███╗██╗███████╗███████╗██╗ ██████╗ ███╗   ██╗
    ██╔══██╗██╔════╝██╔══██╗████╗ ████║██║██╔════╝██╔════╝██║██╔═══██╗████╗  ██║
    ██████╔╝█████╗  ██████╔╝██╔████╔██║██║███████╗███████╗██║██║   ██║██╔██╗ ██║
    ██╔═══╝ ██╔══╝  ██╔══██╗██║╚██╔╝██║██║╚════██║╚════██║██║██║   ██║██║╚██╗██║
    ██║     ███████╗██║  ██║██║ ╚═╝ ██║██║███████║███████║██║╚██████╔╝██║ ╚████║
    ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝

    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

*/

contract MaplePoolPermissionManager is IMaplePoolPermissionManager, MaplePoolPermissionManagerStorage, NonTransparentProxied {

    /**************************************************************************************************************************************/
    /*** Permission Levels                                                                                                              ***/
    /**************************************************************************************************************************************/

    uint256 constant PRIVATE        = 0;  // Allow only when on the allowlist (default).
    uint256 constant FUNCTION_LEVEL = 1;  // Allow when function-specific pool bitmaps match.
    uint256 constant POOL_LEVEL     = 2;  // Allow when pool bitmaps match.
    uint256 constant PUBLIC         = 3;  // Allow always.

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier onlyPermissionAdminOrProtocolAdmins() {
        require(
            permissionAdmins[msg.sender]                         ||
            msg.sender == admin()                                ||
            msg.sender == IGlobalsLike(globals).operationalAdmin(),
            "PPM:NOT_PPM_ADMIN_GOV_OR_OA"
        );

        _;
    }

    modifier onlyPoolDelegateOrProtocolAdmins(address poolManager_) {
        ( address ownedPoolManager_, bool isPoolDelegate_ ) = IGlobalsLike(globals).poolDelegates(msg.sender);

        require(
            isPoolDelegate_ && ownedPoolManager_ == poolManager_ ||
            msg.sender == admin()                                ||
            msg.sender == IGlobalsLike(globals).operationalAdmin(),
            "PPM:NOT_PD_GOV_OR_OA"
        );

        _;
    }

    modifier onlyGovernorOrOperationalAdmin() {
        require(msg.sender == admin() || msg.sender == IGlobalsLike(globals).operationalAdmin(), "PPM:NOT_GOV_OR_OA");
        _;
    }

    modifier whenProtocolNotPaused() {
        require(!IGlobalsLike(globals).isFunctionPaused(msg.sig), "PPM:PAUSED");
        _;
    }

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function setLenderBitmaps(address[] calldata lenders_,uint256[] calldata bitmaps_)
        external override whenProtocolNotPaused onlyPermissionAdminOrProtocolAdmins
    {
        require(lenders_.length > 0,                "PPM:SLB:NO_LENDERS");
        require(lenders_.length == bitmaps_.length, "PPM:SLB:LENGTH_MISMATCH");

        for (uint256 i; i < lenders_.length; ++i) {
            lenderBitmaps[lenders_[i]] = bitmaps_[i];
        }

        emit LenderBitmapsSet(lenders_, bitmaps_);
    }

    function setPermissionAdmin(address permissionAdmin_, bool isPermissionAdmin_)
        external override whenProtocolNotPaused onlyGovernorOrOperationalAdmin
    {
        permissionAdmins[permissionAdmin_] = isPermissionAdmin_;

        emit PermissionAdminSet(permissionAdmin_, isPermissionAdmin_);
    }

    /**************************************************************************************************************************************/
    /*** Pool Configuration Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    function configurePool(
        address            poolManager_,
        uint256            permissionLevel_,
        bytes32[] calldata functionIds_,
        uint256[] calldata poolBitmaps_
    )
        external override whenProtocolNotPaused onlyPoolDelegateOrProtocolAdmins(poolManager_)
    {
        require(permissionLevels[poolManager_] != PUBLIC,   "PPM:CP:PUBLIC_POOL");
        require(permissionLevel_ <= PUBLIC,                 "PPM:CP:INVALID_LEVEL");
        require(functionIds_.length > 0,                    "PPM:CP:NO_FUNCTIONS");
        require(functionIds_.length == poolBitmaps_.length, "PPM:CP:LENGTH_MISMATCH");

        for (uint256 i; i < functionIds_.length; ++i) {
            poolBitmaps[poolManager_][functionIds_[i]] = poolBitmaps_[i];
        }

        permissionLevels[poolManager_] = permissionLevel_;

        emit PoolPermissionLevelSet(poolManager_, permissionLevel_);
        emit PoolBitmapsSet(poolManager_, functionIds_, poolBitmaps_);
    }

    function setLenderAllowlist(
        address            poolManager_,
        address[] calldata lenders_,
        bool[]    calldata booleans_
    )
        external override whenProtocolNotPaused onlyPoolDelegateOrProtocolAdmins(poolManager_)
    {
        require(lenders_.length > 0,                 "PPM:SLA:NO_LENDERS");
        require(lenders_.length == booleans_.length, "PPM:SLA:LENGTH_MISMATCH");

        for (uint256 i; i < lenders_.length; ++i) {
            lenderAllowlist[poolManager_][lenders_[i]] = booleans_[i];
        }

        emit LenderAllowlistSet(poolManager_, lenders_, booleans_);
    }

    function setPoolBitmaps(
        address            poolManager_,
        bytes32[] calldata functionIds_,
        uint256[] calldata bitmaps_
    )
        external override whenProtocolNotPaused onlyPoolDelegateOrProtocolAdmins(poolManager_)
    {
        require(functionIds_.length > 0,                "PPM:SPB:NO_FUNCTIONS");
        require(functionIds_.length == bitmaps_.length, "PPM:SPB:LENGTH_MISMATCH");

        for (uint256 i; i < functionIds_.length; ++i) {
            poolBitmaps[poolManager_][functionIds_[i]] = bitmaps_[i];
        }

        emit PoolBitmapsSet(poolManager_, functionIds_, bitmaps_);
    }

    function setPoolPermissionLevel(
        address poolManager_,
        uint256 permissionLevel_
    )
        external override whenProtocolNotPaused onlyPoolDelegateOrProtocolAdmins(poolManager_)
    {
        require(permissionLevels[poolManager_] != PUBLIC, "PPM:SPPL:PUBLIC_POOL");
        require(permissionLevel_ <= PUBLIC,               "PPM:SPPL:INVALID_LEVEL");

        permissionLevels[poolManager_] = permissionLevel_;

        emit PoolPermissionLevelSet(poolManager_, permissionLevel_);
    }

    /**************************************************************************************************************************************/
    /*** Permission-related Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    function hasPermission(
        address poolManager_,
        address lender_,
        bytes32 functionId_
    )
        external override view returns (bool hasPermission_)
    {
        // Allow only if the bitmaps match.
        hasPermission_ = _hasPermission(poolManager_, lender_, permissionLevels[poolManager_], functionId_);
    }

    function hasPermission(
        address            poolManager_,
        address[] calldata lenders_,
        bytes32            functionId_
    )
        external override view returns (bool hasPermission_)
    {
        require(lenders_.length > 0, "PPM:HP:NO_LENDERS");

        uint256 permissionLevel_ = permissionLevels[poolManager_];

        for (uint256 i; i < lenders_.length; ++i) {
            if (!_hasPermission(poolManager_, lenders_[i], permissionLevel_, functionId_)) {
                return false;
            }
        }

        hasPermission_ = true;
    }

    function _hasPermission(
        address poolManager_,
        address lender_,
        uint256 permissionLevel_,
        bytes32 functionId_
    )
        internal view returns (bool hasPermission_)
    {
        // Always allow if the pool is public.
        if (permissionLevel_ == PUBLIC) return true;

        // Always allow if the lender is on the allow list.
        if (lenderAllowlist[poolManager_][lender_]) return true;

        // Always deny if the pool is private and the lender is not on the allow list.
        if (permissionLevel_ == PRIVATE) return false;

        // Ignore the function identifier if using pool-level bitmaps.
        if (permissionLevel_ == POOL_LEVEL) functionId_ = bytes32(0);

        uint256 poolBitmap_ = poolBitmaps[poolManager_][functionId_];

        // Allow only if the bitmaps match.
        hasPermission_ = (poolBitmap_ & lenderBitmaps[lender_]) == poolBitmap_;
    }

}
