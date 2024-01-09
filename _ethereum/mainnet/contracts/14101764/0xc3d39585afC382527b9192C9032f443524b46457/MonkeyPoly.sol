// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

//███    ███  ██████  ███    ██ ██   ██ ███████ ██    ██ ██████   ██████  ██      ██    ██
//████  ████ ██    ██ ████   ██ ██  ██  ██       ██  ██  ██   ██ ██    ██ ██       ██  ██
//██ ████ ██ ██    ██ ██ ██  ██ █████   █████     ████   ██████  ██    ██ ██        ████
//██  ██  ██ ██    ██ ██  ██ ██ ██  ██  ██         ██    ██      ██    ██ ██         ██
//██      ██  ██████  ██   ████ ██   ██ ███████    ██    ██       ██████  ███████    ██
contract MonkeyPoly is ERC721A, Ownable, Pausable {
	using Address for address;
	using Strings for uint256;
	using MerkleProof for bytes32[];

	address proxyRegistryAddress;

	//the merkle root
	bytes32 public root = 0x21a69ae93781ffea397668022e64c09ba2760422692a9d74a8fd2e87deb26f71;

	string public _contractBaseURI = "https://unreveal.monkeypoly.com/";
	string public _contractURI = "https://monkeypoly.com/contract_uri/contract_uri.json";

	uint256 public tokenPrice = 0.03 ether; //price per token

	mapping(address => uint256) public usedAddresses; //used addresses for whitelist

	bool public locked; //baseURI & contractURI lock
	uint256 public maxSupply = 9999; //tokenIDs start from 0

	uint256 public whitelistStartTime = block.timestamp - 1; //TODO: change to real;
	uint256 public publicSaleStartTime = block.timestamp - 1; //TODO: change to real;

	constructor() ERC721A("MonkeyPoly", "MonkeyPoly", 5) {
		_safeMint(msg.sender, 1); //mints 1 nft to the owner for configuring opensea
	}

	/**
	 * @dev whitelist buy
	 */
	function whitelistBuy(
		uint256 qty,
		uint256 tokenId,
		bytes32[] calldata proof
	) external payable whenNotPaused {
		require(qty <= 2, "max 2");
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(usedAddresses[msg.sender] + qty <= 2, "max per wallet reached");
		require(block.timestamp > whitelistStartTime, "not live");
		require(isTokenValid(msg.sender, tokenId, proof), "invalid merkle proof");

		usedAddresses[msg.sender] += qty;

		_safeMint(msg.sender, qty);
	}

	/**
	 * @dev everyone can mint freely
	 */
	function buy(uint256 qty) external payable whenNotPaused {
		require(tokenPrice * qty == msg.value, "exact amount needed");
		require(qty < 6, "max 5 at once");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		require(block.timestamp > publicSaleStartTime, "not live");

		_safeMint(msg.sender, qty);
	}

	/**
	 * @dev can airdrop tokens
	 */
	function adminMint(address to, uint256 qty) external onlyOwner {
		require(totalSupply() + qty <= maxSupply, "out of stock");
		_safeMint(to, qty);
	}

	/**
	 * @dev verification function for merkle root
	 */
	function isTokenValid(
		address _to,
		uint256 _tokenId,
		bytes32[] memory _proof
	) public view returns (bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));
		// verify the proof supplied, and return the verification result
		return _proof.verify(root, leaf);
	}

	function setMerkleRoot(bytes32 _root) external onlyOwner {
		root = _root;
	}

	//----------------------------------
	//----------- other code -----------
	//----------------------------------
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		require(!locked, "locked functions");
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newuri) external onlyOwner {
		require(!locked, "locked functions");
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function setWhitelistStartTime(uint256 newTime) external onlyOwner {
		whitelistStartTime = newTime;
	}

	function setPublicSaleStartTime(uint256 newTime) external onlyOwner {
		publicSaleStartTime = newTime;
	}

	//change the price per token
	function setCost(uint256 newPrice) external onlyOwner {
		tokenPrice = newPrice;
	}

	//change the max supply
	function setmaxMintAmount(uint256 newMaxSupply) public onlyOwner {
		maxSupply = newMaxSupply;
	}

	//blocks staking but doesn't block unstaking / claiming
	function setPaused(bool _setPaused) public onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	//sets the opensea proxy
	function setProxyRegistry(address _newRegistry) external onlyOwner {
		proxyRegistryAddress = _newRegistry;
	}

	// and for the eternity!
	function lockBaseURIandContractURI() external onlyOwner {
		locked = true;
	}

	// earnings withdrawal
	function withdraw() public payable onlyOwner {
		uint256 _total_owner = address(this).balance;

		(bool all1, ) = payable(0xed6f9E7d3A94141E28cA5D1905d2EA9F085D00FA).call{
			value: (_total_owner * 1) / 3
		}(""); //l
		require(all1);
		(bool all2, ) = payable(0x318cbB40Fdaf1A2Ab545B957518cb95D7c18ED32).call{
			value: (_total_owner * 1) / 3
		}(""); //sc
		require(all2);
		(bool all3, ) = payable(0x831C6bF9562791480802055Eb51311f6EedCA783).call{
			value: (_total_owner * 1) / 3
		}(""); //sp
		require(all3);
	}

	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
	 */
	function isApprovedForAll(address owner, address operator) public view override returns (bool) {
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}
		return super.isApprovedForAll(owner, operator);
	}
}

//opensea removal of approvals
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}
