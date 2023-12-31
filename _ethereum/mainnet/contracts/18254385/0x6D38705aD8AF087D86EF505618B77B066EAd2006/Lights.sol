// Light, Kim Asendorf, 2023
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./Strings.sol";

contract Lights is ERC721, ERC721Burnable, Pausable, Ownable {
	using Strings for uint256;

	struct Light {
		string title;
		string description;
		string script;
		string svg;
		string externalURL;
		uint256 price;
		uint256 size;
		bool available;
		address allowed;
	}

	mapping(uint256 => Light) public lights;
	string public htmlPrefix;
	string public htmlSuffix;

	constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) { }

	function setHTMLContainer(string memory _htmlPrefix, string memory _htmlSuffix) public onlyOwner {
		htmlPrefix = _htmlPrefix;
		htmlSuffix = _htmlSuffix;
	}

	function setTitle(uint256 tokenId, string memory _title) public onlyOwner {
		lights[tokenId].title = _title;
	}

	function setDescription(uint256 tokenId, string memory _description) public onlyOwner {
		lights[tokenId].description = _description;
	}

	function setScript(uint256 tokenId, string memory _script) public onlyOwner {
		lights[tokenId].script = _script;
	}

	function setSVG(uint256 tokenId, string memory _svg) public onlyOwner {
		lights[tokenId].svg = _svg;
	}

	function setExternalURL(uint256 tokenId, string memory _externalURL) public onlyOwner {
		lights[tokenId].externalURL = _externalURL;
	}

	function setPrice(uint256 tokenId, uint256 _price) public onlyOwner {
		lights[tokenId].price = _price;
	}

	function setSize(uint256 tokenId, uint256 _size) public onlyOwner {
		lights[tokenId].size = _size;
	}

	function setAvailable(uint256 tokenId, bool _available) public onlyOwner {
		lights[tokenId].available = _available;
	}

	function setAllowed(uint256 tokenId, address _allowed) public onlyOwner {
		lights[tokenId].allowed = _allowed;
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function mint(uint256 tokenId) public payable whenNotPaused {
		require(lights[tokenId].available, "NOT_AVAILABLE");
		require(lights[tokenId].allowed == address(0x0) || lights[tokenId].allowed == msg.sender, "NOT_ALLOWED");
		require(lights[tokenId].price == msg.value, "WRONG_AMOUNT");
		safeMint(tokenId);
	}

	function ownerMint(uint256 tokenId) public onlyOwner {
		safeMint(tokenId);
	}

	function safeMint(uint256 tokenId) private {
		_safeMint(msg.sender, tokenId);
		lights[tokenId].available = false;
	}

	function withdraw(address recipient) public payable onlyOwner {
		Address.sendValue(payable(recipient), address(this).balance);
	}

	function _burn(uint256 tokenId) internal override(ERC721) {
		super._burn(tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal whenNotPaused override(ERC721/*, ERC721Enumerable*/) {
		super._beforeTokenTransfer(from, to, tokenId, batchSize);
	}

	function buildHTML(uint256 tokenId) internal view returns (bytes memory) {
		return abi.encodePacked(
			htmlPrefix,
			lights[tokenId].script,
			htmlSuffix
		);
	}

	function getHTML(uint256 tokenId) public view returns (string memory) {
		require(_exists(tokenId), "NOT_EXISTS");
		bytes memory html = buildHTML(tokenId);
		return string(html);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		require(_exists(tokenId), "NOT_EXISTS");

		bytes memory html = buildHTML(tokenId);

		bytes memory attributes = abi.encodePacked(
			'[',
				'{"trait_type":"Code Size (KB)","value":"', lights[tokenId].size.toString(), '"}',
			']'
		);

		bytes memory dataURI = abi.encodePacked(
			'{',
				'"name":"', lights[tokenId].title, '",',
				'"description":"', lights[tokenId].description, '",',
				'"image":"data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(lights[tokenId].svg)), '",',
				'"external_url":"', lights[tokenId].externalURL, '",',
				'"animation_url":"data:text/html;base64,', Base64.encode(html), '",'
				'"attributes":', attributes,
			'}'
		);

		return string(
			abi.encodePacked(
				"data:application/json;base64,",
				Base64.encode(dataURI)
			)
		);
	}
}