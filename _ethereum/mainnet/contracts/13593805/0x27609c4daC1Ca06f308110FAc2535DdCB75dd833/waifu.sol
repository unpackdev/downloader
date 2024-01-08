// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// Waifus have come to our world but they need your support!
// Adopt your waifu on the Ethereum blockchain, and transport them to our world.

// ⡆⣐⢕⢕⢕⢕⢕⢕⢕⢕⠅⢗⢕⢕⢕⢕⢕⢕⢕⠕⠕⢕⢕⢕⢕⢕⢕⢕⢕⢕
// ⢐⢕⢕⢕⢕⢕⣕⢕⢕⠕⠁⢕⢕⢕⢕⢕⢕⢕⢕⠅⡄⢕⢕⢕⢕⢕⢕⢕⢕⢕
// ⢕⢕⢕⢕⢕⠅⢗⢕⠕⣠⠄⣗⢕⢕⠕⢕⢕⢕⠕⢠⣿⠐⢕⢕⢕⠑⢕⢕⠵⢕
// ⢕⢕⢕⢕⠁⢜⠕⢁⣴⣿⡇⢓⢕⢵⢐⢕⢕⠕⢁⣾⢿⣧⠑⢕⢕⠄⢑⢕⠅⢕
// ⢕⢕⠵⢁⠔⢁⣤⣤⣶⣶⣶⡐⣕⢽⠐⢕⠕⣡⣾⣶⣶⣶⣤⡁⢓⢕⠄⢑⢅⢑
// ⠍⣧⠄⣶⣾⣿⣿⣿⣿⣿⣿⣷⣔⢕⢄⢡⣾⣿⣿⣿⣿⣿⣿⣿⣦⡑⢕⢤⠱⢐
// ⢠⢕⠅⣾⣿⠋⢿⣿⣿⣿⠉⣿⣿⣷⣦⣶⣽⣿⣿⠈⣿⣿⣿⣿⠏⢹⣷⣷⡅⢐
// ⣔⢕⢥⢻⣿⡀⠈⠛⠛⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⡀⠈⠛⠛⠁⠄⣼⣿⣿⡇⢔
// ⢕⢕⢽⢸⢟⢟⢖⢖⢤⣶⡟⢻⣿⡿⠻⣿⣿⡟⢀⣿⣦⢤⢤⢔⢞⢿⢿⣿⠁⢕
// ⢕⢕⠅⣐⢕⢕⢕⢕⢕⣿⣿⡄⠛⢀⣦⠈⠛⢁⣼⣿⢗⢕⢕⢕⢕⢕⢕⡏⣘⢕
// ⢕⢕⠅⢓⣕⣕⣕⣕⣵⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣷⣕⢕⢕⢕⢕⡵⢀⢕⢕
// ⢑⢕⠃⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⢕⢕⢕
// ⣆⢕⠄⢱⣄⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢁⢕⢕⠕⢁
// ⣿⣦⡀⣿⣿⣷⣶⣬⣍⣛⣛⣛⡛⠿⠿⠿⠛⠛⢛⣛⣉⣭⣤⣂⢜⠕⢑⣡⣴⣿
import "./console.sol";
import "./reserver.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";

