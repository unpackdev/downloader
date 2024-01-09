// SPDX-License-Identifier: MIT

/**
 * ░█▄ █▒█▀░▀█▀  ▒█▀▄▒██▀░█ ░▒█▒▄▀▄▒█▀▄░█▀▄░▄▀▀
 * ░█▒▀█░█▀ ▒█▒▒░░█▀▄░█▄▄░▀▄▀▄▀░█▀█░█▀▄▒█▄▀▒▄██
 * 
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.9;

import "./CountersUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./BeaconProxy.sol";
import "./UpgradeableBeacon.sol";

import "./MintableRewards.sol";

contract MintableRewardsFactory is AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");
    
    // Address for implementation contract to clone
    UpgradeableBeacon public beacon;

    // Store for hash codes of editions contents: used to prevent re-issuing of the same content
    mapping(bytes32 => bool) internal _contents;

    // Counter for current contract id
    CountersUpgradeable.Counter internal _counter;

    // Store for editions addresses
    mapping(uint256 => address) internal _rewards;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer { }

    /**
     * Initializes the factory with the address of the implementation contract template
     * 
     * @param implementation implementation contract to clone
     */
    function initialize(address implementation) public initializer {
        UpgradeableBeacon _tokenBeacon = new UpgradeableBeacon(implementation);
        //_tokenBeacon.transferOwnership(_msgSender());
        beacon = _tokenBeacon;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ARTIST_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function upgradeBeaconTo(address implementation) public onlyRole(DEFAULT_ADMIN_ROLE) {
        beacon.upgradeTo(implementation);
    }

    /**
     * Creates a new editions contract as a factory with a beacon proxy, returning the address of the newly created contract.
     * Important: None of these fields can be changed after calling this operation, with the sole exception of the contentUrl field which
     * must refer to a content having the same hash.
     * 
     * @param info info of the editions
     * @param size number of NFTs that can be minted from this contract: set to 0 for unbound
     * @param price price for sale in wei
     * @param royalties perpetual royalties paid to the creator upon token selling
     * @param shares array of tuples listing the shareholders and their respective shares in bps (one per each shareholder)
     * @param allowancesRef address of the allowances holding contract
     * @return the address of the editions contract created
     */
    function create(
        MintableRewards.Info memory info,
        uint64 size,
        uint256 price,
        uint16 royalties,
        MintableRewards.Shares[] memory shares,
        address allowancesRef
    ) external onlyRole(ARTIST_ROLE) returns (address) {
        require(!_contents[info.contentHash], "Duplicated content");
        _contents[info.contentHash] = true;
        BeaconProxy proxy = new BeaconProxy(
            address(beacon), 
            abi.encodeWithSelector(MintableRewards(address(0x0)).initialize.selector, _msgSender(), info, size, price, royalties, shares, allowancesRef)
        );
        _counter.increment();
        _rewards[_counter.current()] = address(proxy);
        emit CreatedRewards(_counter.current(), msg.sender, shares, size, address(proxy));
        return address(proxy);
    }

    /**
     * Gets a rewards contract given the unique identifier.
     * 
     * @param rewardsId identifier of rewards contract to retrieve
     * @return the rewards contract
     */
    function get(uint256 rewardsId) external view returns (address) {
        require(rewardsId <= _counter.current(), "Identifier doesn't exist");
        return _rewards[rewardsId];
    }

    /** 
     * @return the number of edition contracts created so far through this factory
     */
    function instances() external view returns (uint256) {
        return _counter.current();
    }

    /**
     * Emitted when an edition is created reserving the corresponding token IDs.
     * 
     * @param index the identifier of the newly created rewards contract
     * @param creator the rewards' owner
     * @param size the number of tokens this rewards contract consists of
     * @param contractAddress the address of the contract representing the rewards
     */
    event CreatedRewards(uint256 indexed index, address indexed creator, MintableRewards.Shares[] indexed shareholders, uint256 size, address contractAddress);
}
