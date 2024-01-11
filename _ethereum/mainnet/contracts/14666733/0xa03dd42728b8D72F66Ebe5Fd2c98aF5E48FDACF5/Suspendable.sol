// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";

/** @title RoleBasedPausable.
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 */
abstract contract Suspendable is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @notice Initializer
     * @param _pauser: the address of the account granted with PAUSER_ROLE
     */
    function __Suspendable_init(address _pauser) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __Suspendable_init_unchained(_pauser);
    }

    function __Suspendable_init_unchained(address _pauser)
        internal
        onlyInitializing
    {
        _setupRole(PAUSER_ROLE, _pauser);
    }

    /**
     * @dev Returns true if the contract is suspended/paused, and false otherwise.
     */
    function suspended() public view virtual returns (bool) {
        return paused();
    }

    /**
     * @notice suspend/pause the contract.
     * Only callable by members of PAUSER_ROLE
     */
    function suspend() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice resume/unpause the contract.
     * Only callable by members of PAUSER_ROLE
     */
    function resume() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    uint256[50] private __gap;
}
