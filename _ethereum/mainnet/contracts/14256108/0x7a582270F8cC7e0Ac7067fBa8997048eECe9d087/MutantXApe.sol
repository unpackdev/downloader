// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC721A.sol";

//            __,__
//   .--.  .-"     "-.  .--.
//  / .. \/  .-. .-.  \/ .. \
// | |  '|  /   Y   \  |'  | |
// | \   \  \ 0 | 0 /  /   / |
//  \ '- ,\.-"`` ``"-./, -' /
//   `'-' /_   ^ ^   _\ '-'`
//       |  \._   _./  |
//       \   \ `~` /   /
//        '._ '-=-' _.'
//           '~---~'
contract MutantXApe is ERC721A, Ownable {
	using Address for address;
	using Strings for uint256;

	string public _contractBaseURI = "ipfs://xxxx/zzzz/";
	string public _unrevealedURI = "ipfs/QmTVYQaAc6ECW5KC4X6QPkLqFMRfh8gfPUDHKZ9oJKvwEg";
	string public _contractURI = "ipfs://QmVpuN1iQpZy1N3QoSRj65cws9uFVjqXGquo9qqvaSLT6t";

	uint256 public maxSupply = 9999; //tokenID starts from 0
	uint256 public preSaleSupply = 6999;

	bool public isRevealed = false;

	uint256 public presalePrice = 0.25 ether;
	uint256 public publicPrice = 0.35 ether;

	uint256 public presaleStartTime = 1645701794; //TODO: update me

	address private devActionsWallet;

	address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

	uint256 private publicSaleKey;

	modifier onlyDev() {
		require(msg.sender == devActionsWallet, "only dev");
		_;
	}

	constructor() ERC721A("Mutant X Ape", "MXA") {
		devActionsWallet = msg.sender;
	}

	/**
	 * @dev need to be whitelisted
	 */
	function presaleBuy(uint256 qty) external payable {
		require(qty <= 2, "max 2 per wallet");
		require(presalePrice * qty == msg.value, "exact amount needed");
		require(totalSupply() + qty <= preSaleSupply, "out of stock");
		require(block.timestamp >= presaleStartTime, "not live");

		_safeMint(msg.sender, qty);
	}

	/**
	 * @dev everyone can buy
	 */
	function publicBuy(uint256 qty, uint256 key) external payable {
		require(publicPrice * qty == msg.value, "exact amount needed");
		require(qty <= 5, "max 5 at once");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		require(key == publicSaleKey && publicSaleKey != 0, "not live");

		_safeMint(msg.sender, qty);
	}

	function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) return new uint256[](0);

		uint256[] memory tokensId = new uint256[](tokenCount);
		for (uint256 i; i < tokenCount; i++) {
			tokensId[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokensId;
	}

	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		if (isRevealed) {
			return string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
		} else {
			return _unrevealedURI;
		}
	}

	function setBaseURI(string memory newBaseURI) external onlyDev {
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newuri) external onlyDev {
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	//recover lost erc20. the chance of getting them back is very low
	function reclaimERC20Token(address erc20Token) external onlyOwner {
		IERC20(erc20Token).transfer(msg.sender, IERC20(erc20Token).balanceOf(address(this)));
	}

	//recover lost nfts. the chance of getting them back is very low
	function reclaimERC721(address erc721Token, uint256 id) external onlyOwner {
		IERC721(erc721Token).safeTransferFrom(address(this), msg.sender, id);
	}

	//opensea proxy, don't touch
	function setProxyRegistry(address newRegistry) external onlyDev {
		proxyRegistryAddress = newRegistry;
	}

	//sets the public sale key
	function setPublicSaleKey(uint256 newKey) external onlyDev {
		publicSaleKey = newKey;
	}

	//change the presale start time
	function setPresaleStartTime(uint256 newStartTime) external onlyDev {
		presaleStartTime = newStartTime;
	}

	//owner reserves the right to change the price
	function changePricePerToken(uint256 newPresalePrice, uint256 newPublicPrice) external onlyOwner {
		presalePrice = newPresalePrice;
		publicPrice = newPublicPrice;
	}

	//only decrease it, no funky stuff
	function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply < maxSupply, "decrease only");
		maxSupply = newMaxSupply;
	}

	//call this to reveal the jpegs
	function reveal() external onlyDev {
		require(!isRevealed, "cannot un-reveal");
		isRevealed = true;
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

	//sends teh monies from the contract to the owner
	function withdrawETH() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}

//opensea removal of approvals
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}
