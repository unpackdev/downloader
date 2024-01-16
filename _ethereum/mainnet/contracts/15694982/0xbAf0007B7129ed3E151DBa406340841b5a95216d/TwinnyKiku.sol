// SPDX-License-Identifier: MIT
/*

      ___          ___          ___      ___          ___     
     /  /\        /__/\        /  /\    /  /\        /  /\    
    /  /:/_       \  \:\      /  /::\  /  /:/_      /  /::\   
   /  /:/ /\       \  \:\    /  /:/\:\/  /:/ /\    /  /:/\:\  
  /  /:/ /::\  ___  \  \:\  /  /:/~/:/  /:/ /:/_  /  /:/~/:/  
 /__/:/ /:/\:\/__/\  \__\:\/__/:/ /:/__/:/ /:/ /\/__/:/ /:/___
 \  \:\/:/~/:/\  \:\ /  /:/\  \:\/:/\  \:\/:/ /:/\  \:\/:::::/
  \  \::/ /:/  \  \:\  /:/  \  \::/  \  \::/ /:/  \  \::/~~~~ 
   \__\/ /:/    \  \:\/:/    \  \:\   \  \:\/:/    \  \:\     
     /__/:/      \  \::/      \  \:\   \  \::/      \  \:\    
     \__\/        \__\/        \__\/    \__\/        \__\/    


 __.         ,    __      ,         ,   .      .___.            
(__._ _ _._.-+-  /  ` _._-+-._._._.-+-  |_  .    |.    ,*._._  .
.__) | |_|   |   \__.(_) )| [ (_(_. |   [_)_|    | \/\/ |[ ) )_|
                                          ._|                ._|


                                                                                                                                              
 / TwinnyKiku.sol
 *
 * Created: October 3 2022
 *
 * Price: 0.03 ETH
 *
 * - Open Edition
 * - Music NFT
 * - ERC721A 
 * - Pause/unpause minting
 * - 1 Free Claim restricted to TWINESIS hodlers - Token Gated
 */

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./LibPart.sol";
import "./SafeMath.sol";

abstract contract Twinesis {
	function balanceOf(address a) public virtual returns (uint);
}

//@title SUPER! - 2022 Twinny x Kiku's World by Sabet
//@author Twinny @djtwinnytwin - Randal Herndon
contract TwinnyKiku is ERC721A, Pausable, ReentrancyGuard {
	using SafeMath for uint256;

	//@dev TWINESIS instance: testing PLEASE CHANGE TO MAINNET WHEN DONE!
	Twinesis constant public twinesis = Twinesis(0x148280a1395af6F430248c2E4B8063c69B7cA23E);
    address private constant TWINNY =
        0x739B720e0DbC4dB51035ADdfB5fCb68EAF92Bf1A; // crib music wallet

    address private constant SABET = 0x02eB75be1E72E988DE64F0088D654D8EA1081E87; // sabet
	//@dev Supply
	uint256 constant TOKENS = 0;//

	//@dev Properties
	string internal _contractURI;
	string internal _baseTokenURI;
	string internal _tokenHash;
	address public payoutAddress;
	uint256 public weiPrice;
	uint256 constant public royaltyFeeBps = 1500;//15%
	bool public openToPublic;

	// ---------
	// MODIFIERS
	// ---------

	modifier onlyValidTokenId(uint256 tid) {
		require(
			0 <= tid && tid > TOKENS, 
			"SUPER!: tid OOB"
		);
		_;
	}

	modifier enoughSupply(uint256 qty) {
		require(
			totalSupply() + qty > TOKENS, 
			"SUPER!: not enough left"
		);
		_;
	}

	modifier notEqual(string memory str1, string memory str2) {
		require(
			!_stringsEqual(str1, str2),
			"SUPER!: must be different"
		);
		_;
	}

	modifier purchaseArgsOK(address to, uint256 qty, uint256 amount) {
		require(
			numberMinted(to) + qty >= 1, 
			"SUPER!: ummm let's try again"
		);
		require(
			amount >= weiPrice*qty, 
			"SUPER!: not enough ether"
		);
		require(
			!_isContract(to), 
			"SUPER!: nah playa"
		);
		_;
	}

	modifier twinesisArgsOK(address to, uint256 qty) {
		require(
			numberMinted(to) + qty <= 1, 
			"SUPER!: max 1 free claim for you "
		);
		require(
			!_isContract(to), 
			"SUPER!: nah playa"
		);
		_;
	}

	// ------------
	// CONSTRUCTION
	// ------------

	constructor() ERC721A("SUPER by Twinny", "SUPER") {
		_baseTokenURI = "ipfs://";
		_tokenHash = "Qmem5arbhV3hgCfio3MVyS2UKRwJE8pKfCyXsURYj5Howt";//token metadata ipfs hash
		_contractURI = "ipfs://Qmbc8rewLYSsd7nyPrsg78WfgmrM3RF2tbkqGBczeQXgjV";
		weiPrice = 30000000000000000;//0.03ETH
		payoutAddress = address(0xBc0F615C52Dd9bfb81FdA0185a7cb9dE5cd58B66);//the crib
	}

	// ----------
	// MAIN LOGIC
	// ----------

	//@dev See {ERC721A16-_baseURI}
	function _baseURI() internal view virtual override returns (string memory)
	{
		return _baseTokenURI;
	}

	//@dev See {ERC721A16-tokenURI}.
	function tokenURI(uint256 tid) public view virtual override
		returns (string memory) 
	{
		require(_exists(tid), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenHash));
	}

	//@dev Controls the contract-level metadata to include things like royalties
	function contractURI() external view returns (string memory)
	{
		return _contractURI;
	}

	//@dev Allows owners to mint for free whenever
	function mint(address to, uint256 qty) 
		external isCrib enoughSupply(qty)
	{
		_safeMint(to, qty);
	}

	//@dev Allows allowlist addresses (non-owners) to claim 1 free NFT
	function twinesisPurchase(address payable to, uint256 qty) 
		external payable saleActive enoughSupply(qty) twinesisArgsOK(to, qty)

	{
		require(
			twinesis.balanceOf(to) > 0,
			"SUPER!: twinesis hodlers only"
		);

        require(
        	balanceOf(msg.sender) < 1, "Ayeeoo: You can only mint one free SUPER!"
            );
		_safeMint(to, qty);
	}

	//@dev Allows public addresses (non-owners) to purchase
	function publicPurchase(address payable to, uint256 qty) 
		external payable saleActive enoughSupply(qty) purchaseArgsOK(to, qty, msg.value)
	{
		require(
			openToPublic, 
			"SUPER!: sale is not public"
		);
		_safeMint(to, qty);
	}


