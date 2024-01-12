// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol"; 


contract WhatIsThisNFT is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    // -=Configuration=-

    mapping(address => uint) public freeMinted;
    string internal baseUri;
    string public preRevealMetadataURI = 'ipfs://QmUvZoJrJDocCCXg9jTFJvRbLKAgj6VUEsBbCejHuVvyLL/';
    bool public metadataReveal = false;
    uint256 public mintPrice = 0.0666 ether;
    uint256 public maxSupply = 666;
    uint256 public freeMintAmount = 1;
    uint256 public maxPerTXN = 6;
    bool public freeMint = false;
    bool public publicMint = false;
    bytes32 root;
    
    constructor() ERC721A("WhatIsThisNFT", "WITNFT") {}
    
    // -=Mint Functions=-

    function mintFree(bytes32[] memory proof) external nonReentrant {
        require(freeMint, "You cant mint yet.");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))), "You are not whitelisted!");
        require(freeMinted[msg.sender] < 1, "You've already minted your Free WhatIsThis NFT.");
        require(totalSupply() + freeMintAmount <= maxSupply, "Max supply for Free mints has been reached.");
        freeMinted[msg.sender] += freeMintAmount;
        _safeMint(msg.sender, freeMintAmount);

    }

    function mintPublic(uint256 _amount) external payable nonReentrant {
        require(publicMint, "Sale hasnt commenced yet.");
        require(_amount <= maxPerTXN && _amount > 0, "Max 6 per TXN.");
        require(_amount + totalSupply() <= maxSupply, "There's not enough supply left.");
        require(msg.value >= mintPrice * _amount, "One WhatIsThis NFT costs 0.0666 Ether.");
        _safeMint(msg.sender, _amount);
    }
    
    // -=Configuration functions=-

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }
    
    function setMaxPerTXN(uint256 _maxTXN) external onlyOwner {
        maxPerTXN = _maxTXN;
    }

    function togglePublic() external onlyOwner {
        publicMint = !publicMint;
    }
    
    function toggleFreeMint() external onlyOwner {
        freeMint = !freeMint;
    }
    
    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    // -=Metadata functions=-

    function setMetadata(string calldata newUri) external onlyOwner {
        baseUri = newUri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (metadataReveal == false) {
        return preRevealMetadataURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), '.json'))
            : '';
    }

    function setHiddenMetadataUri(string memory hiddenMetadataUri) public onlyOwner {
        preRevealMetadataURI = hiddenMetadataUri;
    }

    function revealMetadata() public onlyOwner {
        metadataReveal = !metadataReveal;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    

    // -=Funds withdrawal=-

    function transferFunds() public onlyOwner {
	    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
    
}