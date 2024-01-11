// SPDX-License-Identifier: GPL-3.0

// Created by 0xzedsi
// The Nerdy Coder Clones

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./ReentrancyGuard.sol";

//import "./LibRoyalties2981.sol";

contract Whales is ERC721Enumerable, Ownable, RoyaltiesV2Impl, ReentrancyGuard  {
  //To concatenate the URL of an NFT
  using Strings for uint256;

  uint256 public totalsupply;
  // set the maximum supply of the NFTs 
  uint256 public constant MAX_SUPPLY = 5000;
  // set the Max mint amount
  uint256 public max_mint_allowed = 2;
  // set the Max NFT per address
  uint256 public max_mint_per_address = 2;

  //Price of one NFT in sale
  uint public priceSale = 0 ether;

  //URI of the NFTs when revealed
  string public baseURI;
  //URI of the NFTs when not revealed
  string public notRevealedURI;
  //The extension of the file containing the Metadatas of the NFTs
  string public baseExtension = ".json";

  //Are the NFTs revealed yet ?
  bool public revealed = false;

  // this bool will allow us to pause the smart contract
  bool public paused = false;

  // set the royalty fees in Bips
  uint96 royaltyFeesInBips;
  // set the address of the receiver of the royalties
  address payable royaltyAddress;

  address payable public withdrawWallet;

  //Keep a track of the number of tokens per address
  mapping(address => uint) nftsPerWallet;

  //The different stages of selling the collection
    enum Steps {
        Sale,
        SoldOut,
        Reveal
    }

    Steps public sellingStep;

  constructor( string memory _name, string memory _symbol, string memory _theBaseURI, string memory _notRevealedURI, uint96 _royaltyFeesInBips, address payable _withdrawWallet, address payable _royaltyAddress) ERC721(_name, _symbol) {
    transferOwnership(msg.sender);
    withdrawWallet = _withdrawWallet;
    sellingStep = Steps.Sale;
    totalsupply = 0;
    baseURI = _theBaseURI;
    notRevealedURI = _notRevealedURI;
    royaltyFeesInBips = _royaltyFeesInBips;
    royaltyAddress = _royaltyAddress;
  }
  //Define the contract level metadata for opensea 
  function contractURI() public view returns (string memory) {
    return "https://ipfs.io/ipfs/QmdR9fXBAPHBQGnK5TxYweaSYKa81Hdh7AnNhMPkHjH8J4/contractMetadata.json";
  }

  // public
  
      /**
    * @notice Allows to mint NFTs
    *
    * @param _ammount The ammount of NFTs the user wants to mint
    **/
  function saleMint(uint256 _ammount) public payable {

    //if the contract is paused
    require(paused == false, "the contract is paused now, you cannot mint");
    //if the minter exceeds the max mint amount per address
    require(nftsPerWallet[msg.sender] + _ammount <= max_mint_per_address, "you cannot mint more NFTs");
    //If everything has been bought
    require(sellingStep != Steps.SoldOut, "Sorry, no NFTs left.");
    //If Sale didn't start yet
    require(sellingStep == Steps.Sale, "Sorry, sale has not started yet.");
    //Did the user then enought Ethers to buy ammount NFTs ?
    require(msg.value == priceSale * _ammount, "Insufficient funds.");
    //The user can only mint max 2 NFTs
    require(_ammount <= max_mint_allowed, "You can't mint more than 3 tokens");
    //If the user try to mint any non-existent token
    require(totalsupply + _ammount <= MAX_SUPPLY, "Sale is almost done and we don't have enough NFTs left.");
    //Add the ammount of NFTs minted by the user to the total he minted
    nftsPerWallet[msg.sender] += _ammount;
    //If this account minted the last NFTs available
    if(totalsupply + _ammount == MAX_SUPPLY) {
        sellingStep = Steps.SoldOut;   
    }
    //Minting all the account NFTs
    for(uint i = 1 ; i <= _ammount ; i++) {
        uint256 newTokenId = totalsupply + 1;
        totalsupply++;
        _safeMint(msg.sender, newTokenId);
        setRoyalties(newTokenId);
    }
}


   /**
    * @notice Allows to get the complete URI of a specific NFT by his ID
    *
    * @param _nftId The id of the NFT
    *
    * @return The token URI of the NFT which has _nftId Id
    **/
    function tokenURI(uint _nftId) public view override(ERC721) returns (string memory) {
        require(_exists(_nftId), "This NFT does not exist.");
        if(revealed == false) {
           // return notRevealedURI;
            return 
              bytes(notRevealedURI).length > 0 
              ? string(abi.encodePacked(notRevealedURI, _nftId.toString(), baseExtension))
              : "";
          }
        
        string memory currentBaseURI = _baseURI();
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
            : "";
    }

 

  //#####################only owner############################
 
    /** 
    * @notice Set pause to true or false
    *
    * @param _paused True or false if you want the contract to be paused or not
    **/
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }


      /**
    * @notice Change the base URI
    *
    * @param _newBaseURI The new base URI
    **/
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

       /**
    * @notice Change the base URI
    *
    * @param _newSalePrice The new base URI
    **/
    function updateSalePrice(uint _newSalePrice) external onlyOwner {
        priceSale = _newSalePrice;
    }

    /**
    * @notice Change the not revealed URI
    *
    * @param _notRevealedURI The new not revealed URI
    **/
    function setNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    /**
    * @notice Allows to set the revealed variable to true
    **/
    function reveal() external onlyOwner{
        revealed = true;
    }

    /**
    * @notice Return URI of the NFTs when revealed
    *
    * @return The URI of the NFTs when revealed
    **/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

//     /** 
// * @notice Allows to change the sellinStep to Sale
// **/
//   function setUpPublicSale() external onlyOwner {
//     require(sellingStep == Steps.Whitelist, "First the whitelist, then the sale.");
//     sellingStep = Steps.Sale;
// }

  // allow owner to withdraw the funds from the contract
  function withdraw() external  onlyOwner {
    (bool success,) = withdrawWallet.call{ value: address(this).balance } ('');
    require(success, "withdraw failed");
  }

  function getbalance () public view returns (uint256){
    return address(this).balance;
  }

  // allow the owner to set the royalties Infos
  function setRoyaltyInfo(address payable _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
    royaltyAddress = _receiver;
    royaltyFeesInBips = _royaltyFeesInBips;
  }

  /**
    * @notice Allows to gift one NFT to an address
    *
    * @param _account The account of the happy new owner of one NFT
    **/
  function gift(address _account) external onlyOwner nonReentrant {
    require(totalsupply + 1 <= MAX_SUPPLY, "Sold out");
    uint256 newTokenId = totalsupply + 1;
    totalsupply++;
    _safeMint(_account, newTokenId);
    setRoyalties(newTokenId);
  }
  //########################Royalties and EIP 2981 ################################

  // set the royalties for Rarible
  function setRoyalties(uint _tokenId) internal  {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = royaltyFeesInBips;
    _royalties[0].account = royaltyAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

// set the interface of the EIP 2981
  function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool){
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES)
    {
      return true;
    }

    if (interfaceId == 0x2a55205a ) 
    {
      return true;
    }

    return super.supportsInterface(interfaceId);
    }

 // implement the EIP 2981 functions 
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

  // helper function to calculate the royalties for a given sale price
  function calculateRoyalty(uint256 _salePrice) view public returns (uint256) 
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

}
