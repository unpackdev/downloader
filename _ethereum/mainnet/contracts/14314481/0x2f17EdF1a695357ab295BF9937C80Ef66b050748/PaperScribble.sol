// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./SVG.sol";
import "./IMetadataProvider.sol";
import "./GameUtils.sol";
import "./GameConnector.sol";

/// @title PaperScribble
contract PaperScribble is GameConnector, IMetadataProvider {

	using Strings for uint256;

	string private constant _CONTRACT_SYMBOL = "X";
	string private constant _OWNER_SYMBOL = "O";

	/// @inheritdoc IMetadataProvider
	function contractSymbol() external pure returns (string memory) {
		return _CONTRACT_SYMBOL;
	}

	/// @inheritdoc IMetadataProvider
	function metadata(ITicTacToe.Game memory game, uint256 tokenId) external view onlyAllowedCallers returns (string memory) {
		return string(OnChain.tokenURI(OnChain.dictionary(OnChain.commaSeparated(
			OnChain.keyValueString("name",  abi.encodePacked("Game ", tokenId.toString())),
			OnChain.keyValueArray("attributes", _attributesFromGame(game)),
			OnChain.keyValueString("image", OnChain.svgImageURI(_createSvg(game)))
		))));
	}

	/// @inheritdoc IMetadataProvider
	function ownerSymbol() external pure returns (string memory) {
		return _OWNER_SYMBOL;
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public pure override(GameConnector, IERC165) returns (bool) {
		return interfaceId == type(IMetadataProvider).interfaceId || super.supportsInterface(interfaceId);
	}

	function _attributesFromGame(ITicTacToe.Game memory game) private pure returns (bytes memory) {
		return OnChain.commaSeparated(
			OnChain.traitAttribute("Wins", bytes(uint256(game.history.wins).toString())),
			OnChain.traitAttribute("Losses", bytes(uint256(game.history.losses).toString())),
			OnChain.traitAttribute("Ties", bytes(uint256(game.history.ties).toString())),
			OnChain.traitAttribute("Restarts", bytes(uint256(game.history.restarts).toString())),
			OnChain.traitAttribute("Voting Power", bytes(uint256(game.history.wins).toString()))
		);
	}

	function _boardElements() private pure returns (bytes memory) {
		return abi.encodePacked(
			_rectElement(100, 100, " filter='url(#roughpaper)'"),
			_rectElement(100, 5, _boardElementAttributes(0, 30)),
			_rectElement(100, 5, _boardElementAttributes(0, 65)),
			_rectElement(5, 100, _boardElementAttributes(30, 0)),
			_rectElement(5, 100, _boardElementAttributes(65, 0)),
			_slotElements()
		);
	}

	function _boardElementAttributes(uint256 xPercent, uint256 yPercent) private pure returns (bytes memory) {
		return abi.encodePacked(" x='", xPercent.toString(), "%' y='", yPercent.toString(), "%' filter='url(#roughtext)'");
	}

	function _createSvg(ITicTacToe.Game memory game) private pure returns (bytes memory) {
		return SVG.createElement("svg", SVG.svgAttributes(540, 540), abi.encodePacked(
			_defsForSvg(game),
			SVG.createElement("g", " clip-path='url(#clip)'", abi.encodePacked(
				_boardElements(),
				_movesForGame(game),
				_winningCrosses(game)
			))
		));
	}

	function _defsForSvg(ITicTacToe.Game memory game) private pure returns (bytes memory) {
		return SVG.createElement("defs", "", abi.encodePacked(
			SVG.createElement("filter", " id='roughpaper'", _paperFilterWithColor("white")),
			SVG.createElement("filter", " id='roughtext' color-interpolation-filters='sRGB'", _paperFilterWithColor("rgb(66,66,66)")),
			_squigglyFilters((game.moves.length + 1) / 2),
			_winFilter(4),
			_winElements(),
			SVG.createElement("clipPath", " id='clip'", _rectElement(100, 100, ""))
		));
	}

	function _movesForGame(ITicTacToe.Game memory game) private pure returns (bytes memory result) {
		uint8[3] memory xPercentages = [15, 50, 85];
		uint8[3] memory yPercentages = [19, 54, 89];
		result = ""; // <text x="15%" y="19%" dominant-baseline='middle' text-anchor='middle' font-size='22em'>X</text>
		for (uint256 move = 0; move < game.moves.length; move++) {
			uint256 position = game.moves[move];
			bytes memory attributes = abi.encodePacked(" filter='url(#squiggly", (move / 2).toString(), ")' font-size='11em' x='", uint256(xPercentages[position % 3]).toString(), "%' text-anchor='middle' y='", uint256(yPercentages[position / 3]).toString(), "%' dominant-baseline='middle'");
			result = abi.encodePacked(result, SVG.createElement("text", attributes, move % 2 == 0 ? bytes(_CONTRACT_SYMBOL) : bytes(_OWNER_SYMBOL)));
		}
	}

	function _paperFilterWithColor(bytes memory color) private pure returns (bytes memory) {
		return abi.encodePacked(
			"<feTurbulence type='fractalNoise' baseFrequency='0.04' result='noise' numOctaves='5'/>",
			SVG.createElement("feDiffuseLighting", abi.encodePacked(" in='noise' lighting-color='", color, "' surfaceScale='2'"), "<feDistantLight azimuth='45' elevation='60'/>"),
			"<feComposite operator='in' in2='SourceGraphic' result='texture'/>"
		);
	}

	function _rectElement(uint256 widthPercentage, uint256 heightPercentage, bytes memory attributes) private pure returns (bytes memory) {
		return abi.encodePacked("<rect width='", widthPercentage.toString(), "%' height='", heightPercentage.toString(), "%'", attributes, "/>");
	}

	function _slotElements() private pure returns (bytes memory result) {
		uint8[3] memory percentages = [29, 64, 99];
		result = ""; // <text x='29%' y='29%' text-anchor='end' filter='url(#roughtext)' font-size='2em'>0</text>
		for (uint256 slot = 0; slot < 9; slot++) {
			bytes memory attributes = abi.encodePacked(" font-size='1em' x='", uint256(percentages[slot % 3]).toString(), "%' text-anchor='end' y='", uint256(percentages[slot / 3]).toString(), "%' filter='url(#roughtext)'");
			result = abi.encodePacked(result, SVG.createElement("text", attributes, bytes(slot.toString())));
		}
	}

	function _squigglyFilter(uint256 scale, uint256 index) private pure returns (bytes memory result) {
		return abi.encodePacked(
			abi.encodePacked("<feTurbulence baseFrequency='0.01' result='noise' numOctaves='3' seed='", index.toString(), "'/>"),
			abi.encodePacked("<feDisplacementMap in='SourceGraphic' in2='noise' scale='", scale.toString(), "'/>")
		);
	}

	function _squigglyFilters(uint256 totalFilters) private pure returns (bytes memory result) {
		result = "";
		for (uint256 index = 0; index < totalFilters; index++) {
			bytes memory attributes = abi.encodePacked(" id='squiggly", index.toString() ,"'");
			result = abi.encodePacked(result, SVG.createElement("filter", attributes, _squigglyFilter(3, index)));
		}
	}

	function _useElement(uint256 x, uint256 y, string memory name) private pure returns (bytes memory) {
		return abi.encodePacked("<use stroke-linecap='round' x='", x.toString(), "%' y='", y.toString(), "%' filter='url(#win)' href='#", name, "' stroke='red'/>");
	}

	function _winElements() private pure returns (bytes memory) {
		// 'M0 0 M90 90' works around a Chrome rendering issue
		return abi.encodePacked(
			_winPath("horizontal", "M0 0 M90 90 M81 81 L459 81"),
			_winPath("vertical", "M0 0 M90 90 M81 81 L81 459"),
			_winPath("criss", "M81 81 L459 459"),
			_winPath("cross", "M459 81 L81 459")
		);
	}

	function _winFilter(uint256 scale) private pure returns (bytes memory) {
		return SVG.createElement("filter", " id='win'",
			abi.encodePacked(
				_paperFilterWithColor("rgb(225,0,0)"),
				"<feTurbulence baseFrequency='0.02' result='noise' numOctaves='3' seed='0'/>",
				"<feDisplacementMap in='texture' in2='noise' scale='", scale.toString(), "'/>"
			)
		);
	}

	function _winningCrosses(ITicTacToe.Game memory game) private pure returns (bytes memory) {
		if (game.state == ITicTacToe.GameState.OwnerWon) {
			GameUtils.GameInfo memory gameInfo = GameUtils.gameInfoFromGame(game);
			return _winningCrossesForMap(GameUtils.mapForPlayer(gameInfo, GameUtils.GamePlayer.Owner));
		} else if (game.state == ITicTacToe.GameState.ContractWon) {
			GameUtils.GameInfo memory gameInfo = GameUtils.gameInfoFromGame(game);
			return _winningCrossesForMap(GameUtils.mapForPlayer(gameInfo, GameUtils.GamePlayer.Contract));
		}
		return "";
	}

	function _winningCrossesForMap(uint256 map) private pure returns (bytes memory result) {
		result = "";
		if (GameUtils.bitsMatch(map, 448)) {
			result = abi.encodePacked(result, _useElement(0, 0, "horizontal"));
		}
		if (GameUtils.bitsMatch(map, 292)) {
			result = abi.encodePacked(result, _useElement(0, 0, "vertical"));
		}
		if (GameUtils.bitsMatch(map, 273)) {
			result = abi.encodePacked(result, _useElement(0, 0, "criss"));
		}
		if (GameUtils.bitsMatch(map, 146)) {
			result = abi.encodePacked(result, _useElement(35, 0, "vertical"));
		}
		if (GameUtils.bitsMatch(map, 84)) {
			result = abi.encodePacked(result, _useElement(0, 0, "cross"));
		}
		if (GameUtils.bitsMatch(map, 73)) {
			result = abi.encodePacked(result, _useElement(70, 0, "vertical"));
		}
		if (GameUtils.bitsMatch(map, 56)) {
			result = abi.encodePacked(result, _useElement(0, 35, "horizontal"));
		}
		if (GameUtils.bitsMatch(map, 7)) {
			result = abi.encodePacked(result, _useElement(0, 70, "horizontal"));
		}
		return result;
	}

	function _winPath(string memory id, string memory path) private pure returns (bytes memory) {
		return abi.encodePacked("<path id='", id, "' d='", path, "' stroke-width='4%'/>");
	}
}