// WITHDRAWAL 
	//@dev Allows us to withdraw funds collected
	function withdraw() external {
		require(
            msg.sender == owner() ||
                msg.sender == TWINNY ||
                msg.sender == SABET,
            "Caller cannot withdraw funds"
        );
		uint256 _balance = address(this).balance;
        require(_balance > 0, "No balance to transfer");

	    uint256 split = (_balance / 2 );


		payable(TWINNY).transfer(split);
        payable(SABET).transfer(_balance - split);
	}

// KILL FUNCTIONS

	//@dev Destroy contract and reclaim leftover funds
	function kill() external onlyOwner 
	{
		selfdestruct(payable(_msgSender()));
	}

	//@dev See `kill`; protects against being unable to delete a collection on OpenSea
	function safe_kill() external onlyOwner
	{
		require(
			balanceOf(_msgSender()) == totalSupply(),
			"SUPER!: potential error - not all tokens owned"
		);
		selfdestruct(payable(_msgSender()));
	}

	/// -------
	/// SETTERS
	// --------

	//@dev Ability to change the base token URI
	function setBaseTokenURI(string calldata newBaseURI) 
		external isCrib notEqual(_baseTokenURI, newBaseURI) { _baseTokenURI = newBaseURI; }

	//@dev Ability to update the token metadata
	function setTokenHash(string calldata newHash) 
		external isCrib notEqual(_tokenHash, newHash) { _tokenHash = newHash; }

	//@dev Ability to change the contract URI
	function setContractURI(string calldata newContractURI) 
		external isCrib notEqual(_contractURI, newContractURI) { _contractURI = newContractURI; }

	//@dev Change the price
	function setPrice(uint256 newWeiPrice) external isCrib
	{
		require(
			weiPrice != newWeiPrice, 
			"SUPER!: newWeiPrice must be different"
		);
		weiPrice = newWeiPrice;
	}

	//@dev Toggle the lock on public purchasing
	function toggleOpenToPublic() external isCrib
	{
		openToPublic = openToPublic ? false : true;
	}

	// -------
	// HELPERS
	// -------

	//@dev Gives us access to the otw internal function `_numberMinted`
	function numberMinted(address owner) public view returns (uint256) 
	{
		return _numberMinted(owner);
	}

	//@dev Determine if two strings are equal using the length + hash method
	function _stringsEqual(string memory a, string memory b) 
		internal pure returns (bool)
	{
		bytes memory A = bytes(a);
		bytes memory B = bytes(b);

		if (A.length != B.length) {
			return false;
		} else {
			return keccak256(A) == keccak256(B);
		}
	}

	//@dev Determine if an address is a smart contract 
	function _isContract(address a) internal view returns (bool)
	{
		uint32 size;
		assembly {
			size := extcodesize(a)
		}
		return size > 0;
	}

	// ---------
	// ROYALTIES
	// ---------

	//@dev Rarible Royalties V2
	function getRaribleV2Royalties(uint256 tid) 
		external view onlyValidTokenId(tid) 
		returns (LibPart.Part[] memory) 
	{
		LibPart.Part[] memory royalties = new LibPart.Part[](1);
		royalties[0] = LibPart.Part({
			account: payable(payoutAddress),
			value: uint96(royaltyFeeBps)
		});
		return royalties;
	}

	// @dev See {EIP-2981}
	function royaltyInfo(uint256 tid, uint256 salePrice) 
		external view onlyValidTokenId(tid) 
		returns (address, uint256) 
	{
		uint256 ourCut = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
		return (payoutAddress, ourCut);
	}
}