// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base.sol";
import "./BatchCounters.sol";
import "./IDrawer.sol";

contract AtopiaApe is AtopiaBase {
	bool public initialized;
	using BatchCounters for BatchCounters.Counter;
	BatchCounters.Counter private _tokenIds;

	struct Token {
		address token;
		uint256 price;
		uint256 limit;
	}

	event TraitUpdated(uint256 tokenId, uint256 tokenTrait);

	uint256 public constant saleFee = 0.06 ether;
	uint256 public constant BLOCK_COUNT = 1000;

	mapping(address => bool) public memberships;
	mapping(address => uint256) public whitelists;
	Token[] public tokens;

	mapping(uint256 => string) names;

	mapping(uint256 => uint256) public tokenTraits;
	mapping(uint256 => mapping(uint256 => uint256)) public traitStore;
	uint256[] blockHashes;
	uint256 seed;

	IDrawer public drawer;

	uint8 public state;

	function initialize(address bucks) public virtual override {
		require(!initialized);
		initialized = true;
		AtopiaBase.initialize(bucks);
		seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.coinbase, block.timestamp)));
	}

	function migrateV2(uint256[] memory tokenIds) public onlyOwner {
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			uint256 info = infos[tokenId];
			uint256 retired = retiredGrow[tokenId];
			if (retired > 0) infos[tokenId] = (((info >> 192) + retired) << 192) | uint192(info);
		}
	}

	function totalTokens() external view returns (uint256) {
		return tokens.length;
	}

	function onlyState(uint8 _state) internal view {
		require(state >= _state, "Not Allowed");
	}

	function totalSupply() public view returns (uint256) {
		return _tokenIds.current();
	}

	function nextGenInfo(uint256 last) public pure returns (uint256, uint256) {
		if (last < 10_000) {
			return (10_000_000_000, 5 * apeYear); // 10k ABUCKS
		} else if (last < 20_000) {
			return (10_000_000_000, 3 * apeYear); // 10k ABUCKS
		} else if (last < 30_000) {
			return (15_000_000_000, 2 * apeYear); // 15k ABUCKS
		} else if (last < 40_000) {
			return (20_000_000_000, 1 * apeYear); // 20k ABUCKS
		} else {
			return (25_000_000_000, 1 * apeYear); // 25k ABUCKS
		}
	}

	function blockToken(uint16 blockIndex) public view returns (uint256) {
		uint256 blockHash = blockHashes[blockIndex];
		require(blockHash > 0);
		return (blockHash % BLOCK_COUNT) + 1 + blockIndex * BLOCK_COUNT;
	}

	function enter(
		address to,
		uint256 tokenId,
		uint256 _seed
	) internal {
		uint256 tokenTrait;
		uint256 drawerCounts = 0x00020009000a00040001000a000c000c000700070013;
		for (uint16 i = 0; i < 11; i++) {
			// 12 traits
			tokenTrait = (tokenTrait << 16) | ((_seed & 0xFFFF) % (drawerCounts & 0xFFFF));
			_seed = _seed >> 16;
			drawerCounts = drawerCounts >> 16;
		}

		tokenTraits[tokenId] = tokenTrait;
		_mint(to, tokenId);
	}

	function batch(
		address to,
		uint256 amount,
		uint256 age
	) internal {
		uint256 newSeed = seed;
		(uint256 start, uint256 end) = _tokenIds.increment(amount);
		uint256 info = ((block.timestamp - age) << 64) | uint64(block.timestamp);
		for (uint256 i = start; i <= end; i++) {
			infos[i] = info;

			newSeed = uint256(keccak256(abi.encodePacked(uint8(i), uint128(info), newSeed)));
			enter(to, i, newSeed);

			if (i % BLOCK_COUNT == 0) {
				blockHashes.push(newSeed);
			}
		}
		seed = newSeed;
	}

	function mint(uint256 amount) external payable {
		onlyState(2);
		require(amount <= 7);
		require(totalSupply() + amount <= 10_000);
		require(msg.value >= saleFee * amount);
		batch(msg.sender, amount, 5 * apeYear);
	}

	function mintPresale(uint256 amount) external payable {
		onlyState(1);
		require(whitelists[msg.sender] >= amount);
		whitelists[msg.sender] -= amount;
		require(totalSupply() + amount <= 10_000);
		require(msg.value >= saleFee * amount);
		batch(msg.sender, amount, 5 * apeYear);
	}

	function mintOG() external {
		onlyState(1);
		require(memberships[msg.sender]);
		delete memberships[msg.sender];
		require(totalSupply() < 10_000);
		batch(msg.sender, 1, 5 * apeYear);
	}

	function mintWithToken(uint256 index, uint256 amount) external {
		onlyState(1);
		require(amount <= (state == 1 ? 3 : 7));
		require(tokens[index].limit >= amount);
		tokens[index].limit -= amount;
		require(totalSupply() + amount <= 10_000);
		IBucks(tokens[index].token).transferFrom(msg.sender, admin, tokens[index].price * amount);
		batch(msg.sender, amount, 5 * apeYear);
	}

	function mintNextGen(uint256 amount) external {
		uint256 last = totalSupply();
		uint256 end = last + amount;
		require(end <= 50_000);
		require((last / 10_000) == (end / 10_000));
		(uint256 price, uint256 age) = nextGenInfo(end);
		bucks.burnFrom(msg.sender, price * amount);
		batch(msg.sender, amount, age);
	}

	function setName(uint256 tokenId, string memory name) external {
		onlyTokenOwner(tokenId);
		bucks.burnFrom(msg.sender, 10_000_000_000);
		names[tokenId] = name;
	}

	function placeItem(
		uint256 tokenId,
		uint16 traitType,
		uint256 traitId,
		bool isStore
	) internal {
		uint16 traitPos = (10 - traitType) * 16;
		uint256 tokenTrait = tokenTraits[tokenId];
		uint256 exchangeId = (tokenTrait >> traitPos) & 0xFFFF;

		if (isStore) {
			uint256 store = traitStore[tokenId][traitType];
			uint256 count = store & 0xFFFF;
			store = store >> 16;
			if (count == 0 && exchangeId > 0) {
				store = exchangeId;
				count = 1;
			}
			traitStore[tokenId][traitType] = (store << 32) | (traitId << 16) | (count + 1);
		}

		tokenTrait = ((tokenTrait ^ (exchangeId << traitPos)) ^ 0) | (traitId << traitPos);
		tokenTraits[tokenId] = tokenTrait;
		emit TraitUpdated(tokenId, tokenTrait);
	}

	function useItemFor(
		uint256 tokenId,
		uint256 itemInfo,
		uint256 amount
	) internal {
		// Min Age
		require(getAge(tokenId) >= itemInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
		itemInfo = itemInfo >> 128;
		// Bonus Trait
		if (itemInfo & 0xFFFFFFFF > 0) {
			require(amount == 1);
			placeItem(tokenId, uint16((itemInfo >> 16) & 0xFFFF), uint16(itemInfo & 0xFFFF), true);
		}
		itemInfo = itemInfo >> 64;
		// Bonus Age
		useItemInternal(tokenId, itemInfo * amount);
	}

	function useItem(
		uint256 tokenId,
		uint256 itemId,
		uint256 amount
	) external {
		onlyTokenOwner(tokenId);
		IShop _shop = IShop(shop);
		uint256 itemInfo = _shop.itemInfo(itemId - 1);
		_shop.burn(msg.sender, itemId, amount);
		useItemFor(tokenId, itemInfo, amount);
	}

	function buyAndUseItem(uint256 tokenId, uint256 itemInfo) external {
		require(shop == msg.sender);
		useItemFor(tokenId, itemInfo, 1);
	}

	function makeup(
		uint256 tokenId,
		uint16 traitType,
		uint256 storeIndex
	) external {
		onlyTokenOwner(tokenId);
		uint256 store = traitStore[tokenId][traitType];
		uint256 count = store & 0xFFFF;
		require(storeIndex < count);
		placeItem(tokenId, traitType, (store >> ((storeIndex + 1) * 16)) & 0xFFFF, false);
	}

	function claimTraits(uint16 blockIndex) external {
		uint256 tokenId = blockToken(blockIndex);
		blockHashes[blockIndex] = 0;
		uint16 traitIndex = 0x000a + blockIndex;
		require(traitIndex < drawer.totalItems(5));
		placeItem(tokenId, 5, traitIndex, true);
		traitIndex = 0x0002 + blockIndex;
		require(traitIndex < drawer.totalItems(10));
		placeItem(tokenId, 10, traitIndex, false);
	}

	function setState(uint8 _state) external onlyOwner {
		state = _state;
	}

	function setDrawer(address _drawer) external onlyOwner {
		drawer = IDrawer(_drawer);
		emit DrawerUpdated(_drawer);
	}

	// function addMembership(address[] calldata members) public onlyOwner {
	// 	for (uint256 i = 0; i < members.length; i++) {
	// 		memberships[members[i]] = true;
	// 	}
	// }

	// function addWhitelists(address[] calldata members) public onlyOwner {
	// 	for (uint256 i = 0; i < members.length; i++) {
	// 		whitelists[members[i]] = 3;
	// 	}
	// }

	// function addToken(
	// 	address token,
	// 	uint256 price,
	// 	uint256 limit
	// ) public onlyOwner {
	// 	tokens.push(Token(token, price, limit));
	// }

	function withdraw() external onlyOwner {
		payable(admin).transfer(address(this).balance);
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		require(ownerOf[tokenId] != address(0), "Token Invalid");
		return drawer.tokenURI(tokenId, names[tokenId], tokenTraits[tokenId], uint16((getAge(tokenId) / apeYear)));
	}
}
