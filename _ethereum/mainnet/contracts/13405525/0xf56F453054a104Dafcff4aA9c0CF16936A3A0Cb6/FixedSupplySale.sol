// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AletheaERC721Spec.sol";
import "./IntelligentNFTv2.sol";
import "./AccessControl.sol";

/**
 * @title Fixed Supply Sale
 *
 * @notice Fixed Supply Sale sales fixed amount of iNFTs for a fixed price in a fixed period of time;
 *      underlying NFTs and AI Personalities are being minted as well as a part of the sale process
 *
 * @notice In restricted mode (FEATURE_PUBLIC_SALE feature disabled) sells the items only to
 *      accounts having `ROLE_BUYER` permission (used to mint first hundred iNFTs in the 10k sale campaign)
 *
 * @dev Technically, all the "fixed" parameters can be changed on the go after smart contract is deployed
 *      and operational, but this ability is reserved for quick fix-like adjustments, and to provide
 *      an ability to restart and run a similar sale after the previous one ends
 *
 * @dev When buying an iNFT from this smart contract:
 *      1) next NFT is minted to the transaction sender address
 *      2) next AI Personality is minted directly to iNFT smart contract for further locking
 *      3) next iNFT is created, bound to an NFT minted in step (1)
 *         and locking the AI Personality minted in step (2)
 *      4) no ALI tokens are minted, no ALI tokens are locked or consumed in the process
 *
 * @dev Deployment and setup:
 *      1. Deploy smart contract, specify smart contract addresses during the deployment
 *         - iNFT deployed instance address
 *         - NFT deployed instance address
 *         - AI Personality deployed instance address
 *      2. Execute `initialize` function and set up the sale parameters;
 *         sale is not active until it's initialized
 */
