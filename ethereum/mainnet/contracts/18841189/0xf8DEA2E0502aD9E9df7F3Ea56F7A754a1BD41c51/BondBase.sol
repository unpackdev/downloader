// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IBond.sol";
import "./ERC721Enumerable.sol";

abstract contract BondBase is IBond, ERC721Enumerable {
    /// @dev The maximum epoch duration.
    uint256 public immutable maxEpoch;

    /// @dev The epoch start time.
    uint256 public immutable startEpoch;

    /// @dev end date of epochs
    uint256 public immutable endEpoch;

    /// @dev The super admin address.
    address public superAdmin;

    constructor(
        address _superAdmin,
        address _vault,
        uint256 _maxEpoch,
        uint256 _endEpoch
    ) ERC721("FORGE", "FORGE") {
        superAdmin = _superAdmin;
        vault = _vault;
        maxEpoch = _maxEpoch;
        startEpoch = block.timestamp;
        endEpoch = _endEpoch;
    }

    /// @dev The vault address that will be storing the funds ideally a vault smart contract.
    address public vault;

    /// @dev Mapping to track whitelisted addresses.
    mapping(address => bool) public whitelist;

    /// @dev Mapping to track admin addresses.
    mapping(address => bool) public admin;

    /// @dev Mapping to store bond data.
    mapping(uint256 => Bond) public bondData;

    /// @dev Mapping to track disqualified bonds until a certain epoch.
    mapping(uint256 => uint256) public disqualifiedBondUntilEpoch;

    /// @dev Mapping to store whitelisted tokens.
    mapping(address => bool) public tokenWhitelist;

    /// @dev Token ID counter to track the next ID for minting.
    uint256 public tokenIdCounter = 1;

    /// @dev Restriction flag for minting.
    bool public restrictedMint = false;

    /// @dev currencies and their data
    mapping(address => CurrencyDetails) public currencies;

    /// @dev mapping of users and their bond values
    mapping(address => mapping(address => uint256)) public bondValueMinted;

    /// @dev mapping of currencies and their USD value.
    mapping(address => uint256) public currencyValue;

    /// @dev paused flag
    bool public paused = false;

    /// @dev even emitted when a bond is minted.
    event BondMinted(address indexed to, uint256 bondId);

    /// @dev modifier to check if the caller is the super admin
    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "Not a superAdmin");
        _;
    }
    /// @dev modifier to check if the caller is the admin or super admin
    modifier onlyAdmin() {
        require(
            admin[msg.sender] || msg.sender == superAdmin,
            "Not an admin or superAdmin"
        );
        _;
    }

    /// @dev modifier to check if the caller is the admin or super admin
    modifier onlyWhitelisted() {
        if (restrictedMint) {
            require(whitelist[msg.sender], "Not whitelisted");
        }
        _;
    }
    /// @dev modifier to check if the currency is whitelisted
    modifier currencyWhitelisted(address _contractAddress) {
        require(tokenWhitelist[_contractAddress], "Currency not whitelisted");
        _;
    }

    /// @dev modifier to check if the contract is paused
    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /// @dev event emitted when a user is whitelisted
    event WhitelistToggled(address indexed account);

    /// @dev event emitted when a mint occurs
    event Mint(
        address indexed account,
        uint256 value,
        address indexed currency
    );

    /// @dev event emitted when mint restriction is toggled
    event MintRestrictionToggled(bool restricted);

    /// @dev allows super admin to toggle an admin account
    function toggleAdminStatus(address _account) external onlySuperAdmin {
        admin[_account] = !admin[_account];
    }

    /// @dev allows admin to add currencies
    function addCurrency(address _contractAddress) external onlyAdmin {
        tokenWhitelist[_contractAddress] = true;
    }

    /**
    @dev allows admins to togglez paused status
     */
    function togglePaused() external onlyAdmin {
        paused = !paused;
    }

    /// @dev allows admins to toggle restricted minting
    function toggleRestricted() external onlyAdmin {
        restrictedMint = !restrictedMint;
        emit MintRestrictionToggled(restrictedMint);
    }

    /**
    @dev allows admins to add currencies and their details.
    *
    @param _contractAddress the address of the currency
    @param _minimum the minimum amount of tokens that can be purchased
    @param _maximum the maximum amount of tokens that can be purchased
    @param _maximumSupply the maximum supply of tokens
    @param _interestRate the interest rate of the bond
    @param _marketPrice the market price of the token
     */
    function addCurrencyDetails(
        address _contractAddress,
        uint256 _minimum,
        uint256 _maximum,
        uint256 _maximumSupply,
        uint256 _interestRate,
        uint256 _marketPrice
    ) external onlyAdmin {
        currencies[_contractAddress] = CurrencyDetails({
            minimum: _minimum,
            maximum: _maximum,
            maximumSupply: _maximumSupply,
            totalMinted: 0,
            interestRate: _interestRate
        });
        currencyValue[_contractAddress] = _marketPrice;
        tokenWhitelist[_contractAddress] = true;
    }

    /** 
    @dev allows admins to update market value of currency.
    *
    @param _contractAddress the address of the currency
    @param _marketPrice the market price of the token
    */
    function updateCurrencyValue(
        address _contractAddress,
        uint256 _marketPrice
    ) external onlyAdmin {
        currencyValue[_contractAddress] = _marketPrice;
    }

    /**
    @dev allows super admin to update vault address.
    *
    @param _vault the address of the vault
     */
    function updateVault(address _vault) external onlySuperAdmin {
        vault = _vault;
    }

    /// @dev virutal function to allow for custom disqualification logic.
    function disqualifyForEpochs(
        uint256 tokenId,
        uint256 epochs
    ) internal virtual {}

    /// @dev virutal function to allow for custom minting logic.
    function mintBond(
        uint256 _value,
        address _contractAddress
    ) public payable virtual {}

    /** 
    @dev allows super admin to renounce their role to someone else.
    *
    @param _newAdmin the address of the new admin
     */

    function renounceSuperAdmin(address _newAdmin) external onlySuperAdmin {
        superAdmin = _newAdmin;
    }
}
