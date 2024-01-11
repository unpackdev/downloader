// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BlerdPassContract is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public  MAX_PUBLIC_MINT = 1;
    uint256 public  MaxPerPublicWallet = 1;
    uint256 public  PUBLIC_SALE_PRICE = .0 ether;

    string private  baseTokenUri;

    bool public publicSale;
    bool public teamMinted;

    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("BlerdPass", "BP"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "BlerdPass :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "BlerdPass :: Not Yet Active or Is Paused.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "BlerdPass :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "BlerdPass :: Already minted 1 time!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "BlerdPass :: Payment is below the price");
        require(_quantity + balanceOf(msg.sender) <= MaxPerPublicWallet , "BlerdPass :: You can not mint more than the maximum allowed per user.");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        
    }


    function teamMint() external onlyOwner{
        require(!teamMinted, "BlerdPass :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 222);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/QmeHCx4advM2pJU4XbSwRKV3BuG3NxfkhHVvy1iBrNSNVC"));
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
         //   ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    //////// Max Per Public Mint
    function setMaxPerPublicMint(uint256 _quantity) public onlyOwner {
        MAX_PUBLIC_MINT=_quantity;
    }
 
    function getMaxPerPublicMint() public view returns (uint256) {
       
           return MAX_PUBLIC_MINT;
    }

    //////// PUBLIC SALE PRICE
    function setPublicPrice(uint256 _newPrice) public onlyOwner() {
        PUBLIC_SALE_PRICE = _newPrice;
    }

    function getPublicPrice(uint256 _quantity) public view returns (uint256) {
       
        return _quantity*PUBLIC_SALE_PRICE ;
    }

    ////// Max Per Public Wallet
    function setMaxPerPublicWallet(uint256 _maxPerPublicWallet) public onlyOwner() {
        MaxPerPublicWallet = _maxPerPublicWallet;
    }

    function getMaxPerPublicWallet() public view returns (uint256) {
       
        return MaxPerPublicWallet ;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner{
        uint256 withdrawAmount_35 = address(this).balance * 35/100;
        uint256 withdrawAmount_20 = (address(this).balance - withdrawAmount_35) * 20/100;
        payable(0xF914056FE1130741c44bcF7B5E00ad9A2A4B5291).transfer(withdrawAmount_35);
        payable(0xF7D955567D172480b01Fa6732CA5100C0B795926).transfer(withdrawAmount_20);
        payable(msg.sender).transfer(address(this).balance);
    }
}