contract FixedSupplySale is AccessControl {
	// ----- SLOT.1 (256/256)
	/**
	 * @notice Price of a single iNFT minted (with the underlying NFT and AI Personality minted)
	 *      When buying several iNFTs at once the price accumulates accordingly, with no discount
	 *
	 * @dev Maximum item price is ~18.44 ETH
	 */
	uint64 public itemPrice;

	/**
	 * @dev Next iNFT / bound NFT / AI Personality ID to mint;
	 *      initially this is the first "free" ID which can be minted;
	 *      at any point in time this should point to a free, mintable ID
	 *      for iNFT / bound NFT / AI Personality
	 *
	 * @dev `nextId` cannot be zero, we do not ever mint NFTs with zero IDs
	 */
	uint32 public nextId = 1;

	/**
	 * @dev Last iNFT / bound NFT / AI Personality ID to mint;
	 *      once `nextId` exceeds `finalId` the sale pauses
	 */
	uint32 public finalId;

	/**
	 * @notice Sale start unix timestamp; the sale is active after the start (inclusive)
	 */
	uint32 public saleStart;

	/**
	 * @notice Sale end unix timestamp; the sale is active before the end (exclusive)
	 */
	uint32 public saleEnd;

	/**
	 * @notice Once set, limits the amount of iNFTs one can buy in a single transaction;
	 *       When unset (zero) the amount of iNFTs is limited only by block size and
	 *       amount of iNFTs left for sale
	 */
	uint32 public batchLimit;

	/**
	 * @notice Counter of the iNFTs sold (minted) by this sale smart contract
	 */
	uint32 public soldCounter;

	// ----- NON-SLOTTED
	/**
	 * @dev ALI ERC20 contract address to transfer tokens and bind to iNFTs created,
	 *      should match with `iNftContract.aliContract`
	 */
	address public immutable aliContract;

	/**
	 * @dev NFT ERC721 contract address to mint NFTs from and bind to iNFTs created
	 */
	address public immutable nftContract;

	/**
	 * @dev Personality Pod ERC721 contract address to mint and lock into iNFTs created
	 */
	address public immutable personalityContract;

	/**
	 * @dev iNFT contract address used to create iNFTs
	 */
	address public immutable iNftContract;

	// ----- SLOT.2
	/**
	 * @dev iNFTs may get created with the ALI tokens bound to them.
	 *      The tokens are transferred from the address specified.
	 *      The address specified has to approve the sale to spend tokens.
	 *
	 * @dev Both `aliSource` and `aliValue` must be set in order to bind tokens
	 *      to iNFTs sold
	 *
	 * @dev Both `aliSource` and `aliValue` can be either set or unset
	 */
	address public aliSource;

	/**
	 * @dev iNFTs may get created with the ALI tokens bound to them.
	 *      Specified amount of tokens is transferred from the address specified above
	 *      for each iNFT created, and is bound within the iNFT
	 *      The address specified above has to approve the sale to spend tokens.
	 *
	 * @dev Both `aliSource` and `aliValue` must be set in order to bind tokens
	 *      to iNFTs sold
	 *
	 * @dev Both `aliSource` and `aliValue` can be either set or unset
	 */
	uint96 public aliValue;

	/**
	 * @notice Allows buying the items publicly, effectively ignoring the buyer permission
	 *
	 * @dev When `FEATURE_PUBLIC_SALE` is enabled, `ROLE_BUYER` is ignored and
	 *      buying items via buy(), buyTo(), buySingle(), buySingleTo() becomes publicly accessible
	 */
	uint32 public constant FEATURE_PUBLIC_SALE = 0x0000_0001;

	/**
	 * @notice Sale manager is responsible for managing properties of the sale,
	 *      such as sale price, amount, start/end dates, etc.
	 *
	 * @dev Role ROLE_SALE_MANAGER allows updating sale properties via initialize() function
	 */
	uint32 public constant ROLE_SALE_MANAGER = 0x0001_0000;

	/**
	 * @notice Withdrawal manager is responsible for withdrawing ETH obtained in sale
	 *      from the sale smart contract
	 *
	 * @dev Role ROLE_WITHDRAWAL_MANAGER allows ETH withdrawals:
	 *      - withdraw()
	 *      - withdrawTo()
	 */
	uint32 public constant ROLE_WITHDRAWAL_MANAGER = 0x0002_0000;

	/**
	 * @notice Buyer can buy items via the restricted sale
	 *
	 * @dev Role ROLE_BUYER allows buying items via buy(), buyTo(), buySingle(), buySingleTo()
	 */
	uint32 public constant ROLE_BUYER = 0x0004_0000;

	/**
	 * @dev Fired in initialize()
	 *
	 * @param _by an address which executed the initialization
	 * @param _itemPrice price of one iNFT created
	 * @param _nextId next ID of the iNFT, NFT, and AI Pod to mint
	 * @param _finalId final ID of the iNFT, NFT, and AI Pod to mint
	 * @param _saleStart start of the sale, unix timestamp
	 * @param _saleEnd end of the sale, unix timestamp
	 * @param _batchLimit how many iNFTs is allowed to buy in a single transaction
	 * @param _aliSource an address to transfer ALI tokens from to bind to iNFTs created
	 * @param _aliValue an amount of ALI tokens to transfer and bind for each iNFT created
	 */
	event Initialized(
		address indexed _by,
		uint64 _itemPrice,
		uint32 _nextId,
		uint32 _finalId,
		uint32 _saleStart,
		uint32 _saleEnd,
		uint32 _batchLimit,
		address indexed _aliSource,
		uint96 _aliValue
	);

	/**
	 * @dev Fired in buy(), buyTo(), buySingle(), and buySingleTo()
	 *
	 * @param _by an address which executed and payed the transaction, probably a buyer
	 * @param _to an address which received token(s) and iNFT(s) minted
	 * @param _amount number of tokens and iNFTs minted
	 * @param _aliValue number of ALI tokens transferred
	 * @param _value ETH amount charged
	 */
	event Bought(address indexed _by, address indexed _to, uint256 _amount, uint256 _aliValue, uint256 _value);

	/**
	 * @dev Fired in withdraw() and withdrawTo()
	 *
	 * @param _by an address which executed the withdrawal
	 * @param _to an address which received the ETH withdrawn
	 * @param _value ETH amount withdrawn
	 */
	event Withdrawn(address indexed _by, address indexed _to, uint256 _value);

	/**
	 * @dev Creates/deploys FixedSupplySale and binds it to NFT, AI Personality, and iNFT
	 *      smart contracts on construction
	 *
	 * @param _ali deployed ALI ERC20 smart contract address; sale may bind tokens to iNFTs created
	 * @param _iNft deployed iNFT smart contract address; sale will create iNFTs of that type
	 * @param _nft deployed NFT smart contract address; sale will mint NFTs of that type
	 *      and bind created iNFT to these NFTs
	 * @param _personality deployed AI Personality smart contract; sale will mint AI Personality
	 *      tokens of that type and lock them within iNFTs
	 */
	constructor(address _ali, address _nft, address _personality, address _iNft) {
		// verify the inputs are set
		require(_ali != address(0), "ALI Token contract is not set");
		require(_nft != address(0), "NFT contract is not set");
		require(_personality != address(0), "AI Personality contract is not set");
		require(_iNft != address(0), "iNFT contract is not set");

		// verify inputs are valid smart contracts of the expected interfaces
		require(ERC165(_ali).supportsInterface(type(ERC20).interfaceId), "unexpected ALI Token type");
		require(
			ERC165(_nft).supportsInterface(type(ERC721).interfaceId)
			&& ERC165(_nft).supportsInterface(type(MintableERC721).interfaceId),
			"unexpected NFT type"
		);
		require(
			ERC165(_personality).supportsInterface(type(ERC721).interfaceId)
			&& ERC165(_personality).supportsInterface(type(MintableERC721).interfaceId),
			"unexpected AI Personality type"
		);
		require(ERC165(_iNft).supportsInterface(type(IntelligentNFTv2Spec).interfaceId), "unexpected iNFT type");

		// assign the addresses
		aliContract = _ali;
		nftContract = _nft;
		personalityContract = _personality;
		iNftContract = _iNft;
	}

	/**
	 * @notice Number of iNFTs left on sale
	 *
	 * @dev Doesn't take into account if sale is active or not,
	 *      if `nextId - finalId < 1` returns zero
	 *
	 * @return number of iNFTs left on sale
	 */
	function itemsOnSale() public view returns(uint32) {
		// calculate items left on sale, taking into account that
		// finalId is on sale (inclusive bound)
		return finalId > nextId? finalId + 1 - nextId: 0;
	}

	/**
	 * @notice Number of iNFTs available on sale
	 *
	 * @dev Takes into account if sale is active or not, doesn't throw,
	 *      returns zero if sale is inactive
	 *
	 * @return number of iNFTs available on sale
	 */
	function itemsAvailable() public view returns(uint32) {
		// delegate to itemsOnSale() if sale is active, return zero otherwise
		return isActive()? itemsOnSale(): 0;
	}

	/**
	 * @notice Active sale is an operational sale capable of minting and selling
	 *      iNFTs (together with minting the underlying assets - NFTs and AI Personalities)
	 *
	 * @dev The sale is active when all the requirements below are met:
	 *      1. Price is set (`itemPrice` is not zero)
	 *      2. `finalId` is not reached (`nextId <= finalId`)
	 *      3. current timestamp is between `saleStart` (inclusive) and `saleEnd` (exclusive)
	 *
	 * @dev Function is marked as virtual to be overridden in the helper test smart contract (mock)
	 *      in order to test how it affects the sale process
	 *
	 * @return true if sale is active (operational) and can sell iNFTs, false otherwise
	 */
	function isActive() public view virtual returns(bool) {
		// evaluate sale state based on the internal state variables and return
		return itemPrice > 0 && nextId <= finalId && saleStart <= now256() && saleEnd > now256();
	}

	/**
	 * @dev Restricted access function to set up sale parameters, all at once,
	 *      or any subset of them
	 *
	 * @dev To skip parameter initialization, set it to `-1`,
	 *      that is a maximum value for unsigned integer of the corresponding type;
	 *      `_aliSource` and `_aliValue` must both be either set or skipped
	 *
	 * @dev Example: following initialization will update only _itemPrice and _batchLimit,
	 *      leaving the rest of the fields unchanged
	 *      initialize(
	 *          100000000000000000,
	 *          0xFFFFFFFF,
	 *          0xFFFFFFFF,
	 *          0xFFFFFFFF,
	 *          0xFFFFFFFF,
	 *          10,
	 *          0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF,
	 *          0xFFFFFFFFFFFFFFFFFFFFFFFF
	 *      )
	 *
	 * @dev Requires next ID to be greater than zero (strict): `_nextId > 0`
	 * @dev Requires ALI source/value to be both either set or unset (zero);
	 *      if set, ALI value must not be less than 1e12 (0.000001 ALI)
	 *
	 * @dev Requires transaction sender to have `ROLE_SALE_MANAGER` role
	 *
	 * @param _itemPrice price of one iNFT created (with NFT and AI Personality also minted);
	 *      setting the price to zero deactivates the sale
	 * @param _nextId next ID of the iNFT, NFT, and AI Pod to mint, will be increased
	 *      in smart contract storage after every successful buy
	 * @param _finalId final ID of the iNFT, NFT, and AI Pod to mint; sale is capable of producing
	 *      `_finalId - _nextId + 1` iNFTs
	 * @param _saleStart start of the sale, unix timestamp
	 * @param _saleEnd end of the sale, unix timestamp; sale is active only
	 *      when current time is within _saleStart (inclusive) and _saleEnd (exclusive)
	 * @param _batchLimit how many iNFTs is allowed to buy in a single transaction,
	 *      set to zero to disable the limit
	 * @param _aliSource an address to transfer ALI tokens from to bind to iNFTs created
	 * @param _aliValue an amount of ALI tokens to transfer and bind for each iNFT created
	 */
	function initialize(
		uint64 _itemPrice,	// <<<--- keep type in sync with the body type(uint64).max !!!
		uint32 _nextId,	// <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _finalId,	// <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _saleStart,	// <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _saleEnd,	// <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _batchLimit,	// <<<--- keep type in sync with the body type(uint32).max !!!
		address _aliSource,	// <<<--- keep that in sync with the body type(uint160).max !!!
		uint96 _aliValue	// <<<--- keep type in sync with the body type(uint96).max !!!
	) public {
		// check the access permission
		require(isSenderInRole(ROLE_SALE_MANAGER), "access denied");

		// verify the inputs
		require(_nextId > 0, "zero nextId");
		// ALI source/value should be either both set or both unset
		// ALI value must not be too low if set
		require(_aliSource == address(0) && _aliValue == 0 || _aliSource != address(0) && _aliValue >= 1e12, "invalid ALI source/value");

		// no need to verify extra parameters - "incorrect" values will deactivate the sale

		// initialize contract state based on the values supplied
		// take into account our convention that value `-1` means "do not set"
		// 0xFFFFFFFFFFFFFFFF, 64 bits
		if(_itemPrice != type(uint64).max) {
			itemPrice = _itemPrice;
		}
		// 0xFFFFFFFF, 32 bits
		if(_nextId != type(uint32).max) {
			nextId = _nextId;
		}
		// 0xFFFFFFFF, 32 bits
		if(_finalId != type(uint32).max) {
			finalId = _finalId;
		}
		// 0xFFFFFFFF, 32 bits
		if(_saleStart != type(uint32).max) {
			saleStart = _saleStart;
		}
		// 0xFFFFFFFF, 32 bits
		if(_saleEnd != type(uint32).max) {
			saleEnd = _saleEnd;
		}
		// 0xFFFFFFFF, 32 bits
		if(_batchLimit != type(uint32).max) {
			batchLimit = _batchLimit;
		}
		// 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF and 0xFFFFFFFFFFFFFFFFFFFFFFFF, 160 and 96 bits
		if(uint160(_aliSource) != type(uint160).max && _aliValue != type(uint96).max) {
			aliSource = _aliSource;
			aliValue = _aliValue;
		}

		// emit an event - read values from the storage since not all of them might be set
		emit Initialized(
			msg.sender,
			itemPrice,
			nextId,
			finalId,
			saleStart,
			saleEnd,
			batchLimit,
			aliSource,
			aliValue
		);
	}

	/**
	 * @notice Buys several (at least two) iNFTs in a batch.
	 *      Accepts ETH as payment and creates iNFT with minted bound NFT and minted linked AI Personality
	 *
	 * @param _amount amount of iNFTs to create (same amount of NFTs and AI Personalities
	 *      will be created and bound/locked to iNFT), two or more
	 */
	function buy(uint32 _amount) public virtual payable {
		// delegate to `buyTo` with the transaction sender set to be a recipient
		buyTo(msg.sender, _amount);
	}

	/**
	 * @notice Buys several (at least two) iNFTs in a batch to an address specified.
	 *      Accepts ETH as payment and creates iNFT with minted bound NFT and minted linked AI Personality
	 *
	 * @param _to address to mint tokens and iNFTs to
	 * @param _amount amount of iNFTs to create (same amount of NFTs and AI Personalities
	 *      will be created and bound/locked to iNFT), two or more
	 */
	function buyTo(address _to, uint32 _amount) public virtual payable {
		// check the access permission
		require(isFeatureEnabled(FEATURE_PUBLIC_SALE) || isSenderInRole(ROLE_BUYER), "access denied");

		// verify the inputs
		require(_to != address(0), "recipient not set");
		require(_amount > 1 && (batchLimit == 0 || _amount <= batchLimit), "incorrect amount");

		// verify there is enough items available to buy the amount
		// verifies sale is in active state under the hood
		require(itemsAvailable() >= _amount, "inactive sale or not enough items available");

		// calculate the total price required and validate the transaction value
		uint256 totalPrice = uint256(itemPrice) * _amount;
		require(msg.value >= totalPrice, "not enough funds");

		// based on ALI value set on the contract and amount of iNFTs to create
		// calculate the cumulative ALI value to be sent to iNFT
		// note: cumulative ALI value may overflow uint96, store it into uint256 on stack
		uint256 _aliValue = uint256(aliValue) * _amount;
		// if it's not zero (that is if ALI token binding is enabled)
		if(_aliValue != 0) {
			// transfer ALI amount required to iNFT smart contract
			ERC20(aliContract).transferFrom(aliSource, iNftContract, _aliValue);
		}

		// mint NFTs to the recipient
		MintableERC721(nftContract).safeMintBatch(_to, nextId, _amount);

		// mint AI Personality directly to iNFT smart contract
		MintableERC721(personalityContract).mintBatch(iNftContract, nextId, _amount);

		// create iNFT bound to NFT minted and locking the AI Personality minted
		IntelligentNFTv2(iNftContract).mintBatch(
			nextId, // first recordId
			aliValue, // ALI value
			personalityContract, // AI Personality contract address
			nextId, // first AI Personality ID
			nftContract, // NFT contract address
			nextId, // first target NFT ID
			_amount // amount of iNFTs to create
		);

		// increment `nextId`
		nextId += _amount;
		// increment `soldCounter`
		soldCounter += _amount;

		// if ETH amount supplied exceeds the price
		if(msg.value > totalPrice) {
			// send excess amount back to sender
			payable(msg.sender).transfer(msg.value - totalPrice);
		}

		// emit en event
		emit Bought(msg.sender, _to, _amount, _aliValue, totalPrice);
	}

	/**
	 * @notice Buys single iNFTs.
	 *      Accepts ETH as payment and creates iNFT with minted bound NFT and minted linked AI Personality
	 */
	function buySingle() public virtual payable {
		// delegate to `buySingleTo` with the transaction sender set to be a recipient
		buySingleTo(msg.sender);
	}

	/**
	 * @notice Buys single iNFTs to an address specified.
	 *      Accepts ETH as payment and creates iNFT with minted bound NFT and minted linked AI Personality
	 *
	 * @param _to address to mint tokens and iNFT to
	 */
	function buySingleTo(address _to) public virtual payable {
		// check the access permission
		require(isFeatureEnabled(FEATURE_PUBLIC_SALE) || isSenderInRole(ROLE_BUYER), "access denied");

		// verify the inputs and transaction value
		require(_to != address(0), "recipient not set");
		require(msg.value >= itemPrice, "not enough funds");

		// verify sale is in active state
		require(isActive(), "inactive sale");

		// if ALI token binding is enabled
		if(aliValue != 0) {
			// transfer ALI amount required to iNFT smart contract
			ERC20(aliContract).transferFrom(aliSource, iNftContract, aliValue);
		}
		// mint NFT to the recipient
		MintableERC721(nftContract).safeMint(_to, nextId);
		// mint AI Personality directly to iNFT smart contract
		MintableERC721(personalityContract).mint(iNftContract, nextId);
		// create iNFT bound to NFT minted and locking the AI Personality minted
		IntelligentNFTv2(iNftContract).mint(nextId, aliValue, personalityContract, nextId, nftContract, nextId);

		// increment `nextId`
		nextId++;
		// increment `soldCounter`
		soldCounter++;

		// if ETH amount supplied exceeds the price
		if(msg.value > itemPrice) {
			// send excess amount back to sender
			payable(msg.sender).transfer(msg.value - itemPrice);
		}

		// emit en event
		emit Bought(msg.sender, _to, 1, aliValue, itemPrice);
	}

	/**
	 * @dev Restricted access function to withdraw ETH on the contract balance,
	 *      sends ETH back to transaction sender
	 */
	function withdraw() public {
		// delegate to `withdrawTo`
		withdrawTo(msg.sender);
	}

	/**
	 * @dev Restricted access function to withdraw ETH on the contract balance,
	 *      sends ETH to the address specified
	 *
	 * @param _to an address to send ETH to
	 */
	function withdrawTo(address _to) public {
		// check the access permission
		require(isSenderInRole(ROLE_WITHDRAWAL_MANAGER), "access denied");

		// verify withdrawal address is set
		require(_to != address(0), "address not set");

		// ETH value to send
		uint256 _value = address(this).balance;

		// verify sale balance is positive (non-zero)
		require(_value > 0, "zero balance");

		// send the entire balance to the transaction sender
		payable(_to).transfer(_value);

		// emit en event
		emit Withdrawn(msg.sender, _to, _value);
	}

	/**
	 * @dev Testing time-dependent functionality may be difficult;
	 *      we override time in the helper test smart contract (mock)
	 *
	 * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
	 */
	function now256() public view virtual returns (uint256) {
		// return current block timestamp
		return block.timestamp;
	}
}
