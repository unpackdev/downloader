//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGalleryFactory {
	event Gallerycreated(address indexed galleryaddress, address indexed _creator);
	event Mintednftinnewgallery(
		address indexed galleryaddress,
		address indexed _owner,
		uint256 indexed tokenid,
		address minter
	);

	struct galleryAndNFT {
		string _id;
		address _owner;
		string _uri;
		// string _nftname;
		address artist;
		address thirdParty;
		uint256 amount;
		uint256 artistFee;
		uint256 galleryOwnerFee;
		uint256 artistSplit;
		uint256 thirdPartyFee;
		uint256 expiryTime;
		bool physicalTwin;
	}

	/* @notice create new gallery contract
        @param name name of the gallery
        @param _owner address of gallery owner*/
	function createGallery(string calldata _name, address _owner) external;

	///@notice creategallery and mint a NFT
	function mintNftInNewGallery(galleryAndNFT memory gallery) external;

	///@notice change address of nftcontract
	///@param newNft new address of the nftcontract
	function changeNftAddress(address newNft) external;

	///@notice change the address of marketcontract
	///@param newMarket new address of the marketcontract
	function changeMarketAddress(address newMarket) external;

	//get the information of gallery creacted
	function listgallery()
		external
		returns (
			string[] memory name,
			address[] memory owner,
			address[] memory galleryaddress
		);
}
