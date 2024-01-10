// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./BaseVesting.sol";

import "./ISpoolBuildersVesting.sol";

/**
 * @notice Implementation of the {ISpoolBuildersVesting} interface.
 *
 * @dev This contract inherits BaseVesting, this is where most of the functionality is located.
 *      It overrides some functions where necessary.
 */
contract SpoolBuildersVesting is BaseVesting, ISpoolBuildersVesting {

    /**
     * @notice sets the contracts initial values
     *
     * @param spoolOwnable the spool owner contract that owns this contract
     * @param _spool SPOOL token contract address, the token that is being vested.
     * @param _vestingDuration the length of time (in seconds) the vesting is to last for.
     */
    constructor(ISpoolOwner spoolOwnable, IERC20 _spool, uint256 _vestingDuration)
        BaseVesting(spoolOwnable, _spool, _vestingDuration)
    {}

    /**
     * @notice Allows vests to be set. 
     *
     * @dev
     * internally calls _setVests function on BaseVesting.
     *
     * Can be called an arbitrary number of times before `begin()` is successfully 
     * called on the base contract.
     *
     * Requirements:
     *
     * - the caller must be the owner
     *
     * @param members array of addresses to set vesting for
     * @param amounts array of SPOOL token vesting amounts to to be set for each address
     */
    function setVests(address[] calldata members, uint192[] calldata amounts)
        external
        override
        onlyOwner
    {
        _setVests(members, amounts);
    }
}
