// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract TurtleVerse is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    event Paused();
    event Resumed();
    event UnmintedTurtlesBurned();

    uint256 public constant MAX_TURTLES = 3333; // reserve+whitelist+public sale
    uint256 public constant PRIVATE_RESERVE = 10; // community, giveaways, events
    uint256 public constant FREE_RESERVE = 1111;
    uint256 public TURTLE_PRICE = 30000000000000000; // 0.03 ETH
    uint256 public constant PURCHASE_LIMIT = 20;

    // COLLECTION PROVENANCE TO BE ADDED AFTER THE SALE
    string public TURTLES_PROVENANCE = "";

    address private constant TEAM1 = 0xb17308B7942aeCE53B36B9799e15E3d9420a2BC4;
    address private constant TEAM2 = 0xa0B4aB49Ea3C060175BBc47e0316abc6C8904202;

    address public verifiedSigner;
    uint256 public totalSupply;
    uint256 public reservedSupply;
    bool public revealed;
    bool public paused;
    bool public terminated;
    bool public uriLocked;
    mapping(uint256 => uint256) public genesisTurtles;
    mapping(address => uint256) public freeMintUsed;
    string public baseURI;

    constructor() ERC721("TurtleVerse", "TURTLEVERSE") {
        baseURI = "https://api.turtleverse.info";
    }

    // owner controls
    function setProvenanceHash(string memory provenanceHash)
        external
    {
        requireOnlyOwner();
        require(
            bytes(TURTLES_PROVENANCE).length == 0,
            "Provenance hash already set."
        );
        require(bytes(provenanceHash).length > 0, "Provenance hash is empty");
        TURTLES_PROVENANCE = provenanceHash;
    }

    function reserveTurtles(address to) external {
        requireOnlyOwner();
        require(to != address(0), "Zero receiver address");
        require(reservedSupply < PRIVATE_RESERVE, "Out of reserved Turtles.");
        _mintOwner(to);
        _checkReveal();
    }

    function setVerifiedSigner(address signer) external {
        requireOnlyOwner();
        require(signer != address(0), "Cannot set zero verified signer.");
        verifiedSigner = signer;
    }

    function toggle() external {
        requireOnlyOwner();
        paused = !paused;
        if (paused) emit Paused();
        else emit Resumed();
    }

    function burnUnminted() external {
        requireOnlyOwner();
        terminated = true;
        emit UnmintedTurtlesBurned();
    }

    function lockURI() external {
        requireOnlyOwner();
        uriLocked = true;
    }

    function setURI(string memory uri) external {
        requireOnlyOwner();
        require(!uriLocked, "URI locked");
        baseURI = uri;
    }

    function reveal() external {
        requireOnlyOwner();
        revealed = true;
    }

    function setTurtlePrice(uint256 newPrice) external {
        requireOnlyOwner();
        TURTLE_PRICE = newPrice;
    }

    function identGenesisTurtles(uint256[] calldata turtleIds)
        external 
    {
        requireOnlyOwner();
        for (uint256 t = 0; t < turtleIds.length; t++) {
            _setGenesisTurtle(turtleIds[t]);
        }
    }

    function mint(uint256 turtles, bytes calldata signature) external payable nonReentrant {
        _notPausedOrTerminated();
        if (_freebieZone()) {
            mintFree(turtles, signature);
        } else {
            mintAtCost(turtles);
        }
    }

    function mintFree(uint256 turtles, bytes calldata signature) internal {
        require(turtles >= 1 && turtles <= PURCHASE_LIMIT, "Invalid Quantity");
        require(freeMintUsed[msg.sender] + turtles <= PURCHASE_LIMIT, "Freebie Limit Exceeded");
        require(msg.value == 0, "Expected 0 ETH");
        _validSignature(msg.sender, signature);
        freeMintUsed[msg.sender] += turtles;
        _mintPublic(msg.sender, turtles);
    }

    function mintAtCost(uint256 turtles) internal {
        require(turtles >= 1 && turtles <= PURCHASE_LIMIT, "Invalid Quantity");
        require(turtles <= _mintable(), "Max Turtles Supply Exceeded.");
        require(
            turtles * TURTLE_PRICE == msg.value,
            "Invalid ETH Amount Sent."
        );

        _mintPublic(msg.sender, turtles);

        _checkReveal();
    }

    function tokenExists(uint256 turtleId) external view returns (bool) {
        return _exists(turtleId);
    }

    function tokenURI(uint256 turtleId)
        public
        view
        virtual
        override
        returns (string memory result)
    {
        require(_exists(turtleId), "Request for non-existent token");

        if (revealed) {
            return
                string(
                    abi.encodePacked(baseURI, "/metadata/", turtleId.toString(), ".json")
                );
        } else {
            return string(abi.encodePacked(baseURI, "/metadata/invisible.json"));
        }
    }

    function withdraw() external {
        payable(TEAM1).transfer(address(this).balance / 4);
        payable(TEAM2).transfer(address(this).balance);
    }

    function freebiesAvailable() external view returns (bool) {
        return _freebieZone();
    }

    function freebiesMintableBy(address by) external view returns (uint256) {
        return PURCHASE_LIMIT - freeMintUsed[by];
    }

    function freebiesMintable() external view returns (uint256) {
        return PURCHASE_LIMIT - freeMintUsed[msg.sender];
    }

    function isGenesisTurtle(uint256 turtle) external view returns (bool) {
        return _isGenesisTurtle(turtle);
    }

    function _checkReveal() internal {
        if ((totalSupply - reservedSupply) == (MAX_TURTLES - PRIVATE_RESERVE)) {
            revealed = true;
        }
    }

    function _setGenesisTurtle(uint256 turtleId) internal {
        uint256 wordIndex = turtleId / 256;
        uint256 bitIndex = turtleId % 256;
        genesisTurtles[wordIndex] = genesisTurtles[wordIndex] | (1 << bitIndex);
    }

    function _isGenesisTurtle(uint256 turtleId) internal view returns (bool) {
        uint256 wordIndex = turtleId / 256;
        uint256 bitIndex = turtleId % 256;
        uint256 word = genesisTurtles[wordIndex];
        uint256 mask = (1 << bitIndex);
        return word & mask == mask;
    }

    function _mintPublic(address to, uint256 qt) internal {
        for (uint256 t = 0; t < qt; t++) {
            _safeMint(to, PRIVATE_RESERVE + (totalSupply - reservedSupply) + t);
        }

        totalSupply += qt;
    }

    function _mintOwner(address to) internal {
        reservedSupply += 1;
        totalSupply += 1;
        _safeMint(to, reservedSupply - 1);
    }

    function _freebieZone() internal view returns (bool) {
        return (totalSupply - reservedSupply) < FREE_RESERVE;
    }

    function _mintable() internal view returns (uint256) {
        return MAX_TURTLES - PRIVATE_RESERVE - (totalSupply - reservedSupply);
    }

    function _notPausedOrTerminated() internal view {
        require(!paused, "Contract/Minting is paused.");
        require(!terminated, "Minting stopped forever.");
    }

    function _validSignature(address account, bytes calldata signature)
        internal
        view
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(account))
            )
        );
        require(
            hash.recover(signature) == verifiedSigner,
            "Invalid signature."
        );
    }

    function requireOnlyOwner() internal view {
        require(msg.sender == owner(), "Ownable: caller is not the owner");
    }
}
