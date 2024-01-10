// contracts/SkatePunksClub.sol
// SPDX-License-Identifier: No License

pragma solidity 0.8.10;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

/**
 * @title Skate Punks Club (SKPC) contract
 * @dev Extends ERC721 Non-Fungible Token Standard
 */
contract SkatePunksClub is ERC721Enumerable, ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    string public SKPC_PROVENANCE = "";

    bool public saleIsActive = false;
    bool public whitelistIsActive = false;

    string private baseTokenURI = "";

    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    uint256 public constant punkPricePublic = 75000000000000000; // 0.075 ETH
    uint256 public constant punkPriceWhitelist = 50000000000000000; // 0.050 ETH

    mapping(address => uint16) purchases;

    uint256 public constant maxPunksPurchasePublic = 20;
    uint256 public constant maxPunksPurchaseWhitelist = 10;

    uint256 public MAX_PUNKS;
    uint256 public REVEAL_TIMESTAMP;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply,
        uint256 saleStart
    ) ERC721(name, symbol) {
        MAX_PUNKS = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart + (86400 * 6);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Set some Skatepunks aside for charity and giveaways
     */
    function reservePunks() public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < 650; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * Set reveal timestamp
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    /**
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SKPC_PROVENANCE = provenanceHash;
    }

    /**
     * Set base URI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * Pause whitelist if active, make active if paused
     */
    function flipWhitelistState() public onlyOwner {
        whitelistIsActive = !whitelistIsActive;
    }

    /**
     * Mints Skatepunks
     */
    function mintPunk(uint16 numberOfTokens, uint256 timestamp, bytes memory signature) public payable {
        if (whitelistIsActive && signature.length > 0) {
            address signer = ECDSA.recover(keccak256(abi.encode(numberOfTokens, timestamp)), signature);
            require(signer == msg.sender, "Not authorized to mint");
        }

        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_PUNKS, "Purchase would exceed max supply of Skatepunks");

        if (whitelistIsActive) {
            require((purchases[msg.sender] + numberOfTokens) <= maxPunksPurchaseWhitelist, "You will exceed the maximum tokens allowed per address for the private sale");
            require(punkPriceWhitelist.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        } else {
            require((purchases[msg.sender] + numberOfTokens) <= maxPunksPurchasePublic, "You will exceed the maximum tokens allowed per address for the public sale");
            require(punkPricePublic.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        }

        purchases[msg.sender] = purchases[msg.sender] + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_PUNKS) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == MAX_PUNKS || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_PUNKS;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % MAX_PUNKS;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
