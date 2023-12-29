// A L T E R N A T E
// G E N E R A T O R
// Kim Asendorf, 2023
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import "./Base64.sol";
import "./Strings.sol";

library Generator {
	using Strings for uint256;

	struct Color {
		uint256 hue;
		uint256 saturation;
		uint256 lightness;
	}

	struct Edition {
		uint256 version;
		uint256 jsSeed;
		uint256 layout;
		Color[3] colors;
		string system;
	}

	function random(uint256 seed) public pure returns (uint256) {
		uint256 r = seed;
		unchecked {
			r = r * 16807 % 2147483647;
		}
		return r;
	}

	function getPalette(uint256 seed) public pure returns (Color[] memory, string memory) {
		seed = random(seed);
		uint256 mode = seed % 9;

		if (mode < 2) {
			return (getRandomPalette(seed), "Random");
		} else if (mode < 4) {
			return (getMonochromePalette(seed), "Monochrome");
		} else if (mode < 6) {
			return (getTriadicPalette(seed), "Triadic");
		} else if (mode < 8) {
			return (getAnalogousPalette(seed), "Analogous");
		} else {
			return (getGreyscalePalette(seed), "Greyscale");
		}
	}

	function getRandomPalette(uint256 seed) private pure returns (Color[] memory) {
		Color[] memory colors = new Color[](3);

		seed = random(seed);
		uint256 h0 = seed % 360;

		seed = random(seed);
		uint256 h1 = seed % 360;

		seed = random(seed);
		uint256 s = seed % 25;

		seed = random(seed);
		uint256 l = 10 + seed % 15;

		colors[0] = Color(h0, 100, 50);
		colors[1] = Color(h1, 100, 50);
		colors[2] = Color(h0, s, l);

		return colors;
	}

	function getMonochromePalette(uint256 seed) private pure returns (Color[] memory) {
		Color[] memory colors = new Color[](3);

		seed = random(seed);
		uint256 h = seed % 360;

		seed = random(seed);
		uint256 s = 65 + seed % 20;

		seed = random(seed);
		uint256 l = 15 + seed % 15;

		colors[0] = Color(h, 100, 50);
		colors[1] = Color(h, 100, s);
		colors[2] = Color(h, 10, l);

		return colors;
	}

	function getTriadicPalette(uint256 seed) private pure returns (Color[] memory) {
		Color[] memory colors = new Color[](3);

		seed = random(seed);
		uint256 h0 = shiftHue(seed % 240);
		uint256 h1 = shiftHue((h0 + 120) % 240);
		uint256 h2 = shiftHue((h1 + 120) % 240);

		colors[0] = Color(h0, 100, 50);
		colors[1] = Color(h1, 80, 40);
		colors[2] = Color(h2, 10, 15);

		return colors;
	}

	function getAnalogousPalette(uint256 seed) private pure returns (Color[] memory) {
		Color[] memory colors = new Color[](3);

		seed = random(seed);
		uint256 h0 = seed % 360;
		uint256 h1 = (h0 + 30) % 360;

		seed = random(seed);
		uint256 l = 50 + seed % 25;

		colors[0] = Color(h0, 100, 50);
		colors[1] = Color(h1, 100, 25);
		colors[2] = Color(0, 0, l);

		return colors;
	}

	function getGreyscalePalette(uint256 seed) private pure returns (Color[] memory) {
		Color[] memory colors = new Color[](3);

		seed = random(seed);
		uint256 l0 = 4 + seed % 92;

		seed = random(seed);
		uint256 l1 = 4 + seed % 92;

		colors[0] = Color(0, 0, 0);
		colors[1] = Color(0, 0, l0);
		colors[2] = Color(0, 0, l1);

		return colors;
	}

	function shiftHue(uint256 h) private pure returns (uint256) {
		if (h > 90) h += 60;
		if (h > 270) h += 60;
		return h;
	}

	function getStyle(Color[3] memory colors) private pure returns (bytes memory) {
		bytes memory style;
		for (uint256 i = 0; i < 3; i++) {
			style = abi.encodePacked(style, ".c", i.toString(), "{fill:hsl(", colors[i].hue.toString(), ",", colors[i].saturation.toString(), "%,", colors[i].lightness.toString(), "%);}");
		}
		return style;
	}

	function getSVG(uint256 tokenId, Edition memory edition, string memory baseXML, string memory layoutXML) private pure returns (bytes memory) {
		bytes memory style = getStyle(edition.colors);
		return abi.encodePacked(
			'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">',
				'<style>', style, '</style>',
				'<defs>',
					'<text id="token">', tokenId.toString(), '</text>',
					'<text id="version">', edition.version.toString(), '/4</text>',
					'<text id="seed">', edition.jsSeed.toString(), '</text>',
					'<text id="system">', edition.system, '</text>',
				'</defs>',
				baseXML,
				layoutXML,
			'</svg>'
		);
	}

	function getImage(uint256 tokenId, Edition memory edition, string memory baseXML, string memory layoutXML) public pure returns (string memory) {
		bytes memory svg = getSVG(tokenId, edition, baseXML, layoutXML);
		return string(abi.encodePacked(
			"data:image/svg+xml;base64,",
			Base64.encode(svg)
		));
	}

	function getColorsString(Color[3] memory colors) private pure returns (bytes memory) {
		bytes memory str = "let colors=[";
		for (uint256 i = 0; i < 3; i++) {
			str = abi.encodePacked(str, "[", colors[i].hue.toString(), ",", colors[i].saturation.toString(), ",", colors[i].lightness.toString(), "]");
			if (i < 2) {
				str = abi.encodePacked(str, ',');
			}
		}
		return abi.encodePacked(str, "]");
	}

	function getHTML(Edition memory edition, string memory htmlPrefix, string memory htmlSuffix, string memory script) private pure returns (bytes memory) {
		bytes memory colorsStr = getColorsString(edition.colors);
		return abi.encodePacked(
			htmlPrefix,
			'let seed=', edition.jsSeed.toString(), ';let layout=', edition.layout.toString(), ';', colorsStr, ';', script,
			htmlSuffix
		);
	}

	function getAnimationURL(Edition memory edition, string memory htmlPrefix, string memory htmlSuffix, string memory script) public pure returns (string memory) {
		bytes memory html = getHTML(edition, htmlPrefix, htmlSuffix, script);
		return string(abi.encodePacked(
			"data:text/html;base64,",
			Base64.encode(html)
		));
	}

	function getExternalURLWithParams(string memory externalURL, uint256 tokenId, uint256 version) public pure returns (bytes memory) {
		return abi.encodePacked(
			externalURL, '?tokenId=', tokenId.toString(), '&version=', version.toString()
		);
	}

	function getAttributes(Edition memory edition) private pure returns (bytes memory) {
		return abi.encodePacked(
			'[',
				'{"trait_type":"Seed","value":"', edition.jsSeed.toString(), '"},',
				'{"trait_type":"Version","value":"', edition.version.toString(), '"},',
				'{"trait_type":"Layout","value":"', edition.layout == 0 ? 'Grid' : 'Rows', '"},',
				'{"trait_type":"Colors","value":"', edition.system, '"}',
			']'
		);
	}

	function getDataURI(string memory name, uint256 tokenId, Edition memory edition, string memory description, string memory image, string memory animationURL, bytes memory externalURLWithParams) private pure returns (bytes memory) {
		bytes memory attributes = getAttributes(edition);
		return abi.encodePacked(
			'{',
				'"name":"', name, ' ', tokenId.toString(), 'v', edition.version.toString(), '",',
				'"description":"', description, '",',
				'"image":"', image, '",',
				'"animation_url":"', animationURL, '",',
				'"external_url":"', externalURLWithParams, '",',
				'"attributes":', attributes,
			'}'
		);
	}

	function getTokenURI(string memory name, uint256 tokenId, Edition memory edition, string memory description, string memory image, string memory animationURL, bytes memory externalURLWithParams) public pure returns (string memory) {
		bytes memory dataURI = getDataURI(name, tokenId, edition, description, image, animationURL, externalURLWithParams);
		return string(
			abi.encodePacked(
				"data:application/json;base64,",
				Base64.encode(dataURI)
			)
		);
	}

	function getColorsJson(Color[3] memory colors) private pure returns (bytes memory) {
		bytes memory str = '[';
		for (uint256 i = 0; i < 3; i++) {
			str = abi.encodePacked(str, '{"hue":', colors[i].hue.toString(), ',"saturation":', colors[i].saturation.toString(), ',"lightness":', colors[i].lightness.toString(), '}');
			if (i < 2) {
				str = abi.encodePacked(str, ',');
			}
		}
		return abi.encodePacked(str, ']');
	}

	function getEdition(uint256 tokenId, Edition memory edition, address owner) public pure returns (string memory) {
		return string(
			abi.encodePacked(
				'{',
					'"tokenId":', tokenId.toString(), ',',
					'"version":', edition.version.toString(), ',',
					'"seed":', edition.jsSeed.toString(), ',',
					'"layout":', edition.layout.toString(), ',',
					'"system":"', edition.system, '",',
					'"colors":', getColorsJson(edition.colors), ',',
					'"owner":"', Strings.toHexString(uint256(uint160(owner)), 20), '"',
				'}'
			)
		);
	}
}