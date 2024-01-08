// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

/**
 * @title PoliteRaptors contract
 */
contract PoliteRaptors is ERC721Enumerable, ERC721URIStorage, Ownable {
    string public provenanceHash = "";
    uint256 public maxRaptors;
    bool public metadataFrozen;
    bool public provenanceFrozen;

    // in case something breaks this contract and we have to use fallback contract
    address public fallbackMinter;

    string public baseUri;
    bool public saleIsActive;

    bool public revealed;
    string public unrevealedTokenUri;

    event SetBaseUri(string indexed baseUri);

    modifier whenSaleIsActive() {
        require(saleIsActive, "PRP: Sale is not active");
        _;
    }

    modifier whenMetadataIsNotFrozen() {
        require(!metadataFrozen, "PRP: Metadata already frozen.");
        _;
    }

    modifier whenProvenanceIsNotFrozen() {
        require(!provenanceFrozen, "PRP: Provenance already frozen.");
        _;
    }

    constructor() ERC721("Polite Raptors Pack", "PRP") {
        saleIsActive = false;
        maxRaptors = 10000;
        metadataFrozen = false;
        provenanceFrozen = false;
        revealed = false;
    }

    // ------------------
    // Explicit overrides
    // ------------------

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage, ERC721) returns (string memory) {
        if (revealed) {
            return super.tokenURI(tokenId);
        } else {
            return unrevealedTokenUri;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // ------------------
    // Public functions
    // ------------------

    function mint(uint256 amount) external payable whenSaleIsActive {
        require(amount <= 50, "PRP: Amount exceeds max per mint");
        require(totalSupply() + amount <= maxRaptors, "PRP: Purchase would exceed cap");
        require(totalSupply() >= 3000, "PRP: Free mint not finished");

        bool refundPrev = true;
        uint256 _mintPrice = 50000000000000000; // 0.05 ETH
        uint256 supplyAfterMint = totalSupply() + amount;

        if (supplyAfterMint > 9000) {
            _mintPrice = 100000000000000000; // 0.1 ETH
            refundPrev = false;
        } else if (supplyAfterMint > 6000) {
            _mintPrice = 75000000000000000; // 0.075 ETH
        }

        require(_mintPrice * amount <= msg.value, "PRP: ETH value sent is not correct");

        uint256 mintIndex = totalSupply() + 1;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintIndex);
            address prevOwner = ownerOf(mintIndex - 3000);
            if (refundPrev && !isContract(prevOwner)) {
                payable(prevOwner).transfer(_mintPrice - 25000000000000000);
            }
            mintIndex += 1;
        }
    }

    function mintFree(uint256 amount) external whenSaleIsActive {
        require(totalSupply() + amount <= 3000, "PRP: Free to mint limit reached");
        require(totalSupply() + amount <= maxRaptors, "PRP: Mint would exceed cap");
        require(amount <= 3, "PRP: Only 3 free mints per tx");
        require(balanceOf(msg.sender) + amount <= 3, "PRP: Only 3 per address");

        uint256 mintIndex = totalSupply() + 1;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintIndex);
            mintIndex += 1;
        }
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    function fallbackMint(uint256 amount) external {
        require(totalSupply() + amount <= maxRaptors, "PRP: Mint would exceed cap");
        require(msg.sender == fallbackMinter, "PRP: Only for fallback minter");

        uint256 mintIndex = totalSupply() + 1;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, mintIndex);
            mintIndex += 1;
        }
    }

    // ------------------
    // Owner functions
    // ------------------

    function setBaseUri(string memory _baseUri) external onlyOwner whenMetadataIsNotFrozen {
        baseUri = _baseUri;
        emit SetBaseUri(baseUri);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyOwner whenMetadataIsNotFrozen {
        super._setTokenURI(_tokenId, _tokenURI);
    }

    function mintForCommunity(address to, uint256 numberOfTokens) external onlyOwner {
        require(to != address(0), "PRP: Cannot mint to zero address.");
        require(totalSupply() + numberOfTokens <= maxRaptors, "PRP: Mint would exceed cap");

        uint256 mintIndex = totalSupply() + 1;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, mintIndex);
            mintIndex += 1;
        }
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner whenProvenanceIsNotFrozen {
        provenanceHash = _provenanceHash;
    }

    function setUnrevealedTokenUri(string memory _unrevealedTokenUri) external onlyOwner whenMetadataIsNotFrozen {
        unrevealedTokenUri = _unrevealedTokenUri;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function emergencyRecoverTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(receiver != address(0), "Cannot recover tokens to the 0 address");
        token.transfer(receiver, amount);
    }

    function freezeMetadata() external onlyOwner whenMetadataIsNotFrozen {
        metadataFrozen = true;
    }

    function freezeProvenance() external onlyOwner whenProvenanceIsNotFrozen {
        provenanceFrozen = true;
    }

    function setFallbackMinter(address newFallbackMinter) external onlyOwner {
        fallbackMinter = newFallbackMinter;
    }

    function reduceMaxRaptors(uint256 newMaxRaptors) external onlyOwner {
        require(newMaxRaptors < maxRaptors, "PRP: Can only be reduced!");
        maxRaptors = newMaxRaptors;
    }

    // ------------------
    // Private helper functions
    // ------------------
    function isContract(address _addr) private returns (bool isContract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}
