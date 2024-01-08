// SPDX-License-Identifier: MIT

/**
 * ░█▄█░▄▀▄▒█▀▒▄▀▄░░░▒░░░▒██▀░█▀▄░█░▀█▀░█░▄▀▄░█▄░█░▄▀▀░░░█▄░█▒█▀░▀█▀
 * ▒█▒█░▀▄▀░█▀░█▀█▒░░▀▀▒░░█▄▄▒█▄▀░█░▒█▒░█░▀▄▀░█▒▀█▒▄██▒░░█▒▀█░█▀░▒█▒
 * 
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.6;

import "./Clones.sol";
import "./Counters.sol";
import "./AccessControl.sol";

import "./MintableEditions.sol";

contract MintableEditionsFactory is AccessControl {
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Counter for current contract id
    CountersUpgradeable.Counter internal _counter;

    // Address for implementation of Edition contract to clone
    address private _implementation;

    // Store for hash codes of editions contents: used to prevent re-issuing of the same content
    mapping(bytes32 => bool) private _contents;

    /**
     * Initializes the factory with the address of the implementation contract template
     * 
     * @param implementation Edition implementation contract to clone
     */
    constructor(address implementation) {
        _implementation = implementation;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ARTIST_ROLE, msg.sender);
    }

    function setImplementation(address implementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _implementation = implementation;
    }


    /**
     * Creates a new editions contract as a factory with a deterministic address, returning the address of the newly created contract.
     * Important: None of these fields can be changed after calling this operation, with the sole exception of the contentUrl field which
     * must refer to a content having the same hash.
     * 
     * @param info name of editions, used in the title as "$name $tokenId/$size"
     * @param size number of NFTs that can be minted from this contract: set to 0 for unbound
     * @param price price for sale in wei
     * @param royalties perpetual royalties paid to the creator upon token selling
     * @param shares array of tuples listing the shareholders and their respective shares in bps (one per each shareholder)
     * @param allowances array of tuples listing the allowed minters and their allowances
     * @return the address of the editions contract created
     */
    function create(
        MintableEditions.Info memory info,
        uint64 size,
        uint256 price,
        uint16 royalties,
        MintableEditions.Shares[] memory shares,
        MintableEditions.Allowance[] memory allowances
    ) external onlyRole(ARTIST_ROLE) returns (address) {
        require(!_contents[info.contentHash], "Duplicated content");
        _contents[info.contentHash] = true;
        uint256 id = _counter.current();
        address instance = Clones.cloneDeterministic(_implementation, bytes32(abi.encodePacked(id)));
        MintableEditions(instance).initialize(msg.sender, info, size, price, royalties, shares, allowances);
        emit CreatedEditions(id, msg.sender, shares, size, instance);
        _counter.increment();
        return instance;
    }

    /**
     * Gets an editions contract given the unique identifier. Contract ids are zero-based.
     * 
     * @param index zero-based index of editions contract to retrieve
     * @return the editions contract
     */
    function get(uint256 index) external view returns (MintableEditions) {
        return MintableEditions(Clones.predictDeterministicAddress(_implementation, bytes32(abi.encodePacked(index)), address(this)));
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
     * @param index the identifier of the newly created editions contract
     * @param creator the editions' owner
     * @param size the number of tokens this editions contract consists of
     * @param contractAddress the address of the contract representing the editions
     */
    event CreatedEditions(uint256 indexed index, address indexed creator, MintableEditions.Shares[] indexed shareholders, uint256 size, address contractAddress);
}
