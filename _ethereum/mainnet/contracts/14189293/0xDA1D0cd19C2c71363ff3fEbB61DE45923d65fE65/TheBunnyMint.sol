// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./SafeMath.sol";

// @author: greenbunny.eth
/*                                                                                                               
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::c:::,...........,::::c:::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::;'....,:. ,::' .::,......':::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::'...;cc:cdx;..,,;c:,,;cccccc,...,:::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::,.,:'.oo,',cxocclloxocc;'',,,,:ll:..,c::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::,.'l:,codc..::,,,,:xo'.,,;ccccccok:...';::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::c, .llcll;'..'cdddlco:':ddc,'',..,l;.cl..;:::::::::::::::::::::::::::::::::
:::::::::::::::::::::::c:,'.''. .;odlcccldxc,,:ddllc:::c;''';cdd..;c::::::::::::::::::::::::::::::::
:::::::::::::::::::::::c;..dkk; 'cc,..'',okllxkkl,''','',:ox,.cd. .;::::::::::::::::::::::::::::::::
::::::::::::::::::::::::;..;okl,,,,. 'xOko;..,::::::::cxl.,xo;;;..,,';::::::::::::::::::::::::::::::
::::::::::::::::::::::::;..,okOklcxxclko;. ':;;;.  .::;;' ,xo;:::oOc .::::::::::::::::::::::::::::::
:::::::::::::::::::::::,. .,;,,,..lkOd;. .,;;;cxo::;;dxl::;,:lk0Od:,',::::::::::::::::::::::::::::::
:::::::::::::::::::::'.,;;;;;;.  ..,,;c' ,lc,..'lkx; .;dd;;lxOl,''';::::::::::::::::::::::::::::::::
:::::::::::::::::::::;,'';::::::c;..;;'..':ll:' ,dxoccc,;lxkl;:;..,:::::::::::::::::::::::::::::::::
:::::::::::::::::::::::;,...'';:ol..lc..''',;c;..',',ll';ko';ldl.  .;:::::::::::::::::::::::::::::::
::::::::::::::::::::::::;..l:..,cc'':ll,.......;;;;:c;,cdOc ;doc'...',,,;:::::::::::::::::::::::::::
:::::::::::::::::::::::c;..c:'.',;c;.'oc...........;oc,.'l; ,o:;oxxxxc'''',:::::::::::::::::::::::::
::::::::::::::::::::::::::'.,xl''',,..;ldl;. ....  .;;,,,,,'';okxxxdccc:;..;c:::::::::::::::::::::::
::::::::::::::::::::::::::;.':dx, .','.';;;;;;;;;;;;:dkkOkkxxxl::::' ..,;,,:c:::::::::::::::::::::::
::::::::::::::::::::::::::::;.,;:,. ...';okOkkOkkkkOkkdc;;;;;;;;;;;,.,cdd;..,:::::::::::::::::::::::
::::::::::::::::::::::::::;'..,cxkl:;;:;,;;,;;,,,,;;;;;;::;;;:oxkkxxoxkkd;..,:::::::::::::::::::::::
::::::::::::::::::::::::;.'lc,,;lkkxxo;;::::::::::::::cdxxxxxxxxxxxxxKXd;,,:c:::::::::::::::::::::::
:::::::::::::::::::::::'..;ooc;,'''.',cox:'''''''''..''......'...'...',',;::::::::::::::::::::::::::
:::::::::::::::::::::::;'.,dO0xoddolcccdOdcccccclcc'.,;.    'c..;,      .,c:::::::::::::::::::::::::
:::::::::::::::::::::::::;,,lOxloxxdlllodoldxxxxxxxxo:'.....:xdl;....;l. ,::::::::::::::::::::::::::
:::::::::::::::::::::::::::;,'..,codoxOKXOdxxxxkOOOOOxdxxdddddkOxxxo:ox:.';:::;,;:::::::::::::::::::
::::::::::::::::::::::::::::::::. ,::cdOKkdxkxkO00000000000Ol;d0000o,lO0d..;::;,::::::::::::::::::::
::::::::::::::::::::::::::::::;'. .. .,cdddxkxkO0000OdlllllldkkkkOkkkO0K0lcdoc::::::::::::::::::::::
::::::::::::::::::::::::::::;'. .''''. .;cdxxxk00000Ol;;;;;;okkkkkkkkO0K0OOOdccc::::::::::::::::::::
::::::::::::::::::::::::::;'. .''',,'''. .;lxxkkOOO00000000000000000000koc::::::::::::::::::::::::::
::::::::::::::::::::::::;'. .''',,,,;,'''...;oxdxkkOOOOOO0OOOOOOOOOo;;;oxl::::::::::::::::::::::::::
::::::::::::::::::::::::,.  ..,,,,,,,,,,''......:xkkkkkkkkkkkkkxko;. .':lc::::::::::::::::::::::::::
:::::::::::::::::::::::..  ....',;,,;,',;'.'..   .....''''''''....    .';:::::::::::::::::::::::::::
::::::::::::::::::::::;.  .......',,,,,'.. ..      .,;cdxxxxxd'         .,::::::::::::::::::::::::::
:::::::::::::::::::::;,.  .........',,..  .....  ..'cx0KXNNNX0:..        ,c:::::::::::::::::::::::::
:::::::::::::::::::;,.   ............. ............'ckXNWWWWN0:.....     .;:::::::::::::::::::::::::
:::::::::::::::::::'  . ...........................'ckXNWWWWWXc...... .   .;::::::::::::::::::::::::
*/

// Minting factory for TheBunnyMint 

