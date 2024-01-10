// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";
import "./Counters.sol";

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
*/

// special case Minting Factory - for private collection 

contract CAPremierCollection is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl {

    // Keep track of the minting counters, nft types and proces
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;                                               // this is all 721, so there is a token ID
 
    // permission roles for this contract - love me some OpenZepplin 4.x
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Setup the token URI for all nft types
    string private _baseTokenURI = "https://gateway.pinata.cloud/ipfs/";

    // events that the contract emits
    event WelcomeToTheCollection(uint256 id);

    // ----------------------------------------------------------------------------------------------
    // Construct this...

    constructor() ERC721("CAPemierCollection", "CAPC") {

        // set the permissions
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // burn ID 0 - it's not used
        _tokenIdCounter.increment();
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
    // Mint Mangment 

    function setTokenURI( uint256 tokenId, string memory _uri ) public onlyRole(MINTER_ROLE) {
         _setTokenURI( tokenId, _uri );
    }

    function mintNFT( address _to, string memory _uri ) public onlyRole(MINTER_ROLE) {

        // let's mint the actual token - no checks required
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint( _to, tokenId );
        _setTokenURI( tokenId, _uri );

        emit WelcomeToTheCollection( tokenId );
    }

    function burnNFT(uint256 _tokenId) public onlyRole(MINTER_ROLE) {
        _burn( _tokenId );
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

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}