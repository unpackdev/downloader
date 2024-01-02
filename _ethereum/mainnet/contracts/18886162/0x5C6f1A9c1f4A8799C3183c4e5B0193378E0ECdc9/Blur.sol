// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC2981.sol";
import "./ERC2981.sol";
 
 
contract Blur is ERC721A, Ownable, ReentrancyGuard, ERC2981 { 
    event DevMintEvent(address ownerAddress, uint256 startWith, uint256 amountMinted);
    uint256 public devTotal;
    uint256 public _maxSupply = 10000;
    uint256 public _mintPrice = 0.001 ether;
    uint256 public _maxMintPerTx = 100;
    uint256 public _maxFreeMintPerAddr = 1;
    uint256 public _maxFreeMintSupply = 5000;
    uint256 public devSupply = 0;
 
    using Strings for uint256;
    string public baseURI;
    bool public revealed = false;
    string public notRevealedUri;

    mapping(address => uint256) private _mintedFreeAmount;
 
    // Royalties
    address public royaltyAdd;
 
    constructor(string memory initBaseURI) ERC721A("Blur-20", "BLUR") {
        baseURI = initBaseURI;
        setDefaultRoyalty(msg.sender, 0); // 700%
    }
 
    // Set default royalty account & percentage
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public {
        royaltyAdd = _receiver;
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
 
    // Set token specific royalty
    function setTokenRoyalty(uint256 tokenId, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, royaltyAdd, feeNumerator);
    }
 
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view override returns (address, uint256) {
        (, uint256 royaltyAmt) = super.royaltyInfo(_tokenId, _salePrice);
        return (royaltyAdd, royaltyAmt);
    }
 
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || 
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }
 
    function mint(uint256 count) external payable {
        uint256 cost = _mintPrice;
        bool isFree = (
            (totalSupply() + count < _maxFreeMintSupply + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= _maxFreeMintPerAddr)
        ) || (msg.sender == owner());
 
        if (isFree) {
            cost = 0;
        }
 
        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < _maxSupply - devSupply + 1, "Sold out!");
        require(count < _maxMintPerTx + 1, "Max per TX reached.");
 
        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }
 
        _safeMint(msg.sender, count);
    }
 
    function devMint() public onlyOwner {
        devTotal += devSupply;
        emit DevMintEvent(_msgSender(), devTotal, devSupply);
        _safeMint(msg.sender, devSupply);
    }

   
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

 function reveal() public onlyOwner {
      revealed = true;
  }
  
 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

   if(revealed == false) {
        return notRevealedUri;
    }

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

   function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }


    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
 
    function setFreeAmount(uint256 amount) external onlyOwner {
        _maxFreeMintSupply = amount;
    }
 
    function setPrice(uint256 _newPrice) external onlyOwner {
        _mintPrice = _newPrice;
    }
 
    function setMaxMintPerTx(uint256 _newMaxMintPerTx) external onlyOwner {
        _maxMintPerTx = _newMaxMintPerTx;
    }
 
    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success);
    }
}

