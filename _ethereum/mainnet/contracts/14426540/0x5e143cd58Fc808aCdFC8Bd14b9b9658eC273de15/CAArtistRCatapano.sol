// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

// @author: canvasartists.io
//  
/*                                                                                                               
                             (//////////////////////    &                  &    
                       %(/////////////////////////// /.///&          &  & &%     
                    //(//////////////////////////// /.*****.//       %% &%&&     
                 (((///////////////////////////// /.********.////    &%&&##&     
              (////////////////////////////////// /.**,,,*,**./////& &%#%##%&    
            #///////////     ,//////////////// /. /.,     .*,/////// /.##(##%(#    
           (///////////                                   /////// /.***((/#((    
         #/////////////                                   ////// /.***,,///((    
        (//////////////.                                 .//// /.****,,,,*(/     
       %////////////////      / /.,,,,,,,*******,**       // /. /.**,,,,,,,./      
       /////////////////      *,,,,,,,,,********./.      / /. /.,,,,,,,,****      
      //////////////////       /.****,*** /.********.       /.*,,,,,,,,******&     
      (/////////////////      ////////////////////.      *,,,,,,,*,,*******     
      //////////////////      ////////// /.********       ,,,,,,,*,,********     
      (/////////////////      ,,,,,*********,,,,,*       ,,,,,,,,*,********     
      (//////////// /.,,                                   ,,,,,*,,********      
       //////// /.,*,,,,                                   ,**,************      
       &//// /.***,,*,,,            ,*********,           .***************       
        (/ /.****,,,,,,,,*,*,*****.////// /.******************************        
         (****,,,,,*,,,*,**.//// /.*,***********************************         
        (((,*,,,/,,,* /..// /.***,**,// /.*./ /.**************************          
        ((/(*,*,,* /.****,,,** /. /   ,*   *  *,,.* ******************            
        &///#( /.****,,,.//////////// /. ********* ** **************              
        %(/%((&##,*,./////// / . /.* *  * ./ /.,*  * . *.*********                
          %&%&##(#& /////////// /.****************************                   
          &&&%%%&       .//// /.**************************                       
          &&&                 #*********************%                            
           &                                                                                                                                                              
       ...       .                 ,        

       Welcome to CanvasArtists the new home for premier artists!     
*/

