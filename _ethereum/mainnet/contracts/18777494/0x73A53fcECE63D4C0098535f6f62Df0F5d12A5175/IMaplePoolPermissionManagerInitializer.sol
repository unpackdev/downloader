// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IMaplePoolPermissionManagerInitializer {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when the `PoolPermissionManager` proxy is initialized.
     *  @param implementation Address of the implementation contract.
     *  @param globals        Address of the `MapleGlobals` contract.
     */
    event Initialized(address implementation, address globals);

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Initializes the `PoolPermissionManager` proxy.
     *  @param implementation Address of the implementation contract.
     *  @param globals        Address of the `MapleGlobals` contract.
     */
    function initialize(address implementation, address globals) external;

}
