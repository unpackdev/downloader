// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "./TimelockController.sol";

error PreviouslyInitialized();

contract ChelseaDAOTimelockController is TimelockController {
    address public chelseaDAO = address(0);

    constructor()
        TimelockController(3 days, new address[](0), new address[](0))
    {} // solhint-disable-line no-empty-blocks

    function initialize(address chelseaDAO_)
        external
        onlyRole(TIMELOCK_ADMIN_ROLE)
    {
        if (chelseaDAO != address(0)) revert PreviouslyInitialized();

        chelseaDAO = chelseaDAO_;
        _setupRole(PROPOSER_ROLE, chelseaDAO);
        _setupRole(EXECUTOR_ROLE, chelseaDAO);
    }
}
