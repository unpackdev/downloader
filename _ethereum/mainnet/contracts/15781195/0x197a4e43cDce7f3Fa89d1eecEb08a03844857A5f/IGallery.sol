//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGallery {
	struct TokenInfo {
		string uri;
		uint256 tokenId;
		uint256 minprice;
		uint256 feeExpiryTime;
		address thirdParty;
		bool onSell;
		address artist;
		bool hasPhysicalTwin;
		uint256 totalSell;
		bool USD;
	}
	///feeInfo for nft
	struct FeeInfo {
		uint256 artistFee;
		uint256 gallerySplit;
		uint256 artistSplit;
		uint256 thirdPartyFee;
	}

	event Nftadded(uint256 indexed nftid, address indexed _artist);
	event Nftminted(uint256 indexed _tokenId, address indexed _minter);
	event Nftburned(uint256 indexed _tokenId, address indexed _from);
	event Transfered(uint256 indexed _tokenId, address indexed _from, address indexed _to);
	event Nftmintedandsold(uint256 indexed _tokenId, address indexed _minter, uint256 indexed _price);
	event Nftmintedandairdrop(uint256 indexed _tokenId, address indexed _receiver, address indexed _owner);
	event Nftmintedandairdropwithverification(uint256 indexed _tokenId, address indexed _owner);
	event NftAirdropped(uint256 indexed _tokenId, address indexed _reciever);

	/*@notice add nft to gallery*/
	// function addNft(string calldata _uri, string calldata _name) external;

	/*@notice mint Nft
    @param nftid id of nft to mint
    @param _to address to mint the token */
	function mintNFT(string calldata uri, address artist) external returns (uint256 tokenId);

	function mintAndSellNft(
		string memory _uri,
		address artist,
		address thirdParty,
		uint256 amount,
		uint256 artistSplit,
		uint256 gallerySplit,
		uint256 artistFee,
		uint256 thirdPartyFee,
		uint256 feeExpiryTime,
		bool physicalTwin
	) external returns (uint256 tokenId);

	// /*@notice get nft details
	// @param nftid  id of  nft to get details*/
	// function getNftdetails(bytes32 _nftid)
	// 	external
	// 	view
	// 	returns (
	// 		string memory tokenuri,
	// 		address[] memory owner,
	// 		address minter
	// 	);

	/* @notice transfer nft
    @param from address of current owner
    @param to address of new owner */
	function transferNft(
		address from,
		address to,
		uint256 tokenId
	) external;

	/*@notice burn token
    @param _tokenid id of token to be burned */
	function burn(uint256 _tokenId) external;

	/*@notice buynft
    @param tokenid id of token to be bought*/
	function buyNft(uint256 tokenid) external payable;

	/*@notice cancel the sell 
    @params _tokenId id of the token to cancel the sell */
	function cancelNftSell(uint256 _tokenid) external;

	/* @notice add token for sale
    @param _tokenId id of token
    @param amount minimum price to sell token*/
	function sellNft(
		uint256 tokenid,
		uint256 amount,
		FeeInfo memory feedata,
		address _thirdParty,
		uint256 _feeExpiryTime,
		bool physicalTwin,
		bool USD
	) external;

	/*@notice get token details
    @param tokenid  id of  token to get details*/
	function getTokendetails(uint256 tokenid)
		external
		view
		returns (
			string memory tokenuri,
			address owner,
			uint256 minprice,
			bool onSell,
			uint256 artistfee,
			uint256 galleryOwnerFee
		);

	//@notice get the list of token minted in gallery//
	function getListOfTokenIds() external view returns (uint256[] memory);

	//@notice get the list of nfts added in gallery//

	function retreiveBalance() external;
}
