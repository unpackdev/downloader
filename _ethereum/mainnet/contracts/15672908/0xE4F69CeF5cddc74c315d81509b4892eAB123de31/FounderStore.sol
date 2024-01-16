// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Founder Cards Store (v.1)
/// @author Studio Avante
/// @notice Contains token info for Founder Cards (ids 1 and 2)
/// @dev Serves CardsMinter.sol, will be upgraded to a generic store when Endless Crawler is released
pragma solidity ^0.8.16;
import "./Ownable.sol";
import "./Base64.sol";
import "./ICardsStore.sol";

contract FounderStore is ICardsStore, Ownable {

	struct Attribute {
		bytes name;
		bytes value;
	}

	struct Card {
		uint256 price;
		uint128 supply;
		bytes imageData;
		string name;
	}
	
	mapping(uint256 => Card) private _cards;

	/// @notice Emitted when a new card is created
	/// @param id Token id
	/// @param name The name of the card
	event Created(uint256 indexed id, string indexed name);

	constructor() {
		_cards[1] = Card(
			1_000_000_000_000_000_000, // 1 eth
			16,
			'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 16 16" shape-rendering="crispEdges"><path stroke="#1a1a1a" d="M4 0h8M3 1h2m6 0h2M2 2h2m1 0h6m1 0h2M1 3h2m1 0h8m1 0h2M1 4h1m1 0h10m1 0h1M1 5h1m1 0h10m1 0h1M1 6h1m1 0h10m1 0h1M1 7h1m1 0h3m2 0h5m1 0h1M1 8h1m1 0h2m1 0h2m1 0h4m1 0h1M1 9h1m1 0h2m1 0h7m1 0h1M1 10h1m1 0h2m1 0h7m1 0h1M1 11h1m1 0h2m1 0h7m1 0h1M1 12h1m1 0h2m1 0h5m1 0h1m1 0h1M1 13h1m1 0h2m1 0h2m1 0h4m1 0h1M1 14h1m1 0h3m2 0h2m2 0h1m1 0h1M1 15h14"/><path stroke="#f3e9c3" d="M5 1h1m2 0h1M4 2h1m6 0h1M3 3h1m8 0h1m0 1h1m-1 1h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m-1 1h1m10 0h1M2 12h1m10 1h1"/><path stroke="#f2e9c3" d="M6 1h2m1 0h2m2 11h1M2 13h1m-1 1h1m10 0h1"/><path stroke="#f3e9c4" d="M2 4h1M2 5h1"/><path stroke="#ffbea6" d="M6 7h2M5 8h1m2 0h1M5 9h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m2 0h1m-3 1h2"/><path stroke="#f3eac4" d="M13 10h1"/><path stroke="#774e3f" d="M11 12h1"/><path stroke="#b58776" d="M10 14h2"/></svg>',
			'Champion'
		);
		emit Created(1, _cards[1].name);
		_cards[2] = Card(
			160_000_000_000_000_000, // 0.16 eth
			256,
			'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 16 16" shape-rendering="crispEdges"><path stroke="#1a1a1a" d="M4 0h8M3 1h2m6 0h2M2 2h2m1 0h6m1 0h2M1 3h2m1 0h8m1 0h2M1 4h1m1 0h10m1 0h1M1 5h1m1 0h10m1 0h1M1 6h1m1 0h10m1 0h1M1 7h1m1 0h2m1 0h2m1 0h4m1 0h1M1 8h1m1 0h2m1 0h2m1 0h4m1 0h1M1 9h1m1 0h2m1 0h2m1 0h4m1 0h1M1 10h1m1 0h2m4 0h4m1 0h1M1 11h1m1 0h2m1 0h2m1 0h4m1 0h1M1 12h1m1 0h2m1 0h2m1 0h2m1 0h1m1 0h1M1 13h1m1 0h2m1 0h2m1 0h4m1 0h1M1 14h1m1 0h2m1 0h2m1 0h1m2 0h1m1 0h1M1 15h14"/><path stroke="#f3e9c3" d="M5 1h1m2 0h1M4 2h1m6 0h1M3 3h1m8 0h1m0 1h1m-1 1h1M2 6h1m10 0h1M2 7h1m10 0h1M2 8h1m10 0h1M2 9h1m10 0h1M2 10h1m-1 1h1m10 0h1M2 12h1m10 1h1"/><path stroke="#f2e9c3" d="M6 1h2m1 0h2m2 11h1M2 13h1m-1 1h1m10 0h1"/><path stroke="#f3e9c4" d="M2 4h1M2 5h1"/><path stroke="#ffbea6" d="M5 7h1m2 0h1M5 8h1m2 0h1M5 9h1m2 0h1m-4 1h4m-4 1h1m2 0h1m-4 1h1m2 0h1m-4 1h1m2 0h1m-4 1h1m2 0h1"/><path stroke="#f3eac4" d="M13 10h1"/><path stroke="#774e3f" d="M11 12h1"/><path stroke="#b58776" d="M10 14h2"/></svg>',
			'Hero'
		);
		emit Created(2, _cards[2].name);
	}

	//---------------
	// Public
	//

	/// @notice Returns the Store version
	/// @return version This contract version (1)
	function getVersion() public pure override returns (uint8) {
		return 1;
	}

	/// @notice Check if a Token exists
	/// @param id Token id
	/// @return bool True if it exists, False if not
	function exists(uint256 id) public pure override returns (bool) {
		return (id > 0 && id <= 2);
	}

	/// @notice Returns a Token stored info
	/// @param id Token id
	/// @return card FounderStore.Card structure
	function getCard(uint256 id) public view returns (Card memory) {
		require(exists(id), 'Card does not exist');
		return _cards[id];
	}

	/// @notice Returns the number of Cards maintained by this contract
	/// @return number 2
	function getCardCount() public pure override returns (uint256) {
		return 2;
	}

	/// @notice Returns the total amount of Cards available for purchase
	/// @param id Token id
	/// @return number
	function getCardSupply(uint256 id) public view override returns (uint256) {
		require(exists(id), 'Card does not exist');
		return _cards[id].supply;
	}

	/// @notice Returns the price of a Card
	/// @param id Token id
	/// @return price The Card price, in WEI
	function getCardPrice(uint256 id) public view override returns (uint256) {
		require(exists(id), 'Card does not exist');
		return _cards[id].price;
	}

	/// @notice Run all the required tests to purchase a Card, reverting the transaction if not allowed to purchase
	/// @param id Token id
	/// @param currentSupply The total amount of minted Tokens, from all accounts
	/// @param balance The amount of tokens the purchaser owns
	/// @param value Transaction value sent, in WEI
	function beforeMint(uint256 id, uint256 currentSupply, uint256 balance, uint256 value) public view override {
		require(exists(id), 'Card does not exist');
		Card storage card = _cards[id];
		require(currentSupply < card.supply, 'Sold out');
		require(balance == 0, 'One per wallet');
		require(value >= card.price, 'Bad value');
	}

	/// @notice Returns a token metadata, compliant with ERC1155Metadata_URI
	/// @param id Token id
	/// @return metadata Token metadata, as json string base64 encoded
	function uri(uint256 id) public view override returns (string memory) {
		require(exists(id), 'Card does not exist');
		Card storage card = _cards[id];
		bytes memory json = abi.encodePacked(
			'{'
				'"name":"', card.name, '",'
				'"description":"The keeper of this card is a Crawler ', card.name, '. Grants all native cards.",'
				'"external_url":"https://endlesscrawler.io",'
				'"background_color":"1f1a20",'
				'"attributes":['
					'{"trait_type":"Type","value":"Class"},'
					'{"trait_type":"Class","value":"', card.name, '"},'
					'{"trait_type":"Edition","value":"Founder"}'
				'],'
				'"image":"data:image/svg+xml;base64,', Base64.encode(card.imageData), '"'
			'}'
		);
		return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
	}
}
