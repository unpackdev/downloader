// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UniqueAsset.sol";
import "./Ownable.sol";

contract Marketplace is Ownable {
	UniqueAsset public token;

	address public partnerAddress;
	address public platformAddress;

	uint public totalFeeBP;
	uint public platformBP;
	uint public partnerBP;

	uint public constant INVERSE_BASIS_POINT = 1000;

	event TokenListed(uint256 indexed _tokenId, uint256 indexed _sellingPrice);

	constructor(address _tokenAddress) {
		token = UniqueAsset(_tokenAddress);

		platformAddress = msg.sender;
		partnerAddress  = msg.sender;
		totalFeeBP 		= 200;
		platformBP 		= 800;
		partnerBP 		= 200;
	}

	struct Listing{
		uint sellingPrice;
		address artist;
	}

	Listing[] listings;
	mapping(uint => uint) tokenListing; //tokenId => listing index + 1

	function artistOf(uint _tokenId) public view returns(address){
		return listings[tokenListing[_tokenId] - 1].artist;
	}

	function mintAndListTokens(string[] calldata URIs, uint _sellingPrice) public {

		require(_sellingPrice > 0, 'price_free');

		listings.push(Listing(_sellingPrice,msg.sender));

		for(uint i = 0; i < URIs.length; i++){
			uint _tokenId = token.mintUniqueToken(URIs[i]);
			tokenListing[_tokenId] = listings.length;
			emit TokenListed(_tokenId, _sellingPrice);
		}
	}

	function setPartnerAddress(address _partnerAddress) public{
		require(partnerAddress == msg.sender,'permission');
		partnerAddress = _partnerAddress;
	}

	function setPlatformAddress(address _platformAddress) public{
		require(platformAddress == msg.sender,'permission');
		platformAddress = _platformAddress;
	}

	function setPlatformFeeInBasisPoints(uint basisPoints) public onlyOwner{
		require(basisPoints < INVERSE_BASIS_POINT, "basisPoints");

		platformBP = basisPoints;
		partnerBP = INVERSE_BASIS_POINT - basisPoints;
	}

	function calculateAffiliateFee(uint256 amount) private view returns (uint256){
		return amount * totalFeeBP  / INVERSE_BASIS_POINT;
	}

	function calculatePartnerFee(uint256 amount) private view returns (uint256){
		return amount * partnerBP  / INVERSE_BASIS_POINT;
	}

	function calculatePlatformFee(uint256 amount) private view returns (uint256){
		return amount * platformBP / INVERSE_BASIS_POINT;
	}

	function validPurchaseOrder(uint256 _tokenId, uint256 _askingPrice) private view returns (bool){
		require(tokenListing[_tokenId] > 0, 'sold');
		return (_askingPrice >= listings[tokenListing[_tokenId] - 1].sellingPrice);
	}

	function markTokenAsSold(uint256 _tokenId) private {
		delete tokenListing[_tokenId];
	}

	function listingPrice(uint256 _tokenId) public view returns (uint256) {
		if(tokenListing[_tokenId] == 0) return 0;
		return listings[tokenListing[_tokenId] - 1].sellingPrice;
	}

	function purchaseToken(uint _tokenId) public payable{
		require(validPurchaseOrder(_tokenId, msg.value));

		uint fee = calculateAffiliateFee(msg.value);
		uint platformFee = calculatePlatformFee(fee);
		uint partnerFee = calculatePartnerFee(fee);

		payable(platformAddress).transfer(platformFee);
		payable(partnerAddress).transfer(partnerFee);
		payable(listings[tokenListing[_tokenId] - 1].artist).transfer(msg.value - fee);


		token.transferFrom(address(this),msg.sender,_tokenId);
	}
}
