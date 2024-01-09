// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Strings.sol";

// @author: greenbunny.eth
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

       This is such an awesome piece of work that I have to admire it mysellf, I know we all copy from
       each other. So those of you who steal ideas from here, just give me a little credit :)       

       Welcome to CanvasArtists the new home for premier artists!     
*/

contract CanvasArtistsMembershipV3 is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {

    // Keep track of the minting counters, membership types and proces
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;                                               // this is all 721, so there is a token ID
 
    // permission roles for this contract - love me some OpenZepplin 4.x
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    // what sale mode are we in
    bool private _premintIsOn = false;                                                          // pre-mint on
    bool private _publicSaleOpen = false;                                                       // public-mint-on

    // setup price multiplier                                                               
    uint256 public constant PRICE_MULTIPLIER = 0.01 ether;                                      // this is used for limiting prices 
 
    // Membership Coonfiguration
    uint256 private constant MAX_MEMBERSHIP_TYPES = 5;                                          // never more than 5 membership types
    uint256 [MAX_MEMBERSHIP_TYPES] private _membershipSupply = [0,0,0,0,0];                     // how many memberships, per type
    uint256 [MAX_MEMBERSHIP_TYPES] private _reservedSupply = [0,0,0,0,0];                       // howmant are available
    uint256 [MAX_MEMBERSHIP_TYPES] private _forSaleSupply = [0,0,0,0,0];                        // how many available for sale
    uint256 [MAX_MEMBERSHIP_TYPES] private _memebershipPrice = [0,0,0,0,0];                     // how much retail price
    bool [MAX_MEMBERSHIP_TYPES] private _membershipAvailableofSale = 
                                                            [false,false,false,false,false];    // available for sale?
    // # Token Supply
    uint256 [MAX_MEMBERSHIP_TYPES] private _totalMintedCount = [0,0,0,0,0];
    uint256 [MAX_MEMBERSHIP_TYPES] private _reservedMintedCount = [0,0,0,0,0];
    uint256 [MAX_MEMBERSHIP_TYPES] private _saleMintedCount =[0,0,0,0,0];

    //whitelist and discounts  
    uint256 private constant MAX_DISCOUNT_TYPES = 5;                                            // maximum number of discounts
    mapping(address => uint256) private _discountType;                                          // discount type
    mapping(uint256 => uint256) private _membershipMap;                                         // IDs to memebrships
    uint256 [MAX_MEMBERSHIP_TYPES][MAX_DISCOUNT_TYPES] private _discountTable;                  // discount table

    // Where the funds will go
    address private _addTreasury;

    // Setup the token URI for all membership types
    string private _baseTokenURI = "https://gateway.pinata.cloud/ipfs/";

    // events that the contract emits
    event welcomeToTheMembership(uint256 id);

    // ----------------------------------------------------------------------------------------------
    // Construct this...

    constructor() ERC721("CanvasArtistsMembershipV3", "CAM3") {

        // set the permissions
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(TREASURER_ROLE, msg.sender);

        // configure membership types 1 and 2
        //  type 0 NOT CONFIGURED
        configureMembership( 1, 255, 30, 30 );

       // configigure NO discoujts - must always set slot 0
       _discountTable[1][0] = _memebershipPrice[1];

        // burn ID 0 - it's not used
        _tokenIdCounter.increment();

        // set what's available for sale
        setAvailableForSale( 1, true );

        // set the treasury
        _addTreasury = msg.sender;
    }

    // ----------------------------------------------------------------------------------------------
    // These are all configuration funbctions
    // setup memberships and allow for future expansion

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyRole(MINTER_ROLE) {
        _baseTokenURI = baseURI;
    }

    function configureMembership( uint _mType, uint _mSupply, uint _mReserved, uint _mPrice ) public onlyRole(DEFAULT_ADMIN_ROLE) {

        // make sure membership isn't configured 
        //   for security you only get one shot at this, once configured, can never be reconfigiured

        require( _mType < MAX_MEMBERSHIP_TYPES,     "Invalid type" );
        require( _membershipSupply[_mType] == 0,    "Already configured" );

        _membershipSupply[_mType] = _mSupply;                   // set the total supply of memberships
        _reservedSupply[_mType] = _mReserved;                   // set how many to reserve
        _forSaleSupply[_mType] = _mSupply - _mReserved;         // how many are for sale
        _memebershipPrice[_mType] = _mPrice * PRICE_MULTIPLIER;  // set the retail price of memberships TODO reality
   }

    function _configureDiscountTable( uint _mType, uint _mp0,  uint _mp1,  uint _mp2,  uint _mp3,  uint _mp4 ) private onlyRole(DEFAULT_ADMIN_ROLE) {

        // make sure isn't configured 
        //   for security you only get one shot at this, once configured, can never be reconfigiured

        require( _mType < MAX_MEMBERSHIP_TYPES,     "Invalid type" );
        require( _discountTable[_mType][1] == 0,    "Configured Already" );

        // configure the discount table 
        _discountTable[_mType][0] = _mp0;
        _discountTable[_mType][1] = _mp1;
        _discountTable[_mType][2] = _mp2;
        _discountTable[_mType][3] = _mp3;
        _discountTable[_mType][4] = _mp4;
    }

    function configureDiscountTable( uint _mType, uint _mp0,  uint _mp1,  uint _mp2,  uint _mp3,  uint _mp4 ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _configureDiscountTable( _mType, 
                    _mp0 * PRICE_MULTIPLIER, 
                    _mp1 * PRICE_MULTIPLIER, 
                    _mp2 * PRICE_MULTIPLIER, 
                    _mp3 * PRICE_MULTIPLIER, 
                    _mp4 * PRICE_MULTIPLIER 
        );
    }

    // ----------------------------------------------------------------------------------------------
    // These functions are about whitelist managment and discounts 

    function addToWhitelist( address _user, uint256 _dType ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(WHITELIST_ROLE, _user);
        _discountType[_user] = _dType;
    }
  
    function addToWhitelistArray(address[] memory _users, uint256 _dType ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < _users.length; i++) {
            _grantRole(WHITELIST_ROLE, _users[i]);
            _discountType[_users[i]] = _dType;
        }
    }

    // ----------------------------------------------------------------------------------------------
    // Price management and how much supply is available, and what is contract state

    function getPrice( uint _membershipType ) public view returns (uint256) {

        // return premint discount price
        return _memebershipPrice[_membershipType];
    }

    function getTotalSupply( uint _membershipType ) public view returns (uint256) {

        // return premint discount price
        return _membershipSupply[_membershipType];
    }

    function getAvailableSupply( uint _membershipType ) public view returns (uint256) {

        // return premint discount price
        return _forSaleSupply[_membershipType];
    }

    function getPriceForWallet( uint _membershipType, address _user) public view returns (uint256) {

        // return discount price
        return _discountTable[_membershipType][_discountType[_user]];
    }

    function isOnWhitelist( address _user ) public view returns (bool) {

        // return whitelist status 
        return hasRole(WHITELIST_ROLE, _user);
    }

    // ----------------------------------------------------------------------------------------------
    // Sale and Token managment

    function getMembersipTyoe( uint256 _tokenId ) public view returns (uint256) {
        return _membershipMap[_tokenId];
    }

    function isPresaleOpen() public view returns (bool) {

        // is the presale open
        return _premintIsOn;
    }

    function isPublicSaleOpen() public view returns (bool) {

        // is the presale open
        return _publicSaleOpen;
    }

    function setNoSaleOpen() public onlyRole(MINTER_ROLE) {
        _premintIsOn = false;
        _publicSaleOpen = false;
    }

    function setPreSaleOpen() public onlyRole(MINTER_ROLE) {
        _premintIsOn = true;
        _publicSaleOpen = false;
    }

    function setPublicSaleOpen() public onlyRole(MINTER_ROLE) {
        _premintIsOn = false;
        _publicSaleOpen = true;
    }

    function setAvailableForSale( uint _mType, bool _avail )  public onlyRole(MINTER_ROLE) {

        // do nothing if sold out
        if ( isSoldOut(_mType) != true ) 
            _membershipAvailableofSale[_mType] = _avail;
    }

    function isAvailableForSale( uint _mType ) public view returns (bool) {

        // make sure we are not sold out
        if ( isSoldOut(_mType) )
            return false;
        else
            return _membershipAvailableofSale[_mType];
    }

    function isSoldOut( uint _mType )  public view returns (bool) {
        return ( _forSaleSupply[_mType] == 0 ? true : false );
    }

    function howManyCanMint( address _user ) public view returns (uint256) {
        if ( _discountType[_user] == 0 )
            return 5;
        else if (_discountType[_user] != 4)
            return 3;
        else
            return 1;
    }

    // ----------------------------------------------------------------------------------------------
    // Mint Mangment and making sure it all works right

    // emergancy token URI swapping out - It's needed - sometimes your IPFS provider is down and you need to 
    //   send a hardcoded URL into mint function and then fix it later

    function setTokenURI( uint256 tokenId, string memory _uri ) public onlyRole(MINTER_ROLE) {
         _setTokenURI( tokenId, _uri );
    }

    function _mintTokens( uint _mType, uint _quantity, address _to, string memory _uri, bool _fromReserve ) private {

        for (uint i = 0; i < _quantity; i++) {

            // let's mint the actual token - no checks required
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _safeMint( _to, tokenId );
            _setTokenURI( tokenId, _uri );
            _membershipMap[tokenId] = _mType;

            if ( _fromReserve == false ) {
                _forSaleSupply[_mType] = _forSaleSupply[_mType] - 1;
                emit welcomeToTheMembership( tokenId );
            }
        }
    }

    // mint the reserve tokens for later airdroping

    function mintReserve( uint _mType, address _to, string memory _uri ) public onlyRole(MINTER_ROLE) {

        // Mint reserve supply
        uint quantity = _reservedSupply[_mType];
        require( quantity > 0, "M10: already minted" );               

        _mintTokens( _mType, quantity, _to, _uri, true );

        // erase the reserve
        _reservedSupply[_mType] = 0;
    }

    function airdropMembership( uint _mType, uint _quantity, address _to, string memory _uri ) public onlyRole(MINTER_ROLE) {

        // is the membership type available for sale
        require( isAvailableForSale(_mType), "M0: not for sale" );

        // trying to mint zero tokens
        require( _quantity != 0, "M3: zero tokens" );

        // make sure not trying to mint too many
        require( _quantity <= howManyCanMint(_to), "M4: too many" );

        // is there enough supply available
        require( _forSaleSupply[_mType] >= _quantity, "M5: mint fewer" );

        // Mint it! 
        _mintTokens( _mType, _quantity, _to, _uri, false );
    }

    function mintMembership( uint _mType, uint _quantity, address _to, string memory _uri ) public payable {

        // is the membership type available for sale
        require( isAvailableForSale(_mType), "M0: not for sale" );

        // is presale or public sale open
        require( isPresaleOpen() || isPublicSaleOpen(), "M1: not available for sale" );

        // if premint is on make sure the address is allowed to buy
        bool onWhitelist = isOnWhitelist(_to);
        uint hasDiscount =  _discountType[_to];

        if ( _premintIsOn ) {
            require( onWhitelist, "M2: not whitelist" );
        }

        // trying to mint zero tokens
        require( _quantity != 0, "M3: zero tokens" );

        // make sure not trying to mint too many
        require( _quantity <= howManyCanMint(_to), "M4: too many" );

        // is there enough supply available
        require( _forSaleSupply[_mType] >= _quantity, "M5: mint fewer" );

        // did they give us enough money 
        //uint cost = _quantity * getPriceForWallet( _mType, _to );
        uint cost = _quantity * getPriceForWallet( _mType, _to );
        require( msg.value >= cost, "M6: not enough ETH" );

        // Mint it! 
        _mintTokens( _mType, _quantity, _to, _uri, false );

        // if you had a discount, it's spent
        if ( hasDiscount != 0 ) {
           _discountType[_to] = 0; 
        }
    }

    // ----------------------------------------------------------------------------------------------
    // allow switching of treasury and withdrawall of funds

    function setTreasury( address _newTreasury )  public onlyRole(DEFAULT_ADMIN_ROLE) {
        _addTreasury = _newTreasury;
    }

    function withdrawAll()  public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw( _addTreasury, address(this).balance );
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

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyRole(DEFAULT_ADMIN_ROLE) {
        super._burn(tokenId);
    }
}