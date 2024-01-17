// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";

contract InrToken is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable
{
    // @notice Roles for contract functionality
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

    /// @dev Maximum amount of tokens, which minter can mint in 1 week.
    uint256 public mintLimit;

    /// @notice Info of each minters.
    struct MinterInfo {
        uint256 minted;
        uint256 allowedTime;
    }

    /// @notice address => minter info
    mapping(address => MinterInfo) public mintersInfo;

    /// @dev address -> true - in black list, false - not in black list.
    mapping(address => bool) public blackList;

    // events
    event BlackList(address user, bool blackListed);
    event ChangeLimit(uint256 newLimit);

    // errors
    error BlackListed();
    error MintLimit();
    error NotMinterOrTreasurer();
    error NotBurnerOrTreasurer();
    error ZeroAddress();

    /// @param _name Name of the Token.
    /// @param _symbol Symbol of the Token.
    /// @param _to Address to which preminted amount will be transfered.
    /// @param _amount Amount of preminted tokens.
    /// @dev During creation of the contract, mint limit will be set to 5m tokens.
    /// @dev Premints tokens to address.
    function initialize(
        string memory _name,
        string memory _symbol,
        address _to,
        uint256 _amount
    ) external initializer {
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init(_name);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        mintLimit = 5e24;

        _mint(_to, _amount);
    }

    /// @notice Stops mint, burn and transfer functionality in contract
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Return contract to normal state
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Changes maximum limit for minters
    /// @param _amount Amount for a week for a minter
    function changeMintLimit(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintLimit = _amount;

        emit ChangeLimit(_amount);
    }

    /// @dev Mint tokens can only Minter or Treasurer
    /// @notice Checks limit of minters and update it if necessary
    /// @param to Address to which should tokens be minted
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external {
        if (!_minterOrTreasurer(msg.sender)) revert NotMinterOrTreasurer();

        MinterInfo storage minter = mintersInfo[msg.sender];

        if (block.timestamp > minter.allowedTime) {
            minter.minted = 0;
            minter.allowedTime = block.timestamp + 7 days;
        }
        if (amount + minter.minted > mintLimit) revert MintLimit();
        minter.minted += amount;

        _mint(to, amount);
    }

    /// @notice Burn tokens from msg.sender
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @dev Burn tokens from user can only Burner or Treasurer
    /// @dev Needs allowance from user to burn tokens
    /// @notice Burn tokens from user
    /// @param from Address from which tokens should be burned
    /// @param amount Amount of tokens to burn
    function burnFrom(address from, uint256 amount) external {
        if (!_burnerOrTreasurer(msg.sender)) revert NotBurnerOrTreasurer();

        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    /// @dev Only BlackLister could add user to black list
    /// @notice Add user to black list
    /// @param user Address to add to black list
    function addToBlackList(address user) external onlyRole(BLACKLISTER_ROLE) {
        if (user == address(0)) revert ZeroAddress();

        blackList[user] = true;
        emit BlackList(user, true);
    }

    /// @dev Only WhiteLister could remove user from black list
    /// @notice Remove user from black list
    /// @param user Address to remove from black list
    function removeFromBlackList(address user) external onlyRole(WHITELISTER_ROLE) {
        if (user == address(0)) revert ZeroAddress();

        blackList[user] = false;
        emit BlackList(user, false);
    }

    /// @notice Check if user is in black list
    /// @param user Address to check in black list
    /// @return true if user in black list
    function isBlackListed(address user) public view returns (bool) {
        return blackList[user];
    }

    /// @notice Check amount which minter can mint
    /// @param _minter Address to check in black list
    /// @return _mintLimit amount of tokens, that minter can mint
    function avaliableToMint(address _minter) external view returns (uint256 _mintLimit) {
        if (block.timestamp > mintersInfo[_minter].allowedTime) return mintLimit;
        if (mintersInfo[_minter].minted < mintLimit) {
            return mintLimit - mintersInfo[_minter].minted;
        }
        return 0;
    }

    /// @dev Check if account has Minter or Treasurer role
    /// @param _account Address to check the role
    /// @return res true if has one of the roles
    function _minterOrTreasurer(address _account) internal view returns (bool res) {
        return hasRole(MINTER_ROLE, _account) || hasRole(TREASURER_ROLE, _account);
    }

    /// @dev Check if account has Burner or Treasurer role
    /// @param _account Address to check the role
    /// @return res true if has one of the roles
    function _burnerOrTreasurer(address _account) internal view returns (bool res) {
        return hasRole(BURNER_ROLE, _account) || hasRole(TREASURER_ROLE, _account);
    }

    /// @dev Extend ERC20 _approve by checking blacklist users
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        if (isBlackListed(owner) || isBlackListed(spender)) revert BlackListed();
        super._approve(owner, spender, amount);
    }

    /// @dev Extend ERC20 _beforeTokenTransfer by checking blacklist users
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (isBlackListed(from) || isBlackListed(to)) revert BlackListed();
        super._beforeTokenTransfer(from, to, amount);
    }
}
