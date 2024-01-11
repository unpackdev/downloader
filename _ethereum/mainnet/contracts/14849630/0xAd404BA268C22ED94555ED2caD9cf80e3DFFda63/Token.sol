// SPDX-License-Identifier: none

pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./ProxyRegistry.sol";
import "./Operable.sol";

interface IToken {
	function mint(address to, uint256 tokenId) external;
}

contract BMTToken is ERC721Enumerable, Operable {
	using Strings for uint256;

	string public contractUri;
	string public baseURI;
	mapping(uint256 => string) private tokenURIs;

	mapping(address => bool) public minters;
	address[] public mintersList;

	IProxyRegistry public proxyRegistry;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _baseUri
	) ERC721(_name, _symbol) Operable(_msgSender()) {
		setBaseURI(_baseUri);
	}

	function contractData()
		public
		view
		returns (
			string memory _name,
			string memory _symbol,
			string memory _baseUri,
			string memory _contractUri,
			uint256 _totalSupply
		)
	{
		_name = name();
		_symbol = symbol();
		_contractUri = contractURI();
		_baseUri = baseURI;
		_totalSupply = totalSupply();
	}

	function accountData(address account) public view returns (uint256 _balanceOf, uint256[] memory _tokens) {
		_balanceOf = balanceOf(account);
		if (_balanceOf == 0) {
			_tokens = new uint256[](0);
		} else {
			_tokens = new uint256[](_balanceOf);
			for (uint256 index = 0; index < _balanceOf; index++) {
				_tokens[index] = tokenOfOwnerByIndex(account, index);
			}
		}
	}

	struct TokenData {
		uint256 id;
		string uri;
		bool permanentUri;
	}

	function tokensData(uint256[] memory tokens) public view returns (TokenData[] memory _data) {
		_data = new TokenData[](tokens.length);
		for (uint256 index = 0; index < tokens.length; index++) {
			uint256 tokenId = tokens[index];
			if (_exists(tokenId)) {
				_data[index] = TokenData(tokenId, tokenURI(tokenId), bytes(tokenURIs[tokenId]).length != 0);
			}
		}
	}

	function mint(address to, uint256 tokenId) public {
		require(minters[msg.sender], "Sender is not the minter");
		_mint(to, tokenId);
	}

	function setTokenURI(uint256 tokenId, string memory uri) public onlyOperator {
		require(_exists(tokenId), "Nonexistent token");
		tokenURIs[tokenId] = uri;
		emit PermanentURI(tokenURIs[tokenId], tokenId);
	}

	function setContractURI(string memory uri) public onlyOperator {
		contractUri = uri;
		emit SetContractURI(uri);
	}

	function contractURI() public view returns (string memory uri) {
		if (bytes(contractUri).length > 0) {
			uri = contractUri;
		}
		uri = baseURI;
	}

	function setBaseURI(string memory uri) public onlyOperator {
		baseURI = uri;
		emit SetBaseURI(uri);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		require(_exists(tokenId), "URI query for nonexistent token");

		string memory _tokenURI = tokenURIs[tokenId];

		if (bytes(_tokenURI).length != 0) {
			return _tokenURI;
		}

		if (bytes(baseURI).length != 0) {
			return string(abi.encodePacked(baseURI, tokenId.toString()));
		}
		return "";
	}

	function setMinter(address minter, bool state) public onlyOperator {
		require(minters[minter] != state, "Already set");
		minters[minter] = state;
		if (state) {
			mintersList.push(minter);
		}
		emit SetMinter(minter, state);
	}

	function mintersCount() public view returns (uint256) {
		return mintersList.length;
	}

	function setProxyRegistry(address _proxyRegistry) public onlyOperator {
		proxyRegistry = IProxyRegistry(_proxyRegistry);
		emit SetProxyRegistry(_proxyRegistry);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override(IERC721, ERC721) returns (bool) {
		// allow transfers for proxy contracts (marketplaces)
		if (address(proxyRegistry) != address(0) && proxyRegistry.proxies(owner) == operator) {
			return true;
		}
		return super.isApprovedForAll(owner, operator);
	}

	event SetContractURI(string uri);
	event SetBaseURI(string uri);
	event SetSigner(address minter, bool state);
	event SetMinter(address minter, bool state);
	event SetProxyRegistry(address proxyRegistry);
	event PermanentURI(string uri, uint256 indexed tokenId);
}
