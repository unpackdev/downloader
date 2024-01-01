// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./ERC721URIStorage.sol";

contract MalevaConcierge is ERC721, Ownable, ERC721Royalty, ERC721URIStorage {
    using Strings for uint256;
    
    // Structure to hold NFT type details
    struct NFTType {
        string name;
        uint256 startSupply;
        uint256 currentSupply;
        uint256 preSaleMint;
        uint256 publicMint;
        uint256 totalSupply;
        uint256 price;
    }

    /*
        Platinum: 
        starting Point: 1
        //Details
        startSupply 0
        currentSupply: 0
        preSaleMint 30
        publicMint 90
        totalSupply 150
        price: 9.84
        
        Elite: 
        starting Point: 151
        //Details
        startSupply 150
        currentSupply: 0
        preSaleMint 320
        publicMint 660
        totalSupply 850
        price: 5.94

        Chrome: 
        starting Point: 1001
        //Details
        startSupply 850
        currentSupply: 0
        preSaleMint 1360
        publicMint 2080
        totalSupply 1800
        price: 3.88
     */

    bool public isPresale = true;
    uint private TOTAL_SUPPLY = 2800;
    string private BASE_URI = '';
    string private CONTRACT_URI = '';
    address public PAYMENT_ADDRESS_NFT_SALE;
    address public TEAM_ALLOCATION_ADDRESS;

    modifier onlyPresaleMint () {
        require(isPresale, "Presale mint ended.");
        _;
    }
    modifier onlyPublicMint () {
        require(!isPresale, "Presale is enabled.");
        _;
    }
    modifier onlyWhitelistedAddress () {
        require(presaleWhitelist[msg.sender], "Only White listed address allowed.");
        _;
    }

    mapping(uint256 => NFTType) private _tokenTypes;
    mapping(address => bool) public presaleWhitelist;

    event MintedNFT(uint256 typeId, uint256 tokenId, address indexed recipient);
    event ReserveNFTClaimed(address claimedBy);



    constructor(
        uint[] memory _pricesInETH,
        string memory _uri,
        string memory _contract_uri,
        address _teamAllocationAddress,
        address _paymentAddressForNFTSale, 
        address _paymentAddressForRoyalties
    ) Ownable() ERC721("Maleva Concierge", "MCNFT") {
        BASE_URI = _uri;
        CONTRACT_URI = _contract_uri;
        _tokenTypes[2] = NFTType("Platinum",0, 0, 30, 90, 150, _pricesInETH[0]);
        _tokenTypes[1] = NFTType("Elite", 150, 0, 320, 660, 850, _pricesInETH[1]);
        _tokenTypes[0] = NFTType("Chrome", 1000, 0, 1360, 2080, 1800, _pricesInETH[2]);
        TEAM_ALLOCATION_ADDRESS = _teamAllocationAddress;
        PAYMENT_ADDRESS_NFT_SALE = _paymentAddressForNFTSale;
        _setDefaultRoyalty(_paymentAddressForRoyalties, 1000); // 10% Royalties
    }

    function enablePreSale () external onlyOwner {
        isPresale = !isPresale; 
    }


    function typeOfToken (uint256 typeId) public view returns (NFTType memory) {
        require(typeId >= 0 && typeId < 3, "Invalid NFT type");
        NFTType memory nftType = _tokenTypes[typeId];
        return nftType;
    }

    function mintNFT(uint256 typeId, address recipient) public payable onlyPublicMint {
        NFTType memory nftType = typeOfToken(typeId);
        uint tokenId = nftType.currentSupply + 1;
        require(tokenId <= nftType.publicMint, "NFT type sold out");
        require(msg.value >= nftType.price, "Insufficient funds");
        (bool send, ) = payable(PAYMENT_ADDRESS_NFT_SALE).call{value: msg.value}("");
        require(send, "Error in Sending ETH to Payment Address.");
        NFTType storage toBeUpdateNftType = _tokenTypes[typeId];
        toBeUpdateNftType.currentSupply = tokenId;
        tokenId = tokenId + nftType.preSaleMint;
        _mint(recipient, tokenId);
        emit MintedNFT(typeId, tokenId, recipient);
    }

    function preSaleMint(uint256 typeId, address recipient) public payable onlyPresaleMint onlyWhitelistedAddress {
        NFTType memory nftType = typeOfToken(typeId);
        uint tokenId = nftType.currentSupply + 1;
        require(tokenId <= nftType.preSaleMint, "NFT type sold out");
        require(msg.value >= nftType.price, "Insufficient funds");
        (bool send, ) = payable(PAYMENT_ADDRESS_NFT_SALE).call{value: msg.value}("");
        require(send, "Error in Sending ETH to Payment Address.");
        NFTType storage toBeUpdateNftType = _tokenTypes[typeId];
        toBeUpdateNftType.currentSupply = tokenId;
        tokenId = tokenId + nftType.startSupply;
        _mint(recipient, tokenId);
        emit MintedNFT(typeId, tokenId, recipient);
    }

    function updateTypePrice(uint256 typeId, uint256 newPrice) public onlyOwner {
    require(typeId >= 0 && typeId < 3, "Invalid NFT type");
    NFTType storage nftType = _tokenTypes[typeId];
    nftType.price = newPrice;
    }

    function updateRoyaltyFee(address _recipient, uint96 newFee) public onlyOwner {
        require(newFee > 0, "Invalid fee");
        _setDefaultRoyalty(_recipient, newFee);
    }

    function addToPreSaleWhitelist(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            presaleWhitelist[addresses[i]] = true;
        }
    }

    function removeFromPreSaleWhitelist(address[] memory addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            presaleWhitelist[addresses[i]] = false;
        }
    }

    function mintReserveNFTs(uint256 typeId, address recipient) external {
        require(msg.sender == TEAM_ALLOCATION_ADDRESS, "Not the Team Allocated Address.");
        if (typeId == 0) {
        uint _platinumResStart = 2081;
        uint _platinumResEnd = 2800;
        for (uint _tokenId = _platinumResStart; _tokenId <= _platinumResEnd; _tokenId++) {
            _mint(recipient, _tokenId);
        }
        } else if (typeId == 1) {   
        uint _eliteResStart = 661;
        uint _eliteResEnd = 1000;
        for (uint _tokenId = _eliteResStart; _tokenId <= _eliteResEnd; _tokenId++) {
            _mint(recipient, _tokenId);
        }
        } else if (typeId == 2) {   
        uint _chromeResStart = 91;
        uint _chromeResEnd = 150;
        for (uint _tokenId = _chromeResStart; _tokenId <= _chromeResEnd; _tokenId++) {
            _mint(recipient, _tokenId);
        }
        }
        emit ReserveNFTClaimed(recipient);
    }

    function _baseURI() internal view virtual override returns (string memory) {
            return BASE_URI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(),".json"));
    }
    
    function totalSupply() public view returns (uint) {
        return TOTAL_SUPPLY;
    }

    function withdraw (uint _amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Failed to withdraw ETH");
    }
    function _burn (uint _tokenId) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        super._burn(_tokenId);
    }
}
