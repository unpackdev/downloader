// SPDX-License-Identifier: SPDX-License
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

/*
          _____                    _____                    _____                    _____                    _____                    _____          
         /\    \                  /\    \                  /\    \                  /\    \                  /\    \                  /\    \         
        /::\    \                /::\    \                /::\    \                /::\    \                /::\    \                /::\____\        
       /::::\    \              /::::\    \              /::::\    \               \:::\    \              /::::\    \              /:::/    /        
      /::::::\    \            /::::::\    \            /::::::\    \               \:::\    \            /::::::\    \            /:::/    /         
     /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/    /          
    /:::/__\:::\    \        /:::/__\:::\    \        /:::/__\:::\    \               \:::\    \        /:::/__\:::\    \        /:::/    /           
   /::::\   \:::\    \      /::::\   \:::\    \      /::::\   \:::\    \              /::::\    \      /::::\   \:::\    \      /:::/    /            
  /::::::\   \:::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    /:::/    /             
 /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/    /              
/:::/  \:::\   \:::\____\/:::/__\:::\   \:::\____\/:::/  \:::\   \:::|    |/::\   \/:::/  \:::\____\/:::/  \:::\   \:::\____\/:::/____/               
\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /\::/   |::::\  /:::|____|\:::\  /:::/    \::/    /\::/    \:::\  /:::/    /\:::\    \               
 \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/  \/____|:::::\/:::/    /  \:::\/:::/    / \/____/  \/____/ \:::\/:::/    /  \:::\    \              
          \::::::/    /    \:::\   \:::\    \            |:::::::::/    /    \::::::/    /                    \::::::/    /    \:::\    \             
           \::::/    /      \:::\   \:::\____\           |::|\::::/    /      \::::/____/                      \::::/    /      \:::\    \            
           /:::/    /        \:::\   \::/    /           |::| \::/____/        \:::\    \                      /:::/    /        \:::\    \           
          /:::/    /          \:::\   \/____/            |::|  ~|               \:::\    \                    /:::/    /          \:::\    \          
         /:::/    /            \:::\    \                |::|   |                \:::\    \                  /:::/    /            \:::\    \         
        /:::/    /              \:::\____\               \::|   |                 \:::\____\                /:::/    /              \:::\____\        
        \::/    /                \::/    /                \:|   |                  \::/    /                \::/    /                \::/    /        
         \/____/                  \/____/                  \|___|                   \/____/                  \/____/                  \/____/         
                                                                                                                                                      
          _____                    _____                   _______                   _____                    _____                                   
         /\    \                  /\    \                 /::\    \                 /\    \                  /\    \                                  
        /::\    \                /::\    \               /::::\    \               /::\____\                /::\    \                                 
        \:::\    \              /::::\    \             /::::::\    \             /::::|   |               /::::\    \                                
         \:::\    \            /::::::\    \           /::::::::\    \           /:::::|   |              /::::::\    \                               
          \:::\    \          /:::/\:::\    \         /:::/~~\:::\    \         /::::::|   |             /:::/\:::\    \                              
           \:::\    \        /:::/  \:::\    \       /:::/    \:::\    \       /:::/|::|   |            /:::/__\:::\    \                             
           /::::\    \      /:::/    \:::\    \     /:::/    / \:::\    \     /:::/ |::|   |            \:::\   \:::\    \                            
  ____    /::::::\    \    /:::/    / \:::\    \   /:::/____/   \:::\____\   /:::/  |::|   | _____    ___\:::\   \:::\    \                           
 /\   \  /:::/\:::\    \  /:::/    /   \:::\    \ |:::|    |     |:::|    | /:::/   |::|   |/\    \  /\   \:::\   \:::\    \                          
/::\   \/:::/  \:::\____\/:::/____/     \:::\____\|:::|____|     |:::|    |/:: /    |::|   /::\____\/::\   \:::\   \:::\____\                         
\:::\  /:::/    \::/    /\:::\    \      \::/    / \:::\    \   /:::/    / \::/    /|::|  /:::/    /\:::\   \:::\   \::/    /                         
 \:::\/:::/    / \/____/  \:::\    \      \/____/   \:::\    \ /:::/    /   \/____/ |::| /:::/    /  \:::\   \:::\   \/____/                          
  \::::::/    /            \:::\    \                \:::\    /:::/    /            |::|/:::/    /    \:::\   \:::\    \                              
   \::::/____/              \:::\    \                \:::\__/:::/    /             |::::::/    /      \:::\   \:::\____\                             
    \:::\    \               \:::\    \                \::::::::/    /              |:::::/    /        \:::\  /:::/    /                             
     \:::\    \               \:::\    \                \::::::/    /               |::::/    /          \:::\/:::/    /                              
      \:::\    \               \:::\    \                \::::/    /                /:::/    /            \::::::/    /                               
       \:::\____\               \:::\____\                \::/____/                /:::/    /              \::::/    /                                
        \::/    /                \::/    /                 ~~                      \::/    /                \::/    /                                 
         \/____/                  \/____/                                           \/____/                  \/____/                                  
*/

