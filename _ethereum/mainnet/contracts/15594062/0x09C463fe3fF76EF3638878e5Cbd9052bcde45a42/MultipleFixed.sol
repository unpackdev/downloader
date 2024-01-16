// Multiple Fixed Price Marketplace contract
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
interface IMultipleNFT {
	function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
	function balanceOf(address account, uint256 id) external view returns (uint256);
	function getCollectionRoyalties() external view returns (uint256);	
    function getCollectionOwner() external view returns (address);
	function creatorOf(uint256 _tokenId) external view returns (address);
	function itemRoyalties(uint256 _tokenId) external view returns (uint256);
}

contract MultipleFixed is OwnableUpgradeable, ERC1155HolderUpgradeable {
    using SafeMath for uint256;
	
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 public swapFee;	// 25 for 2.5 %
	address public feeAddress; 	

    /* Pairs to swap NFT _id => price */
	struct Pair {
		uint256 pairId;
		address collection;
		uint256 tokenId;		
		address owner;
		address tokenAdr;
		uint256 balance;
		uint256 price;		
		bool bValid;
	}
    
	mapping(uint256 => Pair) public pairs;
	uint256 public currentPairId;

	/** Events */
    event MultiItemListed(Pair item);
	event MultiItemDelisted(address collection, uint256 tokenId, uint256 pairId);
    event MultiItemSwapped(address buyer, uint256 id, uint256 amount, Pair item);


	function initialize(
        address _feeAddress
    ) public initializer {
        __Ownable_init();
        require(_feeAddress != address(0), "Invalid commonOwner");
        feeAddress = _feeAddress;
		swapFee = 25;
		currentPairId = 0;
    }		

	function setFeePercent(uint256 _swapFee) external onlyOwner {		
		require(_swapFee < 1000 , "invalid percent");
        swapFee = _swapFee;
    }
	function setFeeAddress(address _address) external onlyOwner {
		require(_address != address(0x0), "invalid address");
        feeAddress = _address;
    }

    function multipleList(address _collection, uint256 _tokenId, address _tokenAdr, uint256 _amount, uint256 _price) public {
		require(_price > 0, "invalid price");
		require(_amount > 0, "invalid amount");
		IMultipleNFT nft = IMultipleNFT(_collection);
        uint256 nft_token_balance = nft.balanceOf(msg.sender, _tokenId);
		require(nft_token_balance >= _amount, "invalid amount : amount have to be smaller than NFT balance");
		
		nft.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "List");

		currentPairId = currentPairId.add(2);
		pairs[currentPairId].pairId = currentPairId;
		pairs[currentPairId].collection = _collection;
		pairs[currentPairId].tokenId = _tokenId;		
		pairs[currentPairId].owner = msg.sender;
		pairs[currentPairId].tokenAdr = _tokenAdr;
		pairs[currentPairId].balance = _amount;
		pairs[currentPairId].price = _price;		
		pairs[currentPairId].bValid = true;

        emit MultiItemListed(pairs[currentPairId]);
    }

	function multipleDelist(uint256 _id) external {
		require(pairs[_id].bValid, "invalid Pair id");
		require(pairs[_id].owner == msg.sender || msg.sender == owner(), "only owner can delist");

		IMultipleNFT(pairs[_id].collection).safeTransferFrom(address(this), pairs[_id].owner, pairs[_id].tokenId, pairs[_id].balance, "delist Marketplace");
		pairs[_id].balance = 0;
		pairs[_id].bValid = false;

		emit MultiItemDelisted(pairs[_id].collection, pairs[_id].tokenId, _id);
	}

    function multipleBuy(uint256 _id, uint256 _amount) external payable {
        require(pairs[_id].bValid, "invalid Pair id");
		require(pairs[_id].balance >= _amount, "insufficient NFT balance");

		Pair memory item = pairs[_id];
		uint256 tokenAmount = item.price.mul(_amount);
		
		uint256 collectionRoyalties = getCollectionRoyalties(item.collection);
        address collectionOwner = getCollectionOwner(item.collection);

		uint256 nftRoyalty = getNFTRoyalties(item.collection, item.tokenId);
        address nftCreator = getNFTCreator(item.collection, item.tokenId);

		uint256 feeAmount = tokenAmount.mul(swapFee).div(PERCENTS_DIVIDER);
		uint256 collectionOwnerAmount = tokenAmount.mul(collectionRoyalties).div(PERCENTS_DIVIDER); 
		uint256 nftCreatorAmount = tokenAmount.mul(nftRoyalty).div(PERCENTS_DIVIDER);       		
		uint256 ownerAmount = tokenAmount.sub(feeAmount).sub(collectionOwnerAmount).sub(nftCreatorAmount);

		if (item.tokenAdr == address(0x0)) {
            require(msg.value >= tokenAmount, "too small amount");

			if(swapFee > 0) {
				(bool result, ) = payable(feeAddress).call{value: feeAmount}("");
        		require(result, "Failed to send swap fee to feeAddress");			
			}	
			if(collectionRoyalties > 0) {
				(bool result, ) = payable(collectionOwner).call{value: collectionOwnerAmount}("");
        		require(result, "Failed to send collection royalties to collectionOwner");	
			}
			if(nftRoyalty > 0) {
				(bool result, ) = payable(nftCreator).call{value: nftCreatorAmount}("");
        		require(result, "Failed to send royalty to nftCreator");	
			}
			(bool ownerResult, ) = payable(item.owner).call{value: ownerAmount}("");
        	require(ownerResult, "Failed to send coin to item owner");		
        } else {
            IERC20 governanceToken = IERC20(item.tokenAdr);	

			require(governanceToken.transferFrom(msg.sender, address(this), tokenAmount), "insufficient token balance");		
			// transfer governance token to admin
			if(swapFee > 0) {
				require(governanceToken.transfer(feeAddress, feeAmount));		
			}

			if(collectionRoyalties > 0) {
				// transfer governance token to collection owner
				require(governanceToken.transfer(collectionOwner, collectionOwnerAmount));				
			}

			if(nftRoyalty > 0) {
				// transfer governance token to nft creator
				require(governanceToken.transfer(nftCreator, nftCreatorAmount));				
			}
			
			// transfer governance token to owner		
			require(governanceToken.transfer(item.owner, ownerAmount));			
        }
		
		// transfer NFT token to buyer
		IMultipleNFT(item.collection).safeTransferFrom(address(this), msg.sender, item.tokenId, _amount, "buy from Marketplace");

		pairs[_id].balance = item.balance.sub(_amount);
		if (pairs[_id].balance == 0) {
			pairs[_id].bValid = false;
		}		
        emit MultiItemSwapped(msg.sender, _id, _amount, item);
    }

	function getCollectionRoyalties(address collection) view private returns(uint256) {
        IMultipleNFT nft = IMultipleNFT(collection); 
        try nft.getCollectionRoyalties() returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }
    function getCollectionOwner(address collection) view private returns(address) {
        IMultipleNFT nft = IMultipleNFT(collection); 
        try nft.getCollectionOwner() returns (address ownerAddress) {
            return ownerAddress;
        } catch {
            return address(0x0);
        }
    }

	function getNFTRoyalties(address collection, uint256 tokenId) view private returns(uint256) {
        IMultipleNFT nft = IMultipleNFT(collection); 
        try nft.itemRoyalties(tokenId) returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }

    function getNFTCreator(address collection, uint256 tokenId) view private returns(address) {
        IMultipleNFT nft = IMultipleNFT(collection); 
        try nft.creatorOf(tokenId) returns (address creatorAddress) {
            return creatorAddress;
        } catch {
            return address(0x0);
        }
    }

	/**
     * @dev To receive ETH
     */
    receive() external payable {}

}