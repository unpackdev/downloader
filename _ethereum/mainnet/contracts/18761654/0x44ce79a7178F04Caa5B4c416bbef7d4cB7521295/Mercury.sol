// SPDX-License-Identifier: MIT

pragma solidity >=0.5.8 <0.9.0;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./MerkleProofUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./console.sol";

contract Mercury is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    uint256 public constant MAX_PER_TYPE = 30;
    uint256 public constant TOTAL_TYPES = 9;
    uint256 public constant MAX_SUPPLY = MAX_PER_TYPE * TOTAL_TYPES;
    uint256 public constant MAX_MINT_PER_ADDRESS_PER_TYPE = 3;

    string private _normalBaseURI;
    string private _pregnantBaseURI;

    bool public preMintPaused;
    bool public publicMintPaused;
    uint256 public maxPreMintSupply;
    bytes32 public merkleRoot;
    uint256[TOTAL_TYPES] public typeSupply;
    uint256 public totalPreMinted;
    uint256 public totalMinted;
    mapping(address => mapping(uint256 => uint256)) public mintedCountPerType;
    uint256 public prePrice;
    uint256 public publicPrice;
    mapping(uint256 => bool) public pregnantMercuries;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Mercury", "M");
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        pause();
        preMintPaused = true;
        publicMintPaused = true;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory baseURI = pregnantMercuries[tokenId]
            ? _pregnantBaseURI
            : _normalBaseURI;
        return
            string(
                abi.encodePacked(
                    baseURI,
                    StringsUpgradeable.toString(tokenId),
                    ".json"
                )
            );
    }

    // UUPS
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Setter
    function setBaseURIs(
        string memory normalBaseURI,
        string memory pregnantBaseURI
    ) public onlyOwner {
        _normalBaseURI = normalBaseURI;
        _pregnantBaseURI = pregnantBaseURI;
    }

    function setPreMintPaused(bool _paused) public onlyOwner {
        preMintPaused = _paused;
    }

    function setPublicMintPaused(bool _paused) public onlyOwner {
        publicMintPaused = _paused;
    }

    function setMaxPreMintSupply(uint256 _maxPreMintSupply) public onlyOwner {
        maxPreMintSupply = _maxPreMintSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrePrice(uint256 newPrice) public onlyOwner {
        prePrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function setPregnantStatus(uint256 tokenId, bool status) public onlyOwner {
        pregnantMercuries[tokenId] = status;
    }

    // Getter
    function getNormalBaseURI() public view onlyOwner returns (string memory) {
        return _normalBaseURI;
    }

    function getPregnantBaseURI()
        public
        view
        onlyOwner
        returns (string memory)
    {
        return _pregnantBaseURI;
    }

    // Modifiers
    modifier validateMintable(uint256 typeIndex, uint256 quantity) {
        require(quantity > 0, "Quantity must be greater than 0");
        require(totalMinted + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(typeIndex <= TOTAL_TYPES, "Invalid type index");
        require(
            typeSupply[typeIndex] + quantity <= MAX_PER_TYPE,
            "Exceeds max per type"
        );
        _;
    }

    // Minting
    function preMint(
        address to,
        uint256 typeIndex,
        uint256 quantity,
        bytes32[] calldata proof
    )
        public
        payable
        nonReentrant
        whenNotPaused
        validateMintable(typeIndex, quantity)
    {
        require(prePrice > 0, "prePrice not set");
        require(!preMintPaused, "preMint is paused");
        require(
            mintedCountPerType[to][typeIndex] + quantity <=
                MAX_MINT_PER_ADDRESS_PER_TYPE,
            "Mint limit exceeded for this address and type"
        );
        require(
            totalPreMinted + quantity <= maxPreMintSupply,
            "Exceeds max preMint supply"
        );
        require(
            msg.value == prePrice * quantity,
            "Ether value sent is not correct"
        );
        require(merkleRoot != bytes32(0), "Merkle root not set");
        bytes32 leaf = keccak256(abi.encodePacked(to));
        require(
            MerkleProofUpgradeable.verifyCalldata(proof, merkleRoot, leaf),
            "Invalid proof"
        );
        uint256 tokenId = typeIndex * MAX_PER_TYPE + typeSupply[typeIndex];
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, tokenId + i);
        }
        totalPreMinted += quantity;
        totalMinted += quantity;
        typeSupply[typeIndex] += quantity;
        mintedCountPerType[to][typeIndex] += quantity;
    }

    function publicMint(
        address to,
        uint256 typeIndex,
        uint256 quantity
    )
        public
        payable
        nonReentrant
        whenNotPaused
        validateMintable(typeIndex, quantity)
    {
        require(publicPrice > 0, "publicPrice not set");
        require(!publicMintPaused, "publicMint is paused");
        require(
            mintedCountPerType[to][typeIndex] + quantity <=
                MAX_MINT_PER_ADDRESS_PER_TYPE,
            "Mint limit exceeded for this address and type"
        );
        require(
            msg.value == publicPrice * quantity,
            "Ether value sent is not correct"
        );
        uint256 tokenId = typeIndex * MAX_PER_TYPE + typeSupply[typeIndex];
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, tokenId + i);
        }
        totalMinted += quantity;
        typeSupply[typeIndex] += quantity;
        mintedCountPerType[to][typeIndex] += quantity;
    }

    function ownerMint(
        address to,
        uint256 typeIndex,
        uint256 quantity
    ) public nonReentrant onlyOwner validateMintable(typeIndex, quantity) {
        uint256 tokenId = typeIndex * MAX_PER_TYPE + typeSupply[typeIndex];
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, tokenId + i);
            totalMinted++;
        }
        typeSupply[typeIndex] += quantity;
        mintedCountPerType[to][typeIndex] += quantity;
    }

    // Withdraw
    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}
