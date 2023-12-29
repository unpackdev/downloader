pragma solidity 0.6.6;

import "./Ownable.sol";
import "./SafeMath.sol";

import "./AddressArrayUtils.sol";

// @TODO: This code has been pulled from Set Protocol but does not have the tests inside THIS repo.
// This contract has been audited and tested against though.

/**
 * @title ZoraAuthorized
 *
 * The ZoraAuthorized contract is an inherited contract that sets permissions on certain function calls
 * through the onlyAuthorized modifier. Permissions can be managed only by the Owner of the contract.
 */
contract ZoraAuthorized is Ownable {

    using SafeMath for uint256;
    using AddressArrayUtils for address[];

    /* ============ State Variables ============ */

    // Mapping of addresses to bool indicator of authorization
    mapping (address => bool) public authorized;

    // Array of authorized addresses
    address[] public authorities;

    /* ============ Modifiers ============ */

    // Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        require(
            authorized[msg.sender],
            "Authorizable.onlyAuthorized: Sender not included in authorities"
        );
        _;
    }

    /* ============ Events ============ */

    // Event emitted when new address is authorized.
    event AddressAuthorized (
        address indexed authAddress,
        address authorizedBy
    );

    // Event emitted when address is deauthorized.
    event AuthorizedAddressRemoved (
        address indexed addressRemoved,
        address authorizedBy
    );

    /* ============ Setters ============ */

    /**
     * Add multiple authorized addresses to contract. Can only be set by owner.
     *
     * @param  _authTargets   The addresses of the new authorized contract
     */
    function addAuthorizedAddresses(address[] calldata _authTargets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < authorities.length; i++) {
            addAuthorizedAddress(_authTargets[i]);
        }
    }

    /**
     * Remove authorized address from contract. Can only be set by owner.
     *
     * @param  _authTargets   The addresses to be de-permissioned
     */
    function removeAuthorizedAddresses(address[] calldata _authTargets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < authorities.length; i++) {
            removeAuthorizedAddress(_authTargets[i]);
        }
    }

    /**
     * Add authorized address to contract. Can only be set by owner.
     *
     * @param  _authTarget   The address of the new authorized contract
     */
    function addAuthorizedAddress(address _authTarget)
        public
        onlyOwner
    {
        // Require that address is not already authorized
        require(
            !authorized[_authTarget],
            "Authorizable.addAuthorizedAddress: Address already registered"
        );

        // Set address authority to true
        authorized[_authTarget] = true;

        // Add address to authorities array
        authorities.push(_authTarget);

        // Emit authorized address event
        emit AddressAuthorized(
            _authTarget,
            msg.sender
        );
    }

    /**
     * Remove authorized address from contract. Can only be set by owner.
     *
     * @param  _authTarget   The address to be de-permissioned
     */
    function removeAuthorizedAddress(address _authTarget)
        public
        onlyOwner
    {
        // Require address is authorized
        require(
            authorized[_authTarget],
            "Authorizable.removeAuthorizedAddress: Address not authorized"
        );

        // Delete address from authorized mapping
        authorized[_authTarget] = false;

        authorities = authorities.remove(_authTarget);

        // Emit AuthorizedAddressRemoved event.
        emit AuthorizedAddressRemoved(
            _authTarget,
            msg.sender
        );
    }

    /* ============ Getters ============ */

    /**
     * Get array of authorized addresses.
     *
     * @return address[]   Array of authorized addresses
     */
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory)
    {
        // Return array of authorized addresses
        return authorities;
    }

    /**
     * Check if the address is authorised or not
     *
     * @param addressToCheck The address to check is authorised or not
     *
     * @return boolean       Status of whether the address is approved or not
     *
     */
    function isAuthorized(
        address addressToCheck
    )
        external
        view
        returns (bool)
    {
        return authorized[addressToCheck];
    }
}