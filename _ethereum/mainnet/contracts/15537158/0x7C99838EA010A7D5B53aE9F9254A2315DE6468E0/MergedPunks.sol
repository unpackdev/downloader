// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC721Receiver.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./ERC721.sol";


contract MergedPunks is ERC721A, Ownable {

    using Strings for uint256;

    string public uriPrefix;
    string public uriSuffix = ".json";

    uint256 public price = 0.002 ether;

    uint256 public maxPerTx = 20;

    uint256 public maxFreePerWallet = 3;

    uint256 public totalFree = 3333;

    uint256 public maxSupply = 3333;

    bool public mintEnabled = false;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor() ERC721A("Merged Punks", "MP") {
        _safeMint(msg.sender, 10);
        setUriPrefix("ipfs://QmdUpu81BPEe5tre7mK21CKE7iN3NaDZ7sZdTfL2sxSqMb/");
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
    }

    // Start Token
    
    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
    }

    function createPreMergePunk(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= maxFreePerWallet));

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < maxSupply + 1, "No more");
        require(mintEnabled, "Minting is not live yet");
        require(count < maxPerTx + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token.");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
    : "";
    }

    // BaseURI
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
    }
  }

