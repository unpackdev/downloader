// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./BallcellLiquidBoyaParameters.sol";
import "./BallcellLiquidBoyaMainCreateParameters.sol";
import "./BallcellLiquidBoyaMainMetadata.sol";

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

contract BallcellLiquidBoyaMain is ERC721Enumerable, Ownable {
	uint256 private constant _TOKEN_SUPPLY_AUCTION = 1;
	uint256 private constant _TOKEN_SUPPLY_PROMOTION = 33;
	uint256 private constant _TOKEN_SUPPLY_REWARD = 66;
	uint256 private constant _TOKEN_SUPPLY_HOMEPAGE = 2900;
	uint256 private constant _HOMEPAGE_AMOUNT = 5;
	uint256 private constant _HOMEPAGE_PRICE = 0.03 ether;

	address private _addressProxyRegistry;
	address private _addressContractImage;
	uint256 private _passcode = 0;

	uint256 private _currentTokenId = 0;
	uint256 private _tokenCountHomepage = 0;
	uint256 private _tokenCountPromotion = 0;
	uint256 private _tokenCountReward = 0;

	bool private _saleIsActive = false;
	bool private _saleIsFinish = false;

	bool private _canceled = false;
	bool private _revealed = false;
	string private _seedPhrase = "";
	bytes32 private _seedNumber = 0;

    mapping(uint256 => string) private _tokenNames;

	constructor() ERC721("BallcellLiquidBoya", "BCL") {
		_mintAuction();
	}

	function settingAddressProxyRegistry(address value) public {
		require(_addressProxyRegistry == 0x0000000000000000000000000000000000000000, "already set");
		_addressProxyRegistry = value;
	}

	function settingAddressContractImage(address value) public {
		require(_addressContractImage == 0x0000000000000000000000000000000000000000, "already set");
		_addressContractImage = value;
	}

	function settingPasscode(uint256 value) public {
		require(_passcode == 0, "already set");
		_passcode = value;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	// ホームページで情報を取得できるようにする関数
	uint private constant _keyMintTotal = 0;
	uint private constant _keyMintRemains = 1;
	uint private constant _keyMintPurchasable = 2;
	uint private constant _keyMintPricePerToken = 3;
	uint private constant _keyMintFlagActive = 4;
	uint private constant _keyMintFlagFinish = 5;
	function getMintInformation() public view returns (uint256[6] memory) {
		uint256[6] memory array;
		uint256 mintTotal = _TOKEN_SUPPLY_AUCTION + _TOKEN_SUPPLY_PROMOTION + _TOKEN_SUPPLY_REWARD + _TOKEN_SUPPLY_HOMEPAGE;
		uint256 mintRemains = _TOKEN_SUPPLY_HOMEPAGE - _tokenCountHomepage;
		uint256 mintPurchasable = _HOMEPAGE_AMOUNT;
		array[_keyMintTotal] = mintTotal;
		array[_keyMintRemains] = mintRemains;
		array[_keyMintPurchasable] = mintPurchasable < mintRemains ? mintPurchasable : mintRemains;
		array[_keyMintPricePerToken] = _HOMEPAGE_PRICE;
		array[_keyMintFlagActive] = _saleIsActive ? 1 : 0;
		array[_keyMintFlagFinish] = _saleIsFinish ? 1 : 0;
		return array;
	}

	function getRemainPromotion() public view returns (uint256) {
		return _TOKEN_SUPPLY_PROMOTION - _tokenCountPromotion;
	}

	function getRemainReward() public view returns (uint256) {
		return _TOKEN_SUPPLY_REWARD - _tokenCountReward;
	}

	function _tokenParameters(uint256 tokenId) private view returns (BallcellLiquidBoyaParameters.Parameters memory) {
		require(_exists(tokenId), "non existent token");
		BallcellLiquidBoyaMainCreateParameters.Arguments memory arguments;
		arguments.canceled = _canceled;
		arguments.revealed = _revealed;
		arguments.tokenId = tokenId;
		arguments.passcode = _passcode;
		arguments.owner = _exists(tokenId) ? ownerOf(tokenId) : address(0);
		arguments.seedPhrase = _seedPhrase;
		arguments.seedNumber = _seedNumber;
		arguments.isSpecial = tokenId <= _TOKEN_SUPPLY_AUCTION + _TOKEN_SUPPLY_PROMOTION + _TOKEN_SUPPLY_REWARD;
		return BallcellLiquidBoyaMainCreateParameters.createParameters(arguments);
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		BallcellLiquidBoyaParameters.Parameters memory parameters = _tokenParameters(tokenId);
		return BallcellLiquidBoyaMainMetadata.metadata(parameters, _tokenNames[tokenId], _addressContractImage);
	}

	function tokenArray(uint256 tokenId) public view returns (uint16[18] memory) {
		BallcellLiquidBoyaParameters.Parameters memory parameters = _tokenParameters(tokenId);
		return BallcellLiquidBoyaParameters.createArray(parameters);
	}

	function setSaleIsActive(bool value) public onlyOwner {
		require(!_saleIsFinish, "Sale has already finished");
		require(!_saleIsActive || !value, "Sale has already started");
		require(_saleIsActive || value, "Sale has already stopped");
		_saleIsActive = value;
	}

	// 永遠に販売を終了する関数
	function setSaleIsFinish() public onlyOwner {
		require(!_saleIsFinish, "Sale has already finished");
		_saleIsFinish= true;
	}

	// testnetで存在を隠蔽する関数
	function setCancel(bool value) public onlyOwner {
		require(!_canceled || !value, "already canceled");
		require(_canceled || value, "not canceled");
		_canceled = value;
	}

	function reveal(string memory seedPhrase) public onlyOwner {
		require(!_revealed, "already revealed");
		_revealed = true;
		_seedPhrase = seedPhrase;
		_seedNumber = blockhash(block.number - 1);
	}

	function rename(uint256 tokenId, string memory tokenName) public onlyOwner {
		bytes32 hashCurr = keccak256(abi.encodePacked(_tokenNames[tokenId]));
		bytes32 hashNext = keccak256(abi.encodePacked(tokenName));
		require(hashCurr != hashNext, "same name");
		_tokenNames[tokenId] = tokenName;
	}

	function _mintAuction() private onlyOwner {
		uint256 tokenAmountMint = _TOKEN_SUPPLY_AUCTION;
		uint256 tokenOffset = 1;
		for (uint256 i = 0; i < tokenAmountMint; i++) {
			address minter = msg.sender;
			uint256 tokenId = tokenOffset + i;
			_safeMint(minter, tokenId);
			_tokenNames[tokenId] = "origin";
		}
	}

	function mintPromotion(address[] memory winner, string memory tokenName) public onlyOwner {
		uint256 tokenAmountMint = winner.length;
		uint256 tokenAmountExist = _tokenCountPromotion;
		uint256 tokenSupply = _TOKEN_SUPPLY_PROMOTION;
		uint256 tokenOffset = 1 + tokenAmountExist + _TOKEN_SUPPLY_AUCTION;
		require(tokenAmountExist + tokenAmountMint <= tokenSupply, "token stock shortage");
		for (uint256 i = 0; i < tokenAmountMint; i++) {
			address minter = winner[i];
			uint256 tokenId = tokenOffset + i;
			_safeMint(minter, tokenId);
			_tokenNames[tokenId] = tokenName;
		}
		_tokenCountPromotion = tokenAmountExist + tokenAmountMint;
	}

	function mintReward(address[] memory winner, string memory tokenName) public onlyOwner {
		uint256 tokenAmountMint = winner.length;
		uint256 tokenAmountExist = _tokenCountReward;
		uint256 tokenSupply = _TOKEN_SUPPLY_REWARD;
		uint256 tokenOffset = 1 + tokenAmountExist + _TOKEN_SUPPLY_AUCTION + _TOKEN_SUPPLY_PROMOTION;
		require(tokenAmountExist + tokenAmountMint <= tokenSupply, "token stock shortage");
		for (uint256 i = 0; i < tokenAmountMint; i++) {
			address minter = winner[i];
			uint256 tokenId = tokenOffset + i;
			_safeMint(minter, tokenId);
			_tokenNames[tokenId] = tokenName;
		}
		_tokenCountReward = tokenAmountExist + tokenAmountMint;
	}

	function mintHomepage(uint tokenAmountMint) public payable {
		require(!_saleIsFinish, "Sale has finished");
		require(_saleIsActive, "Sale has stopped");
		uint256 tokenAmountExist = _tokenCountHomepage;
		uint256 tokenSupply = _TOKEN_SUPPLY_HOMEPAGE;
		uint256 tokenOffset = 1 + tokenAmountExist + _TOKEN_SUPPLY_AUCTION + _TOKEN_SUPPLY_PROMOTION + _TOKEN_SUPPLY_REWARD;
		require(tokenAmountMint <= _HOMEPAGE_AMOUNT, "incorrect token amount");
		require(tokenAmountExist + tokenAmountMint <= tokenSupply, "token stock shortage");
		require(tokenAmountMint * _HOMEPAGE_PRICE <= msg.value, "incorrect ether amount");
		address minter = msg.sender;
		for (uint256 i = 0; i < tokenAmountMint; i++) {
			uint256 tokenId = tokenOffset + i;
			_safeMint(minter, tokenId);
		}
		_tokenCountHomepage = tokenAmountExist + tokenAmountMint;
	}

	function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, "no balance");
		payable(msg.sender).transfer(balance);
	}

	function isApprovedForAll(address owner, address operator) override public view returns (bool) {
		if (_addressProxyRegistry == address(0)) { return super.isApprovedForAll(owner, operator); }
		ProxyRegistry proxyRegistry = ProxyRegistry(_addressProxyRegistry);
		if (address(proxyRegistry.proxies(owner)) == operator) { return true; }
		return super.isApprovedForAll(owner, operator);
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

