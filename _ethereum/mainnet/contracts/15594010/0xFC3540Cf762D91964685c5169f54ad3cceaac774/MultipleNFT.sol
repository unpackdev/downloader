// MultipleNFT token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

interface INFTFactory {
	function getMintFee() external view returns (uint256);	
}

contract MultipleNFT is ERC1155Upgradeable {
    using SafeMath for uint256;

    struct Item {
        uint256 id;
        address creator;
        string uri;
        uint256 supply;
        uint256 royalty;        
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 constant public MAX_NFT_ROYALTY = 100; // 10%
    
    string public name;
    bool public isPublic;
    address public factory;
    address private owner;
    uint256 private royalties; // 10 for 1%

    uint256 public currentID;
    mapping (uint256 => Item) public Items;


    event MultiItemCreated(uint256 id, string uri, uint256 supply, address creator, uint256 royalty);

    event CollectionUriUpdated(string collection_uri);    
    event CollectionNameUpdated(string collection_name);
    event TokenUriUpdated(uint256 id, string uri);

    /**
		Initialize from Swap contract
	 */
    function initialize(string memory _name, string memory _uri, address creator, uint256 _royalties, bool bPublic 
    ) public initializer {
        _setURI(_uri);
        factory = _msgSender();  
        name = _name;
        owner = creator;
        royalties = _royalties;
        isPublic = bPublic;        
    }

    
    /**
		GET/SET Collection URI
	 */
    function contractURI() external view returns (string memory) {
        return super.uri(0);
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
        emit CollectionUriUpdated(newuri);        
    }

    
    /**
		Transfer owner
	 */
    function transferOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;        
    }

    /**
		Change Collection Name
	 */
    function setName(string memory newname) external onlyOwner {
        name = newname;
        emit CollectionNameUpdated(newname);
    }


    /**
		Get/Set token Uri
	 */    
    function uri(uint256 _id) public view override returns (string memory) {
        require(_exists(_id), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");
        // We have to convert string to bytes to check for existence

        bytes memory customUriBytes = bytes(Items[_id].uri);
        if (customUriBytes.length > 0) {
            return Items[_id].uri;
        } else {
            return super.uri(_id);
        }
    }

    function setCustomURI(uint256 _tokenId, string memory _newURI)
        external
        creatorOnly(_tokenId)
    {
        Items[_tokenId].uri = _newURI;       
        emit TokenUriUpdated(_tokenId, _newURI);        
    }


    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) external view returns (uint256) {
        require(_exists(_id), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");
        return Items[_id].supply;        
    }

    
    /**
		Create Card - Only Minters
	 */
    function addItem( uint256 supply, string memory _uri, uint256 royalty ) external payable returns (uint256) {
        require(royalty <= MAX_NFT_ROYALTY, "invalid royalty");
        uint256 mintFee = INFTFactory(factory).getMintFee();
        require(msg.value >= mintFee, "insufficient fee");
        if (mintFee > 0) {            
            (bool result, ) = payable(factory).call{value: mintFee}("");
        	require(result, "Failed to send mint fee to factory"); 
        }
        

        require( _msgSender() == owner || isPublic,
            "Only minter can add item"
        );
        require(supply > 0, "supply can not be 0");

        
        currentID = currentID.add(1);
        if (supply > 0) {
            
            _mint(_msgSender(), currentID, supply, "Mint");
        }

        Items[currentID] = Item(currentID, _msgSender(), _uri, supply, royalty);
        emit MultiItemCreated(currentID, _uri, supply, _msgSender(), royalty);
        return currentID;
    }


    function burn(address from, uint256 id, uint256 amount) external returns(bool){
		uint256 nft_token_balance = balanceOf(_msgSender(), id);
		require(nft_token_balance > 0, "Only owner can burn");
        require(nft_token_balance >= amount, "invalid amount : amount have to be smaller than the balance");		
		_burn(from, id, amount);
        Items[id].supply = Items[id].supply - amount;
		return true;
	}

    function getCollectionRoyalties() public view returns (uint256) {
        return royalties;
    }

    function getCollectionOwner() public view returns (address) {
        return owner;
    }

    function creatorOf(uint256 _tokenId) public view returns (address) {
        return Items[_tokenId].creator;
    }

    function itemRoyalties(uint256 _tokenId) public view returns (uint256) {
        return Items[_tokenId].royalty;
	}

    modifier onlyOwner() {
        require(owner == _msgSender(), "caller is not the owner");
        _;
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return _id <= currentID;
    }

    /**
     * @dev Require _msgSender() to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            Items[_id].creator == _msgSender(),
            "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    /**
     * @dev To receive ETH
     */
    receive() external payable {}
}
