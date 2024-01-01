// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./console.sol";
import "./IBRC_ERC20.sol";


contract BRC_ERC20 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable, IBRC_ERC20 {
    /* ********************************** */
    /*       STORAGE VARIABLES            */
    /* ********************************** */
    //storage reserve for future variables
    uint256[50] __gap;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint public version;
    address currentBaseContract;

    //!!!!!!!!!!!!! new variables should be placed above here !!!!!!!!!!!!!


    /* ********************************** */
    /*            MODIFIERS               */
    /* ********************************** */
    /**
     * Only admin role
     */
    modifier _onlyAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller has not the Amind role!");
        _;
    }

    /* ********************************** */
    /*     PUBLIC FUNCTIONS               */
    /* ********************************** */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("CoinBRL - Brazilian Real Stablecoin", "CBRL");
        __ERC20Burnable_init();
        __AccessControl_init();
        __ERC20Permit_init("CoinBRL - Brazilian Real Stablecoi");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        version = 0;
    }

   

    //ONLY ADMIN CAN MINT 
    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    /**
    * Get Current Version of Base Contract
    */
    function getBaseContract() public view returns (address){
        return currentBaseContract;
    }

    /**
    * Get Current Base Version
    */
    function getVersion() public view returns (uint){
        return version;
    }

    /**
     * Returns allowance
     */
    function getApproval(address _owner, address _operator) public view returns (uint){
        return allowance(_owner, _operator);
    }

    

    /**
     * Verify if address has MINTER role
     */
    function isMinter(address _verifyAddr) 
        public view 
        returns (bool)
    {
        return hasRole(MINTER_ROLE, _verifyAddr);
    } 

    /**
     * Verify if address has ADMIN role
     */
    function isAdmin(address _verifyAddr) 
        public view 
        override
        returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, _verifyAddr);
    } 

    /**
     * Add an address as minter here
     */
    function addMinter(address _newMinter) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override
    {
        _grantRole(MINTER_ROLE, _newMinter);
    } 

    /**
     * Add an address as admin here 
     */
    function addAdmin(address _newAdmin) 
        public onlyRole(DEFAULT_ADMIN_ROLE) 
        override
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    } 

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {
        currentBaseContract = newImplementation;
        version++;
    }
}
