pragma solidity 0.6.7;

import "./ERC721.sol";

contract SimpleExchange {

	ERC721 public token;

	mapping(uint => uint) public orderBook;

	event TokenListed(
		uint indexed _tokenId,
		uint indexed _price
	);

	event TokenSold(
		uint indexed _tokenId,
		uint indexed _price
	);

	constructor (address _tokenAddress) public{
		token  = ERC721(_tokenAddress);
		require (_tokenAddress != address(0), "Token address is 0.");
	}


	function listToken(uint _tokenId, uint _price) external{
		//check if msg.sender  owns tokenID
		//check if exchange contract has approval
		address owner = token.ownerOf(_tokenId);
		require(owner ==  msg.sender);
		token.isApprovedForAll(owner, msg.sender);
		orderBook[_tokenId] = _price;
		emit TokenListed(_tokenId, _price);
	}

	function removeListToken(uint _tokenId) external{
		//check if msg.sender  owns tokenID
		//check if exchange contract has approval
		address owner = token.ownerOf(_tokenId);
		require(owner ==  msg.sender);
		token.isApprovedForAll(owner, msg.sender);
		orderBook[_tokenId] = 0;
	}

	function validBuyOrder(uint _tokenId, uint _askPrice) private view returns (bool){
		require(orderBook[_tokenId] > 0);
		return (_askPrice >= orderBook[_tokenId]);
	}

	function markTokenAsSold(uint _tokenId) private{
		orderBook[_tokenId] = 0;
	}

	function listingPrice(uint _tokenId) external view returns(uint){
		return orderBook[_tokenId];
	}

	function buyToken(uint _tokenId) external payable{
		require(validBuyOrder(_tokenId, msg.value));
		address owner = token.ownerOf(_tokenId);
		address payable payableOwner = address(uint160(owner));
		payableOwner.transfer(msg.value);
		token.safeTransferFrom(owner, msg.sender, _tokenId);
		markTokenAsSold(_tokenId);
		emit TokenSold(_tokenId, msg.value);
	}
}