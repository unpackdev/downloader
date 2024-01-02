// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.9;
 
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC2981.sol";
import "./ERC2981.sol";
 
 
contract MO is ERC721A, Ownable, ReentrancyGuard, ERC2981 { 
    event DevMintEvent(address ownerAddress, uint256 startWith, uint256 amountMinted);
    uint256 public devTotal;
    uint256 public _maxSupply = 420;
    uint256 public _mintPrice = 0.0042 ether;
    uint256 public _maxMintPerTx = 10;
    uint256 public _maxFreeMintPerAddr = 0;
    uint256 public _maxFreeMintSupply = 0;
    uint256 public devSupply = 0;
 
    using Strings for uint256;
    string public baseURI;
    mapping(address => uint256) private _mintedFreeAmount;
 
    // Royalties
    address public royaltyAdd;
 
    constructor(string memory initBaseURI) ERC721A("Mars Oasis", "MO") {
        baseURI = initBaseURI;
        setDefaultRoyalty(msg.sender, 420); // 4%
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
 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
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