contract TheBunnyMint is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {

    // Keep track of the minting counters, nft types and proces
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;                                           // this is all ERC-721, so there is a token ID
 
    // permission roles for this contract - love me some OpenZepplin 4.x
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Setup the token URI for all nft types
    string private _baseTokenURI = "https://gateway.pinata.cloud/ipfs/";

    // events that the contract emits
    event WelcomeToTheBunnyMint(uint256 id);

        // NFT Coonfiguration
    uint256 private _nftSupply = 499;                                                   // how many nfts
    uint256 private _forSaleSupply = 499;                                               // how many nfts
    uint256 private _nftPrice = 0;                                                      // how much retail price
    bool    private _nftAvailableForSale = true;                                        // available for sale?

    // # Token Supply
    uint256 private _totalMintedCount = 0;
    uint256 private _saleMintedCount = 0;

    // Where the funds will go
    address public _mintTreasury           = 0xd92599904c5A3cdD40BCf12eF8c32f7071691258;
    address public _donkeyDAOGuildTreasury = 0x542fAB1Ab936E5523AEfAF2026593236bB4F12FE; 

    bool    private _ticketMode = true;
    bytes32 private _ticketValue;

    // ----------------------------------------------------------------------------------------------
    // Construct this...

    constructor() ERC721("TheBunnyMint", "TBMGEN0") {
        // set the permissions
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(TREASURER_ROLE, msg.sender);

        // burn ID 0 - it's not used
        _tokenIdCounter.increment();

        // set the treasury
        _mintTreasury = msg.sender;
        _donkeyDAOGuildTreasury = msg.sender;
    }

   // ----------------------------------------------------------------------------------------------
    // These are all configuration funbctions
    // setup nft and allow for future expansion

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyRole(MINTER_ROLE) {
        _baseTokenURI = baseURI;
    }

    // ----------------------------------------------------------------------------------------------
    // Price management and how much supply is available, and what is contract state

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

    function isAvailableForSale() public view returns (bool) {

        // make sure we are not sold out
        if ( isSoldOut() )
            return false;
        else
            return _nftAvailableForSale;
    }

    function isSoldOut()  public view returns (bool) {
        return ( _forSaleSupply == 0 ? true : false );
    }

    function howManyCanMint() public view returns (uint256) {
        return( _nftSupply );
    }

    // for all of you looking at the code, I totally know this shit is not secure, we should use a merkle proof
    //  but I wanted to create a deterrent for the spammers and n00bs

    function setTicket(string memory _value) public onlyRole(MINTER_ROLE) {
        _ticketValue = keccak256(abi.encodePacked(_value));
         _ticketMode = true;
    }

      function clearTicket() public onlyRole(MINTER_ROLE) {
         _ticketMode = false;
    }

    // ----------------------------------------------------------------------------------------------
    // Mint Mangment and making sure it all works right

    // emergancy token URI swapping out - It's needed - sometimes your IPFS provider is down and you need to 
    //   send a hardcoded URL into mint function and then fix it later

    function setTokenURI( uint256 tokenId, string memory _uri ) public {

        if ( !hasRole(MINTER_ROLE, msg.sender ) ) {
            require( ownerOf(tokenId) != msg.sender, "No permission to update!" );
        }
         _setTokenURI( tokenId, _uri );
    }

    function _mintToken( address _to, string memory _uri) private {

        // let's mint the actual token - no checks required
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint( _to, tokenId );
        _setTokenURI( tokenId, _uri );

        _forSaleSupply = _forSaleSupply - 1;
        emit WelcomeToTheBunnyMint( tokenId );
    }

    function bunnyMint( address _to, string memory _uri, string memory _ticket ) public payable {
        
        // is the nft type available for sale
        require( isAvailableForSale(), "Not for sale" );

        // is there enough supply available
        require( _forSaleSupply >= 1, "Sold Out" );

        if ( _ticketMode == true )
            require( keccak256(abi.encodePacked(_ticket)) == _ticketValue, "Invalid mint ticket" );

        // Mint it! 
        _mintToken( _to, _uri );
    }

    function bunnyMintReserve( address _to, uint256 quantity, string memory _uri ) public onlyRole(MINTER_ROLE) {

        // is there enough supply available
        require( _forSaleSupply >= quantity, "Sold Out" );

        // Mint it! 
        for( uint i=0; i < quantity; i++ )
            _mintToken( _to, _uri );
    }

    // you must be the admin or the owner of the NFT to burn it

    function burnNFT(uint256 _tokenId) public {

        if ( !hasRole(DEFAULT_ADMIN_ROLE, msg.sender ) ) {
            require( ownerOf(_tokenId) != msg.sender, "No permision to burn!" );
        }

        _burn( _tokenId );
    }

    // ----------------------------------------------------------------------------------------------
    // allow switching of treasury and withdrawall of funds

    function setTreasury( address _newMintTreasury, address _newDonkeyDAOGuildTreasury )  public onlyRole(TREASURER_ROLE) {
        _mintTreasury = _newMintTreasury;
        _donkeyDAOGuildTreasury = _newDonkeyDAOGuildTreasury;
    }

    function withdrawAll() public onlyRole(TREASURER_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "Empty balance");

        _widthdraw( _mintTreasury, balance.mul(50).div(100) );
        _widthdraw( _donkeyDAOGuildTreasury, balance.mul(50).div(100) );
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
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalToken() 
        public
        view
        returns (uint256)
    {
        return _tokenIdCounter.current()-1;
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

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyRole(DEFAULT_ADMIN_ROLE) {
        super._burn(tokenId);
    }
}