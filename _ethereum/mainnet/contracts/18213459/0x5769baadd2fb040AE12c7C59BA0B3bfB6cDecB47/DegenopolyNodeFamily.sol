// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";

import "./IAddressProvider.sol";
import "./IDegenopolyNodeManager.sol";

contract DegenopolyNodeFamily is ERC721PresetMinterPauserAutoIdUpgradeable {
    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice color family
    string public color;

    /// @notice reward boost
    uint256 public rewardBoost;

    /// @notice address provider
    IAddressProvider public addressProvider;
    
    /// @dev new owner
    address newOwner;

    /* ======== ERRORS ======== */

    error ZERO_ADDRESS();

    /* ======== EVENTS ======== */

    event AddressProvider(address addressProvider);
    event NewOwner(address newOwner);

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize1(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _color,
        uint256 _rewardBoost,
        address _addressProvider
    ) external initializer {
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();

        // color family
        color = _color;

        // reward boost
        rewardBoost = _rewardBoost;

        // set address provider
        addressProvider = IAddressProvider(_addressProvider);
        _setupRole(MINTER_ROLE, addressProvider.getDegenopolyNodeManager());

        // init
        __ERC721PresetMinterPauserAutoId_init(_name, _symbol, _baseTokenURI);
    }

    /* ======== MODIFIERS ======== */

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert ZERO_ADDRESS();

        addressProvider = IAddressProvider(_addressProvider);

        emit AddressProvider(_addressProvider);
    }

    function setNewOwner(address _newOwner) external onlyOwner {
        newOwner = _newOwner;        
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);

        emit NewOwner(_newOwner);
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _firstTokenId,
        uint256 _batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _firstTokenId, _batchSize);

        if (_from != address(0)) {
            IDegenopolyNodeManager(addressProvider.getDegenopolyNodeManager())
                .burnNodeFamily(_from);
        }

        if (_to != address(0)) {
            IDegenopolyNodeManager(addressProvider.getDegenopolyNodeManager())
                .mintNodeFamily(_to);
        }
    }
}
