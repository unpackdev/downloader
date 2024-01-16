// NFT Factory Contract
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./ClonesUpgradeable.sol";

interface INFTCollection {
	function initialize(string memory _name, string memory _uri, address creator, uint256 royalties, bool bPublic) external;	
}

contract NFTFactory is OwnableUpgradeable {
    using SafeMath for uint256;

    address[] public collections;
	uint256 private mintFee;
	address private singleNFTImplementation;
	address private multipleNFTImplementation;

	uint256 constant public MAX_COLLECTION_ROYALTY = 50; // 5%
	
	/** Events */
    event MultiCollectionCreated(address collection_address, address owner, string name, string uri, uint256 royalties, bool isPublic);
    event SingleCollectionCreated(address collection_address, address owner, string name, string uri, uint256 royalties, bool isPublic);
    
	function initialize(
		address _singleNFTImplementation,
		address _multipleNFTImplementation
	) public initializer {
        __Ownable_init();
        singleNFTImplementation = _singleNFTImplementation;
		multipleNFTImplementation = _multipleNFTImplementation;
		mintFee = 0;
    }

	function updateSingleNFTImplementation(address singleNFTImplementation_)
        external
        onlyOwner
    {
        singleNFTImplementation = singleNFTImplementation_;
    }
    function viewSingleNFTImplementation() external view returns (address) {
        return singleNFTImplementation;
    }

	function updateMultipleNFTImplementation(address multipleNFTImplementation_)
        external
        onlyOwner
    {
        multipleNFTImplementation = multipleNFTImplementation_;
    }
    function viewMultipleNFTImplementation() external view returns (address) {
        return multipleNFTImplementation;
    }


	function getMintFee() external view returns (uint256) {
        return mintFee;
    }

	function setMintFee(uint256 _mintFee) external onlyOwner {
       	mintFee = _mintFee;
    }

	function createMultipleCollection(string memory _name, string memory _uri, uint256 royalties, bool bPublic) external returns(address collection) {
		require(royalties < MAX_COLLECTION_ROYALTY, "invalid royalties");
		if(bPublic){
			require(owner() == msg.sender, "Only owner can create public collection");	
		}		
		collection = ClonesUpgradeable.clone(multipleNFTImplementation);

        INFTCollection(collection).initialize(_name, _uri, msg.sender, royalties, bPublic);
		collections.push(collection);
		emit MultiCollectionCreated(collection, msg.sender, _name, _uri, royalties, bPublic);
	}

	function createSingleCollection(string memory _name, string memory _uri, uint256 royalties, bool bPublic) external returns(address collection) {
		require(royalties <= MAX_COLLECTION_ROYALTY, "invalid royalties");
		if(bPublic){
			require(owner() == msg.sender, "Only owner can create public collection");	
		}		
		collection = ClonesUpgradeable.clone(singleNFTImplementation);

        INFTCollection(collection).initialize(_name, _uri, msg.sender, royalties, bPublic);
		collections.push(collection);		
		emit SingleCollectionCreated(collection, msg.sender, _name, _uri, royalties, bPublic);
	}

	function withdrawBNB() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, "insufficient balance");		
		(bool result, ) = payable(msg.sender).call{value: balance}("");
        require(result, "Failed to withdraw balance"); 
	}

	/**
     * @dev To receive ETH
     */
    receive() external payable {}
}