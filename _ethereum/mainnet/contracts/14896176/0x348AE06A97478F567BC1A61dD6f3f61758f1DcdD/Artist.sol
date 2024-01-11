// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.14;

/*
██   ██ ██       ██████   ██████  ██    ██ 
██  ██  ██      ██    ██ ██    ██ ██    ██ 
█████   ██      ██    ██ ██    ██ ██    ██ 
██  ██  ██      ██    ██ ██    ██  ██  ██  
██   ██ ███████  ██████   ██████    ████   
*/

import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract Artist is
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _fullTrackIds;
    CountersUpgradeable.Counter private _tokenIds;

    string private baseURI;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public DOMAIN_SEPARATOR;

    mapping(uint256 => FullTrack) public fullTrackIdToFullTrack;
    mapping(uint256 => uint256) public tokenIdToUriId;
    mapping(uint256 => uint256) private tokenIdToFullTrackId;
    mapping(uint256 => mapping(address => uint256)) private royalties;
    mapping(uint256 => address[]) private royaltiesReceivers;

    struct InitializationData {
        string name;
        string symbol;
        address admin;
        address pauser;
        address minter;
        address owner;
        string baseUri;
    }

    struct FullTrack {
        uint32 supply;
        uint32 sold;
        uint32 startTime;
        uint256 price;
        string fullTrackHash;
    }

    event FullTrackCreated(
        uint256 indexed fullTrackId,
        uint32 supply,
        uint32 startTime,
        uint256 price
    );

    event FullTrackPurchased(
        uint256 indexed fullTrackId,
        uint256 tokenId,
        uint32 indexed sold,
        address indexed buyer
    );

    function initialize(InitializationData calldata initializationData)
        public
        initializer
        returns (bool)
    {
        __ERC721_init_unchained(
            initializationData.name,
            initializationData.symbol
        );
        __Pausable_init_unchained();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(uint256 chainId,address verifyingContract)"
                ),
                block.chainid,
                address(this)
            )
        );
        baseURI = initializationData.baseUri;
        _grantRole(DEFAULT_ADMIN_ROLE, initializationData.admin);
        _grantRole(PAUSER_ROLE, initializationData.pauser);
        _grantRole(MINTER_ROLE, initializationData.minter);
        _transferOwnership(initializationData.owner);

        return true;
    }

    function createFullTrack(
        uint32 supply,
        uint32 startTime,
        uint256 price,
        string calldata fullTrackHash,
        address[] calldata royaltyAddresses,
        uint256[] calldata royaltyAmounts
    ) external onlyRole(MINTER_ROLE) {
        _fullTrackIds.increment();
        uint256 fullTrackId = _fullTrackIds.current();

        fullTrackIdToFullTrack[fullTrackId] = FullTrack(
            supply,
            0,
            startTime,
            price,
            fullTrackHash
        );

        uint256 total;
        for (uint256 i = 0; i < royaltyAddresses.length; i++) {
            require(
                royaltyAddresses[i] != address(0) && royaltyAmounts[i] > 0,
                "Artist: Invalid royalties data"
            );
            royalties[fullTrackId][royaltyAddresses[i]] = royaltyAmounts[i];
            total += royaltyAmounts[i];
        }
        royaltiesReceivers[fullTrackId] = royaltyAddresses;
        require(
            total == 10_000,
            "Artist: Royalties addition must be equal to 100%"
        );

        emit FullTrackCreated(
            _fullTrackIds.current(),
            supply,
            startTime,
            price
        );
    }

    function buyFullTrack(uint256 fullTrackId, bytes calldata signature)
        external
        payable
        whenNotPaused
    {
        require(
            fullTrackId <= _fullTrackIds.current(),
            "Artist: Purchase for non existent fullTrackId"
        );
        require(
            msg.value >= fullTrackIdToFullTrack[fullTrackId].price,
            "Artist: Please submit the asking price"
        );
        require(
            fullTrackIdToFullTrack[fullTrackId].startTime < block.timestamp,
            "Artist: FullTrack is not available yet"
        );
        require(
            fullTrackIdToFullTrack[fullTrackId].supply >
                fullTrackIdToFullTrack[fullTrackId].sold,
            "Artist: FullTrack is sold out"
        );

        address signer = _verify(signature, fullTrackId);
        require(
            hasRole(MINTER_ROLE, signer),
            "Artist: Signature invalid or unauthorized"
        );
        address[] memory _royaltiesReceivers = royaltiesReceivers[fullTrackId];
        for (uint256 i = 0; i < _royaltiesReceivers.length; i++) {
            uint256 royalty = royalties[fullTrackId][_royaltiesReceivers[i]];
            (bool success, ) = payable(_royaltiesReceivers[i]).call{
                value: (msg.value * royalty) / 10_000
            }("");
            require(success, "Artist: Transfer failed");
        }
        _tokenIds.increment();
        fullTrackIdToFullTrack[fullTrackId].sold++;
        tokenIdToFullTrackId[_tokenIds.current()] = fullTrackId;
        tokenIdToUriId[_tokenIds.current()] = fullTrackIdToFullTrack[
            fullTrackId
        ].sold;

        _safeMint(msg.sender, _tokenIds.current(), "");

        emit FullTrackPurchased(
            _fullTrackIds.current(),
            _tokenIds.current(),
            fullTrackIdToFullTrack[fullTrackId].sold,
            msg.sender
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Artist: URI query for nonexistent token");
        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(
                        _baseURI(),
                        "/",
                        fullTrackIdToFullTrack[tokenIdToFullTrackId[tokenId]]
                            .fullTrackHash,
                        "/",
                        tokenIdToUriId[tokenId].toString(),
                        ".json"
                    )
                )
                : "";
    }

    function _verify(bytes calldata signature, uint256 fullTrackId)
        internal
        view
        returns (address)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        keccak256(
                            "SignedData(string name,uint256 fullTrackId,address buyerAddress)"
                        ),
                        keccak256(bytes(name())),
                        fullTrackId,
                        msg.sender
                    )
                )
            )
        );
        return ECDSAUpgradeable.recover(digest, signature);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
