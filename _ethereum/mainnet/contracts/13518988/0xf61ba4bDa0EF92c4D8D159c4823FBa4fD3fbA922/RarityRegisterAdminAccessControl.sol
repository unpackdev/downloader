pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";


contract RarityRegisterAdminAccessControl is AccessControlEnumerable {
  bytes32 public constant RARITY_MANAGER_ROLE = keccak256("RARITY_MANAGER_ROLE");

  address public managerOf;

  event RarityRegisterManagerAdded(address indexed account, address managerOf);
  event RarityRegisterManagerRemoved(address indexed account, address managerOf);
  event RarityManagerAdded(address indexed account, address managerOf);
  event RarityManagerRemoved(address indexed account, address managerOf);

  /**
  * @dev Constructor Add the given account both as the main Admin of the smart contract and a checkpoint admin
  * @param owner The account that will be added as owner
  */
  constructor (address owner, address _managerOf) {
    require(
      owner != address(0),
      "Owner should be a valid address"
    );

    managerOf = _managerOf;

    _setupRole(DEFAULT_ADMIN_ROLE, owner);
    _setupRole(RARITY_MANAGER_ROLE, owner);
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "RarityRegisterAdminAccessControl: Only admin role");
    _;
  }

   modifier onlyRarityManager() {
     require(hasRole(RARITY_MANAGER_ROLE, msg.sender), "RarityRegisterAdminAccessControl: Only rarity manager role");
     _;
   }

  /**
    * @dev checks if the given account is a prizeManager
    * @param account The account that will be checked
    */
   function isRarityManager(address account) public view returns (bool) {
     return hasRole(RARITY_MANAGER_ROLE, account);
   }

   /**
    * @dev Adds a new account to the prizeManager role
    * @param account The account that will have the prizeManager role
    */
   function addRarityManager(address account) public onlyAdmin virtual {
     grantRole(RARITY_MANAGER_ROLE, account);

     emit RarityManagerAdded(account, managerOf);
   }

   /**
    * @dev Removes the sender from the list the prizeManager role
    */
   function renounceRarityManager() public {
     renounceRole(RARITY_MANAGER_ROLE, msg.sender);

     emit RarityManagerRemoved(msg.sender, managerOf);
   }

   /**
    * @dev Removes the given account from the prizeManager role, if msg.sender is admin
    * @param prizeManager The account that will have the prizeManager role removed
    */
   function removeRarityManager(address prizeManager) onlyAdmin public {
     revokeRole(RARITY_MANAGER_ROLE, prizeManager);

     emit RarityManagerRemoved(prizeManager, managerOf);
   }
}