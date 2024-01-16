// SPDX-License-Identifier: SPDX-License
/// @author aboltc
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

/*
@Hythacg
highrises.hythacg.com

Highrises are the iconic elements of American cities.
Reaching radical new heights in technological advancement,
skyscrapers fused Classical, Renaissance, and Gothic motifs
onto steel and defined a new architectural language with
Art Deco and International.

The Highrises project reveals hidden details of remarkable buildings,
including many that are underappreciated. The images showcase structures
that reflect the values and ideals animating the early 20th century.
The stories provide historical context and deepen our understanding
of their importance and value.

a⚡️c
@aboltc_
*/

contract OwnableDelegateProxy {

}

contract OpenseaProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

contract HighriseCollage is ERC721A, Ownable {
	/**
	 * @param __baseURI base uri
	 */
	constructor(string memory __baseURI)
		ERC721A("HighrisesCollage", "HIGHRISE_COLLAGE")
	{
		baseURI = __baseURI;
	}

	/**--------------------------
	 * ERC721A implementation
	 */
	uint128 price = 0.08 ether;
	uint128 TOTAL_SUPPLY = 101;
	/// @dev rinkeby: 0xA9F77C5ddd3264Ac47662bb7907B7087A840Dadb
	address public HIGHRISES_ADDRESS =
		0x516D85f0c80D2C4809736AcA3f3F95cE8545b5d2;
	mapping(address => bool) public claimedAddresses;
	string public baseURI;

	/**
	 * @notice update URI.
	 * @param __baseURI base uri
	 */
	function setTokenURI(string memory __baseURI) public onlyOwner {
		baseURI = __baseURI;
	}

	/**
	 * @notice update price.
	 * @param _price price to update
	 */
	function setPrice(uint128 _price) public onlyOwner {
		price = _price;
	}

	/**
	 * @notice check if address owns highrise token
	 */
	function getIsOwnerOfHighrise(address senderAddress)
		public
		view
		returns (bool)
	{
		return
			!claimedAddresses[msg.sender] &&
			ERC721AQueryable(HIGHRISES_ADDRESS).balanceOf(senderAddress) > 0;
	}

	/**
	 * @notice public mint functionality
	 */
	function mint() public payable {
		require(_totalMinted() + 1 < TOTAL_SUPPLY, "MAX_SUPPLY_OBO");

		bool isOwnerOfHighrise = getIsOwnerOfHighrise(msg.sender);
		uint256 allowListPrice = isOwnerOfHighrise ? 0 : price;

		require(msg.value >= allowListPrice, "INSUFFICIENT_FUNDS");

		if (isOwnerOfHighrise) {
			claimedAddresses[msg.sender] = true;
		}

		_safeMint(msg.sender, 1);
	}

	/**
	 * @notice mint functionality limited to owner
	 */
	function ownerMint(uint256 _mintAmount) public payable onlyOwner {
		require(_totalMinted() + _mintAmount < TOTAL_SUPPLY, "MAX_SUPPLY_OBO");
		_safeMint(msg.sender, _mintAmount);
	}

	/**
	 * @notice overide token
     
      URI to version without tokenId
	 */
	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		return baseURI;
	}

	/**--------------------------
	 * Withdraw functionality
	 */

	/**
	 * @notice withdraw to owner
	 */
	function withdraw() public onlyOwner {
		(bool os, ) = payable(owner()).call{ value: address(this).balance }("");
		require(os);
	}

	/**--------------------------
	 * Marketplace functionality
	 */

	/// @dev rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
	address public proxyRegistryAddress =
		0xa5409ec958C83C3f309868babACA7c86DCB077c1;
	mapping(address => bool) projectProxy;

	function flipProxyState(address proxyAddress) external onlyOwner {
		projectProxy[proxyAddress] = !projectProxy[proxyAddress];
	}

	/**
	 * @notice opensea setter
	 */
	function setProxyRegistryAddress(address _proxyRegistryAddress)
		external
		onlyOwner
	{
		proxyRegistryAddress = _proxyRegistryAddress;
	}

	/**
	 * @dev preapprove for opensea
	 */
	function isApprovedForAll(address _owner, address operator)
		public
		view
		override
		returns (bool)
	{
		OpenseaProxyRegistry proxyRegistry = OpenseaProxyRegistry(
			proxyRegistryAddress
		);
		if (address(proxyRegistry.proxies(_owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(_owner, operator);
	}
}