contract CAArtistRCatapano is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {

    // Keep track of the minting counters, nft types and proces
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;                                               // this is all 721, so there is a token ID

    // NFT Coonfiguration
    uint256 private _nftSupply =  55;                                           // how many nfts
    uint256 private _reservedSupply = 0;                                        // how mant are reserved
    uint256 private _forSaleSupply = 55;                                        // how many available for sale
    uint256 private _nftPrice = 0.1 ether;                                      // TODO nft price 
    bool    private _nftAvailableForSale = true;                                // available for sale?

    // # Token Supply
    uint256 private _totalMintedCount = 0;
    uint256 private _reservedMintedCount = 0;
    uint256 private _saleMintedCount = 0;

    // Where the funds will go
    address private _caTreasury;                                                // CanvasArtists treasury
    address private _artistTreasury;                                            // Artist treasury
    address private _costsTreasury;                                             // where the costs go

    // Setup the token URI for all nft types
    string private _baseTokenURI = "https://gateway.pinata.cloud/ipfs/";
    string private _preRevealURI = "QmY19FtMX7NR8vDSAv2aTnnp3htk5LV3Ctud13wRZWXCxd";    // TODO switch for live

    string public _provenanceHash;                                               // provanace proof 
    string public _artistName = "Robert Catapano";                               // artist name

    // you need some previous token from one of these contracts to mint
    mapping(uint256 => address) private _presaleContracts;                      // contracts that allow presale
    uint256 private _preSalePhase;                                              // what level of presale

    // events that the contract emits
    event WelcomeToTheCollection(uint256 id);

    // ----------------------------------------------------------------------------------------------
    // Construct this...

    constructor() ERC721("CAArtistRCatapano", "CARCAP") {

        // burn ID 0 - it's not used
        _tokenIdCounter.increment();

        // set the presale phase and contracts
        _preSalePhase = 0;
        //_presaleContracts[0] = 0x745Bd250e8006407C981D480C1e9708885E8b777;
        //_presaleContracts[1] = 0xa400b74BcdaA7804e72Fbe43540056722416CBC7;
        //_presaleContracts[2] = 0x751428F2a6dd53D921CdA6fe0c45a580c956F1b1;

        // set the treasury
        _caTreasury = msg.sender;
        _artistTreasury = msg.sender;
        _costsTreasury = msg.sender;
    }

    // ----------------------------------------------------------------------------------------------
    // These are all configuration funbctions
    // setup nft and allow for future expansion

    function pause() public onlyOwner {
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPreRevealURI(string memory _preURI) public onlyOwner {
        _preRevealURI = _preURI;
    }

    function setProvenance(string memory _proof) public onlyOwner {

        if ( _totalMintedCount == 0 )       // locked once we start minting
            _provenanceHash = _proof;
    }

    // ----------------------------------------------------------------------------------------------
    // Price management and how much supply is available, and what is contract state

    function setPrice( uint256 _price ) public onlyOwner {
        _nftPrice = _price ;       
    }

    function getPrice() public view returns (uint256) {

        // return premint discount price
        return _nftPrice;
    }

    function getTotalSupply() public view returns (uint256) {

        // return premint discount price
        return _nftSupply;
    }

    function getAvailableSupply() public view returns (uint256) {

        // return premint discount price
        return _forSaleSupply;
    }

    // ----------------------------------------------------------------------------------------------
    // Sale and Token managment

    function getPreSalePhase() public view returns (uint256) {

        return _preSalePhase;
    }

    function setPreSalePhase( uint256 _phase )  public onlyOwner {
        
        _preSalePhase = _phase;
    }

    function loadPreSaleSlots(address[] memory _contractAddress) public onlyOwner {
        for (uint i = 0; i < _contractAddress.length; i++) {
            _presaleContracts[i] = _contractAddress[i];
        }
    }

    function setAvailableForSale( bool _avail )  public onlyOwner {

        // do nothing if sold out
        if ( isSoldOut() != true ) 
            _nftAvailableForSale = _avail;
    }

    function isAvailableForSale() public view returns (bool) {

        // make sure we are not sold out
        if ( isSoldOut() )
            return false;
        else
            return _nftAvailableForSale;
    }

    function isSoldOut()  public view returns (bool) {
        return ( _forSaleSupply < 1 ? true : false );
    }

    function howManyCanMint() public pure returns (uint256) {
        return( 5 );             // TODO change if different in live
    }

    // ----------------------------------------------------------------------------------------------
    // Mint Mangment and making sure it all works right

    // emergancy token URI swapping out - It's needed - sometimes your IPFS provider is down and you need to 
    //   send a hardcoded URL into mint function and then fix it later

    function setTokenURI( uint256 tokenId, string memory _uri ) public onlyOwner {
         _setTokenURI( tokenId, _uri );
    }

    function _mintTokens( uint _quantity, address _to ) private {

        for (uint i = 0; i < _quantity; i++) {

            // let's mint the actual token - no checks required
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _safeMint( _to, tokenId );
            _setTokenURI( tokenId, _preRevealURI );

            _forSaleSupply = _forSaleSupply - 1;
            emit WelcomeToTheCollection( tokenId );
        }
    }

    function giftNFT( uint _quantity, address _to ) public onlyOwner {

        // is there enough supply available
        require( _forSaleSupply >= _quantity, "M5: gift fewer" );

        // Mint it! 
        _mintTokens( _quantity, _to );
    }

    function mintNFT( uint _preSaleSlot, uint _passTokenId, uint _quantity, address _to ) public payable {

        // is the nft type available for sale
        require( isAvailableForSale(), "M0: not for sale" );

        // depending one the mint phase, there are restrictions on who can mint
        if ( _preSalePhase != 0 ) {
            require( _preSaleSlot < _preSalePhase, "M10: you need a valid membership to mint" );
            require(
                IERC721(_presaleContracts[_preSaleSlot]).ownerOf(_passTokenId) == msg.sender,
                "M11: you need a valid membership to mint"
            );
        }
        // trying to mint zero tokens
        require( _quantity != 0, "M3: zero tokens" );

        // make sure not trying to mint too many
        require( _quantity <= howManyCanMint(), "M4: too many" );

        // is there enough supply available
        require( _forSaleSupply >= _quantity, "M5: mint fewer" );

        // did they give us enough money 
        uint cost = _quantity * _nftPrice;
        require( msg.value >= cost, "M6: not enough ETH" );

        // Mint it! 
        _mintTokens( _quantity, _to );
    }

    // deflationary tactic if ever needed
/* Not needed here
    function burnNFT(uint256 _tokenId) public onlyOwner {

        _burn( _tokenId );
    }
*/
    // ----------------------------------------------------------------------------------------------
    // allow switching of treasury and withdrawall of funds

    function setTreasury( address _newCaTreasury, address _newArtistTreasury, address _newCostsTreasury  )  public onlyOwner {
        _caTreasury = _newCaTreasury;
        _artistTreasury = _newArtistTreasury;
        _costsTreasury  = _newCostsTreasury;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Empty balance");

        _widthdraw( _caTreasury, balance.mul(45).div(100) );
        _widthdraw( _artistTreasury, balance.mul(45).div(100) );
        _widthdraw( _costsTreasury, balance.mul(10).div(100) );
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // ----------------------------------------------------------------------------------------------
    // Managment functions provided by OpenZepplin that were not touched

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

   function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalToken() 
        public
        view
        returns (uint256)
    {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

}