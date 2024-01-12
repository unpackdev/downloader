// SPDX-License-Identifier: SPDX-License
/// @author aboltc
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./ReentrancyGuard.sol";

/*
@FacePressNFT
facepressnft.io

FacePress is a project for the misfits, oddballs, and weirdos. It’s a project
where every image has personality and imperfections are celebrated.
‍
Inspired by the letterpress style and history, FacePress is an introduction to
the mind of artist Danny Schlitz. Many of the designs were brought to life by his
very own childhood memories, pulling inspiration from the 80s and 90s sci-fi and
pop culture. There is truly a face for everyone. 

FacePress will consist of 1000 hand-drawn digital illustrations; every face
being unique, just like you. At FacePress we encourage people to do 2 things:
Live your life and love your face.

a⚡️c
@aboltc_
*/

contract OwnableDelegateProxy {

}

contract OpenseaProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

contract FacePress is
	ERC721ABurnable,
	ERC721AQueryable,
	Ownable,
	ReentrancyGuard
{
	uint256 public cost = 0.05 ether;
	uint256 public maxSupply = 1021;
	bool public isPublicSaleOpen = false;
	bool public isWhitelistSaleOpen = false;
	string public baseURI;
	mapping(address => bool) public whiteList;

	/**
	 * @param __baseURI base uri
	 */
	constructor(string memory __baseURI, address[] memory whiteListAddresses)
		ERC721A("FacePress", "FACEPRESS")
	{
		baseURI = __baseURI;

		for (uint128 i = 0; i < whiteListAddresses.length; i++) {
			whiteList[whiteListAddresses[i]] = true;
		}
	}

	/**--------------------------
	 * Setters
	 */
	function setCost(uint256 _cost) public onlyOwner {
		cost = _cost;
	}

	function setMaxSupply(uint256 _maxSupply) public onlyOwner {
		maxSupply = _maxSupply;
	}

	function setBaseURI(string memory __baseURI) public onlyOwner {
		baseURI = __baseURI;
	}

	function setIsPublicSaleOpen(bool _isPublicSaleOpen) public onlyOwner {
		isPublicSaleOpen = _isPublicSaleOpen;
	}

	function addWhitelistAddresses(address[] memory whiteListAddresses)
		public
		onlyOwner
	{
		for (uint128 i = 0; i < whiteListAddresses.length; i++) {
			whiteList[whiteListAddresses[i]] = true;
		}
	}

	function setIsWhitelistSaleOpen(bool _isWhitelistSaleOpen)
		public
		onlyOwner
	{
		isWhitelistSaleOpen = _isWhitelistSaleOpen;
	}

	/**
	 * @return baseURI base uri
	 */
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	/**--------------------------
	 * Minting
	 */

	/**
	 * @notice Check if mint amount is greater than 1, is within supply, and is paid for.
	 * @param _mintAmount amount to mint
	 */
	modifier mintCompliance(uint256 _mintAmount) {
		require(_mintAmount > 0, "MINT_LESS_THAN_1");
		require(_totalMinted() + _mintAmount < maxSupply, "MAX_SUPPLY_OBO");
		require(msg.value >= cost * _mintAmount, "INSUFFICIENT_FUNDS");
		_;
	}

	/**
	 * @notice general mint
	 * @param _mintAmount amount to mint
	 */
	function mint(uint256 _mintAmount)
		public
		payable
		mintCompliance(_mintAmount)
	{
		require(
			(isWhitelistSaleOpen && whiteList[_msgSender()]) ||
				isPublicSaleOpen,
			"SALE_CLOSED"
		);
		_safeMint(_msgSender(), _mintAmount);
	}

	/**
	 * @notice admin mint
	 * @param _mintAmount amount to mint
	 * @param _receiver recipient of mint
	 */
	function mintForAddress(uint256 _mintAmount, address _receiver)
		public
		onlyOwner
	{
		require(_totalMinted() + _mintAmount < maxSupply, "MAX_SUPPLY_OBO");
		_safeMint(_receiver, _mintAmount);
	}

	/**--------------------------
	 * Withdraw functionality
	 */

	/**
	 * @notice withdraw to owner
	 */
	function withdraw() public onlyOwner nonReentrant {
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
