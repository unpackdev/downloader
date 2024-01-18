// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

/**
 * @title Media Verse Main Island contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MediaVerseMainIsland is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    // Modifier
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "No contracts please");
        _;
    }

    modifier onlyBackendVerified(
        bytes memory _signature,
        Size size,
        uint256 quantity,
        uint256 limit
    ) {
        bytes32 msgHash = keccak256(
            abi.encodePacked(name(), msg.sender, size, quantity, limit)
        );
        require(
            isValidSignature(msgHash, _signature),
            "Not authorized to mint"
        );
        require(
            limit > addressClaimedCountForSize[size][msg.sender],
            "Over address limit"
        );
        _;
    }

    modifier mintCompliance(Size size, uint256 quantity) {
        LandSpec memory land = landSpecs[size];
        require(initialized, "Not initialized");
        require(quantity <= maxMintPerTx, "Over transaction limit");
        require(
            totalSupplyBySize(size) + quantity <= land.maxSupply,
            "Over supply"
        );
        _;
    }

    // Constants
    address private rootSigner; // Root signer
    string private unrevealedURI;
    Counters.Counter private _tokenIdCounterStandardLands;
    Counters.Counter private _tokenIdCounterMediumLands;
    Counters.Counter private _tokenIdCounterLargeLands;

    struct LandSpec {
        uint256 maxSupply;
        uint256 startingTokenId;
    }

    enum Size {
        Standard, // 0
        Medium, // 1
        Large // 2
    }

    mapping(Size => mapping(address => uint256))
        public addressClaimedCountForSize;
    mapping(Size => LandSpec) public landSpecs;

    bool public initialized;
    bool public isRevealed;

    string public baseURI;

    uint256 public maxMintPerTx = 5;

    constructor() ERC721("Media Verse Main Island", "MED") {
        landSpecs[Size.Large] = LandSpec(90, 1);
        landSpecs[Size.Medium] = LandSpec(1860, 91);
        landSpecs[Size.Standard] = LandSpec(4050, 1951);
    }

    function setRootSigner(address _newRootSigner) external onlyOwner {
        rootSigner = _newRootSigner;
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setUnrevealURI(string memory _newUnrevealedURI)
        external
        onlyOwner
    {
        unrevealedURI = _newUnrevealedURI;
    }

    function setMaxMintPerTx(uint256 _maxMint) external onlyOwner {
        maxMintPerTx = _maxMint;
    }

    function getSpec(Size size) private view returns (LandSpec memory) {
        return landSpecs[size];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function initialize(
        address _rootSigner,
        string calldata _initBaseURI,
        string calldata _initUnrevealedURI
    ) external onlyOwner {
        require(!initialized, "Initialization can only be done once");

        initialized = true;

        // Root Signer
        rootSigner = _rootSigner;
        // Base URI
        baseURI = _initBaseURI;
        // Unrevealed URI
        unrevealedURI = _initUnrevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        string memory currentBaseURI = _baseURI();

        if (isRevealed) {
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            Strings.toString(tokenId),
                            ".json"
                        )
                    )
                    : "";
        }

        return unrevealedURI;
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        public
        view
        returns (bool isValid)
    {
        return hash.recover(signature) == rootSigner;
    }

    function mintStandardLands(
        bytes memory signature,
        uint256 quantity,
        uint256 limit
    )
        external
        payable
        onlyBackendVerified(signature, Size.Standard, quantity, limit)
    {
        _mint(Size.Standard, quantity);
    }

    function mintStandardLandsForAddress(uint256 quantity, address receiver)
        external
        onlyOwner
    {
        _mintForAddress(Size.Standard, quantity, receiver);
    }

    function mintMediumLands(
        bytes memory signature,
        uint256 quantity,
        uint256 limit
    )
        external
        payable
        onlyBackendVerified(signature, Size.Medium, quantity, limit)
    {
        _mint(Size.Medium, quantity);
    }

    function mintMediumLandsForAddress(uint256 quantity, address receiver)
        external
        onlyOwner
    {
        _mintForAddress(Size.Medium, quantity, receiver);
    }

    function mintLargeLands(
        bytes memory signature,
        uint256 quantity,
        uint256 limit
    )
        external
        payable
        onlyBackendVerified(signature, Size.Large, quantity, limit)
    {
        _mint(Size.Large, quantity);
    }

    function mintLargeLandsForAddress(uint256 quantity, address receiver)
        external
        onlyOwner
    {
        _mintForAddress(Size.Large, quantity, receiver);
    }

    function _mint(Size size, uint256 quantity)
        internal
        onlyEOA
        mintCompliance(size, quantity)
    {
        addressClaimedCountForSize[size][msg.sender] += quantity;
        _safeMintLoop(size, quantity, msg.sender);
    }

    function _mintForAddress(
        Size size,
        uint256 quantity,
        address receiver
    ) internal onlyOwner {
        LandSpec memory land = landSpecs[size];
        require(
            totalSupplyBySize(size) + quantity <= land.maxSupply,
            "Over supply"
        );
        _safeMintLoop(size, quantity, receiver);
    }

    function _safeMintLoop(
        Size size,
        uint256 quantity,
        address to
    ) internal {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupplyBySize(size) +
                getSpec(size).startingTokenId;
            increaseSupplyBySize(size);
            _safeMint(to, tokenId);
        }
    }

    function getCounter(Size size)
        private
        view
        returns (Counters.Counter storage)
    {
        if (size == Size.Standard) {
            return _tokenIdCounterStandardLands;
        }
        if (size == Size.Medium) {
            return _tokenIdCounterMediumLands;
        }
        if (size == Size.Large) {
            return _tokenIdCounterLargeLands;
        }
        revert("Invalid size");
    }

    function totalSupplyBySize(Size size) public view returns (uint256) {
        return getCounter(size).current();
    }

    function increaseSupplyBySize(Size size) internal {
        getCounter(size).increment();
    }

    function maxSupplyBySize(Size size) public view returns (uint256) {
        return getSpec(size).maxSupply;
    }

    function withdraw(address receiver) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(receiver).transfer(balance);
    }

    fallback() external payable {}

    receive() external payable {}
}
