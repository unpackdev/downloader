//SPDX-License-Identifier: Unlicensed
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./Multicall.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IGalleryFactory.sol";
import "./Gallery.sol";
import "./IGallery.sol";
import "./INFT.sol";
import "./IMarketPlace.sol";

pragma solidity 0.8.10;

contract GalleryFactory is ReentrancyGuard, IGalleryFactory, Multicall, Ownable {
	using Counters for Counters.Counter;
	using EnumerableSet for EnumerableSet.Bytes32Set;

	///@notice stores the gallery info in a struct
	struct galleryInfo {
		address owner;
		address galleryAddress;
		string name;
		IGallery gallery;
	}
	///@dev instance of NFT contract
	INFT public NFT;

	///@dev instance of marketplace contract
	IMarketPlace public marketPlace;

	// IMarketPlace public market_dollar;

	///@notice blockNumber when contract is deployed
	///@dev provides blockNumber when contract is deployed
	uint256 public blockNumber;

	///@notice provides information of the particular gallery
	///@dev maps the bytes32 hash of gallery name with galleryInfo struct
	mapping(bytes32 => galleryInfo) public galleries;

	EnumerableSet.Bytes32Set private allgalleriesId;

	constructor(
		address nft,
		address market // address _dollarmarket
	) checkAddress(nft) checkAddress(market) {
		NFT = INFT(nft);
		marketPlace = IMarketPlace(market);
		// market_dollar = IMarketPlace(_dollarmarket);

		blockNumber = block.number;
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	///@notice create new gallery
	///@param _id unique id  of the gallery
	///@param _owner address of the gallery owner
	function createGallery(string calldata _id, address _owner) public override nonReentrant {
		bytes32 galleryid = findHash(_id);
		require(!allgalleriesId.contains(galleryid), 'Id already registered');
		allgalleriesId.add(galleryid);
		// Gallery galleryaddress = new Gallery(_name, _owner, address(NFT), address(marketPlace), address(market_dollar));
		Gallery galleryaddress = new Gallery(_id, _owner, address(NFT), address(marketPlace));

		galleries[galleryid] = galleryInfo(_owner, address(galleryaddress), _id, IGallery(address(galleryaddress)));
		emit Gallerycreated(address(galleryaddress), _owner);
	}

	///@notice create and mint nft in newly creatd gallery
	///@param gallerydata struct of the information related to gallery creation and nft minting
	///@dev parameter is passed as struct
	function mintNftInNewGallery(galleryAndNFT memory gallerydata) external override nonReentrant {
		bytes32 galleryid = findHash(gallerydata._id);
		require(!allgalleriesId.contains(galleryid), 'Id already registered');
		galleryInfo storage gallery = galleries[galleryid];
		allgalleriesId.add(galleryid);
		Gallery galleryaddress = new Gallery(gallerydata._id, gallerydata._owner, address(NFT), address(marketPlace));
		galleries[galleryid] = galleryInfo(
			gallerydata._owner,
			address(galleryaddress),
			gallerydata._id,
			IGallery(address(galleryaddress))
		);

		NFT.addManagers(address(galleryaddress));
		marketPlace.addGallery(address(galleryaddress), true);

		uint256 tokenid = gallery.gallery.mintAndSellNft(
			gallerydata._uri,
			gallerydata.artist,
			gallerydata.thirdParty,
			gallerydata.amount,
			gallerydata.artistSplit,
			gallerydata.galleryOwnerFee,
			gallerydata.artistFee,
			gallerydata.thirdPartyFee,
			gallerydata.expiryTime,
			gallerydata.physicalTwin
		);
		emit Mintednftinnewgallery(gallery.galleryAddress, gallery.owner, tokenid, gallery.galleryAddress);
	}

	///@notice list the gallery created from the gallery factory
	function listgallery()
		public
		view
		override
		returns (
			string[] memory name,
			address[] memory owner,
			address[] memory galleryAddress
		)
	{
		uint256 total = allgalleriesId.length();
		string[] memory name_ = new string[](total);
		address[] memory owner_ = new address[](total);
		address[] memory galleryaddress_ = new address[](total);

		for (uint256 i = 0; i < total; i++) {
			bytes32 id = allgalleriesId.at(i);
			name_[i] = galleries[id].name;
			owner_[i] = galleries[id].owner;
			galleryaddress_[i] = galleries[id].galleryAddress;
		}
		return (name_, owner_, galleryaddress_);
	}

	///@notice change the nft address
	///@param newnft address of new nft contract
	///@dev only owner can update nft contract address
	function changeNftAddress(address newnft) public override onlyOwner checkAddress(newnft) nonReentrant {
		NFT = INFT(newnft);
	}

	///@notice change the marketplace address
	///@param newMarket address of new marketplace contract
	///@dev only owner can update market place address
	function changeMarketAddress(address newMarket) public override onlyOwner checkAddress(newMarket) nonReentrant {
		marketPlace = IMarketPlace(newMarket);
	}

	///@notice calculates the hash of given string data
	///@dev internal function to assist hash calculation
	function findHash(string memory _data) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(_data));
	}

	function galleryExists(string memory _name) public view returns (bool) {
		bytes32 galleryid = findHash(_name);
		return allgalleriesId.contains(galleryid);
	}
}
