// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.5.0;

import "./Initializable.sol";
import "./PoapRoles.sol";

 /**
 * @title Pausable contract
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * - Users can:
 *   # Pause contract if admin
 *   # Unpause contract if admin
 * @author POAP
 * - Developers:
 *   # Agustin Lavarello
 *   # Rodrigo Manuel Navarro Lajous
 *   # Ramiro Gonzales
 **/
contract PoapPausable is Initializable, PoapRoles {
    /**
     * @dev Emmited when contract is paused
     */
    event Paused(address account);

    /**
     * @dev Emmited when contract is unpaused
     */
    event Unpaused(address account);

    // Boolean to save if contract is paused
    bool private _paused;

    function initialize() public initializer {
        _paused = false;
    }

    /**
     * @dev Get if contract is paused
     * @return ( bool ) If contract is paused
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Contract is Paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Contract is not Paused");
        _;
    }

    /**
     * @dev Called by the owner to pause, triggers stopped state.
     * Requires 
     * - The msg sender to be the admin
     * - The contract does not have to be paused
     */
    function pause() public onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     /**
     * @dev Called by the owner to pause, triggers unstopped state.
     * Requires 
     * - The msg sender to be the admin
     * - The contract does not have to be paused
     */
    function unpause() public onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // For future extensions
    uint256[50] private ______gap;
}
