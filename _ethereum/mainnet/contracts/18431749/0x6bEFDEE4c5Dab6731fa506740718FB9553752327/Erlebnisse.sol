// SPDX-License-Identifier: MIT
/*
 * Erlebnisse.sol
 *
 * Created: October 24, 2023
 */

pragma solidity ^0.8.4;

import "./Satoshigoat.sol";
import "./DateTime.sol";

/*
	NOTES:
		- 3 total states: last day of the century, first 9 months of new century, other
		- 1/1 NFT collection (3 versions exist)
		- Centuries rollover on October 25
*/

//@title Century - Erlebnisse
//@author Jack Kasbeer (satoshigoat) (gh:@jcksber)
contract Erlebnisse is Satoshigoat {

	uint256 public cycleStartTime = 1698192000;//October 25, 2023 (midnight)

	//red: [0,9], black: [10], gold: [11]
	string [12] private _hashes = ["QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-1.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-2.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-3.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-4.json",
                                   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-5.json",
                                   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-6.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-7.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-8.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-9.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/red1-10.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/black1.json",
								   "QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/gold1.json"];

	// ------------------------------
	// CORE FUNCTIONALITY FOR ERC-721
	// ------------------------------

	constructor() Satoshigoat("Erlebnisse", "", "ipfs://") 
	{
		_contractURI = "ipfs://QmRDfRJzg4VXjSJj837Xx7iK2fwTv7Fn82f9dy1j6qwZgK/century1-contract.json";
		_owner = address(0xF1c2eC71b6547d0b30D23f29B9a0e8f76C7Af743);
		payoutAddress = address(0xF1c2eC71b6547d0b30D23f29B9a0e8f76C7Af743);
		cycleStartTime = block.timestamp;
    	purchasePrice = 3.1 ether;//~$6k @ launch
        maxNumTokens = 1;
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
		// SETUP VARIABLES FOR TIME MANIPULATION

		uint newCycleStartTime = cycleStartTime;//will only change if a century or more has passed

		uint256 today = block.timestamp;
		uint256 thisYear = DateTime.getYear(today);
		uint256 startYear = DateTime.getYear(cycleStartTime);//og start date

		uint trueDeltaYears = thisYear - startYear;

		// The modified delta years are to ensure we use [0,100] when doing time math
		uint modDeltaYears = isHundredMultiple(trueDeltaYears) ? uint(100) : (trueDeltaYears % 100);

		// If it has been more than a century we need to add hundred(s) of years to our original cycle start:
		// SIMULATE updating the global variable `cycleStartTime` (which is not possible in this function);
		// this simulated variable is `newCycleStartTime`
		if (trueDeltaYears >= 100) {
			uint numHundreds = trueDeltaYears / uint(100);
			if (isHundredMultiple(trueDeltaYears) && isBeforeCenturyTurn(today))
				newCycleStartTime = DateTime.addYears(cycleStartTime, (numHundreds-1)*100);
			else
				newCycleStartTime = DateTime.addYears(cycleStartTime, numHundreds*100);
		}

		// DETERMINE WHICH STATE THE ART IS IN AND RETURN THE CORRESPONDING HASH

		// FIRST 99 YEARS OF THE CENTURY:
		// Red zone hashes & gold hash: if we are still in the first cycle the gold 
		// state is ignored and only red hashes are used; otw, the first 9 months of
		// a new cycle will be in a gold state
		uint i;
		for (i = 1; i <= 9; i++) {
			if (i == 1) {
                // Is it the beginning of the century?
			    if (trueDeltaYears > 100 || (isHundredMultiple(trueDeltaYears) && !isBeforeCenturyTurn(today))) {
                    if (newCycleStartTime <= today) {
                        if (DateTime.diffDays(newCycleStartTime, today) <= 274) {
                            return _hashes[11];
                        }
                    }
                } 
            }
			// This covers the first 90 years for the first century
			// or the next 89 years and 3 months if it has been more than 100 years
			if (modDeltaYears <= 10*i) {
				// Edge cases: 10 year difference, but January 1st <= today <= October 24th
				if (modDeltaYears == 10*i) {
					if (isBeforeCenturyTurn(today)) return _hashes[i-1];//red states 1 thru 9
					else return _hashes[i];//red states 2 thru 10 (edge cases for decades)
				}
				return _hashes[i-1];//red states 1 thru 9
			}
		}
		// This covers the first 9 years of final red state (10)
		if (modDeltaYears <= 99) return _hashes[9];

		/*
		 * assert(modDeltaYears == 100) which => the new century approaches (we are in the final 91.25 days)
		 * assert(diffDays(block.timestamp, addYears(newCycleStartTime, 100)) != 0)
		 * ^ this case is covered in the for loop above
		 */
		
		// LAST YEAR OF THE CENTURY:
		// January 1 thru October 23 is still in the final red state; only October 24 is the black state.
		// If we are stil in the final red state the number of days between now and the turn of the next century
		// will be greater than 1; otw, it's the last day of the century and the state is black.
		uint nextCenturyStart = DateTime.addYears(newCycleStartTime, 100);
		uint numDaysToNextCentury = DateTime.diffDays(today, nextCenturyStart);

		if (numDaysToNextCentury <= 1) return _hashes[10];
		else return _hashes[9];
	}

	//@dev Helper function to determine if the date is between January 1 and October 24
	function isBeforeCenturyTurn(uint256 today) internal pure returns (bool) 
	{
		uint256 thisMonth = DateTime.getMonth(today);//todays month
		uint256 thisDay = DateTime.getDay(today);//todays day

		if (thisMonth < 10 || (thisMonth == 10 && thisDay < 25))
			return true;
		else
			return false;
	}

	//@dev Helper function to determine if a number is a multiple of 100
	function isHundredMultiple(uint256 x) internal pure returns (bool) 
	{
		return x % 100 == 0 && x != 0;
	}

	//@dev Mint a token (owners only)
	function mint(address payable to) 
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
		if (idx < 0 || idx > 11) 
			revert DataError("index out of bounds");
		if (_stringsEqual(_hashes[idx], newHash)) 
			revert DataError("hash is the same");
		_hashes[idx] = newHash;
	}

	//@dev [BACKUP METHOD] No clue why this would be needed but it's here lol
	function setCycleStartTime(uint256 newStartTime) external isSquad 
	{
		if (cycleStartTime == newStartTime)
			revert DataError("new time is the same as old time");
		cycleStartTime = newStartTime;
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
}
