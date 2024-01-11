// SPDX-License-Identifier: Unlicense

/*
  __  __   _  __   ____  _____  ____    ___    _  __
 / / / /  / |/ /  /  _/ / ___/ / __ \  / _ \  / |/ /
/ /_/ /  /    /  _/ /  / /__  / /_/ / / , _/ /    / 
\____/  /_/|_/  /___/  \___/  \____/ /_/|_| /_/|_/  
                                                    
   __  ___  ____  ______  ____    ___   _____ __  __  _____   __    ____
  /  |/  / / __ \/_  __/ / __ \  / _ \ / ___/ \ \/ / / ___/  / /   / __/
 / /|_/ / / /_/ / / /   / /_/ / / , _// /__    \  / / /__   / /__ / _/  
/_/  /_/  \____/ /_/    \____/ /_/|_| \___/    /_/  \___/  /____//___/  
                                                                        
  _____   ___    _  __  _____
 / ___/  / _ |  / |/ / / ___/
/ (_ /  / __ | /    / / (_ / 
\___/  /_/ |_|/_/|_/  \___/  
                             
*/

pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./RandomlyAssigned.sol";

contract UMGContract is ERC721, Ownable, RandomlyAssigned {

	using Counters for Counters.Counter;

	using Strings for uint256;

    /*
    * Private Variables
    */
    uint256 private constant NUMBER_OF_RESERVED_UNICORNS = 200;
    uint256 private constant MAX_SUPPLY = 10000;

	struct WalletStruct {
		uint256 _numberOfMintsByAddress;
		bool _isInWhiteList;
	}

	enum SalePhase {
		Locked,
		PreSale,
		PublicSale
	}

	string private _defaultURI;
	string private _tokenBaseURI;
	string private baseExtension = ".json";
	uint256 private _maxMintsPerWallet = 100;

	Counters.Counter private supply;

	/*
	 * Public Variables
	 */
    uint256 public mintPrice = 0.5 ether;
	uint256 public reservedTokensMinted;
	uint256 public whiteListCounter;

	SalePhase public phase = SalePhase.Locked;
	
	bool public contractPaused = false;
    bool public isMintEnabled = false;

    mapping(address => WalletStruct) public wallets;

	/*
	 * Constructor
	 */
    constructor(string memory URI) payable ERC721('Unicorn Motorcycle Gang', 'UMG') RandomlyAssigned(MAX_SUPPLY, NUMBER_OF_RESERVED_UNICORNS){
		_defaultURI = URI;
		_tokenBaseURI = _defaultURI;
		mintPrice = 0.5 ether;
		phase = SalePhase.Locked;
		contractPaused = false;
		isMintEnabled = false;
	}

    // ======================================================== Owner Functions

	/// Breaks and pauses contract interaction
	/// @dev modifies the state of the `contractPaused` variable
	function circuitBreaker() public onlyOwner {
		if (contractPaused == false) { 
			contractPaused = true; 
		}else{ 
			contractPaused = false; 
		}
	}

	/// Set the default URI for the metadata
	/// @dev modifies the state of the `_defaultURI` variable
	/// @param URI the URI to set as the default URI
	function setDefaultURI(string memory URI) 
		external 
		onlyOwner 
		checkIfPaused()
	{
		_defaultURI = URI;
	}

	/// Set the base token URI for the metadata
	/// @dev modifies the state of the `_tokenBaseURI` variable
	/// @param URI the URI to set as the base token URI
	function setTokenBaseURI(string memory URI) 
		external 
		onlyOwner 
		checkIfPaused()
	{
		_tokenBaseURI = URI;
	}

	// Adjust max mints per wallet
	/// @dev modifies the state of the `_maxMintsPerWallet` variable
	/// @notice sets the max mints for wallets
	/// @param _newMaxMints The new max minst per wallet
	function adjustMaxMintsPerWallet(uint256 _newMaxMints)
		external
		onlyOwner
		checkIfPaused()
	{
		_newMaxMints < 0 ? _maxMintsPerWallet = 100 : _maxMintsPerWallet = _newMaxMints;
	}

	// Adjust the mint price
	/// @dev modifies the state of the `mintPrice` variable
	/// @notice sets the price for minting a token
	/// @param _newPrice The new price for minting
	function adjustMintPrice(uint256 _newPrice)
		external
		onlyOwner
		checkIfPaused()
	{
		mintPrice > 0 ? mintPrice = 0.5 ether : mintPrice = _newPrice;
	}

	/// Activate or deactivate minting
	/// @dev set the state of `isMintEnabled` variable to true or false
	/// @notice Activate or deactivate the minting event
    function toggleIsMintEnabled() 
		external
		onlyOwner
		checkIfPaused()
	{
        isMintEnabled = !isMintEnabled;
    }

	/// Advance Phase
	/// @dev Advance the sale phase state
	/// @notice Advances sale phase state incrementally
	function enterPhase(SalePhase _phase) 
		external
		onlyOwner 
		checkIfPaused()
	{
		require(uint8(_phase) != uint8(phase), 'Can only change phases');
		phase = _phase;
	}

	/// Adds addresses to white list
	/// @dev Adds addresses to an internal list
	/// @notice Adds a number of addresses to an internal white list.
	/// @param _addedAddressesList The new addresses that wants to be added to the white list
	function addAddressesToWhiteList(address[] memory _addedAddressesList)
		external
		onlyOwner
		checkIfPaused()
	{
		require(whiteListCounter < MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS, 'Can not add more addresses than avialable tokens');

		for (uint256 i; i < _addedAddressesList.length; i++) {
			require(!_searchInWhiteList(_addedAddressesList[i]), 'Can not add a wallet that has been added');
			wallets[_addedAddressesList[i]]._isInWhiteList = true;
			whiteListCounter++;
		}
	}

	/// Adds an array of tokens to an address
	/// @dev Adds reserved tokens to an address that has been reserved
	/// @notice Adds reserved tokens to an address
	/// @param to recipient address
	/// @param tokensId The reserved tokens that will be added to the address
	function claimReservedTokens(
		address to,
		uint256[] memory tokensId
	) 
		external 
		onlyOwner 
		ensureAvailabilityFor(tokensId.length)
		checkIfPaused()
	{
		require(isMintEnabled, 'Minting not enabled');
		require(tokensId.length + wallets[to]._numberOfMintsByAddress <= _maxMintsPerWallet, 'Exceeds number of earned Tokens');
		require(NUMBER_OF_RESERVED_UNICORNS > reservedTokensMinted, 'Reserved tokens sold out');
        require(NUMBER_OF_RESERVED_UNICORNS >= reservedTokensMinted + tokensId.length, 'Exceeds reserved maximum supply');

		wallets[to]._numberOfMintsByAddress += tokensId.length;
		reservedTokensMinted += tokensId.length;
		
		for (uint256 i; i < tokensId.length; i++) {
			uint256 tokenId = tokensId[i];
			assert(tokenId <= NUMBER_OF_RESERVED_UNICORNS);
			_safeMint(to, tokenId);
		}
	}

	/// Disburse payments
	/// @dev transfers amounts that correspond to addresses passeed in as args
	/// @param payees_ recipient addresses
	/// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
    function disbursePayments(
		address[] memory payees_,
		uint256[] memory amounts_
	) 
		external
	 	onlyOwner 
		checkIfPaused()
	{
		require(
			payees_.length == amounts_.length,
			'Payees and amounts length mismatch'
		);
		for (uint256 i; i < payees_.length; i++) {
			makePaymentTo(payees_[i], amounts_[i]);
		}
	}

	/// Make a payment
	/// @dev internal function called by `disbursePayments` to send Ether to an address
    function makePaymentTo(address address_, uint256 amt_) private {
		(bool success, ) = address_.call{value: amt_}('');
		require(success, 'Transfer failed.');
	}

	// ======================================================== External Functions

	/// Get current supply
	/// @dev returns a uint256 that is equal to the current supply
	function totalSupply() public view returns (uint256) {
    	return supply.current();
  	}

	/// Mint during presale
	/// @dev mints by addresses validated using the internal white list
	/// @notice mints tokens with randomized token IDs to addresses eligible for presale
	/// @param count number of tokens to mint in transaction
	function mintPresale(uint256 count) 
		external 
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count)
		checkIfPaused()
	{
		require(phase == SalePhase.PreSale, 'Not presale');
        require(isMintEnabled, 'Minting not enabled');
        require(count > 0, 'Count is 0 or below');
        require(wallets[msg.sender]._numberOfMintsByAddress + count <= _maxMintsPerWallet, 'Exceeds max per wallet');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS > supply.current(), 'Sold out');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS >= supply.current() + count, 'Exceeds maximum supply');
        require(count <=  _maxMintsPerWallet, 'You only can mint a maximum of 100');
		require(_searchInWhiteList(msg.sender), 'Address is not in whitelist');

        wallets[msg.sender]._numberOfMintsByAddress += count;

        for(uint256 i; i < count; i++){
		    _mintRandomId(msg.sender);
        }
    }

	/// Public minting open to all
	/// @dev mints tokens during public sale, limited by `_maxMintsPerWallet`
	/// @notice mints tokens with randomized IDs to the sender's address
	/// @param count number of tokens to mint in transaction
    function mint(uint256 count) 
		external 
		payable
		ensureAvailabilityFor(count)
		validateEthPayment(count)
		checkIfPaused()
	{
		require(phase == SalePhase.PublicSale, "Not public sale");
        require(isMintEnabled, 'Minting not enabled');
        require(count > 0, 'Count is 0 or below');
        require(wallets[msg.sender]._numberOfMintsByAddress + count <= _maxMintsPerWallet, 'Exceeds max per wallet');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS > supply.current(), 'Sold out');
        require(MAX_SUPPLY - NUMBER_OF_RESERVED_UNICORNS >= supply.current() + count, 'Exceeds maximum supply');
        require(count <=  _maxMintsPerWallet, 'You can only mint a maximum of 100');

        wallets[msg.sender]._numberOfMintsByAddress += count;

        for(uint256 i; i < count; i++){
		    _mintRandomId(msg.sender);
        }
    }

