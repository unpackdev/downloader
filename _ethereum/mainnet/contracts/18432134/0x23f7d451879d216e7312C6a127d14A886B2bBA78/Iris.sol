// SPDX-License-Identifier: MIT
/*
 * Iris.sol
 *
 * Created: October 24, 2023
 */

pragma solidity ^0.8.4;

import "./Satoshigoat.sol";
import "./DateTime.sol";

/*
	NOTES:
		- 6 total states: first day of year, Q1, Q2, Q3, Q4, last day of year
		- 6 total tokens
*/

//@title Iris
//@author Jack Kasbeer (satoshigoat) (gh:@jcksber)
contract Iris is Satoshigoat {

	//0: first day of year
	//1: season 1
	//2: season 2
	//3: season 3
    //4: season 4
    //5: last day of year
	string [6] private _hashes = ["QmdUDaffL7z9rVh7K1HSASKpiLDWRPFNFcSydJv7Zs1Ep8",
								  "QmejBL5Qe9JSdG2QkJgM5jpsuSRMwVN3YxkULCiwgNuAcM",
								  "Qmd6CmXZKjBV8mjB78QrrUJeaqLuYk53dWYtVgvrUJeP9Z",
								  "QmZNNvCwG8JAdzDLVjxoxzoxsAYhuEgikuaEX4qe6XThYV",
                                  "QmcuCKpwN9sgPpK9UzRTjZCYuYR4i3qwzaJBTau8Vhi3NG",
                                  "QmQzT8J4gPErnX6KWe4HwHJfX9bbBdK2NCy2zuMPVhg3EA"];

	// ------------------------------
	// CORE FUNCTIONALITY FOR ERC-721
	// ------------------------------

	constructor() Satoshigoat("Iris", "", "ipfs://") 
	{
		_contractURI = "ipfs://QmNPBQWsPxv81vMuVz8nkq82m2C1NRcsheVTcVkZ74hgjA";
		_owner = address(0xF1c2eC71b6547d0b30D23f29B9a0e8f76C7Af743);
		payoutAddress = address(0xF1c2eC71b6547d0b30D23f29B9a0e8f76C7Af743);
    	purchasePrice = 1 ether;//~$1700k @ launch
        maxNumTokens = 6;
	}
	
	//@dev See {ERC721A-tokenURI}
	function tokenURI(uint256 tid) public view virtual override 
		returns (string memory) 
	{	
		if (!_exists(tid))
			revert URIQueryForNonexistentToken();
		return string(abi.encodePacked(_baseURI(), _getIPFSHash()));
	}

	//@dev Get the appropriate IPFS hash based on the day
	function _getIPFSHash() private view returns (string memory)
	{	
        uint256 month = DateTime.getMonth(block.timestamp);
        uint256 day = DateTime.getDay(block.timestamp);

        // Determine the correct hash to use based on the day and month
        if (month == 1 && day == 1)
            return _hashes[0];//first day of year
        else if (month == 12 && day == 31)
            return _hashes[5];//last day of year
        else if (1 <= month && month <= 3)
            return _hashes[1];//Q1
        else if (4 <= month && month <= 6)
            return _hashes[2];//Q2
        else if (7 <= month && month <= 9)
            return _hashes[3];//Q3
        else
            return _hashes[4];//Q4 (months 10-12)
	}

	//@dev Mint a token (owners only)
	function mint(address to) 
		external
		isSquad
		nonReentrant
		enoughSupply(1)
		notContract(to)
	{
		_safeMint(to, 1);
	}

	//@dev Purchase a token
	function purchase()
		external
		payable
        isPublic
		nonReentrant
		enoughSupply(1)
		enoughEther(msg.value)
	{
		_safeMint(_msgSender(), 1);
	}

	// ----------------
	// BACKUP FUNCTIONS
	// ----------------

	//@dev [BACKUP METHOD] Change one of the ipfs hashes for the project
	function setIPFSHash(uint8 idx, string memory newHash) external isSquad
	{
		if (idx < 0 || idx > 5) 
			revert DataError("index out of bounds");
		if (_stringsEqual(_hashes[idx], newHash)) 
			revert DataError("hash is the same");
		_hashes[idx] = newHash;
	}

	//@dev [BACKUP METHOD] Allow squad to burn any token
	function burn(uint256 tid) external isSquad
	{
		_burn(tid);
	}

	//@dev [BACKUP METHOD] Destroy contract and reclaim leftover funds
	function kill() external onlyOwner
	{
		selfdestruct(payable(_msgSender()));
	}

	//@dev [BACKUP METHOD] See `kill`; protects against being unable to delete a collection on OpenSea
	function safe_kill() external onlyOwner
	{
		if (balanceOf(_msgSender()) != totalSupply())
			revert DataError("potential error - not all tokens owned");
		selfdestruct(payable(_msgSender()));
	}


    // TESTING...

    function printDate() external view returns (uint256 month, uint256 day, uint256 year) {
        day = DateTime.getDay(block.timestamp);
        month = DateTime.getMonth(block.timestamp);
        year = DateTime.getYear(block.timestamp);
    }
}
