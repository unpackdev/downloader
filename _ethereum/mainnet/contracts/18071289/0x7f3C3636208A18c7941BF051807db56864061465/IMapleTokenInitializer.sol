// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC20.sol";

interface IMapleTokenInitializer is IERC20 {

    /**
     *  @dev    Contract was initialized
     *  @param  tokenMigrator Address of the Maple token migrator contract.
     *  @param  treasury      Address of the Maple treasury contract.
     */
    event Initialized(address tokenMigrator, address treasury);

    /**
     * @dev   Initializes MapleToken state.
     * @param tokenMigrator Address of the Maple token migrator contract.
     * @param treasury      Address of the Maple treasury contract.
     */
    function initialize(address tokenMigrator, address treasury) external;

}
