//SPDX-License-Identifier: Unlicensed

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./Multicall.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./IGallery.sol";
import "./INFT.sol";
import "./IMarketPlace.sol";

pragma solidity 0.8.10;

contract Gallery is ReentrancyGuard, Ownable, IGallery, Multicall, IERC721Receiver {
	///@notice map the given address with boolean
	///@dev checks whether the given address is added as admins or not
	mapping(address => bool) public admins;

	///@notice id of the gallery
	///@dev provides the unique id of this gallery
	string public id;

	///@notice address of the gallery owner
	///@dev provides the address of the gallery creator
	address public creator;

	///@dev instance of NFT contract
	INFT public nft;

	///@dev creates the instance of Marketplace contract
	IMarketPlace public market;

	///@notice blockNumber when contract is deployed
	///@dev provides blockNumber when contract is deployed
	uint256 public blockNumber;

	///@notice expirytime for airdrop in terms of hours
	uint256 public airDropTime;

	using EnumerableSet for EnumerableSet.AddressSet;
	using EnumerableSet for EnumerableSet.UintSet;

	constructor(
		string memory _id,
		address _owner, //gallery owner address
		address _nft,
		address _market // address _dollarmarket
	) checkAddress(_nft) checkAddress(_market) {
		id = _id;
		creator = _owner;
		nft = INFT(_nft);
		admins[_owner] = true;
		admins[msg.sender] = true;
		market = IMarketPlace(_market);
		transferOwnership(_owner);
		blockNumber = block.number;
		airDropTime = 72;
		// market_dollar = IMarketPlace(_dollarmarket);
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	///@notice to check whether the sender address is admin/owner or not
	///@dev modifier to check whether the sender address is admin/owner or not
	modifier _onlyAdminOrOwner(address _owner) {
		require(admins[_owner] || owner() == _owner, 'only owner/admin');
		_;
	}

	///@notice to check whether the sender address is owner of given token id or not
	///@dev modifier check whether the sender address is owner of given token id or not
	modifier onlyTokenOwner(uint256 tokenid) {
		address owner = address(nft.ownerOf(tokenid));
		require(owner == msg.sender, 'Only Token Owner');
		_;
	}

	///@notice to check whether the sender address is owner of given token id or not or the owner of the gallery
	///@dev modifier to check whether the sender address is owner of given token id or not or the owner of the gallery
	modifier onlyOwnerorTokenOwner(uint256 tokenid) {
		address tokenowner = nft.ownerOf(tokenid);
		if (tokenowner != msg.sender && owner() != msg.sender && !admins[msg.sender])
			revert('Only token-owner/gallery-owner');
		_;
	}

	struct AirDropInfo {
		uint256 tokenId;
		bytes32 verificationCode;
		bool isClaimed;
		address receiver;
		uint256 expiryTime;
	}

	EnumerableSet.UintSet private listOfTokenIds;
	EnumerableSet.UintSet private listOfTokenIdsForSale;
	EnumerableSet.UintSet private listofTokenAirDropped;

	mapping(uint256 => TokenInfo) public tokeninfo;
	mapping(uint256 => FeeInfo) public feeInfo;

	mapping(uint256 => AirDropInfo) public airDropInfo;

	receive() external payable {}

	///@notice Mint the nft through gallery
	///@param _uri token uri of the nft to be minted
	///@param _artist address of the artist of nft
	///@dev onlyAdmin or Owner of gallery can mint the nft
	function mintNFT(string memory _uri, address _artist)
		public
		override
		_onlyAdminOrOwner(msg.sender)
		nonReentrant
		returns (uint256)
	{
		uint256 tokenid = nft.mint(_uri, address(this));
		// if (owner() != creator) transferOwnership(creator);
		listOfTokenIds.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.artist = _artist;
		emit Nftminted(tokenid, address(this));
		return tokenid;
	}

	///@notice burn the given token Id
	///@param _tokenId token id to burn
	///@dev only gallery owner or token owner can burn the given token id
	function burn(uint256 _tokenId) public override onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		nft.burn(_tokenId);
		listOfTokenIds.remove(_tokenId);
		listOfTokenIdsForSale.remove(_tokenId);
		emit Nftburned(_tokenId, msg.sender);
	}

	///@notice transfer the given token Id
	///@param from address of current owner of the given tokenId
	///@param to address of new owner for the given tokenId
	///@param tokenId token id to transfer
	///@dev only gallery owner or token owner can transfer the given token id
	function transferNft(
		address from,
		address to,
		uint256 tokenId
	) public override onlyOwnerorTokenOwner(tokenId) nonReentrant {
		nft.safeTransferFrom(from, to, tokenId);
		emit Transfered(tokenId, from, to);
	}

	///@notice buy the given token id
	///@param tokenid token id to be bought by the buyer
	///@dev payable function
	function buyNft(uint256 tokenid) public payable override nonReentrant {
		require(listOfTokenIds.contains(tokenid), 'Tokenid N/A');
		TokenInfo storage Token = tokeninfo[tokenid];
		require(Token.onSell, 'Not on sell');
		listOfTokenIdsForSale.remove(tokenid);
		Token.onSell = false;
		Token.minprice = 0;
		Token.USD = false;

		market.buy{ value: msg.value }(tokenid, msg.sender);
		Token.totalSell = Token.totalSell + 1;
	}

	///@notice set the nft for sell
	///@param tokenId token id to be listed for sale
	///@param amount selling price of the token id
	///@param feeData tuple value containing fee information about nft(artistFee,gallerySplit,artistSplit,thirdPartyfee)
	///@param _thirdParty address of the thirdparty to recieve royalty on nft sell form second sell onwards
	///@param _feeExpiryTime time period till the thirdparty will recieve the royalty
	///@param physicalTwin flag to indicate physical twin is avaiable or not
	///@param USD boolean value to indicate pricing is in dollar or not
	///@dev function to list nft for sell and can be called only by galleryOwner or tokenOwner
	function sellNft(
		uint256 tokenId,
		uint256 amount,
		FeeInfo memory feeData,
		address _thirdParty,
		uint256 _feeExpiryTime,
		bool physicalTwin,
		bool USD
	) public override onlyOwnerorTokenOwner(tokenId) nonReentrant {
		require(listOfTokenIds.contains(tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[tokenId];
		FeeInfo storage fee = feeInfo[tokenId];
		Token.tokenId = tokenId;
		Token.minprice = amount;
		Token.onSell = true;
		fee.artistFee = feeData.artistFee;
		fee.artistSplit = feeData.artistSplit;
		fee.thirdPartyFee = feeData.thirdPartyFee;
		Token.hasPhysicalTwin = physicalTwin;
		Token.USD = USD;
		fee.gallerySplit = feeData.gallerySplit;
		listOfTokenIdsForSale.add(tokenId);
		nft.setApprovalForAll(address(market), true);
		if (Token.totalSell == 0) {
			nft.setArtistRoyalty(tokenId, Token.artist, uint96(feeData.artistFee));
			Token.thirdParty = _thirdParty;
			Token.feeExpiryTime = calculateExpiryTime(_feeExpiryTime);
		}
		market.sell(
			tokenId,
			amount,
			feeData.artistSplit,
			feeData.gallerySplit,
			feeData.thirdPartyFee,
			Token.feeExpiryTime,
			_thirdParty,
			creator,
			Token.artist,
			USD
		);
	}

	///@notice mint the nft and list for sell
	///@param _uri token uri of the nft to be minted
	///@param artist address of the artist of nft
	///@param thirdParty address of the third party asssociated with nft
	///@param amount selling price of the token id
	///@param artistSplit spilt rate  artist will recieve while selling nft for first time
	///@param gallerySplit split rate to be transferred to gallery owner while selling nft
	///@param artistFee commission rate to be transferred to artist while selling nft
	///@param thirdPartyFee commission rate to be transferred to thirdparty while selling nft
	///@param feeExpiryTime time limit to pay third party commission fee
	///@param physicalTwin flag to indicate physical twin is avaiable or not
	///@dev function to mint the  nft and list it for  sell in a single transaction
	function mintAndSellNft(
		string calldata _uri,
		address artist,
		address thirdParty,
		uint256 amount,
		uint256 artistSplit,
		uint256 gallerySplit,
		uint256 artistFee,
		uint256 thirdPartyFee,
		uint256 feeExpiryTime,
		bool physicalTwin
	) public override returns (uint256 _tokenId) {
		uint256 tokenId = mintNFT(_uri, artist);
		FeeInfo memory feedata = FeeInfo(artistFee, gallerySplit, artistSplit, thirdPartyFee);
		sellNft(
			tokenId,
			amount,
			feedata,
			// feeInfo{artistFee,gallerySplit,artistSplit,thirdPartyFee},
			thirdParty,
			feeExpiryTime,
			physicalTwin,
			true
		);
		emit Nftmintedandsold(tokenId, address(this), amount);
		return tokenId;
	}

	///@notice cancel the nft listed for sell
	///@param _tokenId id of the token to be removed from list
	///@dev only gallery owner or token owner can cancel the sell of nft
	function cancelNftSell(uint256 _tokenId) public override onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.minprice = 0;
		Token.onSell = false;
		Token.USD = false;
		listOfTokenIdsForSale.remove(_tokenId);
		market.cancelSell(_tokenId);
	}

	///@notice change the  artist commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _artistfee new artist fee commission rate
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function changeArtistCommission(uint256 _tokenId, uint256 _artistfee)
		public
		onlyOwnerorTokenOwner(_tokenId)
		nonReentrant
	{
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		FeeInfo storage Fee = feeInfo[_tokenId];
		Fee.artistFee = _artistfee;
		market.changeArtistFee(_tokenId, _artistfee);
	}

	///@notice change the  gallery commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _gallerySplit new gallery owner fee commission rate
	///@dev only gallery owner or token owner can change  the gallery owner commission rate for given  nft
	function changeGalleryCommission(uint256 _tokenId, uint256 _gallerySplit)
		public
		onlyOwnerorTokenOwner(_tokenId)
		nonReentrant
	{
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		FeeInfo storage fee = feeInfo[_tokenId];
		fee.gallerySplit = _gallerySplit;
		market.changeGalleryFee(_tokenId, _gallerySplit);
	}

	///@notice change the  selling price of the listed nft
	///@param _tokenId id of the token
	///@param _minprice new selling price
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function reSaleNft(uint256 _tokenId, uint256 _minprice) public onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.minprice = _minprice;
		market.resale(_tokenId, _minprice);
	}

	///@notice list the token ids associated with this gallery
	function getListOfTokenIds() public view override returns (uint256[] memory) {
		return listOfTokenIds.values();
	}

	///@notice get the details of the given tokenid
	///@param tokenid id of the token whose detail is to be known
	function getTokendetails(uint256 tokenid)
		public
		view
		override
		returns (
			string memory tokenuri,
			address owner,
			uint256 minprice,
			bool onSell,
			uint256 artistfee,
			uint256 gallerySplit
		)
	{
		TokenInfo memory Token = tokeninfo[tokenid];
		FeeInfo memory fee = feeInfo[tokenid];
		address tokenowner = nft.ownerOf(tokenid);
		string memory uri = nft.tokenURI(tokenid);
		return (uri, tokenowner, Token.minprice, Token.onSell, fee.artistFee, fee.gallerySplit);
	}

	///@notice list the token ids listed for sale from this gallery
	function getListOfTokenOnSell() public view returns (uint256[] memory) {
		return listOfTokenIdsForSale.values();
	}

	///@notice retreive the balance accumulated with gallery contract
	///@dev only gallery owner can retreive the balance of gallery
	function retreiveBalance() public override onlyOwner nonReentrant {
		uint256 amount = address(this).balance;
		(bool success, ) = payable(msg.sender).call{ value: amount }(' ');
		require(success, 'Fail-to-retrieve');
	}

	///@notice initiate the airdrop feature
	///@dev approve the address to transfer nft on owner's behalf
	///@param _to address to approve
	///@param _tokenId tokenid to approve
	function manageAirDrop(address _to, uint256 _tokenId) public onlyOwner {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		if (tokeninfo[_tokenId].onSell) cancelNftSell(_tokenId);
		listofTokenAirDropped.add(_tokenId);
		// require(!tokeninfo[tokenId].onSell, 'Token is on sell');
		nft.approve(_to, _tokenId);
		emit NftAirdropped(_tokenId, _to);
	}

	///@notice initiate the airdrop feature with verification code
	///@dev add verification code associated with  particular artswap token
	///@param _randomstring random string used as code to verify airdrop
	///@param _tokenid token Id of artswap token to be dropped
	function manageAirDropWithVerification(string memory _randomstring, uint256 _tokenid)
		public
		_onlyAdminOrOwner(msg.sender)
	{
		require(listOfTokenIds.contains(_tokenid), 'N/A in this gallery');
		if (tokeninfo[_tokenid].onSell) cancelNftSell(_tokenid);
		listofTokenAirDropped.add(_tokenid);
		AirDropInfo storage airdrop = airDropInfo[_tokenid];
		airdrop.tokenId = _tokenid;
		airdrop.isClaimed = false;
		airdrop.expiryTime = calculateExpiryTime(airDropTime);
		airdrop.verificationCode = getHash(_randomstring);
	}

	///@notice initiate the airdrop feature without tokenid
	///@dev mint token and approve the address to transfer nft on owner's behalf
	///@param to address to approve
	///@param _uri metadata of the nft
	///@param _artist address of the artist
	function mintandAirDrop(
		address to,
		string calldata _uri,
		address _artist
	) public _onlyAdminOrOwner(msg.sender) returns (uint256) {
		uint256 tokenid = nft.mint(_uri, address(this));
		listOfTokenIds.add(tokenid);
		listofTokenAirDropped.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		// Token.nftId = _id;
		Token.artist = _artist;
		nft.approve(to, tokenid);
		emit Nftmintedandairdrop(tokenid, to, address(this));
		return tokenid;
	}

	///@notice initiate the airdrop feature without tokenid
	///@dev mint token and store  the verification code to claim the airdropped token
	///@param _randomstring random string used as code to verify airdrop
	///@param _uri metadata of the nft
	///@param _artist address of the artist
	function mintandAirDropwithVerification(
		string memory _randomstring,
		string calldata _uri,
		address _artist
	) public _onlyAdminOrOwner(msg.sender) nonReentrant returns (uint256) {
		uint256 tokenid = nft.mint(_uri, address(this));
		listOfTokenIds.add(tokenid);
		listofTokenAirDropped.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.artist = _artist;
		Token.feeExpiryTime = calculateExpiryTime(0);
		AirDropInfo storage airdrop = airDropInfo[tokenid];
		airdrop.tokenId = tokenid;
		airdrop.isClaimed = false;
		airdrop.verificationCode = getHash(_randomstring);
		airdrop.expiryTime = calculateExpiryTime(airDropTime);
		//  block.timestamp + airDropTime * 1 hours;
		emit Nftmintedandairdropwithverification(tokenid, address(this));
		return tokenid;
	}

	///@notice verify the airdrop feature enabled with verification code
	///@dev verify the verification code and transfer the specified tokenid to the specified new owner
	///@param _to new address to transfer the ownership
	///@param _tokenId nft id to transfer
	///@param _randomstring verification code associated with given nft
	function verifyAirDrop(
		address _to,
		uint256 _tokenId,
		string memory _randomstring
	) public {
		AirDropInfo storage airdrop = airDropInfo[_tokenId];
		bytes32 _code = getHash(_randomstring);
		require(airdrop.verificationCode == _code, 'Invalid Code');
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		require(block.timestamp <= airdrop.expiryTime, 'airdrop:expired');
		if (tokeninfo[_tokenId].onSell) cancelNftSell(_tokenId);
		airdrop.isClaimed = true;
		airdrop.receiver = _to;
		address owner = nft.ownerOf(_tokenId);
		nft.safeTransferFrom(owner, _to, _tokenId);
		emit NftAirdropped(_tokenId, _to);
	}

	///@notice changes the airdrop expiration time in terms of hour
	///@param _newtime new time in terms of hours
	///@dev only Admin or gallery owner can change the airdrop expiration time
	function changeAirDropTime(uint256 _newtime) public _onlyAdminOrOwner(msg.sender) nonReentrant {
		airDropTime = _newtime;
	}

	///@notice calculate the expiry time
	///@param time expiry time in terms of hours
	///@dev utils function to calculate expiry time
	function calculateExpiryTime(uint256 time) private view returns (uint256) {
		// uint256 timeToAdd = time * 365;
		return (block.timestamp + time * 1 hours);
	}

	///@notice generate the hash value
	///@dev generate the keccak256 hash of given input value
	///@param _string string value whose hash is to be calculated
	function getHash(string memory _string) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(_string));
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		// emit NFTReceived(operator, from, tokenId, data);
		return IERC721Receiver.onERC721Received.selector;
	}
}
