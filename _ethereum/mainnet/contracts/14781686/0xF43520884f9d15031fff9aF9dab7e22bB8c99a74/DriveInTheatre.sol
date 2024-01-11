// SPDX-License-Identifier: MIT
/*
 * DriveInTheatre.sol
 *
 * Created: May 14, 2022
 */

pragma solidity ^0.8.4;

import "./Satoshigoat.sol";

//@title Eddie's Drive-In Theatre by LOGIK
//@author Jack Kasbeer (gh:@jcksber, tw:@satoshigoat, ig:@overprivilegd)
contract DriveInTheatre is Satoshigoat {

	string [MAX_NUM_TOKENS] _hashes = ["QmQX9bEitWHCfoG9Mmh9byUPBLaDDtXgfrTrnFBfthASpJ",
									   "QmVLnYUwiQYJTJrZwPQbWkQF5vuggcSPKEvm4vKKSFdzRB",
									   "QmS3nfUUq6uKqJUAcghfxfQzrR4bU8RL5nvDDm9SKcRBZN",
									   "QmTQyroWQHEujbrsv8S2pSmkhuRPDfrQE3bdHCvc2H3dwU"];

	// -----------
	// RESTRICTORS
	// -----------

	modifier purchaseArgsOK(address to, uint256 qty, uint256 amount) {
		if (_isContract(to))
			revert DataError("silly rabbit :P");
		_;
	}

	// ---------------
	// DriveInGif Core
	// ---------------

	constructor() Satoshigoat("Eddies Drive-In Theatre by LOGIK", "", "ipfs://") 
	{
		payoutAddress = address(0x6b8C6E15818C74895c31A1C91390b3d42B336799);
	}
	
	//@dev See {ERC721A-tokenURI}
	function tokenURI(uint256 tid) public view virtual override 
		returns (string memory) 
	{	
		if (!_exists(tid))
			revert URIQueryForNonexistentToken();
		return string(abi.encodePacked(_baseURI(), _hashes[tid]));
	}

	//@dev Allows owners to mint for free
	function mint(address to, uint256 qty)
		external isSquad enoughSupply(qty)
	{
		_safeMint(to, qty);
	}
	
	//@dev Allow owners to burn - completely a backup function
	function burn(uint256 tid) external isSquad
	{
		_burn(tid);
	}

	//@dev Destroy contract and reclaim leftover funds
	function kill() external onlyOwner 
	{
		selfdestruct(payable(_msgSender()));
	}

	//@dev See `kill`; protects against being unable to delete a collection on OpenSea
	function safe_kill() external onlyOwner
	{
		if (balanceOf(_msgSender()) != totalSupply())
			revert DataError("potential error - not all tokens owned");
		selfdestruct(payable(_msgSender()));
	}

	//@dev Ability to change the ipfs hashes
	function setHash(uint8 idx, string calldata newHash) 
		external isSquad notEqual(_hashes[idx], newHash) { _hashes[idx] = newHash; }
}
