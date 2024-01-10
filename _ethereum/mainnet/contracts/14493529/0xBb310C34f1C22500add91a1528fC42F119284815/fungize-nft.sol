import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


contract FungizeNft is ERC721, Ownable, ReentrancyGuard{

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MintPrice = 0.05 ether;
    mapping(address => uint256) public WhiteList;
    uint256 public MaxCollectionSize = 5555;
    uint256 private CurrentSupply;
    bool public SaleOpen;
    string public BaseUri;
    bool public PublicSaleOpen;

    constructor() ERC721("MUSH", "Fungize Token"){

    }

    function uploadWhitelist(address[] calldata _address) public onlyOwner{
        for(uint256 i; i < _address.length; i++){
            WhiteList[_address[i]] = 3;
        }
    }

    function mintMushroom(uint256 _quantity) public payable nonReentrant {
        require(SaleOpen, "Sale closed");
        require(WhiteList[msg.sender] >= _quantity || PublicSaleOpen, "Not allowed");
        require(CurrentSupply < MaxCollectionSize, "Sold out");
        require(_quantity <= 3 && _quantity != 0, "incorrect quantity");
        require(_quantity.mul(MintPrice) == msg.value, "incorrect ether");
        

        for(uint256 i; i < _quantity; i++){
            _safeMint(msg.sender, CurrentSupply++);
        }

        if (!PublicSaleOpen){
            WhiteList[msg.sender] -= _quantity;
        }
    }

    function adminMint(address _to) public payable onlyOwner {
        require(CurrentSupply < MaxCollectionSize, "Sold out");
        _safeMint(_to, CurrentSupply++);
    }

    //only owner function.. Needs updating with Wei amount.
    function updateMintAmount(uint256 _mintPrice) public onlyOwner {
        MintPrice = _mintPrice;
    }

    //only owner function
    function toggleSale() public onlyOwner {
        SaleOpen = !SaleOpen;
    }

    //only owner function
    function togglePublicSale() public onlyOwner {
        PublicSaleOpen = !PublicSaleOpen;
    }

    //only owner function
    function updateBaseUri(string memory _uri) public onlyOwner {
        BaseUri = _uri;
    }

    //only owner function
    function ownerMintMushroom(address _to) public onlyOwner { 
        require(CurrentSupply < MaxCollectionSize, "Sold out");
               
        _safeMint(_to, CurrentSupply++);
    }

    function withdrawEth() public onlyOwner {		
		payable(msg.sender).transfer(address(this).balance);		
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return BaseUri;
    }
    
    function totalSupply() public view returns (uint256) {
        return CurrentSupply;
    }
}
