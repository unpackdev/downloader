// SPDX-License-Identifier: MIT

pragma solidity^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";

contract BlockheadTweets is ERC721Enumerable, Ownable {
    mapping(uint256 => bool) private hasBeenMinted;
    uint256 maxTokens = 250;
    string ipfsHash;

    event TokenMinted(uint256 tokenId, address to);

    // constructor
    constructor() ERC721 ("Blockhead Tweets", "GOODGRIEF") {
        ipfsHash = "QmebYor8onxF86nv5UzoQ7zzXUav4WtxLCkMg687TuheL2";
    }
    
    // minting functionality
    function mintToken(uint256 tokenId) external payable {
        require(!hasBeenMinted[tokenId], "This token ID has already been minted.");
        require (tokenId >= 1 && tokenId <= 250, "Token ID is out of range.");
        require(totalSupply() < 250, "Minting is done.");
        require(msg.value == 0.5 ether, "Incorrect ETH transferred -- please send exactly 0.5 ETH.");
        payable(owner()).transfer(address(this).balance);
        hasBeenMinted[tokenId] = true;        
        _safeMint(msg.sender, tokenId);
        emit TokenMinted(tokenId, msg.sender);

    }
    
    function ownerMint(uint256 tokenId) external onlyOwner {
        require(!hasBeenMinted[tokenId], "This token ID has already been minted.");
        require (tokenId >= 1 && tokenId <= 250, "Token ID is out of range.");
        require(totalSupply() < 250, "Minting is done.");
        hasBeenMinted[tokenId] = true;
        _safeMint(msg.sender, tokenId);
        emit TokenMinted(tokenId, msg.sender);
    }
    
    // token URI retrieval
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return (string(abi.encodePacked("ipfs://", ipfsHash, "/", tokenId)));
    }

    function withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }
}
