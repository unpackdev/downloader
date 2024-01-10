// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// Inheritance
import "./OwnedwManager.sol"; 
// Internal references
import "./MixinResolver.sol";
import "./IAddressResolver.sol";
 
interface IMixinResolver_ {
    function rebuildCache() external;
}  

contract AddressResolver is   OwnedwManager, IAddressResolver {     
    mapping(bytes32 => address) public repository;

    constructor(address _owner) OwnedwManager(_owner, _owner)  {}
 
    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(address[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            IMixinResolver_(destinations[i]).rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external override view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external override view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external override view returns (address) {
        //IIssuer issuer = IIssuer(repository["Issuer"]);
        //require(address(issuer) != address(0), "Cannot find Issuer address");
        //return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}
