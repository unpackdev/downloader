// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title BCUT_Token contract
 * @dev This is the implementation of the ERC20 BCUT Token.
 * The implementation exposes a Permit() function to allow for a spender to send a signed message
 * and approve funds to a spender following EIP2612 to make integration with other contracts easier.
 *
 * The token is initially owned by the deployer address that can mint tokens to create the initial
 * distribution. For convenience, an initial supply can be passed in the initializer that will be
 * assigned to the deployer.
 *
 */
contract BCUTToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {

    // Define Access Roles
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // -- Events --

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    error RevertedWithMessage(string message);

    /**
     * @dev Event emitted when an new owner is added by admin
     * @param currentOwner is the current owner.
     * @param newOwner is the new owner
    */
    event OwnershipSuggested(address indexed currentOwner, address indexed newOwner);

     /**
     * @dev Event emitted when ownership is updated
     * @param owner is the current owner.
    */
    event OwnershipAccepted(address indexed owner);

    address private pendingAdmin;

    address private currentAdmin;

    /// @custom:oz-upgrades-unsafe-allow constructor
      constructor() {
          _disableInitializers();
    } 

    function initialize(address _rootAdmin, address _to, uint256 _initialSupply) initializer public {
        __ERC20_init("bitsCrunch Token", "BCUT");
        __ERC20Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _rootAdmin);
        _grantRole(MANAGER_ROLE, _rootAdmin);

        _mint(_to, _initialSupply);
    }

    function mint(address to, uint256 amount) public onlyManager {
        _mint(to, amount);
    }

     /**
     * @dev suggest a adminRole to an address.
     * @param _newOwner The address to grant the admin role to.
     */
    function transferOwnership(address _newOwner) public onlyAdmin {
        _checkAndRevert(_newOwner != address(0), "BCUT:New Owner Cant be zero");
        _checkAndRevert(_newOwner != msg.sender, "BCUT:Admin Exists");
        pendingAdmin = _newOwner;
        currentAdmin = msg.sender;

        emit OwnershipSuggested(currentAdmin,pendingAdmin);
    }

     /**
     * @dev New Suggested Admin accepts the ownership
     */
     function acceptOwnership() public onlyPendingAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, pendingAdmin);

        // Revoke the role for the previous admin if it's not address(0)
        if (currentAdmin != address(0)) {
            _revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        }
        currentAdmin = address(0); // Reset the previous admin's address
        pendingAdmin = address(0);

        emit OwnershipAccepted(msg.sender);
    }   

    /**
     * @dev Grants a manager role to an address.
     * @param _address The address to grant the manager role to.
     */
    function grantManagerRole(address _address) external onlyAdmin {
        _checkAndRevert(
            _address != address(0),
            "BCUT: Manager could not be zero address"
        );
        _grantRole(MANAGER_ROLE, _address);
        emit ManagerAdded(_address);
    }

    /**
     * @dev Revokes a manager role from an address.
     * @param _address The address to revoke the manager role from.
     */
    function revokeManagerRole(address _address) external onlyAdmin {
        _checkAndRevert(
            _address != address(0),
            "BCUT: Manager could not be zero address"
        );
        _revokeRole(MANAGER_ROLE, _address);
        emit ManagerRemoved(_address);
    }

    function _checkAndRevert(bool condition, string memory message) internal pure {
        if(!condition){
            revert RevertedWithMessage(message);
        }
    }
   
    function _isAdmin() internal view returns(bool){
        return(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    }

    function _isManager() internal view returns(bool){
        return(hasRole(MANAGER_ROLE, _msgSender()));
    }


    /// @dev Upgrades the implementation of the proxy to new address.
    function _authorizeUpgrade(address) internal override onlyAdmin {}
  
    /**
    * @dev modifier to check admin rights.
    * contract owner and root admin have admin rights
    */
    modifier onlyAdmin(){
        _checkAndRevert(_isAdmin(), "BCUT: Restricted to owner");
        _;
    }

    /**
    * @dev modifier to check pending admin rights.
    */
    modifier onlyPendingAdmin() {
        _checkAndRevert(_msgSender() == pendingAdmin,"BCUT:Caller Not Autherized");
        _;
    }

    /**
    * @dev modifier to check manager rights.
    * contract owner and root admin have rights give or approve manager 
    */
    modifier onlyManager(){
        _checkAndRevert(_isManager() || _isAdmin(), "BCUT: Not Admin or Manager");
        _;
    }

}
