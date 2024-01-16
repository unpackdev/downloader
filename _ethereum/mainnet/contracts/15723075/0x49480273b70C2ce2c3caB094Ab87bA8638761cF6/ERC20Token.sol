// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title ERC20 token
 * @dev Basic ERC20 Implementation, Inherits the OpenZepplin ERC20 implentation.
 */
contract ERC20Token is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable  {
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    mapping (address => bool) internal isBlackListed;
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event AddedBlackList(address indexed _user);
    event RemovedBlackList(address indexed _user);

    /**
     * @notice Contract initialize.
     * @dev Initialize can only be called once.
     * @param name_ Name of the token.
     * @param symbol_ Symbol of the token
     * @param initialBalance The amount to mint to contract deployer.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 initialBalance
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __Pausable_init();
        __AccessControl_init();
        _setRoleAdmin(GUARDIAN_ROLE, GUARDIAN_ROLE);
        _setRoleAdmin(TIMELOCK_ROLE, TIMELOCK_ROLE);
        _setRoleAdmin(MINTER_ROLE, TIMELOCK_ROLE);

        _grantRole(GUARDIAN_ROLE, msg.sender);
        _grantRole(TIMELOCK_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _mint(msg.sender, initialBalance * 10 ** decimals());
    }

    /**
     * @notice Implements Guardian role.
     */
    modifier onlyGuardian() {
        require(hasRole(GUARDIAN_ROLE, msg.sender), "Restricted to guardian");
        _;
    }

    /**
     * @notice Implements Timelock role.
     */
    modifier onlyTimelock() {
        require(hasRole(TIMELOCK_ROLE, msg.sender), "Restricted to timelock");
        _;
    }

    /**
     * @notice Implements Minter role.
     */
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Restricted to minter");
        _;
    }

    /**
     * @notice Throw if argument _addr is blacklisted.
     * @param _addr The address to check
     */
    modifier notBlacklisted(address _addr) {
        require(
            !isBlackListed[_addr],
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    /**
     * @notice Changes the guardian address
     * @param newGuardian New guardian address
     * @param oldGuardian Old guardian address
     */ 
    function setGuardian(address newGuardian, address oldGuardian) external onlyGuardian {
        require(newGuardian != address(0), "newGuardian cannot be the zero address");
        require(oldGuardian != address(0), "oldGuardian cannot be the zero address");
        _revokeRole(GUARDIAN_ROLE, oldGuardian);
        _grantRole(GUARDIAN_ROLE, newGuardian);
    }

    /**
     * @notice Revokes the guardian address
     * @param oldGuardian Guardian address to revoke
     */ 
    function revokeGuardian(address oldGuardian) external onlyGuardian {
        require(oldGuardian != address(0), "oldGuardian be the zero address");
        _revokeRole(GUARDIAN_ROLE, oldGuardian);
    }

    /**
     * @notice Changes the timelock address
     * @param newTimelock timelock address
     * @param oldTimelock Old timelock address
     */ 
    function setTimelock(address newTimelock, address oldTimelock) external onlyTimelock {
        require(newTimelock != address(0), "newTimelock cannot be the zero address");
        require(oldTimelock != address(0), "oldTimelock cannot be the zero address");
        _revokeRole(TIMELOCK_ROLE, oldTimelock);
        _grantRole(TIMELOCK_ROLE, newTimelock);
    }

    /**
     * @notice Revokes the timelock address
     * @param oldTimelock timelock address to revoke
     */ 
    function revokeTimelock(address oldTimelock) external onlyTimelock {
        require(oldTimelock != address(0), "oldTimelock be the zero address");
        _revokeRole(TIMELOCK_ROLE, oldTimelock);
    }

    /**
     * @notice Changes the minter address
     * @param newMinter New minter address
     * @param oldMinter Old minter address
     */ 
    function setMinter(address newMinter, address oldMinter) external onlyTimelock {
        require(newMinter != address(0), "newMinter cannot be the zero address");
        require(oldMinter != address(0), "oldMinter cannot be the zero address");
        _revokeRole(MINTER_ROLE, oldMinter);
        _grantRole(MINTER_ROLE, newMinter);
    }

    /**
     * @notice Revokes the minter address
     * @param oldMinter minter address to revoke
     */ 
    function revokeMinter(address oldMinter) external onlyTimelock {
        require(oldMinter != address(0), "oldMaster be the zero address");
        _revokeRole(MINTER_ROLE, oldMinter);
    }

    /**
     * @notice pause
     * @dev pause the contract
     */
    function pause() external onlyGuardian {
        _pause();
    }

    /**
     * @notice unpause
     * @dev unpause the contract
     */
    function unpause() external onlyGuardian {
        _unpause();
    }

    /**
     * @notice Mint amount of tokens.
     * @dev Function to mint tokens to specific account.
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     * Emits an {Mint} event.
     */
    function mint(address account, uint256 amount) external onlyMinter whenNotPaused notBlacklisted(account) {
        _mint(account, amount);
        emit Mint(account, amount);
    }

    /**
     * @notice Burns `amount` tokens from a `burner` address
     * @dev Function to burn tokens.
     * @param burner Address to burn from
     * @param amount The amount of tokens to burn
     * Emits an {Burn} event.
     */
    function burn(address burner, uint256 amount) external onlyMinter whenNotPaused {
        _burn(burner, amount);
        emit Burn(burner, amount);
    }

    /**
     * @notice Override _transfer to add whenNotPaused and notBlacklisted check.
     * @dev Make a function callable only when the contract is not paused
     * and account is not blacklisted.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused notBlacklisted(sender) notBlacklisted(recipient) virtual override {
        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice Add suspicious account to blacklist.
     * @dev Function to add suspicious account to blacklist, 
     * Only callable by contract owner.
     * @param evilUser The address that will add to blacklist
     * Emits an {AddedBlackList} event.
     */
    function addBlackList(address evilUser) public onlyGuardian {
        isBlackListed[evilUser] = true;
        emit AddedBlackList(evilUser);
    }

    /**
     * @notice Remove suspicious account from blacklist.
     * @dev Function to remove suspicious account from blacklist, 
     * Only callable by contract owner.
     * @param clearedUser The address that will remove from blacklist
     * Emits an {RemovedBlackList} event.
     */
    function removeBlackList(address clearedUser) public onlyGuardian {
        isBlackListed[clearedUser] = false;
        emit RemovedBlackList(clearedUser);
    }

    /**
     * @notice Address blacklisted check.
     * @dev Function to check address whether get blacklisted, 
     * Only callable by contract owner.
     * @param addr The address that will check whether get blacklisted
     */
    function getBlacklist(address addr) public onlyGuardian view returns(bool) {
        return isBlackListed[addr];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}