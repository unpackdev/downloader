pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";


contract RaffleAdminAccessControl is AccessControlEnumerable {
  bytes32 public constant RAFFLE_MANAGER_ROLE = keccak256("RAFFLE_MANAGER_ROLE");
  bytes32 public constant PRIZE_MANAGER_ROLE = keccak256("PRIZE_MANAGER_ROLE");

  address public managerOf;

  event RaffleManagerAdded(address indexed account, address managerOf);
  event RaffleManagerRemoved(address indexed account, address managerOf);
  event PrizeManagerAdded(address indexed account, address managerOf);
  event PrizeManagerRemoved(address indexed account, address managerOf);

  /**
  * @dev Constructor Add the given account both as the main Admin of the smart contract and a checkpoint admin
  * @param raffleOwner The account that will be added as raffleOwner
  */
  constructor (address raffleOwner, address _managerOf) {
    require(
      raffleOwner != address(0),
      "Raffle owner should be a valid address"
    );

    managerOf = _managerOf;

    _setupRole(DEFAULT_ADMIN_ROLE, raffleOwner);
    _setupRole(PRIZE_MANAGER_ROLE, raffleOwner);
    _setupRole(RAFFLE_MANAGER_ROLE, raffleOwner);
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "RaffleAdminAccessControl: Only admin role");
    _;
  }

  modifier onlyManager() {
    require(hasRole(RAFFLE_MANAGER_ROLE, msg.sender), "RaffleAdminAccessControl: Only manager role");
    _;
  }

   modifier onlyPrizeManager() {
    require(hasRole(PRIZE_MANAGER_ROLE, msg.sender), "RaffleAdminAccessControl: Only prize manager role");
    _;
  }

  /**
  * @dev Adds a new account to the manager role
  * @param account The account that will have the manager role
  */
  function addRaffleManager(address account) public onlyAdmin {
    grantRole(RAFFLE_MANAGER_ROLE, account);

    emit RaffleManagerAdded(account, managerOf);
  }

  /**
  * @dev Removes the sender from the list the manager role
  */
  function renounceRaffleManager() public {
    renounceRole(RAFFLE_MANAGER_ROLE, msg.sender);

    emit RaffleManagerRemoved(msg.sender, managerOf);
  }

  /**
  * @dev checks if the given account is a prizeManager
  * @param account The account that will be checked
  */
  function isRaffleManager(address account) public view returns (bool) {
    return hasRole(RAFFLE_MANAGER_ROLE, account);
  }

  /**
  * @dev Removes the given account from the manager role, if msg.sender is manager
  * @param manager The account that will have the manager role removed
  */
  function removeRaffleManager(address manager) public onlyAdmin {
    revokeRole(RAFFLE_MANAGER_ROLE, manager);

    emit RaffleManagerRemoved(manager, managerOf);
  }

  /**
    * @dev checks if the given account is a prizeManager
    * @param account The account that will be checked
    */
   function isPrizeManager(address account) public view returns (bool) {
     return hasRole(PRIZE_MANAGER_ROLE, account);
   }

   /**
    * @dev Adds a new account to the prizeManager role
    * @param account The account that will have the prizeManager role
    */
   function addPrizeManager(address account) public onlyAdmin virtual {
     grantRole(PRIZE_MANAGER_ROLE, account);

     emit PrizeManagerAdded(account, managerOf);
   }

   /**
    * @dev Removes the sender from the list the prizeManager role
    */
   function renouncePrizeManager() public {
     renounceRole(PRIZE_MANAGER_ROLE, msg.sender);

     emit PrizeManagerRemoved(msg.sender, managerOf);
   }

   /**
    * @dev Removes the given account from the prizeManager role, if msg.sender is admin
    * @param prizeManager The account that will have the prizeManager role removed
    */
   function removePrizeManager(address prizeManager) onlyAdmin public {
     revokeRole(PRIZE_MANAGER_ROLE, prizeManager);

     emit PrizeManagerRemoved(prizeManager, managerOf);
   }
}