// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract NipplePunkTickets is ERC721Enumerable, Ownable {
    uint256 constant NIPPLE_PUNK_TOTAL_SUPPLY = 10000;

    uint256 public available = 0;
    uint256 public nextTokenId = 0;

    bool public presaleOpen = false;
    bool public publicMintOpen = false;
    bytes32 public presaleWhitelistMerkleRoot;

    uint256 public publicMintPrice = 0.07 ether;
    uint256 public presaleMintPrice = 0.02 ether;

    mapping(address => bool) presaleUsed;

    uint16[NIPPLE_PUNK_TOTAL_SUPPLY] public ticketToNipplePunkMapping;
    bytes32 public mappingHash;

    constructor(bytes32 mappingHash_) ERC721("NipplePunkTickets", "\u2299T") {
        mappingHash = mappingHash_;
    }

    modifier onlyWhenNextTokenAvailable() {
        require(nextTokenId < available, "No more tokens available");
        _;
    }

    function _mintImpl() private {
        _safeMint(_msgSender(), nextTokenId++);
    }

    function presaleMint(bytes32[] calldata proof)
        external
        payable
        onlyWhenNextTokenAvailable
    {
        require(presaleOpen, "Presale is not open");
        require(msg.value >= presaleMintPrice, "Wrong price");
        require(
            !presaleUsed[_msgSender()],
            "You have already used your presale quota"
        );
        require(
            MerkleProof.verify(
                proof,
                presaleWhitelistMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Invalid proof"
        );
        presaleUsed[_msgSender()] = true;
        _mintImpl();
    }

    function publicMintMultiple(uint256 count)
        external
        payable
        onlyWhenNextTokenAvailable
    {
        require(publicMintOpen, "Public mint is not open");
        require(msg.value >= publicMintPrice * count, "Wrong price");
        for (uint256 i = 0; i < count; i++) {
            _mintImpl();
        }
    }

    function publicMint() external payable onlyWhenNextTokenAvailable {
        this.publicMintMultiple(1);
    }


    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function setAvailable(uint256 _available) external onlyOwner {
        available = _available;
    }

    function setPresaleOpen(bool _presaleOpen) external onlyOwner {
        presaleOpen = _presaleOpen;
    }

    function setPublicMintOpen(bool _publicMintOpen) external onlyOwner {
        publicMintOpen = _publicMintOpen;
    }

    function setPresaleWhitelistMerkleRoot(bytes32 _presaleWhitelistMerkleRoot)
        external
        onlyOwner
    {
        presaleWhitelistMerkleRoot = _presaleWhitelistMerkleRoot;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    function setPresaleMintPrice(uint256 _presaleMintPrice) external onlyOwner {
        presaleMintPrice = _presaleMintPrice;
    }

    function calculateMappingHash() public view returns (bytes32) {
        return keccak256(abi.encode(ticketToNipplePunkMapping));
    }

    function verifyMappingHash() external view returns (bool) {
        return mappingHash == calculateMappingHash();
    }

    function setMapping(uint16[] calldata mappings, uint16 offset)
        external
        onlyOwner
    {
        require(
            offset + mappings.length < NIPPLE_PUNK_TOTAL_SUPPLY,
            "invalid offset or mapping length"
        );
        for (uint256 i = 0; i < mappings.length; i++) {
            ticketToNipplePunkMapping[i + offset] = mappings[i];
        }
    }
}
