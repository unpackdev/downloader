// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/// @custom:security-contact dev@utrib.one
contract GIFT_PoR is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
   
    uint256 GIFT_reserve;
    uint256 Vault_index;
    //string vaultName;

    struct Vault{
        string name;
        uint256 amount;
    }

    // An array of 'Vaults' structs
    Vault[] public vaults;
    
    //Events
    event updateReserve(
        uint256 GIFT_reserve,
        uint256 Vault_index,
        address indexed sender
    );
    // event newVault(
    //     string vaultName,
    //     address indexed sender
    // );
  
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

     

    function initialize(address defaultAdmin, address upgrader)
        initializer public
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(AUDITOR_ROLE, defaultAdmin);
        _grantRole(ADMIN_ROLE, defaultAdmin);
       _grantRole(UPGRADER_ROLE, upgrader);
    }

     // add vault 
    function addVault(string memory _name) public onlyRole(ADMIN_ROLE){
        vaults.push(Vault({name: _name, amount: 0}));
    }
    // get all vaults (array)
    // function that returns entire array
    function getVaults() public view returns (Vault[] memory) {
        return vaults;
    }

    // update Reserve in vault by index
    function setReserve(uint256 _index, uint256 _amount) public onlyRole(AUDITOR_ROLE) {
        uint256 new_GIFT_reserve = 0;

        Vault storage vault = vaults[_index];
        vault.amount = _amount;

         //Set overall GIFT Reserve
        uint arrayLength = vaults.length;
        for (uint i=0; i<arrayLength; i++) {
            new_GIFT_reserve = new_GIFT_reserve + vaults[i].amount;
        }
        emit updateReserve(
            GIFT_reserve = new_GIFT_reserve,
            Vault_index = _index,
            msg.sender
        );
    }

   

    function retrieveReserve() public view returns (uint256) {
        return (GIFT_reserve);
    }
    

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
