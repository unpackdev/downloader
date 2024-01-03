// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./Address.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";

/**
 * @title A contract to manage the cap table for an alternative asset
 * @author @ScalingFunds Engineering Team
 */
contract ScalingFundsToken is ERC20Snapshot, AccessControl {
  bool public areInvestorTransfersDisabled;
  bool public isCapTableLocked;
  bool public isTokenLaunched;
  bool public isTokenDead;

  bytes32 public constant SCALINGFUNDS_AGENT = keccak256("SCALINGFUNDS_AGENT");
  bytes32 public constant TRANSFER_AGENT = keccak256("TRANSFER_AGENT");
  bytes32 public constant ALLOWLISTED_INVESTOR =
    keccak256("ALLOWLISTED_INVESTOR");

  ScalingFundsToken internal _previousContract;

  /**********/
  /* EVENTS */
  /**********/

  /**
   * @notice Emitted when transfers between investors are disabled
   * @param caller Address that called the function
   */
  event InvestorTransfersDisabled(address indexed caller);

  /**
   * @notice Emitted when transfers between investors are enabled
   * @param caller Address that called the function
   */
  event InvestorTransfersEnabled(address indexed caller);

  /**
   * @notice Emitted when the CapTable is locked preventing transfers
   * @param caller Address that called the function
   */
  event CapTableLocked(address indexed caller);

  /**
   * @notice Emitted when the CapTable is unlocked allowing transfers
   * @param caller Address that called the function
   */
  event CapTableUnlocked(address indexed caller);

  /**
   * @notice Emitted when the Token is launched
   * @param caller Address that called the function
   */
  event TokenLaunched(address indexed caller);

  /**
   * @notice Emitted when the token is killed
   * @param caller Address that called the function
   * @param reason Reason for killing the token
   */
  event TokenKilled(address indexed caller, string reason);

  /**
   * @notice Emitted when a transfer of tokens is forced from one address to another
   * @param from Address that is sending tokens
   * @param to Address that is receiving tokens
   * @param amount Amount of tokens that were transferred
   * @param reason Reason for conducting force-transfer
   */
  event ForcedTransfer(
    address indexed from,
    address indexed to,
    uint256 amount,
    string reason
  );

  /**
   * @notice Emitted when _previousContract is linked
   * @param previousContractAddress Address of the previous contract that was previously tracking the cap table of this asset
   */
  event PreviousContractLinked(address indexed previousContractAddress);

  /*************/
  /* MODIFIERS */
  /*************/

  /**
   * @notice Modified function is only callable when investor transfers are enabled
   * @dev Used to prevent transfers between investors
   */
  modifier whenInvestorTransfersAreEnabled() {
    require(!areInvestorTransfersDisabled, "Investor Transfers are disabled");
    _;
  }

  /**
   * @notice Modified function is only callable when cap table is unlocked
   * @dev Used to prevent all changes to the cap table
   */
  modifier whenCapTableIsUnlocked() {
    require(!isCapTableLocked, "CapTable is locked");
    _;
  }

  /**
   * @notice Modified function is only callable BEFORE token has launched
   * @dev Used to migrate roles and balances from a previous token
   */
  modifier onlyBeforeLaunch() {
    require(!isTokenLaunched, "Token is already launched");
    _;
  }

  /**
   * @notice Modified function is only callable AFTER token has launched
   * @dev Used to prevent calling non-migration functions before token is launched
   */
  modifier onlyAfterLaunch() {
    require(isTokenLaunched, "Token is not yet launched");
    _;
  }

  /**
   * @notice Modified function is only callable when the token is active
   * @dev Used to prevent any state changes on a dead token
   */
  modifier whenTokenIsActive() {
    require(!isTokenDead, "Token is dead");
    _;
  }

  /**
   * @notice Modified function is only callable by a SCALINGFUNDS_AGENT
   * @dev Used for launching the token, migrations and, if need be, killing the token
   */
  modifier onlyScalingFundsAgent {
    require(
      super.hasRole(SCALINGFUNDS_AGENT, msg.sender),
      "Caller does not have SCALINGFUNDS_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function's `account` param can NOT be a SCALINGFUNDS_AGENT
   * @param account The address to check
   * @dev Used to prevent ScalingFunds agents to become transfer agents or allowlisted investors
   */
  modifier isNotScalingFundsAgent(address account) {
    require(
      !super.hasRole(SCALINGFUNDS_AGENT, account),
      "account cannot have SCALINGFUNDS_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function is only callable by a TRANSFER_AGENT
   * @dev Used for all transfer agent responsibilities such as managing the allowlist, locking the cap table, or conducting a force-transfer
   */
  modifier onlyTransferAgent {
    require(
      super.hasRole(TRANSFER_AGENT, msg.sender),
      "Caller does not have TRANSFER_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function's `account` param can NOT be a TRANSFER_AGENT
   * @param account The address to check
   * @dev Used to prevent transfer agents to become ScalingFunds agents or allowlisted investors
   */
  modifier isNotTransferAgent(address account) {
    require(
      !super.hasRole(TRANSFER_AGENT, account),
      "account cannot have TRANSFER_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function is only callable by a TRANSFER_AGENT or SCALINGFUNDS_AGENT
   * @dev Used to enable transfer agents and ScalingFunds agents to easily retrieve all allowlisted investors or all transfer agents
   */
  modifier onlyTransferAgentOrScalingFundsAgent {
    require(
      super.hasRole(TRANSFER_AGENT, msg.sender) ||
        super.hasRole(SCALINGFUNDS_AGENT, msg.sender),
      "Caller does not have TRANSFER_AGENT or SCALINGFUNDS_AGENT role"
    );
    _;
  }

  /**
   * @notice Modified function's `account` param must be an ALLOWLISTED_INVESTOR
   * @param account Investor address to check
   */
  modifier isAllowlistedInvestor(address account) {
    require(
      super.hasRole(ALLOWLISTED_INVESTOR, account),
      "account does not have ALLOWLISTED_INVESTOR role"
    );
    _;
  }

  /**
   * @notice Modified function's `account` param can NOT be an ALLOWLISTED_INVESTOR
   * @param account Investor address to check
   */
  modifier isNotAllowlistedInvestor(address account) {
    require(
      !super.hasRole(ALLOWLISTED_INVESTOR, account),
      "account cannot have ALLOWLISTED_INVESTOR role"
    );
    _;
  }

  /*************/
  /* FUNCTIONS */
  /*************/

  /**
   * @notice Initializes the token and sets up the initial roles
   * @param name ERC20 name of the deployed token
   * @param symbol ERC20 symbol ot the deployed token
   * @param transferAgent Address of the first transfer agent
   * @param scalingFundsAgent Address of the first ScalingFunds agent
   * @dev - All tokens are initialized in pre-launch mode to allow for potential migrations to happen
   * - All tokens have investor-transfers disabled by default and must be explicitly enabled by the transfer agent, if desired.
   */
  constructor(
    string memory name,
    string memory symbol,
    address transferAgent,
    address scalingFundsAgent
  ) ERC20(name, symbol) {
    areInvestorTransfersDisabled = true;
    isCapTableLocked = false;
    isTokenDead = false;
    isTokenLaunched = false;

    super._setupRole(TRANSFER_AGENT, transferAgent);
    super._setupRole(SCALINGFUNDS_AGENT, scalingFundsAgent);

    super._setRoleAdmin(SCALINGFUNDS_AGENT, SCALINGFUNDS_AGENT);
    super._setRoleAdmin(TRANSFER_AGENT, TRANSFER_AGENT);
    super._setRoleAdmin(ALLOWLISTED_INVESTOR, TRANSFER_AGENT);
  }

  /*****************/
  /* STATE CONTROL */
  /*****************/

  /**
   * @notice Disables transfers between investors
   * @dev - Used to temporarily disable all transfers between investors
   * - Transfer agents are not affected by this and can continue to manage the cap table.
   * - Emits {InvestorTransfersDisabled} event
   *
   * Can only be called:
   * - by transfer agents
   * - when investor-transfers are enabled
   * - AFTER token has launched
   * - when token is active (NOT dead)
   */
  function disableInvestorTransfers()
    external
    onlyTransferAgent
    whenTokenIsActive
    onlyAfterLaunch
    whenInvestorTransfersAreEnabled
  {
    areInvestorTransfersDisabled = true;
    emit InvestorTransfersDisabled(msg.sender);
  }

  /**
   * @notice Enables transfer between investors
   * @dev - Used to enable allowlisted investors to transfer tokens with each other
   * - Emits {InvestorTransfersEnabled} event
   *
   * Can only be called:
   *
   * - by transfer agents
   * - AFTER token has launched
   * - when token is active (NOT dead)
   */
  function enableInvestorTransfers()
    external
    onlyTransferAgent
    whenTokenIsActive
    onlyAfterLaunch
  {
    require(areInvestorTransfersDisabled, "Investor Transfers are enabled");
    areInvestorTransfersDisabled = false;
    emit InvestorTransfersEnabled(msg.sender);
  }

  /**
   * @notice Locks the cap table
   * @dev - Used to effectively "freeze" the cap table and prevent all balance changes, for example when conducting dividend payouts
   * - Emits {CapTableLocked} event
   *
   * Can only be called:
   * - by transfer agents
   * - when cap table is unlocked
   * - AFTER token has launched
   * - when token is active (NOT dead)
   */
  function lockCapTable()
    external
    onlyTransferAgent
    whenTokenIsActive
    onlyAfterLaunch
    whenCapTableIsUnlocked
  {
    isCapTableLocked = true;
    emit CapTableLocked(msg.sender);
  }

  /**
   * @notice Unlocks the cap table
   * @dev - Used to "unfreeze" the cap table and re-enable balance changes, for example after conducting dividend payouts
   * - Emits {CapTableUnlocked} event
   *
   * Can only be called:
   * - by transfer agents
   * - when token is active (NOT dead)
   * - AFTER token has launched
   */
  function unlockCapTable()
    external
    onlyTransferAgent
    whenTokenIsActive
    onlyAfterLaunch
  {
    require(isCapTableLocked, "CapTable is already unlocked");
    isCapTableLocked = false;
    emit CapTableUnlocked(msg.sender);
  }

  /**
   * @notice Launches the token after intialisation (and optional migration) is complete
   * @dev - This action is irreversible, a token can not be "unlaunched" to return to the pre-launch phase
   * - Emits {TokenLaunched} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   * - when token is active (NOT dead)
   */
  function launchToken()
    external
    onlyScalingFundsAgent
    whenTokenIsActive
    onlyBeforeLaunch
  {
    isTokenLaunched = true;
    emit TokenLaunched(msg.sender);
  }

  /**
   * @notice Kills and permanently deactivates the token
   * @param reason A short comment on why the token is being killed
   * @dev - Used after the managed asset has reached its end of life, or when migrating the cap table to a new contract
   * - Emits {TokenKilled} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - before OR after token has launched
   * - when token is active (NOT dead)
   */
  function killToken(string calldata reason)
    external
    onlyScalingFundsAgent
    whenTokenIsActive
  {
    bytes memory reasonAsBytes = bytes(reason);
    require(reasonAsBytes.length > 0, "reason string is empty");
    isTokenDead = true;
    emit TokenKilled(msg.sender, reason);
  }

  /**
   * @notice Takes a snapshot of the current balances
   * @dev - Used to simplify contract migrations, or to take cap table snapshots ahead of dividend payouts and similar corporate actions
   * - Emits {Snapshot} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - before OR after token has launched
   */
  function takeSnapshot() external onlyScalingFundsAgent returns (uint256) {
    return super._snapshot();
  }

  /*********/
  /* ERC20 */
  /*********/

  /**
   * @notice Issues tokens to allowlisted investors
   * @param to Investor address to issue tokens to
   * @param amount Amount of tokens to issue
   * @dev - Emits {Transfer} event
   *
   * Can only be called:
   * - by transfer agents
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function mint(address to, uint256 amount)
    public
    onlyAfterLaunch
    onlyTransferAgent
    isAllowlistedInvestor(to)
    returns (bool)
  {
    super._mint(to, amount);
    return true;
  }

  /**
   * @notice Redeems tokens for investors by burning them
   * @param account Investor address to redeem tokens from
   * @param amount Amount of tokens to redeem
   * @dev - Emits {Transfer} event
   *
   * Can only be called:
   * - by transfer agents
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function burn(address account, uint256 amount)
    public
    onlyAfterLaunch
    onlyTransferAgent
    returns (bool)
  {
    super._burn(account, amount);
    return true;
  }

  /**
   * @notice Issues tokens to allowlisted investors in batch
   * @param accounts Investor addresses to issue tokens to
   * @param amounts Amounts of tokens to issue to each address at same index
   * @dev - Emits {Transfer} events
   *
   * Can only be called:
   * - by transfer agents
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function batchMint(address[] calldata accounts, uint256[] calldata amounts)
    external
    onlyAfterLaunch
    onlyTransferAgent
    returns (bool)
  {
    require(
      (accounts.length == amounts.length),
      "accounts and amounts do not have the same length"
    );
    for (uint256 i = 0; i < accounts.length; i++) {
      mint(accounts[i], amounts[i]);
    }
    return true;
  }

  /**
   * @notice ERC20 Transfer function override that prevents transfers from or to non-allowlisted addresses
   * @param to Recipient's address
   * @param amount Amount of tokens to transfer
   * @dev - Transfers will be rejected when TransferAgent has disabled transfers between investors
   * - Emits {Transfer} event
   *
   * Can only be called:
   * - by allowlisted investors
   * - when investor-transfers are enabled
   * - if `to` address is also allowlisted
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function transfer(address to, uint256 amount)
    public
    override
    whenInvestorTransfersAreEnabled
    isAllowlistedInvestor(msg.sender)
    isAllowlistedInvestor(to)
    returns (bool)
  {
    return super.transfer(to, amount);
  }

  /**
   * @notice Force-transfer tokens
   * @param from Previous token holder
   * @param to New token holder
   * @param amount Amount of tokens to transfer
   * @param reason Reason for conducting a force-transfer
   * @dev - Used to enable transfer agents to comply with court orders or other legal transfer requests
   * - Emits {ForcedTransfer} event
   *
   * Can only be called:
   * - by transfer agents
   * - if `from` and `to` address are both allowlisted
   * - if a `reason` for the force-transfer has been given
   * - AFTER token has launched
   * - when token is active and cap table is unlocked (via `_beforeTokenTransfer` hook)
   */
  function forceTransfer(
    address from,
    address to,
    uint256 amount,
    string memory reason
  )
    external
    onlyAfterLaunch
    onlyTransferAgent
    isAllowlistedInvestor(from)
    isAllowlistedInvestor(to)
    returns (bool)
  {
    bytes memory reasonAsBytes = bytes(reason);
    require(reasonAsBytes.length > 0, "reason string is empty");
    super._transfer(from, to, amount);
    emit ForcedTransfer(from, to, amount, reason);
    return true;
  }

  /**
   * @notice ERC20 BeforeTokenTransfer override that prevents all transfers when cap tab is locked or token is dead
   * @param from Sender address
   * @param to Recipient address
   * @param amount Amount of tokens to transfer
   * @dev - This hook is always called before any transfer (including minting and burning which in Ethereum are effectively transfer FROM or TO the zero-address)
   *
   * Can only be called:
   * - when token is active
   * - cap table is unlocked
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenTokenIsActive whenCapTableIsUnlocked {
    super._beforeTokenTransfer(from, to, amount);
  }

  /************************************/
  /* ACCESS CONTROL & ROLE MANAGEMENT */
  /************************************/

  /**
   * @notice Adds an individual investor to the allowlist
   * @param account Investor address to add to the allowlist
   * @dev - Emits {RoleGranted} event
   *
   * Can only be called:
   * - by transfer agents
   * - if `account` is not a transfer agent or a ScalingFunds agent
   */
  function addInvestorToAllowlist(address account)
    public
    onlyTransferAgent
    isNotTransferAgent(account)
    isNotScalingFundsAgent(account)
    returns (bool)
  {
    require(account != address(0), "Zero address cannot be allowlisted");
    super.grantRole(ALLOWLISTED_INVESTOR, account);
    return true;
  }

  /**
   * @notice Removes an individual investor from the allowlist
   * @param account Investor address to remove from the allowlist
   * @dev - Emits {RoleRevoked} event
   *
   * Can only be called:
   * - by transfer agents
   */
  function removeInvestorFromAllowlist(address account)
    public
    onlyTransferAgent
    returns (bool)
  {
    super.revokeRole(ALLOWLISTED_INVESTOR, account);
    return true;
  }

  /**
   * @notice Adds investors to the allowlist in batch
   * @param accounts List of investor addresses to add to the allowlist
   * @dev - Emits {RoleGranted} events
   *
   * Can only be called:
   * - by transfer agents
   */
  function batchAddInvestorsToAllowlist(address[] calldata accounts)
    public
    onlyTransferAgent
    returns (bool)
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      addInvestorToAllowlist(accounts[i]);
    }
    return true;
  }

  /**
   * @notice Removes investors from the allowlist in batch
   * @param accounts List of investor addresses to remove from the allowlist
   * @dev - Emits {RoleRevoked} events
   *
   * Can only be called:
   * - by transfer agents
   */
  function batchRemoveInvestorsFromAllowlist(address[] calldata accounts)
    public
    onlyTransferAgent
    returns (bool)
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      removeInvestorFromAllowlist(accounts[i]);
    }
    return true;
  }

  /**
   * @notice Gets all allowlisted investors
   * @dev - Used for migrations and reconciling on-chain with off-chain data
   *
   * Can only be called:
   * - by transfer agents
   * - by ScalingFunds agents
   */
  function getAllAllowlistedInvestors()
    external
    view
    onlyTransferAgentOrScalingFundsAgent
    returns (address[] memory)
  {
    uint256 investorCount = super.getRoleMemberCount(ALLOWLISTED_INVESTOR);
    address[] memory allowlistedInvestors = new address[](investorCount);
    for (uint256 i = 0; i < investorCount; i++) {
      address _investor = super.getRoleMember(ALLOWLISTED_INVESTOR, i);
      allowlistedInvestors[i] = _investor;
    }
    return allowlistedInvestors;
  }

  /**
   * @notice Adds a new transfer agent
   * @param account Address to grant TRANSFER_AGENT role to
   * @dev - Emits {RoleGranted} event
   *
   * Can only be called:
   * - by transfer agents
   * - if `account` is not an allowlisted investor
   * - if `account` is not a ScalingFunds agent
   * - if `account` is not the zero address
   */
  function addTransferAgent(address account)
    external
    onlyTransferAgent
    isNotAllowlistedInvestor(account)
    isNotScalingFundsAgent(account)
  {
    require(account != address(0), "Transfer agent cannot be zero address");
    super.grantRole(TRANSFER_AGENT, account);
  }

  /**
   * @notice Removes a transfer agent
   * @param account Address to revoke TRANSFER_AGENT role from
   * @dev - Emits {RoleRevoked} event
   *
   * Can only be called:
   * - by transfer agents
   */
  function removeTransferAgent(address account) external onlyTransferAgent {
    super.revokeRole(TRANSFER_AGENT, account);
  }

  /**
   * @notice Gets all transfer agents
   * @dev - Used for migrations and reconciling on-chain with off-chain data
   *
   * Can only be called:
   * - by transfer agents
   * - by ScalingFunds agents
   */
  function getAllTransferAgents()
    external
    view
    onlyTransferAgentOrScalingFundsAgent
    returns (address[] memory)
  {
    uint256 transferAgentCount = super.getRoleMemberCount(TRANSFER_AGENT);
    address[] memory transferAgents = new address[](transferAgentCount);
    for (uint256 i = 0; i < transferAgentCount; i++) {
      address _transferAgent = super.getRoleMember(TRANSFER_AGENT, i);
      transferAgents[i] = _transferAgent;
    }
    return transferAgents;
  }

  /**
   * @notice Adds a ScalingFunds agent
   * @param account Address to grant SCALINGFUNDS_AGENT role to
   * @dev - Emits {RoleGranted} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - if `account` is not an allowlisted investor
   * - if `account` is not a transfer agent
   * - if `account` is not the zero address
   */
  function addScalingFundsAgent(address account)
    external
    onlyScalingFundsAgent
    isNotAllowlistedInvestor(account)
    isNotTransferAgent(account)
  {
    require(
      (account != address(0)),
      "ScalingFunds agent cannot be zero address"
    );
    super.grantRole(SCALINGFUNDS_AGENT, account);
  }

  /**
   * @notice Removes a ScalingFunds agent
   * @param account Address to revoke SCALINGFUNDS_AGENT role from
   * @dev - Emits {RoleRevoked} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   */
  function removeScalingFundsAgent(address account)
    external
    onlyScalingFundsAgent
  {
    super.revokeRole(SCALINGFUNDS_AGENT, account);
  }

  /**
   * @notice Gets all Scalingfunds agents
   * @dev - Used for migrations and reconciling on-chain with off-chain data
   *
   * Can only be called:
   * - by ScalingFunds agents
   */
  function getAllScalingFundsAgents()
    external
    view
    onlyScalingFundsAgent
    returns (address[] memory)
  {
    uint256 scalingfundAgentCount =
      super.getRoleMemberCount(SCALINGFUNDS_AGENT);
    address[] memory scalingfundAgents = new address[](scalingfundAgentCount);
    for (uint256 i = 0; i < scalingfundAgentCount; i++) {
      address _scalingFundsAgent = super.getRoleMember(SCALINGFUNDS_AGENT, i);
      scalingfundAgents[i] = _scalingFundsAgent;
    }
    return scalingfundAgents;
  }

  /**********************/
  /* CONTRACT MIGRATION */
  /**********************/

  /**
   * @notice Links this token to a predecessor token that was previously tracking this asset's CapTable
   * @param _previousContractAddress Previous contract to link to
   * @dev - Used to keep audit trail intact in case of a contract migration
   * - Emits {PreviousContractLinked} event
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - if `_previousContract` is not already linked
   * - if `_previousContractAddress` is a smart contract (NOT an individual wallet)
   * - BEFORE token has launched
   */
  function linkPreviousContract(address _previousContractAddress)
    external
    onlyScalingFundsAgent
    onlyBeforeLaunch
  {
    require(
      address(_previousContract) == address(0),
      "_previousContract can only be linked once"
    );

    require(
      Address.isContract(_previousContractAddress),
      "_previousContractAddress must be a contract"
    );

    _previousContract = ScalingFundsToken(_previousContractAddress);

    emit PreviousContractLinked(_previousContractAddress);
  }

  function previousContractAddress() external view returns (address) {
    return address(_previousContract);
  }

  /**
   * @notice Migrates initial list of transfer agents
   * @param transferAgents List of addresses to grant TRANSFER_AGENT role to
   * @dev - Emits {RoleGranted} events
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   */
  function migrateTransferAgents(address[] calldata transferAgents)
    external
    onlyScalingFundsAgent
    onlyBeforeLaunch
  {
    for (uint256 i = 0; i < transferAgents.length; i++) {
      super._setupRole(TRANSFER_AGENT, transferAgents[i]);
    }
  }

  /**
   * @notice Migrates initial list of allowlisted investors
   * @param investors List of addresses to grant ALLOWLISTED_INVESTOR role to
   * @dev - Emits {RoleGranted} events
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   */
  function migrateAllowlistedInvestors(address[] calldata investors)
    external
    onlyScalingFundsAgent
    onlyBeforeLaunch
  {
    for (uint256 i = 0; i < investors.length; i++) {
      super._setupRole(ALLOWLISTED_INVESTOR, investors[i]);
    }
  }

  /**
   * @notice Migrates initial list of ScalingFunds agents
   * @param scalingFundsAgents List of addresses to grant SCALINGFUNDS_AGENT role to
   * @dev - Emits {RoleGranted} event for every ScalingFunds agent address
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   */
  function migrateScalingFundsAgents(address[] calldata scalingFundsAgents)
    external
    onlyScalingFundsAgent
    onlyBeforeLaunch
  {
    for (uint256 i = 0; i < scalingFundsAgents.length; i++) {
      super._setupRole(SCALINGFUNDS_AGENT, scalingFundsAgents[i]);
    }
  }

  /**
   * @notice Migrates balances from a snapshot of the previousContract
   * @param investors List of investors to migrate balances for
   * @param snapshotId Snapshot ID on the previousContract
   * @dev - Emits {Transfer} event for every migrated balance
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   */
  function migrateBalancesFromSnapshot(
    address[] calldata investors,
    uint256 snapshotId
  ) external onlyScalingFundsAgent onlyBeforeLaunch {
    for (uint256 i = 0; i < investors.length; i++) {
      address investor = investors[i];
      uint256 balance = super.balanceOf(investor);
      uint256 snapshotBalance =
        _previousContract.balanceOfAt(investor, snapshotId);
      // reset investor balance to zero for safety (e.g. avoids the case where `migrateBalances()` was called before already)
      if (balance > 0) {
        super._burn(investor, balance);
      }
      super._mint(investor, snapshotBalance);
    }
  }

  /**
   * @notice Migrates balances of investors from an off-chain source
   * @param investors List of investors to migrate balances for
   * @param balances Matching list of balances for each investor
   * @dev - Emits {Transfer} event for every migrated balance
   *
   * Can only be called:
   * - by ScalingFunds agents
   * - BEFORE token has launched
   * - if the `investors` list and the `balances` list have the same length
   */
  function migrateBalances(
    address[] calldata investors,
    uint256[] calldata balances
  ) external onlyScalingFundsAgent onlyBeforeLaunch returns (bool) {
    require(
      (investors.length == balances.length),
      "investors and balances do not have the same length"
    );
    for (uint256 i = 0; i < balances.length; i++) {
      address investor = investors[i];
      uint256 newBalance = balances[i];
      uint256 currentBalance = super.balanceOf(investor);
      // reset investor balance to zero for safety (e.g. avoids the case where `migrateBalancesFromSnapshot()` was called before already)
      if (currentBalance > 0) {
        super._burn(investor, currentBalance);
      }
      super._mint(investor, newBalance);
    }
    return true;
  }

  /********************************/
  /* ERC20 UNSUPPORTED OPERATIONS */
  /********************************/

  /**
   * @notice `transferFrom` is not supported in this contract
   */
  function transferFrom(
    address,
    address,
    uint256
  ) public pure override returns (bool) {
    revert("Operation Not Supported");
  }

  /**
   * @notice `approve` is not supported in this contract
   */
  function approve(address, uint256) public pure override returns (bool) {
    revert("Operation Not Supported");
  }

  /**
   * @notice `allowance` is not supported in this contract
   */
  function allowance(address, address) public pure override returns (uint256) {
    revert("Operation Not Supported");
  }

  /**
   * @notice `increaseAllowance` is not supported in this contract
   */
  function increaseAllowance(address, uint256)
    public
    pure
    override
    returns (bool)
  {
    revert("Operation Not Supported");
  }

  /**
   * @notice `dereaseAllowance` is not supported in this contract
   */
  function decreaseAllowance(address, uint256)
    public
    pure
    override
    returns (bool)
  {
    revert("Operation Not Supported");
  }

  /***************************************/
  /* AcessControl UNSUPPORTED OPERATIONS */
  /***************************************/
  /**
   * @notice `renounceRole` is not supported in this contract
   */
  function renounceRole(bytes32, address) public pure override {
    revert("Operation Not Supported");
  }

  /**
   * @notice `grantRole` is not supported in this contract
   */
  function grantRole(bytes32, address) public pure override {
    revert("Operation Not Supported");
  }
}