// ======================================================== Internal Functions

	/// @dev internal check to ensure a ID outside of the collection, doesn't get minted
	function _mintRandomId(address to) private {
		supply.increment();
        uint256 tokenId = nextToken();
        assert(tokenId > NUMBER_OF_RESERVED_UNICORNS && tokenId <= MAX_SUPPLY);
        _safeMint(to, tokenId);
    }

	/// @dev internal check to ensure an address is in the white list
	function _searchInWhiteList(address to) private view returns(bool) {
		return wallets[to]._isInWhiteList;
	}

	// ======================================================== Overrides

	/// Return the tokenURI for a given ID
	/// @dev overrides ERC721's `tokenURI` function and returns either the `_tokenBaseURI` or a default URI
	/// @notice reutrns the tokenURI using the `_default` URI if the token ID hasn't been suppleid with a unique custom URI
	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721)
		returns (string memory)
	{
		require(_exists(tokenId), 'Cannot query non-existent token');

		return
			bytes(_tokenBaseURI).length > 0
				? string(
					abi.encodePacked(_tokenBaseURI, '/', tokenId.toString(), baseExtension)
				)
				: _baseURI();
	}

	/// Returns _defaultURI as the base URI
	/// @dev overrides ERC721's `_baseURI` function and returns default URI as the base URI
	/// @notice reutrns the tokenURI using the `_tokenBase` URI if the token ID hasn't been suppleid with a unique custom URI
	function _baseURI() 
		internal 
		view 
		override(ERC721) 
		returns (string memory) 
	{
        return _defaultURI;
    }

// ======================================================== Modifiers

	/// Modifier to validate Eth payments on payable functions
	/// @dev compares the product of the state variable `mintPrice` and supplied `count` to msg.value
	/// @param count factor to multiply by
	modifier validateEthPayment(uint256 count) {
		require(
			mintPrice * count == msg.value,
			'Ether value sent is not correct'
		);
		_;
	}

	/// Modifier to validate that the contract is not puased
	/// @dev compares state of the variable `contractPaused` to ensure it is false
	modifier checkIfPaused() {
		require(contractPaused == false, 'Contract paused');
		_;
	}

}