struct FlightPass {
	bool claimed;
	bool exists;
}

struct Hookup {
	bool exists;
	uint256 price;
}

struct HookupList {
	mapping(address => Hookup) addressPriceMapping;
	uint256 addressCount;
}

struct ReserveList {
	mapping(address => bool) addressMapping;
	uint256 addressCount;
}

contract AerialIcons is ERC721, Ownable {
	address public sweetAndy = 0xBE7B3DB607525EA25956B4d28d6e552967225622;

	string public baseURI;

	uint128 public revealIndex = 0;
	uint128 public dropCount = 0;
	uint128 public dropSize = 0;
	uint128 private constant MAX_SUPPLY = 100; // Max supply
	uint256 public presalePrice = 250000000000000000; // 0.25 eth presale price
	uint256 public listPrice = 330000000000000000; // 0.33 eth list price

	mapping(uint256 => FlightPass) private flightPassMap; // mapping for winning flight path indexes
	mapping(uint256 => string) private flightPassRedemptionMap; // mapping for winning flight path indexes

	ReserveList private presale;
	HookupList private hookup;

	uint128 public currentDropReserveCount = 0;
	uint128 public currentDropReserveIndex = 0;
	mapping(uint128 => mapping(address => bool)) public currentDropReserve;

	// Keep track of state
	using Counters for Counters.Counter;
	Counters.Counter private boardingPassCounter;
	Counters.Counter private flightPassCounter;

	/**
	 * @param _baseURI base uri for tokens
	 * @param _presaleAddresses - list of presale addresses
	 */
	constructor(
		string memory _baseURI,
		address[] memory _presaleAddresses,
		uint256[] memory _flightPassIndexes
	) ERC721("AerialIcons", "AerialIcons") {
		baseURI = _baseURI;

		setPresaleAddresses(_presaleAddresses);

		for (uint128 i = 0; i < _flightPassIndexes.length; i++) {
			flightPassMap[_flightPassIndexes[i]] = FlightPass({
				claimed: false,
				exists: true
			});
		}
	}

	// General contract state
	/*------------------------------------*/

	/**
	 * Add an address to current drop.
	 */
	function reserveForCurrentDrop(address _address) public onlyOwner {
		require(
			!currentDropReserve[currentDropReserveIndex][_address],
			"ADDRESS_ALEADY_IN_DROP"
		);
		currentDropReserve[currentDropReserveIndex][_address] = true;
		currentDropReserveCount = currentDropReserveCount + 1;
	}

	/**
	 * Remove address from drop
	 */
	function removeFromCurrentDrop(address _address) public onlyOwner {
		require(
			currentDropReserve[currentDropReserveIndex][_address],
			"ADDRESS_NOT_IN_DROP"
		);
		currentDropReserve[currentDropReserveIndex][_address] = false;
		currentDropReserveCount = currentDropReserveCount - 1;
	}

	/**
	 * Set a new drop
	 */
	function handleNewDrop(
		uint128 _dropCount,
		address[] memory _reservedAddresses
	) public onlyOwner {
		dropCount = _dropCount;
		dropSize = _dropCount;
		currentDropReserveCount = 0;
		currentDropReserveIndex = currentDropReserveIndex + 1;

		for (uint128 i = 0; i < _reservedAddresses.length; i++) {
			reserveForCurrentDrop(_reservedAddresses[i]);
		}
	}

	/**
	 * Set a new drop without reserve addresses
	 */
	function handleRawNewDrop(uint128 _dropCount) public onlyOwner {
		dropCount = _dropCount;
		dropSize = _dropCount;
		currentDropReserveCount = 0;
		currentDropReserveIndex = currentDropReserveIndex + 1;
	}

	/**
	 * Escape hatch to update reveal index
	 */
	function handleReveal(uint128 _revealIndex) public onlyOwner {
		revealIndex = _revealIndex;
	}

	/**
	 * Escape hatch to update price.
	 */
	function setPresalePrice(uint128 _presalePrice) public onlyOwner {
		presalePrice = _presalePrice;
	}

	/**
	 * Escape hatch to update list price.
	 */
	function setListPrice(uint128 _listPrice) public onlyOwner {
		listPrice = _listPrice;
	}

	/**
	 * Escape hatch to update URI.
	 */
	function setBaseURI(string memory _baseURI) public onlyOwner {
		baseURI = _baseURI;
	}

	/**
	 * Update a flight passes redemption URI.
	 */
	function setFlightPassRedemptionURI(
		uint256 _tokenId,
		string memory _redemptionURI
	) public onlyOwner {
		flightPassRedemptionMap[_tokenId] = _redemptionURI;
	}

	/**
	 * Add flight pass for certain token index
	 */
	function setFlightPassIndex(uint256 _tokenId) public onlyOwner {
		require(!flightPassMap[_tokenId].claimed, "FLIGHT_PASS_CLAIMED");
		flightPassMap[_tokenId] = FlightPass({ exists: true, claimed: false });
	}

	/**
	 * Update sweet baby andy's address in the event of an emergency
	 */
	function setSweetAndy(address _sweetAndy) public onlyOwner {
		sweetAndy = _sweetAndy;
	}

	/*
	 * Withdraw, sends:
	 * 95% of all past sales to artist.
	 * 5% of all past sales to devs.
	 */
	function withdraw() public onlyOwner {
		// Pass collaborators their cut
		uint256 balance = address(this).balance;

		// Send devs 4.95%
		(bool success, ) = sweetAndy.call{ value: (balance * 5) / 100 }("");
		require(success, "FAILED_SEND_DEV");

		// Send owner remainder
		(success, ) = owner().call{ value: (balance * 95) / 100 }("");
		require(success, "FAILED_SEND_OWNER");
	}

	/**
	 * Add a single address to the reserve list.
	 */
	function addPresaleAddress(address _address) public onlyOwner {
		require(
			!presale.addressMapping[_address],
			"PRESALE_ADDRESS_ALREADY_EXISTS"
		);

		presale.addressMapping[_address] = true;
		presale.addressCount = presale.addressCount + 1;
	}

	/**
	 * Add addresses to presale.
	 */
	function setPresaleAddresses(address[] memory _addresses) public onlyOwner {
		for (uint128 i = 0; i < _addresses.length; i++) {
			// Do not incrememnt counter if this address already exists
			if (!presale.addressMapping[_addresses[i]]) {
				presale.addressMapping[_addresses[i]] = true;
				presale.addressCount = presale.addressCount + 1;
			}
		}
	}

	/**
	 * Remove from presale.
	 */
	function removePresaleAddress(address _address) public onlyOwner {
		require(presale.addressMapping[_address], "RESERVE_ADDRESS_DNE");
		presale.addressMapping[_address] = false;
		presale.addressCount = presale.addressCount - 1;
	}

	/**
	 * Add a single address to the hookup.
	 */
	function addHookupAddress(address _address, uint256 _price)
		public
		onlyOwner
	{
		require(
			!hookup.addressPriceMapping[_address].exists,
			"HOOKUP_ADDRESS_ALREADY_EXISTS"
		);

		hookup.addressPriceMapping[_address] = Hookup({
			exists: true,
			price: _price
		});
		hookup.addressCount = hookup.addressCount + 1;
	}

	/**
	 * Add addresses to hookup.
	 * A bit wacky, but addresses and prices are parallel arrays that
	 * compose into matching key-value pairs.
	 */
	function setHookupAddresses(
		address[] memory _addresses,
		uint256[] memory _prices
	) public onlyOwner {
		require(
			_addresses.length == _prices.length,
			"HOOKUP_ARRAYS_MUST_BE_PARALLEL"
		);

		for (uint128 i = 0; i < _addresses.length; i++) {
			// Do not incrememnt counter if this address already exists
			if (!hookup.addressPriceMapping[_addresses[i]].exists) {
				hookup.addressPriceMapping[_addresses[i]] = Hookup({
					exists: true,
					price: _prices[i]
				});
				hookup.addressCount = hookup.addressCount + 1;
			}
		}
	}

	/**
	 * Remove from hookup list
	 */
	function removeFromHookup(address _address) public onlyOwner {
		require(
			hookup.addressPriceMapping[_address].exists,
			"HOOKUP_ADDRESS_DNE"
		);

		delete hookup.addressPriceMapping[_address];
		hookup.addressCount = hookup.addressCount - 1;
	}

	function getTotalReserved() private view returns (uint256) {
		return (presale.addressCount + hookup.addressCount);
	}

	function isAddressReserved(address _address) private view returns (bool) {
		return
			presale.addressMapping[_address] ||
			hookup.addressPriceMapping[_address].exists;
	}

	// Minting
	/*------------------------------------*/

	function handleDropCount() private {
		dropCount = dropCount - 1;
		if (dropCount == 0) {
			revealIndex = revealIndex + dropSize;
		}
	}

	/**
	 * Mint boarding pass
	 */
	function handleBoardingPass() private {
		_safeMint(msg.sender, boardingPassCounter.current());

		handleDropCount();
		boardingPassCounter.increment();
	}

	/**
	 * Mint flight pass
	 */
	function handleFlightPass() private {
		_safeMint(msg.sender, MAX_SUPPLY - (flightPassCounter.current() + 1));

		flightPassCounter.increment();
		flightPassMap[boardingPassCounter.current()].claimed = true;
		handleDropCount();
	}

	/**
	 * Mint
	 */
	function mint(uint128 purchaseCount) public payable {
		uint256 finalPrice = listPrice;

		if (hookup.addressPriceMapping[msg.sender].exists) {
			finalPrice = hookup.addressPriceMapping[msg.sender].price;
		} else if (presale.addressMapping[msg.sender]) {
			finalPrice = presalePrice;
		}

		require(
			msg.value >= finalPrice + (listPrice * (purchaseCount - 1)),
			"LOW_ETH"
		);

		require(
			(currentDropReserve[currentDropReserveIndex][msg.sender] &&
				dropCount + 1 >= purchaseCount + currentDropReserveCount) ||
				dropCount >= (purchaseCount + currentDropReserveCount),
			"DROP_SUPPLY_REACHED"
		);
		require(
			isAddressReserved(msg.sender) ||
				boardingPassCounter.current() +
					flightPassCounter.current() +
					getTotalReserved() +
					purchaseCount -
					1 <
				MAX_SUPPLY,
			"MAX_SUPPLY_REACHED"
		);

		if (currentDropReserve[currentDropReserveIndex][msg.sender]) {
			delete currentDropReserve[currentDropReserveIndex][msg.sender];
			currentDropReserveCount = currentDropReserveCount - 1;
		}

		for (uint256 i = 0; i < purchaseCount; i++) {
			uint256 nextTokenId = boardingPassCounter.current();
			FlightPass memory flightPass = flightPassMap[nextTokenId];

			if (flightPass.exists && !flightPass.claimed) {
				handleFlightPass();
			} else {
				handleBoardingPass();
			}
		}
	}

	// ERC721 Things
	/*------------------------------------*/

	/**
	 * Get total token supply
	 */
	function totalSupply() public view returns (uint256) {
		return boardingPassCounter.current() + flightPassCounter.current();
	}

	/**
	 * Get token URI
	 */
	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		require(_exists(_tokenId), "TOKEN_DNE");

		if (_tokenId >= MAX_SUPPLY - flightPassCounter.current()) {
			if (bytes(flightPassRedemptionMap[_tokenId]).length != 0) {
				return flightPassRedemptionMap[_tokenId];
			} else {
				return string(abi.encodePacked(baseURI, "flight_pass"));
			}
		} else if (_tokenId + flightPassCounter.current() + 1 > revealIndex) {
			return string(abi.encodePacked(baseURI, "boarding_pass"));
		}

		return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
	}
}
