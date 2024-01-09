// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./IAtopia.sol";
import "./IBucks.sol";
import "./ITrait.sol";
import "./Base64.sol";

contract AtopiaShop is ERC1155 {
	using Base64 for *;

	struct Item {
		uint128 id;
		uint64 bonusAge;
		uint16 bonusTrait;
		uint16 storeIndex;
		ITrait store;
		uint128 minAge;
		uint256 price;
		uint256 stock;
	}

	bool public initialized;

	string public constant name = "Atopia Shop";
	string public constant symbol = "ATPSHOP";

	event ItemUpdated(Item item);

	IAtopia public atopia;
	IBucks public bucks;

	Item[] public items;

	function initialize(address _atopia) external {
		require(!initialized);
		initialized = true;
		atopia = IAtopia(_atopia);
		bucks = atopia.bucks();
		// ERC1155.init("");
	}

	function totalItems() external view returns (uint256) {
		return items.length;
	}

	function itemInfo(uint256 index) public view returns (uint256) {
		return
			(uint256(items[index].bonusAge) << 192) |
			(((uint256(items[index].bonusTrait) << 16) | items[index].storeIndex) << 128) |
			items[index].minAge;
	}

	function onlyAtopiaOwner() internal view {
		require(msg.sender == atopia.owner());
	}

	function addItem(
		uint64 bonusAge,
		uint16 bonusTrait,
		address store,
		uint16[] memory storeIndexes,
		uint128 minAge,
		uint256 price,
		uint256 stock
	) external {
		onlyAtopiaOwner();
		uint256 itemId = items.length;
		itemId = (itemId << 128) | (itemId + 1);
		for (uint16 i = 0; i < storeIndexes.length; i++) {
			items.push(
				Item(uint128(itemId), bonusAge, bonusTrait, storeIndexes[i], ITrait(store), minAge, price, stock)
			);
			emit ItemUpdated(items[itemId >> 128]);
			itemId = (itemId << 128) | (uint128(itemId) + 1);
		}
	}

	function updateItem(
		uint256 itemId,
		uint64 bonusAge,
		uint128 minAge,
		uint256 price,
		uint256 stock
	) external {
		onlyAtopiaOwner();
		uint256 index = itemId - 1;
		items[index].bonusAge = bonusAge;
		items[index].minAge = minAge;
		items[index].price = price;
		items[index].stock = stock;
		emit ItemUpdated(items[index]);
	}

	function buyItem(uint256 itemId, uint256 amount) external {
		uint256 index = itemId - 1;
		uint256 stock = items[index].stock;
		uint256 price = items[index].price * amount;
		require(stock >= amount);
		items[index].stock = stock - amount;
		bucks.transferFrom(msg.sender, address(this), price);
		_mint(msg.sender, itemId, amount, "");
		emit ItemUpdated(items[index]);
	}

	function buyItemAndUse(uint256 itemId, uint256 tokenId) external {
		uint256 index = itemId - 1;
		uint256 stock = items[index].stock;
		uint256 price = items[index].price;
		require(stock > 0);
		items[index].stock = stock - 1;
		bucks.transferFrom(msg.sender, address(this), price);
		emit TransferSingle(msg.sender, address(0), msg.sender, itemId, 1);
		atopia.buyAndUseItem(tokenId, itemInfo(index));
		emit TransferSingle(msg.sender, msg.sender, address(0), itemId, 1);
		emit ItemUpdated(items[index]);
	}

	function distributeItems(uint256[] memory dists, address[] memory users) external {
		require(msg.sender == admin);
		uint256 totalMints;
		for (uint256 i = 0; i < dists.length; i += 2) {
			uint256 itemId = dists[i];
			uint256 index = itemId - 1;
			uint256 amount = dists[i + 1];
			uint256 stock = items[index].stock;
			items[index].stock = stock - amount;
			uint256 end = totalMints + amount;
			for (; totalMints < end; totalMints++) {
				_mint(users[totalMints], itemId, 1, "");
			}
			emit ItemUpdated(items[index]);
		}
	}

	function uri(uint256 id) public view virtual override returns (string memory) {
		Item memory item = items[id - 1];
		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						abi.encodePacked(
							'{"name":"',
							item.store.getTraitName(item.storeIndex),
							'","description":"Atopia Shopping Item","image":"data:image/svg+xml;base64,',
							Base64.encode(
								abi.encodePacked(
									'<?xml version="1.0" encoding="utf-8"?><svg version="1.1" id="_x31_" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1000 1000" style="enable-background:new 0 0 1000 1000;" xml:space="preserve"><style type="text/css">.g{width:100%;height:100%}.h{overflow:visible;}.s{stroke:#000000;stroke-width:10;stroke-miterlimit:10;}.d{stroke-linecap:round;stroke-linejoin:round}.f{fill:#FDA78B;}.c{fill:#FFDAB6;}.e{fill:none;}.l{fill:white;}.b{fill:black;}</style>',
									item.store.getTraitContent(item.storeIndex),
									"</svg>"
								)
							),
							'","attributes":[{"trait_type":"Store","value":"',
							item.store.name(),
							'"},{"display_type":"number","trait_type":"Min Age","value":"',
							((item.minAge * 10) / 365 days).toString(),
							'"},{"display_type":"number","trait_type":"Age Growth (days)","value":"',
							((item.bonusAge * 10) / 1 days).toString(),
							'"},{"trait_type":"Wearable","value":"',
							item.bonusTrait > 0 ? "Yes" : "No",
							'"}]}'
						)
					)
				)
			);
	}
}