contract Waifu is ERC721, Ownable, ERC721URIStorage, ERC721Burnable {
	enum Stage {
		PreSale,
		PrivateSale,
		PublicSale
	}
	Stage public currentStage = Stage.PreSale;
	using Counters for Counters.Counter;
	uint256 maxCommonMintPerTx;
	uint256 commonRampSpeed;

	uint256 legendarySupply;
	uint256 rareSupply;
	uint256 commonSupply;

	string base;

	uint256 commonBasePrice;
	Counters.Counter private commonIDCounter;

	uint256 rareBasePrice;
	mapping(uint256 => bool) rarePurchasedIDs;
	uint256[] rarePurchasedIDArray;

	Reserver reserver;

	struct Config {
		string base;
		uint256 legendarySupply;
		uint256 rareSupply;
		uint256 rareBasePrice;
		uint256 commonSupply;
		uint256 commonRampSpeed;
		uint256 commonBasePrice;
		uint256 maxCommonMintPerTx;
	}

	constructor(Config memory _config, address _reserverAddr)
		ERC721("Waifu Adoption Protocol", "WFU")
	{
		base = _config.base;
		legendarySupply = _config.legendarySupply;
		rareSupply = _config.rareSupply;
		commonSupply = _config.commonSupply;
		maxCommonMintPerTx = _config.maxCommonMintPerTx;
		commonRampSpeed = _config.commonRampSpeed;
		commonBasePrice = _config.commonBasePrice;
		rareBasePrice = _config.rareBasePrice;
		reserver = Reserver(_reserverAddr);
	}

	// PermanentURI is used by OpenSea to freeze metadata
	event PermanentURI(string _value, uint256 indexed _id);

	// flush all accumulated Ether from this contract to the project owner.
	function flush() public {
		(bool success, ) = owner().call{value: address(this).balance}("");
		require(success, "Failed to withdraw");
	}

	// setPublicSale enables and disables purchase by the public
	function setPublicSale() public onlyOwner {
		currentStage = Stage.PublicSale;
		emit onSaleStageChange(Stage.PublicSale);
	}

	// setPrivateSale enables and disables purchase by the public
	function setPrivateSale() public onlyOwner {
		currentStage = Stage.PrivateSale;
		emit onSaleStageChange(Stage.PrivateSale);
	}

	// setPreSale enables and disables purchase by the public
	function setPreSale() public onlyOwner {
		currentStage = Stage.PreSale;
		emit onSaleStageChange(Stage.PreSale);
	}

	// commonSupplyCapReached returns true when common token supply is exhausted
	function commonSupplyCapReached() public view returns (bool) {
		return commonIDCounter.current() == commonSupply;
	}

	// purchasedRareIDs returns an array of purchased rare IDs
	function purchasedRareIDs() public view returns (uint256[] memory) {
		return rarePurchasedIDArray;
	}

	// freeze metadata of a single token
	function freeze(uint256 id) public {
		require(
			msg.sender == owner() || msg.sender == ownerOf(id),
			"You are not the owner"
		);
		emit PermanentURI(tokenURI(id), id);
	}

	// _burn the token
	function _burn(uint256 tokenId)
		internal
		override(ERC721, ERC721URIStorage)
	{
		super._burn(tokenId);
	}

	// contractURI provides baseURI of the contract
	function contractURI() public view returns (string memory) {
		return base;
	}

	// tokenURI returns tokenURI of a single token for metadata
	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721, ERC721URIStorage)
		returns (string memory)
	{
		return super.tokenURI(tokenId);
	}

	// _baseURI provides parent contracts to concatenate URI to build TokenURIs
	function _baseURI() internal view override returns (string memory) {
		return base;
	}

	// updateBaseURI updates the baseURI for change of metadata host
	function updateBaseURI(string memory _newBase) public onlyOwner {
		base = _newBase;
	}

	// getRareUnitPrice linearly increases price
	function getRareUnitPrice() public view returns (uint256) {
		return rareBasePrice;
	}

	// getCommonUnitPrice linearly increases price
	function getCommonUnitPrice() public view returns (uint256) {
		return commonBasePrice + commonIDCounter.current() * commonRampSpeed;
	}

	// setRareBasePrice updates the floor price for rares
	function setRareBasePrice(uint256 amount) public onlyOwner {
		rareBasePrice = amount;
	}

	// setCommonBasePrice updates the floor price for commons
	function setCommonBasePrice(uint256 amount) public onlyOwner {
		commonBasePrice = amount;
	}

	// MoreThanZero verifies amount is larger than 0
	modifier MoreThanZero(uint256 amount) {
		require(amount > 0, "You can not mint zero tokens");
		_;
	}

	// RareIDAvailable verifies rare token has not been already bought
	modifier RareIDAvailable(uint256 id) {
		require(
			rarePurchasedIDs[id] == false,
			"Waifu has already been purchased"
		);
		_;
	}

	// IsRareID verifies ID requested for purchase is a rare token
	modifier IsRareID(uint256 id) {
		require(
			id >= legendarySupply && id < legendarySupply + rareSupply,
			"This ID is not a rare waifu"
		);
		_;
	}

	// BelowMaxCommonMintPerTX verifies the request does not try to mint more than is allowed
	modifier BelowMaxCommonMintPerTX(uint256 amount) {
		require(
			amount <= maxCommonMintPerTx,
			"You can not mint more than 30 at once"
		);
		_;
	}

	// CommonSupplyCapNotReached verifies minted common tokens have not hit supply cap
	modifier CommonSupplyCapNotReached() {
		require(
			commonIDCounter.current() != commonSupply,
			"Supply cap reached"
		);
		_;
	}

	// NotCommonOvermint verifies request does not try to mint more commons than is allowed in one TX
	modifier NotCommonOvermint(uint256 amount) {
		require(
			commonIDCounter.current() + amount <= commonSupply,
			"Minting this many will exceed the common supply cap"
		);
		_;
	}

	// NotRareOvermint verifies request does not try to mint more rares than is allowed in one TX
	modifier NotRareOvermint(uint256 fromID, uint256 amount) {
		require(
			fromID + amount <= legendarySupply + rareSupply,
			"Minting this many will overflow into the common ID allocation"
		);
		_;
	}

	modifier isReservedBy(uint256 id) {
		require(
			reserver.isReservedBy(id, msg.sender),
			"you are not the reserver"
		);
		_;
	}

	// isPrivateSaleActive verifies public sale is active
	modifier isPrivateSaleActive() {
		require(
			currentStage == Stage.PrivateSale,
			"Private sale is not active"
		);
		_;
	}
	// isPublicSaleActive verifies public sale is active
	modifier isPublicSaleActive() {
		require(currentStage == Stage.PublicSale, "Public sale is not active");
		_;
	}

	// devRareMint allows contract owner to mint multiple rares to distribute to early backers
	function devRareMint(
		address to,
		uint256 fromID,
		uint256 amount
	) public onlyOwner MoreThanZero(amount) NotRareOvermint(fromID, amount) {
		for (uint256 id = fromID; id < fromID + amount; id++) {
			_devRareMint(to, id);
		}
	}

	// _devRareMint mints a single rare
	function _devRareMint(address to, uint256 id)
		internal
		onlyOwner
		RareIDAvailable(id)
	{
		_rareMint(to, id);
	}

	// devCommonMint mints many common tokens for distribution to early backers
	function devCommonMint(address to, uint256 amount)
		public
		onlyOwner
		MoreThanZero(amount)
		CommonSupplyCapNotReached
		NotCommonOvermint(amount)
	{
		for (uint256 i = 0; i < amount; i++) {
			_commonMint(to);
		}
	}

	// commonMint is used to mint common tokens
	function commonMint(uint256 amount)
		public
		payable
		MoreThanZero(amount)
		CommonSupplyCapNotReached
		NotCommonOvermint(amount)
		BelowMaxCommonMintPerTX(amount)
		isPublicSaleActive
	{
		require(
			msg.value >= amount * commonBasePrice,
			"You did not pay the correct amount"
		);
		for (uint256 i = 0; i < amount; i++) {
			_commonMint(msg.sender);
		}
	}

	// privateSaleRareMint is used to mint rare tokens during the private sale
	function privateSaleRareMint(uint256 id)
		public
		payable
		IsRareID(id)
		RareIDAvailable(id)
		isReservedBy(id)
		isPrivateSaleActive
	{
		require(
			msg.value >= rareBasePrice,
			"You did not pay the correct amount"
		);
		_rareMint(msg.sender, id);
	}

	// publicSaleRareMint is used to mint rare tokens during the public sale
	function publicSaleRareMint(uint256 id)
		public
		payable
		IsRareID(id)
		RareIDAvailable(id)
		isPublicSaleActive
	{
		require(
			msg.value >= rareBasePrice,
			"You did not pay the correct amount"
		);
		_rareMint(msg.sender, id);
	}

	// _rareMint a rare token, for internal use
	// Used as a helper gated by public functions as it has no validation
	function _rareMint(address to, uint256 id) internal {
		_safeMint(to, id);
		emit onRareMint(id);
		rarePurchasedIDs[id] = true;
		rarePurchasedIDArray.push(id);
	}

	// _commonMint a common token, for internal use
	// Used as a helper gated by public functions as it has no validation
	function _commonMint(address to) internal {
		_safeMint(to, legendarySupply + rareSupply + commonIDCounter.current());
		emit onCommonMint(commonIDCounter.current());
		commonIDCounter.increment();
		if (commonIDCounter.current() == commonSupply) {
			emit onCommonSupplyCapReached();
		}
	}

	// onRareMint event to track rare token minting events
	event onRareMint(uint256 id);

	// onCommonMint event to track common token minting events
	event onCommonMint(uint256 id);

	// onSaleStageChange event to track activated and deactivated sale events
	event onSaleStageChange(Stage stage);

	// onCommonSupplyCapReached event to track supply cap events
	event onCommonSupplyCapReached();
}
