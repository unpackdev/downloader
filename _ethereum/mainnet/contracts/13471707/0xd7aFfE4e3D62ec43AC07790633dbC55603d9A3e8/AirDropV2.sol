// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract AirDropV2 is ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    // array of token ids
    uint256[] private tokenIds;

    // count of tokens
    uint256 public tokenCounter;

    // array of token ids
    string[] private tokenUris;

    //emit token id and uri
    event tokenDetails(uint256 IDs, string URIs);

    // mapping user address with status
    mapping(address => bool) public holders;

    // emit when new holder is added
    event AddHolder(address user, bool status);
  
    /**
     * @dev adds 484 users at one time.
     *
     * Requirements
     * - array must have 484 address.
     * - only owner must call this method.
     *
     * Emits a {AddHolder} event.
    */
    
    function addUserStatus(address[484] calldata _users, bool _status) onlyOwner external {
        for(uint i = 0; i < 484; i++){
            holders[_users[i]] = _status;
            emit AddHolder(_users[i], _status);        
        }
    }

    /**
     * @dev checks whether user address can mint.
     *
     * Returns
     * - status in boolean.
    */

    function checkUserStatus(address _users) external view returns(bool){
        require(_users != address(0x00), "$MONSTERBUDS: Not applied to zero address");
        return holders[_users];
    }

    /**
     * @dev concates the two string and token id to create new URI. 
          *
     * @param _before token uri before part.
     * @param _after token uri after part.
     * @param _token_id token Id.
     *
     * Returns
     * - token uri
    */

    function uriConcate(string memory _before, uint256 _token_id, string memory _after) private pure returns (string memory){
        string memory token_uri = string( abi.encodePacked(_before, _token_id.toString(), _after));
        return token_uri;
    }

    /**
     * @dev mint new air drop nft and send to recipients. 
     *
     * Emits a {tokenDetails} event.
     *
     * Returns
     * - token id.
    */

    function airDropNft() external returns(uint256){
        require(holders[msg.sender] == true, "$MONSTERBUDS: User has already claimed or is not eligible for AirDrop NFT");

        uint256 newItemId;
        string memory uri;
        holders[msg.sender] = false;
                
        newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId); // mint new seed
        uri = uriConcate("https://liveassets.monsterbuds.io/Jerry-token-uri/JerryNFT-", newItemId, ".json"); 
        _setTokenURI(newItemId, uri); // set uri to new seed
        tokenCounter = tokenCounter + 1;

        emit tokenDetails(newItemId, uri);
        return newItemId;
    }

    /**
     * @dev It destroy the contract and returns all balance of this contract to owner.
     *
     * Returns
     * - only owner can call this method.
    */ 

    function selfDestruct() 
        public 
        onlyOwner{
    
        payable(owner()).transfer(address(this).balance);
        //selfdestruct(payable(address(this)));
    }
}