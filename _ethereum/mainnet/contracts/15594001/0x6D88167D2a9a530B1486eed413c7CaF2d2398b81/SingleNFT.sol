// SingleNFT token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./SafeMath.sol";

interface INFTFactory {
	function getMintFee() external view returns (uint256);	
}

contract SingleNFT is ERC721Upgradeable {
    using SafeMath for uint256;    

    uint256 constant public MAX_NFT_ROYALTY = 100; // 10%

	string public collection_name;
    string private collection_uri;
    bool public isPublic;
    address public factory;
    address private owner;
    uint256 private royalties; // 10 for 1%

    struct Item {
        uint256 id;
        address creator;
        string uri;
        uint256 royalty;
    }


    uint256 public currentID;    
    mapping (uint256 => Item) public Items;

    event CollectionUriUpdated(string collection_uri);    
    event CollectionNameUpdated(string collection_name);
    event TokenUriUpdated(uint256 id, string uri);

    event ItemCreated(uint256 id, address creator, string uri, uint256 royalty);
    event Burned(address owner, uint nftID);

    /**
		Initialize from Swap contract
	 */
    function initialize(
        string memory _name,
        string memory _uri,
        address creator,
        uint256 _royalties,
        bool bPublic
    ) public initializer {
        factory = _msgSender();
        
        collection_uri = _uri;
        collection_name = _name;
        owner = creator;
        royalties = _royalties;
        isPublic = bPublic;
    }

    /**
		Change Collection Information
	 */
    function setCollectionURI(string memory newURI) external onlyOwner {
        collection_uri = newURI;
        emit CollectionUriUpdated(newURI);
    }
    function contractURI() external view returns (string memory) {
        return collection_uri;
    }

    function setName(string memory newname) external onlyOwner {
        collection_name = newname;
        emit CollectionNameUpdated(newname);
    }

    
    /**
		Change & Get Item Information
	 */
    function addItem(string memory _tokenURI, uint256 royalty) external payable returns (uint256){
        require(royalty <= MAX_NFT_ROYALTY, "invalid royalty");
        uint256 mintFee = INFTFactory(factory).getMintFee();
        require(msg.value >= mintFee, "insufficient fee");	
        if (mintFee > 0) {
            (bool result, ) = payable(factory).call{value: mintFee}("");
        	require(result, "Failed to send mint fee to factory"); 
        }

        require( _msgSender() == owner || isPublic,
            "Only owner can add item"
        );

        currentID = currentID.add(1);        
        _safeMint(_msgSender(), currentID);
        Items[currentID] = Item(currentID, _msgSender(), _tokenURI, royalty);
        emit ItemCreated(currentID, _msgSender(), _tokenURI, royalty);
        return currentID;
    }

    function burn(uint _tokenId) external returns (bool)  {
        require(_exists(_tokenId), "Token ID is invalid");
        require(ERC721Upgradeable.ownerOf(_tokenId) == _msgSender(), "only owner can burn");
        _burn(_tokenId);
        emit Burned(_msgSender(),_tokenId);
        return true;
    }

    function setTokenURI(uint256 _tokenId, string memory _newURI)
        external
        creatorOnly(_tokenId)
    {
        Items[_tokenId].uri = _newURI;
        emit TokenUriUpdated( _tokenId, _newURI);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return Items[tokenId].uri;
    }  

    function creatorOf(uint256 _tokenId) public view returns (address) {
        return Items[_tokenId].creator;
    }

    function itemRoyalties(uint256 _tokenId) public view returns (uint256) {
        return Items[_tokenId].royalty;
	} 


    function transferOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;        
    } 

    function getCollectionRoyalties() public view returns (uint256) {
        return royalties;
    }
    function getCollectionOwner() public view returns (address) {
        return owner;
    }
    
    modifier onlyOwner() {
        require(owner == _msgSender(), "caller is not the owner");
        _;
    }
    /**
     * @dev Require _msgSender() to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            Items[_id].creator == _msgSender(),
            "ERC721Tradable#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }
    /**
     * @dev To receive ETH
     */
    receive() external payable {}
}
