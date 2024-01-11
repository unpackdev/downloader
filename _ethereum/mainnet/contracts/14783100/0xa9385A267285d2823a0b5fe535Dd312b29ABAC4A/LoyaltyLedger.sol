// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC1155BurnableUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProof.sol";

import "./PassageUtils.sol";
import "./IPassageRegistry.sol";
import "./ILoyaltyLedger.sol";
import "./ERC2771Recipient.sol";
import "./Ownable.sol";
import "./PassageAccess.sol";

///
///
///  ___
/// (  _`\
/// | |_) )  _ _   ___   ___    _ _    __     __
/// | ,__/'/'_` )/',__)/',__) /'_` ) /'_ `\ /'__`\
/// | |   ( (_| |\__, \\__, \( (_| |( (_) |(  ___/
/// (_)   `\__,_)(____/(____/`\__,_)`\__  |`\____)
///                                 ( )_) |
///                                  \___/'
///
/// @title Passage Loyalty Ledger
/// @notice Loyalty Ledger ERC-1155 Token
///

contract LoyaltyLedger is
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    PassageAccess,
    UUPSUpgradeable,
    ERC2771Recipient,
    Ownable,
    ILoyaltyLedger
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using PassageUtils for address;

    IPassageRegistry public passageRegistry;

    CountersUpgradeable.Counter private _tokenTypeCounter;

    bool public versionLocked;

    struct Token {
        string name;
        bool transferEnabled;
        bool claimEnabled;
        bool whitelistClaimEnabled;
        bool maxSupplyLocked;
        bool transferEnabledLocked;
        uint256 maxSupply; // 0 is no max
        uint256 claimFee; // 0 is no fee
        uint256 claimAmount;
        uint256 whitelistClaimFee; // 0 is no fee
        bytes32 whitelistRoot;
        mapping(address => bool) whitelistClaimed; // whitelist address -> claimed
    }

    // tokenId -> Token
    mapping(uint256 => Token) public tokens;

    modifier onlyAuthorizedUpgrader() {
        if (isManaged()) {
            address registry = address(passageRegistry);
            require(registry == _msgSender(), "T1");
        } else {
            _checkRole(UPGRADER_ROLE, _msgSender());
        }
        _;
    }

    modifier versionLockRequired() {
        require(versionLocked == true, "T2");
        _;
    }

    modifier versionLockProhibited() {
        require(versionLocked == false, "T3");
        _;
    }

    modifier maxSupplyLockProhibited(uint256 _id) {
        require(exists(_id), "T4");
        require(tokens[_id].maxSupplyLocked == false, "T5");
        _;
    }

    // ---- constructor/intitalizer ----

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializer function for contract creation instead of constructor to support upgrades
    /// @dev Only intended to be called from the registry
    /// @param _creator The address of the original creator
    function initialize(address _creator) public initializer {
        passageRegistry = IPassageRegistry(_msgSender());

        __ERC1155_init("");
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRoles(_creator);
    }

    // ---- public ----

    /// @notice Mint token to caller
    /// @dev Token must exist. Need to enable claim & set fee/amount (if desired)
    /// @param _id Token ID to mint
    /// @param _amount Number of tokens to mint

    function claim(uint256 _id, uint256 _amount) external payable {
        require(tokens[_id].claimEnabled, "T6");
        require(_amount <= tokens[_id].claimAmount, "T7");
        if (tokens[_id].claimFee > 0) require(msg.value == tokens[_id].claimFee * _amount, "T8");
        _checkMint(_id, _amount);
        _mint(_msgSender(), _id, _amount, "");
    }

    /// @notice Mint token to caller if they are on the supplied whitelist
    /// @dev Must first set whitelist root, enable claim, & set fee (if desired). Merkle tree can be generated with the Javascript library "merkletreejs", the hashing algorithm should be keccak256 and pair sorting should be enabled
    /// @param _id Token ID to mint
    /// @param _maxAmount Maximum number of tokens a user can mint, must be the same as merkle tree leaf
    /// @param _claimAmount Number of tokens to mint, must be less than or equal to max amount
    /// @param _proof Proof for merkle tree
    function claimWhitelist(
        uint256 _id,
        bytes32[] calldata _proof,
        uint256 _maxAmount,
        uint256 _claimAmount
    ) external payable {
        require(tokens[_id].whitelistClaimEnabled, "T9");
        if (tokens[_id].whitelistClaimFee > 0) require(msg.value == tokens[_id].whitelistClaimFee * _claimAmount, "T8");
        require(_claimAmount <= _maxAmount, "T10");
        _checkMint(_id, _claimAmount);
        bool validProof = MerkleProof.verify(
            _proof,
            tokens[_id].whitelistRoot,
            keccak256(abi.encodePacked(_msgSender(), _maxAmount))
        );
        require(validProof, "T11");
        require(!tokens[_id].whitelistClaimed[_msgSender()], "T12");
        tokens[_id].whitelistClaimed[_msgSender()] = true;
        _mint(_msgSender(), _id, _claimAmount, "");
    }

    /// @notice Returns URI for associated token
    /// @param _id Token ID to get URI for
    /// @return uri for token ID
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "T4");

        if (bytes(super.uri(_id)).length > 0) return string(abi.encodePacked(super.uri(_id), "{id}")); // custom URI has been set

        string memory addrStr = address(this).address2Str();
        return
            string(
                abi.encodePacked(
                    passageRegistry.globalLoyaltyBaseURI(),
                    StringsUpgradeable.toString(block.chainid),
                    "/",
                    addrStr,
                    "/",
                    "{id}"
                )
            );
    }

    /// @notice Returns if a given token has been created
    /// @param _id Token ID to check
    /// @return if token exists
    function exists(uint256 _id) public view override returns (bool) {
        return bytes(tokens[_id].name).length > 0;
    }

    /// @notice Returns if Loyalty Ledger is still managed in registry
    /// @return if Loyalty Ledger is still managed in registry
    function isManaged() public view returns (bool) {
        return address(passageRegistry) != address(0);
    }

    /// @notice Returns Loyalty Ledger implementation version
    /// @return version number
    function loyaltyLedgerVersion() public pure virtual returns (uint256) {
        return 0;
    }

    // ---- permissioned ----

    /// @notice Allows MINTER role to mint any number of a token to a given address
    /// @param _to Address to mint token to
    /// @param _id Token ID to mint
    /// @param _amount Number of tokens to mint
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) public onlyRole(MINTER_ROLE) {
        _checkMint(_id, _amount);
        _mint(_to, _id, _amount, "");
    }

    /// @notice Allows MINTER role to mint tokens to a given address
    /// @param _to Address to mint token to
    /// @param _ids List of token IDs
    /// @param _amounts List of token amounts
    function mintBatch(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) public onlyRole(MINTER_ROLE) {
        require(_ids.length == _amounts.length, "T13");
        for (uint256 i = 0; i < _ids.length; i++) {
            _checkMint(_ids[i], _amounts[i]);
        }
        _mintBatch(_to, _ids, _amounts, "");
    }

    /// @notice Allows MINTER role to mint tokens to addresses
    /// @dev All input lists should be the same length
    /// @param _addresses List of address to mint token to
    /// @param _ids List of token IDs
    /// @param _amounts List of token amounts
    function mintBulk(
        address[] calldata _addresses,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) public onlyRole(MINTER_ROLE) {
        require(_addresses.length == _ids.length && _ids.length == _amounts.length, "T13");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _checkMint(_ids[i], _amounts[i]);
            _mint(_addresses[i], _ids[i], _amounts[i], "");
        }
    }

    // ---- admin ----

    /// @notice Allows admin to eject from Passage management & upgrade contract independently of the registry
    /// @dev This is a one-way operation, there is no way to become managed again
    function eject() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isManaged(), "T14");
        address registry = address(passageRegistry);
        revokeRole(DEFAULT_ADMIN_ROLE, registry);
        revokeRole(UPGRADER_ROLE, registry);
        if (bytes(super.uri(0)).length == 0) {
            string memory addrStr = address(this).address2Str();
            string memory defaultUri = string(
                abi.encodePacked(
                    passageRegistry.globalLoyaltyBaseURI(),
                    StringsUpgradeable.toString(block.chainid),
                    "/",
                    addrStr,
                    "/"
                )
            );
            _setURI(defaultUri);
        }

        IPassageRegistry passageRegistryCache = passageRegistry;
        passageRegistry = IPassageRegistry(address(0));
        passageRegistryCache.ejectLoyaltyLedger();
    }

    /// @notice Creates a new token
    /// @param _name The token name
    /// @param _maxSupply Max supply of tokens
    /// @param _transferEnabled If transfer enabled
    /// @param _claimFee The claim fee in wei
    /// @param _whitelistClaimFee The whitelist claim fee in wei
    /// @return ID of created token
    function createToken(
        string calldata _name,
        uint256 _maxSupply,
        bool _transferEnabled,
        uint256 _claimFee,
        uint256 _claimAmount,
        uint256 _whitelistClaimFee
    ) public onlyRole(MANAGER_ROLE) returns (uint256) {
        uint256 id = _tokenTypeCounter.current();
        Token storage t = tokens[id];
        t.name = _name;
        t.maxSupply = _maxSupply;
        t.claimEnabled = false;
        t.transferEnabled = _transferEnabled;
        t.maxSupplyLocked = false;
        t.transferEnabledLocked = false;
        t.claimFee = _claimFee;
        t.claimAmount = _claimAmount;
        t.whitelistClaimEnabled = false;
        t.whitelistClaimFee = _whitelistClaimFee;
        _tokenTypeCounter.increment();
        emit TokenCreated(id, _name, _maxSupply, _transferEnabled);
        return id;
    }

    /// @notice Locks the maxSupply for a token which prevents any future maxSupply updates
    /// @notice this is a one way operation and cannot be undone
    /// @notice the current version must be locked
    /// @param _id id of the token to update
    function lockMaxSupply(uint256 _id)
        external
        versionLockRequired
        maxSupplyLockProhibited(_id)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokens[_id].maxSupplyLocked = true;

        emit MaxSupplyLocked(_id);
    }

    /// @notice Locks the transferEnabled for a token which prevents any future transferEnabled updates
    /// @notice this is a one way operation and cannot be undone
    /// @notice the current version must be locked
    /// @param _id id of the token to update
    function lockTransferEnabled(uint256 _id) external versionLockRequired onlyRole(DEFAULT_ADMIN_ROLE) {
        require(exists(_id), "T4");
        tokens[_id].transferEnabledLocked = true;

        emit TransferEnabledLocked(_id);
    }

    /// @notice Locks the version of the contract preventing any future upgrades
    /// @notice this is a one way operation and cannot be undone
    function lockVersion() external versionLockProhibited onlyRole(DEFAULT_ADMIN_ROLE) {
        versionLocked = true;

        emit VersionLocked();
    }

    /// @notice Allows manager to set the ability to set a new URI rather than use the Loyalty Ledger Global URI
    /// @param newUri Token base URI
    function setURI(string memory newUri) external onlyRole(MANAGER_ROLE) {
        _setURI(newUri);
        emit BaseUriUpdated(newUri);
    }

    /// @notice Allows manager to set the ability for token to be transferred
    /// @param _id ID of token to update
    /// @param _enabled If transfer is enabled
    function setTokenTransferEnabled(uint256 _id, bool _enabled) external onlyRole(MANAGER_ROLE) {
        require(exists(_id), "T4");
        require(tokens[_id].transferEnabledLocked == false, "T15");
        tokens[_id].transferEnabled = _enabled;
        emit TransferEnableUpdated(_id, _enabled);
    }

    /// @notice Allows manager to set if claim is enabled
    /// @param _id ID of token to update
    /// @param _enabled If claim is enabled
    function setTokenClaimEnabled(uint256 _id, bool _enabled) external onlyRole(MANAGER_ROLE) {
        require(exists(_id), "T4");
        tokens[_id].claimEnabled = _enabled;
    }

    /// @notice Allows manager to set the minting claim fee & amount
    /// @param _id ID of token to update
    /// @param _claimFee The claim fee in wei
    /// @param _claimAmount Max number of tokens someone can claim per tx
    function setTokenClaimOptions(
        uint256 _id,
        uint256 _claimFee,
        uint256 _claimAmount
    ) external onlyRole(MANAGER_ROLE) {
        require(exists(_id), "T4");
        tokens[_id].claimFee = _claimFee;
        tokens[_id].claimAmount = _claimAmount;
    }

    /// @notice Allows manager to set max supply of a token
    /// @param _id ID of token to update
    /// @param _maxSupply New max supply for token
    function setTokenMaxSupply(uint256 _id, uint256 _maxSupply)
        external
        maxSupplyLockProhibited(_id)
        onlyRole(MANAGER_ROLE)
    {
        require(_maxSupply >= this.totalSupply(_id), "T16");
        tokens[_id].maxSupply = _maxSupply;
        emit MaxSupplyUpdated(_id, _maxSupply);
    }

    /// @notice Allows manager to set if the whitelist claim is enabled
    /// @param _id ID of token to update
    /// @param _enabled If the whitelist claim is enabled
    function setTokenWhitelistClaimEnabled(uint256 _id, bool _enabled) external onlyRole(MANAGER_ROLE) {
        tokens[_id].whitelistClaimEnabled = _enabled;
    }

    /// @notice Allows manager to set the fee for the whitelist claim
    /// @param _id ID of token to update
    /// @param _claimFee Fee in wei
    function setTokenWhitelistClaimFee(uint256 _id, uint256 _claimFee) external onlyRole(MANAGER_ROLE) {
        require(exists(_id), "T4");
        tokens[_id].whitelistClaimFee = _claimFee;
    }

    /// @notice Allows manager to set the merkle tree root for the whitelist for a given token
    /// @dev Merkle tree can be generated with the Javascript library "merkletreejs", the hashing algorithm should be keccak256 and pair sorting should be enabled
    /// @param _id ID of token to update
    /// @param _whitelistRoot Merkle tree root
    function setWhitelistRoot(uint256 _id, bytes32 _whitelistRoot) external onlyRole(MANAGER_ROLE) {
        require(exists(_id), "T4");
        tokens[_id].whitelistRoot = _whitelistRoot;
    }

    /// @notice Allows manager to set the whitelist claim fee & merkle root for a given token
    /// @dev Merkle tree can be generated with the Javascript library "merkletreejs", the hashing algorithm should be keccak256 and pair sorting should be enabled
    /// @param _id ID of token to update
    /// @param _claimFee Fee in wei
    /// @param _whitelistRoot Merkle tree root
    function setWhitelistOptions(
        uint256 _id,
        uint256 _claimFee,
        bytes32 _whitelistRoot
    ) external onlyRole(MANAGER_ROLE) {
        require(exists(_id), "T4");
        tokens[_id].whitelistClaimFee = _claimFee;
        tokens[_id].whitelistRoot = _whitelistRoot;
    }

    /// @notice Allows default admin to set the owner address
    /// @dev not used for access control, used by services that require a single owner account
    /// @param newOwner address of the new owner
    function setOwnership(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setOwnership(newOwner);
    }

    /// @notice Allows manager to set trusted forwarder for meta-transactions
    /// @param forwarder Address of trusted forwarder
    function setTrustedForwarder(address forwarder) external onlyRole(MANAGER_ROLE) {
        _setTrustedForwarder(forwarder);
    }

    /// @notice Allows manager to transfer eth from contract
    function withdraw() external onlyRole(MANAGER_ROLE) {
        uint256 value = address(this).balance;
        address payable to = payable(_msgSender());
        emit Withdraw(value, _msgSender());
        to.transfer(value);
    }

    // ---- private ----

    function _checkMint(uint256 _id, uint256 _amount) private view {
        require(exists(_id), "T4");
        if (tokens[_id].maxSupply > 0) require(this.totalSupply(_id) + _amount <= tokens[_id].maxSupply, "T17");
    }

    function _setupRoles(address _creator) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _creator);
        _grantRole(UPGRADER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _creator);
        _grantRole(MANAGER_ROLE, _creator);
        _grantRole(MINTER_ROLE, _creator);
        _setOwnership(_creator);
    }

    // ---- meta txs ----

    function _msgSender() internal view virtual override(BaseRelayRecipient, ContextUpgradeable) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(BaseRelayRecipient, ContextUpgradeable)
        returns (bytes calldata)
    {
        return BaseRelayRecipient._msgData();
    }

    // ---- overrides ----

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAuthorizedUpgrader
        versionLockProhibited
    {}

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        // disable non-mint & non-burn transfers if requested
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(tokens[ids[i]].transferEnabled, "T18");
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function hasUpgraderRole(address _address) public view override(ILoyaltyLedger, PassageAccess) returns (bool) {
        return super.hasUpgraderRole(_address);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function upgradeTo(address newImplementation) external override(UUPSUpgradeable, ILoyaltyLedger) onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        override(UUPSUpgradeable, ILoyaltyLedger)
        onlyProxy
    {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }
}
