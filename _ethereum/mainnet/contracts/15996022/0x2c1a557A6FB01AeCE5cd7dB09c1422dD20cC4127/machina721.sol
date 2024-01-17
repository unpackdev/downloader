// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Solidity Modules
import "./ERC721B.sol";
import "./ERC721TokenURI.sol";
import "./Ownable.sol";
import "./Controllerable.sol";

contract Machina is ERC721B("Machina", "MACHINA"), ERC721TokenURI, Ownable,
Controllerable {

    ///// Proxy Initializer /////
    bool public proxyIsInitialized;
    function proxyInitialize(address newOwner_) public {
        require(!proxyIsInitialized, "Proxy already initialized");
        proxyIsInitialized = true;

        // Hardcode
        owner = newOwner_; // Ownable.sol

        name = "Machina"; // ERC721B.sol
        symbol = "MACHINA"; // ERC721B.sol
        nextTokenId = startTokenId(); // ERC721B.sol
    }

    ///// Constructor (For Implementation Contract) /////
    constructor() {
        proxyInitialize(msg.sender);
    }

    ///// Controllerable Config /////
    modifier onlyMinter() {
        require(isController("Minter", msg.sender),
                "Controllerable: Not Minter!");
        _;
    }

    ///// ERC721B Overrides /////
    function startTokenId() public pure virtual override returns (uint256) {
        return 1;
    }

    ///// Ownable Functions /////
    function ownerMint(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }
    function ownerBurn(uint256[] calldata tokenIds_) external onlyOwner {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do {
            _burn(tokenIds_[i], false);
        } while (++i < l); }
    }

    ///// Controllerable Functions /////
    function mintAsController(address to_, uint256 amount_) external onlyMinter {
        _mint(to_, amount_);
    }

    ///// Metadata Governance /////
    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }

    ///// TokenURI /////
    function tokenURI(uint256 tokenId_) public virtual view override 
    returns (string memory) {
        require(ownerOf(tokenId_) != address(0), "Token does not exist!");
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_)));
    }
}