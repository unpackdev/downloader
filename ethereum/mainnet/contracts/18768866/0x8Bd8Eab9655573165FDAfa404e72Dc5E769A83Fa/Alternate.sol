// A L T E R N A T E
// Kim Asendorf, 2023
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";

import "./Generator.sol";

contract Alternate is ERC721A, ERC721ABurnable, Ownable {
	using Strings for uint256;

	uint256 public mintPrice;
	uint256 private modPrice;
	uint256 public supply;

	string private htmlPrefix;
	string private htmlSuffix;

	string private description;
	string private script;
	string private baseXML;
	string[2] private layoutXML;
	string private externalURL;

	mapping(uint256 => uint256) private versions;

	mapping(address => uint256) private allowlist;
	bool private isAllowlist = false;
	bool private isPublic = false;

	event Mint(address minter, uint256 tokenId);
	event Mod(address modder, uint256 tokenId, uint256 version);

	error InvalidAmount(uint256 required);
	error MaxVersionReached();
	error NotAllowed();
	error NotExists();
	error NotOwner();
	error NoSupply(uint256 total);

	constructor(string memory _name, string memory _symbol, uint256 _mintPrice, uint256 _modPrice, uint256 _supply) ERC721A(_name, _symbol) {
		mintPrice = _mintPrice;
		modPrice = _modPrice;
		supply = _supply;
	}

	function mint() external payable {
		if ((!isAllowlist || !(allowlist[msg.sender] > 0)) && !isPublic) {
			revert NotAllowed();
		}
		if (msg.value != mintPrice) {
			revert InvalidAmount({ required: mintPrice });
		}
		if (totalSupply() >= supply) {
			revert NoSupply({ total: supply });
		}
		uint256 tokenId = _nextTokenId();
		_mint(msg.sender, 1);
		versions[tokenId] = 1;
		if (!isPublic && isAllowlist) {
			allowlist[msg.sender]--;
		}
		emit Mint(msg.sender, tokenId);
	}

	function privateMint() external onlyOwner {
		if (totalSupply() >= supply) {
			revert NoSupply({ total: supply });
		}
		uint256 tokenId = _nextTokenId();
		_mint(msg.sender, 1);
		versions[tokenId] = 1;
		emit Mint(msg.sender, tokenId);
	}

	function modify(uint256 tokenId) external payable {
		if (!_exists(tokenId)) {
			revert NotExists();
		}
		if (msg.sender != ownerOf(tokenId)) {
			revert NotOwner();
		}
		uint256 version = versions[tokenId];
		if (version >= 4) {
			revert MaxVersionReached();
		}
		if (msg.value != modPrice * version && msg.sender != owner()) {
			revert InvalidAmount({ required: modPrice * version });
		}
		versions[tokenId] = ++version;
		emit Mod(msg.sender, tokenId, version);
	}

	function privateModify(uint256 tokenId) external onlyOwner {
		if (!_exists(tokenId)) {
			revert NotExists();
		}
		if (msg.sender != ownerOf(tokenId)) {
			revert NotOwner();
		}
		uint256 version = versions[tokenId];
		if (version >= 4) {
			revert MaxVersionReached();
		}
		versions[tokenId] = ++version;
		emit Mod(msg.sender, tokenId, version);
	}

	function setHTMLContainer(string calldata _htmlPrefix, string calldata _htmlSuffix) external onlyOwner {
		htmlPrefix = _htmlPrefix;
		htmlSuffix = _htmlSuffix;
	}

	function setDescription(string calldata _description) external onlyOwner {
		description = _description;
	}

	function setScript(string calldata _script) external onlyOwner {
		script = _script;
	}

	function setImageXML(string calldata _baseXML, string calldata _layout0XML, string calldata _layout1XML) external onlyOwner {
		baseXML = _baseXML;
		layoutXML[0] = _layout0XML;
		layoutXML[1] = _layout1XML;
	}

	function setExternalURL(string calldata _externalURL) external onlyOwner {
		externalURL = _externalURL;
	}

	function buildEdition(uint256 tokenId) private view returns (Generator.Edition memory) {
		Generator.Edition memory edition;

		edition.version = versions[tokenId];

		uint256 seed = tokenId + 1;
		for (uint256 i = 0; i < edition.version; i++) {
			seed = Generator.random(seed);
		}

		edition.jsSeed = seed;

		seed = Generator.random(seed);
		edition.layout = seed % 2;

		seed = Generator.random(seed);
		(Generator.Color[] memory colors, string memory system) = Generator.getPalette(seed);
		edition.colors[0] = colors[0];
		edition.colors[1] = colors[1];
		edition.colors[2] = colors[2];
		edition.system = system;

		return edition;
	}

	function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
		if (!_exists(tokenId)) {
			revert NotExists();
		}

		Generator.Edition memory edition = buildEdition(tokenId);

		string memory image = Generator.getImage(tokenId, edition, baseXML, layoutXML[edition.layout]);
		string memory animationURL = Generator.getAnimationURL(edition, htmlPrefix, htmlSuffix, script);
		bytes memory externalURLWithParams = Generator.getExternalURLWithParams(externalURL, tokenId, edition.version);

		return Generator.getTokenURI(name(), tokenId, edition, description, image, animationURL, externalURLWithParams);
	}

	function getModPrice(uint256 tokenId) external view returns (uint256) {
		uint256 version = versions[tokenId];
		if (version >= 4) {
			revert MaxVersionReached();
		}
		return version * modPrice;
	}

	function getEdition(uint256 tokenId) external view returns (string memory) {
		if (!_exists(tokenId)) {
			revert NotExists();
		}
		Generator.Edition memory edition = buildEdition(tokenId);
		return Generator.getEdition(tokenId, edition, ownerOf(tokenId));
	}

	function getVersion(uint256 tokenId) external view returns (uint256) {
		if (!_exists(tokenId)) {
			revert NotExists();
		}
		return versions[tokenId];
	}

	function getBalance() external view returns (uint256) {
		return address(this).balance;
	}

	function withdraw(address recipient, uint256 amount) external onlyOwner {
		Address.sendValue(payable(recipient), amount);
	}

	function getStatus() external view returns (string memory) {
		if (totalSupply() == supply) {
			return "Completed";
		} else if (isPublic) {
			return "Public";
		} else if (isAllowlist) {
			uint256 amount = allowlist[msg.sender];
			if (amount > 0) {
				return string(abi.encodePacked("Eligible: ", amount.toString()));
			} else {
				return "Allowlist";
			}
		} else {
			return "Closed";
		}
	}

	function addToAllowlist(address[] calldata addresses, uint256[] calldata amount) external onlyOwner {
		for (uint256 i = 0; i < addresses.length; i++) {
			allowlist[addresses[i]] = amount[i];
		}
	}

	function removeFromAllowlist(address[] calldata addresses) external onlyOwner {
		for (uint256 i = 0; i < addresses.length; i++) {
			delete allowlist[addresses[i]];
		}
	}

	function setIsAllowlist(bool _isAllowlist) external onlyOwner {
		isAllowlist = _isAllowlist;
	}

	function setIsPublic(bool _isPublic) external onlyOwner {
		isPublic = _isPublic;
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}