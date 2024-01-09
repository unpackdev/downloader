// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

contract IWasRight is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256[] public predictionsHashes;
    uint256 public IWRPrice = 0 ether;
    string public _baseIWRURI;
    
    event IWasRightMinted(address indexed mintAddress, uint256 indexed tokenId, uint256 predictionHash);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI) ERC721Optimized("IWasRight", "IWR") {
        _baseIWRURI = baseURI;
    }

    function getPredictionHashes() public view returns (uint256[] memory) {
        return predictionsHashes;
    }

    function getPredictionHash(uint256 tokenId) public view returns (uint256) {
        require(predictionsHashes.length > tokenId, "Prediction tokenId does not exist");
        return predictionsHashes[tokenId];
    }

    function giveAway(address to, uint256 predictionHash) public onlyOwner {
        createCollectible(to, predictionHash);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _baseIWRURI = newuri;
    }

    function setMintCost(uint256 newCost) public onlyOwner {
        require(newCost >= 0, "IWRPrice must be greater than zero");
        IWRPrice = newCost;
    }

    function mintIWR(uint256 predictionHash) public payable nonReentrant {
        require(IWRPrice <= msg.value, "Ether value sent is not correct");
        createCollectible(_msgSender(), predictionHash);
    }

    function createCollectible(address mintAddress, uint256 predictionHash) private {
        uint256 tokenId = predictionsHashes.length;
        _safeMint(mintAddress, tokenId);
        predictionsHashes.push(predictionHash);
        emit IWasRightMinted(mintAddress, tokenId, predictionHash);
    }

    function freezeMetadata(uint256 tokenId, string memory ipfsHash) public {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(_msgSender() == ERC721Optimized.ownerOf(tokenId), "Caller is not a token owner");
	    emit PermanentURI(ipfsHash, tokenId);
	}

    function _baseURI() internal view virtual returns (string memory) {
	    return _baseIWRURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
}
