// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

/// @title A smart contract for the NFT Beer Mug project made by madeinbavaria
/// @author Kevin Horst madeinbavaria UG
/// @notice You can use this contract for any NFT Beer Mug editions
contract BeerMugNft is ERC721Upgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    struct Edition {
        uint8 maxDelivery;
        uint8 maxDeliveryAllowlist;
        uint32 maxSupply;
        uint256 price;
        uint256 position;
        CountersUpgradeable.Counter allowlistCounter;
        CountersUpgradeable.Counter tokenIds;
        mapping(address => bool) allowlist;
        bytes baseURI;
        bool started;
        bool restricted;
    }

    uint256 public globalTokensPosition;
    mapping(bytes32 => Edition) public editions;
    mapping(uint256 => bytes32) public globalTokenIndex;
    bytes public contractMetadataURI;
    bool public active;

    function initialize(bool _active, bytes memory _contractMetadataURI) public virtual initializer {
        active = _active;
        contractMetadataURI = _contractMetadataURI;

        __Ownable_init();
        __ERC721_init("BeerMugNft", "MUG");
    }

    modifier onlyIfActive() virtual {
        require(isActive(), "We have closed!");
        _;
    }

    modifier onlyIfExists(bytes32 _edition) virtual {
        require(isExisting(_edition), "Edition does not exist.");
        _;
    }

    modifier onlyIfNotExists(bytes32 _edition) virtual {
        require(!isExisting(_edition), "Edition already exists.");
        _;
    }

    modifier onlyIfStarted(bytes32 _edition) virtual {
        require(
            isStarted(_edition),
            "Please be patient, the serving of our beer mugs has not yet started."
        );
        _;
    }

    modifier onlyIfNotRestricted(bytes32 _edition) virtual {
        require(
            owner() == _msgSender() ||
                !isRestricted(_edition) ||
                (isRestricted(_edition) &&
                    editions[_edition].allowlist[_msgSender()] == true),
            "Please be patient until the public sale, you are not on the guest list."
        );
        _;
    }

    function setActive(bool _active) external virtual onlyOwner {
        active = _active;
    }

    function setContractURI(bytes memory _contractMetadataURI) external virtual onlyOwner {
        contractMetadataURI = _contractMetadataURI;
    }

    /// @notice Mint a new token
    function create(bytes32 _edition, uint8 _count)
        external
        payable
        virtual
        onlyIfActive
        onlyIfStarted(_edition)
        onlyIfNotRestricted(_edition)
    {
        require(
            editions[_edition].tokenIds.current() <
                editions[_edition].maxSupply,
            "Sold out."
        );
        require(
            _count > 0 && isRestricted(_edition)
                ? _count <= editions[_edition].maxDeliveryAllowlist
                : _count <= editions[_edition].maxDelivery,
            "That's to much for one table."
        );
        require(
            msg.value >= editions[_edition].price * _count,
            "Not enough ethers sent to purchase the bill."
        );

        for (uint8 i = 0; i < _count; i++) {
            editions[_edition].tokenIds.increment();
            uint256 newItemId = editions[_edition].position +
                editions[_edition].tokenIds.current();
            globalTokenIndex[newItemId] = _edition;

            _safeMint(_msgSender(), newItemId);
        }
    }

    /// @notice Create a new edition of NFT Beer Mugs
    function create(
        bytes32 _edition,
        uint8 _maxDelivery,
        uint8 _maxDeliveryAllowlist,
        uint32 _maxSupply,
        uint256 _price,
        bool _started,
        bool _restricted,
        bytes memory _baseURI
    ) external virtual onlyOwner onlyIfNotExists(_edition) {
        require(
            _maxSupply > 0 && _maxDelivery > 0 && _maxDeliveryAllowlist > 0,
            "Invalid parameter(s)."
        );

        Edition storage r = editions[_edition];
        r.position = globalTokensPosition;
        r.maxDelivery = _maxDelivery;
        r.maxDeliveryAllowlist = _maxDeliveryAllowlist;
        r.maxSupply = _maxSupply;
        r.price = _price;
        r.started = _started;
        r.restricted = _restricted;
        r.baseURI = _baseURI;

        unchecked {
            globalTokensPosition = globalTokensPosition + _maxSupply;
        }
    }

    function setMaxDeliveries(
        bytes32 _edition,
        uint8 _maxDelivery,
        uint8 _maxDeliveryAllowlist
    ) external virtual onlyOwner onlyIfExists(_edition) {
        require(
            _maxDelivery > 0 && _maxDeliveryAllowlist > 0,
            "Invalid parameter(s)."
        );
        editions[_edition].maxDelivery = _maxDelivery;
        editions[_edition].maxDeliveryAllowlist = _maxDeliveryAllowlist;
    }

    function setStarted(bytes32 _edition, bool _started)
        external
        virtual
        onlyOwner
        onlyIfExists(_edition)
    {
        editions[_edition].started = _started;
    }

    function setRestricted(bytes32 _edition, bool _restricted)
        external
        virtual
        onlyOwner
        onlyIfExists(_edition)
    {
        editions[_edition].restricted = _restricted;
    }

    function setBaseURI(bytes32 _edition, bytes memory _baseURI)
        external
        virtual
        onlyOwner
        onlyIfExists(_edition)
    {
        editions[_edition].baseURI = _baseURI;
    }

    function setPrice(bytes32 _edition, uint256 _price)
        external
        virtual
        onlyOwner
        onlyIfExists(_edition)
    {
        editions[_edition].price = _price;
    }

    function fillAllowlist(bytes32 _edition, address[] memory _addresses)
        external
        virtual
        onlyOwner
        onlyIfExists(_edition)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (editions[_edition].allowlist[_addresses[i]] == true) {
                continue;
            }

            editions[_edition].allowlist[_addresses[i]] = true;
            editions[_edition].allowlistCounter.increment();
        }
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function contractURI() public view virtual returns (string memory) {
        return string(contractMetadataURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        bytes memory baseURI = editions[globalTokenIndex[tokenId]].baseURI;

        return
            baseURI.length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function isActive() public view virtual returns (bool) {
        return active;
    }

    function isExisting(bytes32 _edition) public view virtual returns (bool) {
        return editions[_edition].maxSupply > 0;
    }

    function isStarted(bytes32 _edition) public view virtual returns (bool) {
        return editions[_edition].started;
    }

    function isRestricted(bytes32 _edition) public view virtual returns (bool) {
        return editions[_edition].restricted;
    }

    function isOnAllowlist(bytes32 _edition, address _addr)
        public
        view
        virtual
        returns (bool)
    {
        return editions[_edition].allowlist[_addr] == true;
    }

    function getTotalAllowed(bytes32 _edition)
        public
        view
        virtual
        returns (uint256)
    {
        return editions[_edition].allowlistCounter.current();
    }

    function getMaxDeliveries(bytes32 _edition)
        public
        view
        virtual
        returns (uint8, uint8)
    {
        return (
            editions[_edition].maxDelivery,
            editions[_edition].maxDeliveryAllowlist
        );
    }

    function getPrice(bytes32 _edition) public view virtual returns (uint256) {
        return editions[_edition].price;
    }

    function getMaxSupply(bytes32 _edition)
        public
        view
        virtual
        returns (uint256)
    {
        return editions[_edition].maxSupply;
    }

    function getTokensSold(bytes32 _edition)
        public
        view
        virtual
        returns (uint256)
    {
        return editions[_edition].tokenIds.current();
    }
}
