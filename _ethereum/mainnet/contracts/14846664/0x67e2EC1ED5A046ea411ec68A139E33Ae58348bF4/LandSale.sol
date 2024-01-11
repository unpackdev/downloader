// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Spec.sol";
import "./ERC721Spec.sol";
import "./ERC721SpecExt.sol";
import "./LandERC721Spec.sol";
import "./IdentifiableSpec.sol";
import "./PriceOracleSpec.sol";
import "./LandLib.sol";
import "./SafeERC20.sol";
import "./UpgradeableAccessControl.sol";
import "./MerkleProof.sol";

/**
 * @title Land Sale
 *
 * @notice Enables the Land NFT sale via dutch auction mechanism
 *
 * @notice The proposed volume of land is approximately 100,000 plots, split amongst the 7 regions.
 *      The volume is released over a series of staggered sales with the first sale featuring
 *      about 20,000 land plots (tokens).
 *
 * @notice Land plots are sold in sequences, each sequence groups tokens which are sold in parallel.
 *      Sequences start selling one by one with the configurable time interval between their start.
 *      A sequence is available for a sale for a fixed (configurable) amount of time, meaning they
 *      can overlap (tokens from several sequences are available on sale simultaneously) if this
 *      amount of time is bigger than interval between sequences start.
 *
 * @notice The sale operates in a configurable time interval which should be aligned with the
 *      total number of sequences, their duration, and start interval.
 *      Sale smart contract has no idea of the total number of sequences and doesn't validate
 *      if these timings are correctly aligned.
 *
 * @notice Starting prices of the plots are defined by the plot tier in ETH, and are configurable
 *      within the sale contract per tier ID.
 *      Token price declines over time exponentially, price halving time is configurable.
 *      The exponential price decline simulates the price drop requirement which may be formulated
 *      something like "the price drops by 'x' % every 'y' minutes".
 *      For example, if x = 2, and y = 1, "the price drops by 2% every minute", the halving
 *      time is around 34 minutes.
 *
 * @notice Sale accepts ETH and sILV as a payment currency, sILV price is supplied by on-chain
 *      price oracle (sILV price is assumed to be equal to ILV price)
 *
 * @notice The data required to mint a plot includes (see `PlotData` struct):
 *      - token ID, defines a unique ID for the land plot used as ERC721 token ID
 *      - sequence ID, defines the time frame when the plot is available for sale
 *      - region ID (1 - 7), determines which tileset to use in game,
 *      - coordinates (x, y) on the overall world map, indicating which grid position the land sits in,
 *      - tier ID (1 - 5), the rarity of the land, tier is used to create the list of sites,
 *      - size (w, h), defines an internal coordinate system within a plot,
 *
 * @notice Since minting a plot requires at least 32 bytes of data and due to a significant
 *      amount of plots to be minted (about 100,000), pre-storing this data on-chain
 *      is not a viable option (2,000,000,000 of gas only to pay for the storage).
 *      Instead, we represent the whole land plot data collection on sale as a Merkle tree
 *      structure and store the root of the Merkle tree on-chain.
 *      To buy a particular plot, the buyer must know the entire collection and be able to
 *      generate and present the Merkle proof for this particular plot.
 *
 * @notice The input data is a collection of `PlotData` structures; the Merkle tree is built out
 *      from this collection, and the tree root is stored on the contract by the data manager.
 *      When buying a plot, the buyer also specifies the Merkle proof for a plot data to mint.
 *
 * @notice Layer 2 support (ex. IMX minting)
 *      Sale contract supports both L1 and L2 sales.
 *      L1 sale mints the token in layer 1 network (Ethereum mainnet) immediately,
 *      in the same transaction it is bought.
 *      L2 sale doesn't mint the token and just emits an event containing token metadata and owner;
 *      this event is then picked by the off-chain process (daemon) which mints the token in a
 *      layer 2 network (IMX, https://www.immutable.com/)
 *
 * @dev A note on randomness
 *      Current implementation uses "on-chain randomness" to mint a land plot, which is calculated
 *      as a keccak256 hash of some available parameters, like token ID, buyer address, and block
 *      timestamp.
 *      This can be relatively easy manipulated not only by miners, but even by clients wrapping
 *      their transactions into the smart contract code when buying (calling a `buy` function).
 *      It is considered normal and acceptable from the security point of view since the value
 *      of such manipulation is low compared to the transaction cost.
 *      This situation can change, however, in the future sales when more information on the game
 *      is available, and when it becomes more clear how resource types and their positions
 *      affect the game mechanics, and can be used to benefit players.
 *
 * @dev A note on timestamps
 *      Current implementation uses uint32 to represent unix timestamp, and time intervals,
 *      it is not designed to be used after February 7, 2106, 06:28:15 GMT (unix time 0xFFFFFFFF)
 *
 * @dev Merkle proof verification is based on OpenZeppelin implementation, see
 *      https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
 *
 * @author Basil Gorin
 */
contract LandSale is UpgradeableAccessControl {
	// using ERC20.transfer wrapper from OpenZeppelin adopted SafeERC20
	using SafeERC20 for ERC20;
	// Use Zeppelin MerkleProof Library to verify Merkle proofs
	using MerkleProof for bytes32[];
	// Use Land Library to pack `PlotStore` struct to uint256
	using LandLib for LandLib.PlotStore;

	/**
	 * @title Plot Data, a.k.a. Sale Data
	 *
	 * @notice Data structure modeling the data entry required to mint a single plot.
	 *      The contract is initialized with the Merkle root of the plots collection Merkle tree.
	 * @dev When buying a plot this data structure must be supplied together with the
	 *      Merkle proof allowing to verify the plot data belongs to the original collection.
	 */
	struct PlotData {
		/// @dev Token ID, defines a unique ID for the land plot used as ERC721 token ID
		uint32 tokenId;
		/// @dev Sequence ID, defines the time frame when the plot is available for sale
		uint32 sequenceId;
		/// @dev Region ID defines the region on the map in IZ
		uint8 regionId;
		/// @dev x-coordinate within the region plot
		uint16 x;
		/// @dev y-coordinate within the region plot
		uint16 y;
		/// @dev Tier ID defines land rarity and number of sites within the plot
		uint8 tierId;
		/// @dev Plot size, limits the (x, y) coordinates for the sites
		uint16 size;
	}

	/**
	 * @notice Deployed LandERC721 token address to mint tokens of
	 *      (when they are bought via the sale)
	 */
	address public targetNftContract;

	/**
	 * @notice Deployed sILV (Escrowed Illuvium) ERC20 token address,
	 *      accepted as a payment option alongside ETH
	 * @dev Note: sILV ERC20 implementation never returns "false" on transfers,
	 *      it throws instead; we don't use any additional libraries like SafeERC20
	 *      to transfer sILV therefore
	 */
	address public sIlvContract;

	/**
	 * @notice Land Sale Price Oracle is used to convert the token prices from USD
	 *      to ETH or sILV (ILV)
	 */
	address public priceOracle;

	/**
	 * @notice Input data root, Merkle tree root for the collection of plot data elements,
	 *      available on sale
	 *
	 * @notice Merkle root effectively "compresses" the (potentially) huge collection of elements
	 *      and allows to store it in a single 256-bits storage slot on-chain
	 */
	bytes32 public root;

	/**
	 * @dev Sale start unix timestamp, scheduled sale start, the time when the sale
	 *      is scheduled to start, this is the time when sale activates,
	 *      the time when the first sequence sale starts, that is
	 *      when tokens of the first sequence become available on sale
	 * @dev The sale is active after the start (inclusive)
	 */
	uint32 public saleStart;

	/**
	 * @dev Sale end unix timestamp, this is the time when sale deactivates,
	 *      and tokens of the last sequence become unavailable
	 * @dev The sale is active before the end (exclusive)
	 */
	uint32 public saleEnd;

	/**
	 * @dev Price halving time, the time required for a token price to reduce to the
	 *      half of its initial value
	 * @dev Defined in seconds
	 */
	uint32 public halvingTime;

	/**
	 * @dev Time flow quantum, price update interval, used by the price calculation algorithm,
	 *      the time is rounded down to be multiple of quantum when performing price calculations;
	 *      setting this value to one effectively disables its effect;
	 * @dev Defined in seconds
	 */
	uint32 public timeFlowQuantum;

	/**
	 * @dev Sequence duration, time limit of how long a token / sequence can be available
	 *      for sale, first sequence stops selling at `saleStart + seqDuration`, second
	 *      sequence stops selling at `saleStart + seqOffset + seqDuration`, and so on
	 * @dev Defined in seconds
	 */
	uint32 public seqDuration;

	/**
	 * @dev Sequence start offset, first sequence starts selling at `saleStart`,
	 *      second sequence starts at `saleStart + seqOffset`, third at
	 *      `saleStart + 2 * seqOffset` and so on at `saleStart + n * seqOffset`,
	 *      where `n` is zero-based sequence ID
	 * @dev Defined in seconds
	 */
	uint32 public seqOffset;

	/**
	 * @dev Sale paused unix timestamp, the time when sale was paused,
	 *     non-zero value indicates that the sale is currently in a paused state
	 *     and is not operational
	 *
	 * @dev Pausing a sale effectively pauses "own time" of the sale, this is achieved
	 *     by tracking cumulative sale pause duration (see `pauseDuration`) and taking it
	 *     into account when evaluating current sale time, prices, sequences on sale, etc.
	 *
	 * @dev Erased (set to zero) when sale start time is modified (see initialization, `initialize()`)
	 */
	uint32 public pausedAt;

	/**
	 * @dev Cumulative sale pause duration, total amount of time sale stayed in a paused state
	 *      since the last time sale start time was set (see initialization, `initialize()`)
	 *
	 * @dev Is increased only when sale is resumed back from the paused state, is not updated
	 *      when the sale is in a paused state
	 *
	 * @dev Defined in seconds
	 */
	uint32 public pauseDuration;

	/**
	 * @dev Tier start prices, starting token price for each (zero based) Tier ID,
	 *      defined in ETH, can be converted into sILV via Uniswap/Sushiswap price oracle,
	 *      sILV price is defined to be equal to ILV price
	 */
	uint96[] public startPrices;

	/**
	 * @dev Sale beneficiary address, if set - used to send funds obtained from the sale;
	 *      If not set - contract accumulates the funds on its own deployed address
	 */
	address payable public beneficiary;

	/**
	 * @dev A bitmap of minted tokens, required to support L2 sales:
	 *      when token is not minted in L1 we still need to track it was sold using this bitmap
	 *
	 * @dev Bitmap is stored as an array of uint256 data slots, each slot holding
	 *     256 bits of the entire bitmap.
	 *     An array itself is stored as a mapping with a zero-index integer key.
	 *     Each mapping entry represents the state of 256 tokens (each bit corresponds to a
	 *     single token)
	 *
	 * @dev For a token ID `n`,
	 *      the data slot index `i` is `n / 256`,
	 *      and bit index within a slot `j` is `n % 256`
	 */
	mapping(uint256 => uint256) public mintedTokens;

	/**
	 * @notice Enables the L1 sale, buying tokens in L1 public function
	 *
	 * @notice Note: sale could be activated/deactivated by either sale manager, or
	 *      data manager, since these roles control sale params, and items on sale;
	 *      However both sale and data managers require some advanced knowledge about
	 *      the use of the functions they trigger, while switching the "sale active"
	 *      flag is very simple and can be done much more easier
	 *
	 * @dev Feature FEATURE_L1_SALE_ACTIVE must be enabled in order for
	 *      `buyL1()` function to be able to succeed
	 */
	uint32 public constant FEATURE_L1_SALE_ACTIVE = 0x0000_0001;

	/**
	 * @notice Enables the L2 sale, buying tokens in L2 public function
	 *
	 * @notice Note: sale could be activated/deactivated by either sale manager, or
	 *      data manager, since these roles control sale params, and items on sale;
	 *      However both sale and data managers require some advanced knowledge about
	 *      the use of the functions they trigger, while switching the "sale active"
	 *      flag is very simple and can be done much more easier
	 *
	 * @dev Feature FEATURE_L2_SALE_ACTIVE must be enabled in order for
	 *      `buyL2()` function to be able to succeed
	 */
	uint32 public constant FEATURE_L2_SALE_ACTIVE = 0x0000_0002;

	/**
	 * @notice Pause manager is responsible for:
	 *      - sale pausing (pausing/resuming the sale in case of emergency)
	 *
	 * @dev Role ROLE_PAUSE_MANAGER allows sale pausing/resuming via pause() / resume()
	 */
	uint32 public constant ROLE_PAUSE_MANAGER = 0x0001_0000;

	/**
	 * @notice Data manager is responsible for supplying the valid input plot data collection
	 *      Merkle root which then can be used to mint tokens, meaning effectively,
	 *      that data manager may act as a minter on the target NFT contract
	 *
	 * @dev Role ROLE_DATA_MANAGER allows setting the Merkle tree root via setInputDataRoot()
	 */
	uint32 public constant ROLE_DATA_MANAGER = 0x0002_0000;

	/**
	 * @notice Sale manager is responsible for:
	 *      - sale initialization (setting up sale timing/pricing parameters)
	 *
	 * @dev Role ROLE_SALE_MANAGER allows sale initialization via initialize()
	 */
	uint32 public constant ROLE_SALE_MANAGER = 0x0004_0000;

	/**
	 * @notice People do mistake and may send ERC20 tokens by mistake; since
	 *      NFT smart contract is not designed to accept and hold any ERC20 tokens,
	 *      it allows the rescue manager to "rescue" such lost tokens
	 *
	 * @notice Rescue manager is responsible for "rescuing" ERC20 tokens accidentally
	 *      sent to the smart contract, except the sILV which is a payment token
	 *      and can be withdrawn by the withdrawal manager only
	 *
	 * @dev Role ROLE_RESCUE_MANAGER allows withdrawing any ERC20 tokens stored
	 *      on the smart contract balance
	 */
	uint32 public constant ROLE_RESCUE_MANAGER = 0x0008_0000;

	/**
	 * @notice Withdrawal manager is responsible for withdrawing funds obtained in sale
	 *      from the sale smart contract via pull/push mechanisms:
	 *      1) Pull: no pre-setup is required, withdrawal manager executes the
	 *         withdraw function periodically to withdraw funds
	 *      2) Push: withdrawal manager sets the `beneficiary` address which is used
	 *         by the smart contract to send funds to when users purchase land NFTs
	 *
	 * @dev Role ROLE_WITHDRAWAL_MANAGER allows to set the `beneficiary` address via
	 *      - setBeneficiary()
	 * @dev Role ROLE_WITHDRAWAL_MANAGER allows pull withdrawals of funds:
	 *      - withdraw()
	 *      - withdrawTo()
	 */
	uint32 public constant ROLE_WITHDRAWAL_MANAGER = 0x0010_0000;

	/**
	 * @dev Fired in setInputDataRoot()
	 *
	 * @param _by an address which executed the operation
	 * @param _root new Merkle root value
	 */
	event RootChanged(address indexed _by, bytes32 _root);

	/**
	 * @dev Fired in initialize()
	 *
	 * @param _by an address which executed the operation
	 * @param _saleStart sale start unix timestamp, and first sequence start time
	 * @param _saleEnd sale end unix timestamp, should match with the last sequence end time
	 * @param _halvingTime price halving time (seconds), the time required for a token price
	 *      to reduce to the half of its initial value
	 * @param _timeFlowQuantum time flow quantum (seconds), price update interval, used by
	 *      the price calculation algorithm to update prices
	 * @param _seqDuration sequence duration (seconds), time limit of how long a token / sequence
	 *      can be available for sale
	 * @param _seqOffset sequence start offset (seconds), each sequence starts `_seqOffset`
	 *      later after the previous one
	 * @param _startPrices tier start prices (wei), starting token price for each (zero based) Tier ID
	 */
	event Initialized(
		address indexed _by,
		uint32 _saleStart,
		uint32 _saleEnd,
		uint32 _halvingTime,
		uint32 _timeFlowQuantum,
		uint32 _seqDuration,
		uint32 _seqOffset,
		uint96[] _startPrices
	);

	/**
	 * @dev Fired in pause()
	 *
	 * @param _by an address which executed the operation
	 * @param _pausedAt when the sale was paused (unix timestamp)
	 */
	event Paused(address indexed _by, uint32 _pausedAt);

	/**
	 * @dev Fired in resume(), optionally in initialize() (only if sale start is changed)
	 *
	 * @param _by an address which executed the operation
	 * @param _pausedAt when the sale was paused (unix timestamp)
	 * @param _resumedAt when the sale was resumed (unix timestamp)
	 * @param _pauseDuration cumulative sale pause duration (seconds)
	 */
	event Resumed(address indexed _by, uint32 _pausedAt, uint32 _resumedAt, uint32 _pauseDuration);

	/**
	 * @dev Fired in setBeneficiary
	 *
	 * @param _by an address which executed the operation
	 * @param _beneficiary new beneficiary address or zero-address
	 */
	event BeneficiaryUpdated(address indexed _by, address indexed _beneficiary);

	/**
	 * @dev Fired in withdraw() and withdrawTo()
	 *
	 * @param _by an address which executed the operation
	 * @param _to an address which received the funds withdrawn
	 * @param _eth amount of ETH withdrawn (wei)
	 * @param _sIlv amount of sILV withdrawn (wei)
	 */
	event Withdrawn(address indexed _by, address indexed _to, uint256 _eth, uint256 _sIlv);

	/**
	 * @dev Fired in buyL1()
	 *
	 * @param _by an address which had bought the plot
	 * @param _tokenId Token ID, part of the off-chain plot metadata supplied externally
	 * @param _sequenceId Sequence ID, part of the off-chain plot metadata supplied externally
	 * @param _plot on-chain plot metadata minted token, contains values copied from off-chain
	 *      plot metadata supplied externally, and generated values such as seed
	 * @param _eth ETH price of the lot (wei, non-zero)
	 * @param _sIlv sILV price of the lot (wei, zero if paid in ETH)
	 */
	event PlotBoughtL1(
		address indexed _by,
		uint32 indexed _tokenId,
		uint32 indexed _sequenceId,
		LandLib.PlotStore _plot,
		uint256 _eth,
		uint256 _sIlv
	);

	/**
	 * @dev Fired in buyL2()
	 *
	 * @param _by an address which had bought the plot
	 * @param _tokenId Token ID, part of the off-chain plot metadata supplied externally
	 * @param _sequenceId Sequence ID, part of the off-chain plot metadata supplied externally
	 * @param _plot on-chain plot metadata minted token, contains values copied from off-chain
	 *      plot metadata supplied externally, and generated values such as seed
	 * @param _eth ETH price of the lot (wei, non-zero)
	 * @param _sIlv sILV price of the lot (wei, zero if paid in ETH)
	 */
	event PlotBoughtL2(
		address indexed _by,
		uint32 indexed _tokenId,
		uint32 indexed _sequenceId,
		LandLib.PlotStore _plot,
		uint256 _plotPacked,
		uint256 _eth,
		uint256 _sIlv
	);

	/**
	 * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @dev Binds the sale smart contract instance to
	 *      1) the target NFT smart contract address to be used to mint tokens (Land ERC721),
	 *      2) sILV (Escrowed Illuvium) contract address to be used as one of the payment options
	 *      3) Price Oracle contract address to be used to determine ETH/sILV price
	 *
	 * @param _nft target NFT smart contract address
	 * @param _sIlv sILV (Escrowed Illuvium) contract address
	 * @param _oracle price oracle contract address
	 */
	function postConstruct(address _nft, address _sIlv, address _oracle) public virtual initializer {
		// verify the inputs are set
		require(_nft != address(0), "target contract is not set");
		require(_sIlv != address(0), "sILV contract is not set");
		require(_oracle != address(0), "oracle address is not set");

		// verify the inputs are valid smart contracts of the expected interfaces
		require(
			ERC165(_nft).supportsInterface(type(ERC721).interfaceId)
			&& ERC165(_nft).supportsInterface(type(MintableERC721).interfaceId)
			&& ERC165(_nft).supportsInterface(type(LandERC721Metadata).interfaceId),
			// note: ImmutableMintableERC721 is not required by the sale
			"unexpected target type"
		);
		require(ERC165(_oracle).supportsInterface(type(LandSalePriceOracle).interfaceId), "unexpected oracle type");
		// for the sILV ERC165 check is unavailable, but we can check some ERC20 functions manually
		require(ERC20(_sIlv).balanceOf(address(this)) < type(uint256).max, "sILV.balanceOf failure");
		require(ERC20(_sIlv).transfer(address(0x1), 0), "sILV.transfer failure");
		require(ERC20(_sIlv).transferFrom(address(this), address(0x1), 0), "sILV.transferFrom failure");

		// assign the addresses
		targetNftContract = _nft;
		sIlvContract = _sIlv;
		priceOracle = _oracle;

		// execute all parent initializers in cascade
		UpgradeableAccessControl._postConstruct(msg.sender);
	}

	/**
	 * @dev `startPrices` getter; the getters solidity creates for arrays
	 *      may be inconvenient to use if we need an entire array to be read
	 *
	 * @return `startPrices` as is - as an array of uint96
	 */
	function getStartPrices() public view virtual returns (uint96[] memory) {
		// read `startPrices` array into memory and return
		return startPrices;
	}

	/**
	 * @notice Restricted access function to update input data root (Merkle tree root),
	 *       and to define, effectively, the tokens to be created by this smart contract
	 *
	 * @dev Requires executor to have `ROLE_DATA_MANAGER` permission
	 *
	 * @param _root Merkle tree root for the input plot data collection
	 */
	function setInputDataRoot(bytes32 _root) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_DATA_MANAGER), "access denied");

		// update input data Merkle tree root
		root = _root;

		// emit an event
		emit RootChanged(msg.sender, _root);
	}

	/**
	 * @notice Verifies the validity of a plot supplied (namely, if it's registered for the sale)
	 *      based on the Merkle root of the plot data collection (already defined on the contract),
	 *      and the Merkle proof supplied to validate the particular plot data
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the plot data collection elements via `web3.utils.soliditySha3`, making sure
	 *         the packing order and types are exactly as defined in `PlotData` struct
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed collection, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given plot data element the proof is constructed by hashing it (as in step 1),
	 *         and querying the MerkleTree for a proof, providing the hashed plot data element as a leaf
	 *
	 * @dev See also: https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
	 *
	 * @param plotData plot data to verify
	 * @param proof Merkle proof for the plot data supplied
	 * @return true if plot is valid (belongs to registered collection), false otherwise
	 */
	function isPlotValid(PlotData memory plotData, bytes32[] memory proof) public view virtual returns (bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(
				plotData.tokenId,
				plotData.sequenceId,
				plotData.regionId,
				plotData.x,
				plotData.y,
				plotData.tierId,
				plotData.size
			));

		// verify the proof supplied, and return the verification result
		return proof.verify(root, leaf);
	}

	/**
	 * @dev Restricted access function to set up sale parameters, all at once,
	 *      or any subset of them
	 *
	 * @dev To skip parameter initialization, set it to `-1`,
	 *      that is a maximum value for unsigned integer of the corresponding type;
	 *      for `_startPrices` use a single array element with the `-1` value to skip
	 *
	 * @dev Example: following initialization will update only `_seqDuration` and `_seqOffset`,
	 *      leaving the rest of the fields unchanged
	 *      initialize(
	 *          0xFFFFFFFF, // `_saleStart` unchanged
	 *          0xFFFFFFFF, // `_saleEnd` unchanged
	 *          0xFFFFFFFF, // `_halvingTime` unchanged
	 *          21600,      // `_seqDuration` updated to 6 hours
	 *          3600,       // `_seqOffset` updated to 1 hour
	 *          [0xFFFFFFFFFFFFFFFFFFFFFFFF] // `_startPrices` unchanged
	 *      )
	 *
	 * @dev Sale start and end times should match with the number of sequences,
	 *      sequence duration and offset, if `n` is number of sequences, then
	 *      the following equation must hold:
	 *         `saleStart + (n - 1) * seqOffset + seqDuration = saleEnd`
	 *      Note: `n` is unknown to the sale contract and there is no way for it
	 *      to accurately validate other parameters of the equation above
	 *
	 * @dev Input params are not validated; to get an idea if these params look valid,
	 *      refer to `isActive() `function, and it's logic
	 *
	 * @dev Requires transaction sender to have `ROLE_SALE_MANAGER` role
	 *
	 * @param _saleStart sale start unix timestamp, and first sequence start time
	 * @param _saleEnd sale end unix timestamp, should match with the last sequence end time
	 * @param _halvingTime price halving time (seconds), the time required for a token price
	 *      to reduce to the half of its initial value
	 * @param _timeFlowQuantum time flow quantum (seconds), price update interval, used by
	 *      the price calculation algorithm to update prices
	 * @param _seqDuration sequence duration (seconds), time limit of how long a token / sequence
	 *      can be available for sale
	 * @param _seqOffset sequence start offset (seconds), each sequence starts `_seqOffset`
	 *      later after the previous one
	 * @param _startPrices tier start prices (wei), starting token price for each (zero based) Tier ID
	 */
	function initialize(
		uint32 _saleStart,           // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _saleEnd,             // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _halvingTime,         // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _timeFlowQuantum,     // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _seqDuration,         // <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _seqOffset,           // <<<--- keep type in sync with the body type(uint32).max !!!
		uint96[] memory _startPrices // <<<--- keep type in sync with the body type(uint96).max !!!
	) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_SALE_MANAGER), "access denied");

		// Note: no input validation at this stage, initial params state is invalid anyway,
		//       and we're not limiting sale manager to set these params back to this state

		// set/update sale parameters (allowing partial update)
		// 0xFFFFFFFF, 32 bits
		if(_saleStart != type(uint32).max) {
			// update the sale start itself, and
			saleStart = _saleStart;

			// if the sale is in paused state (non-zero `pausedAt`)
			if(pausedAt != 0) {
				// emit an event first - to log old `pausedAt` value
				emit Resumed(msg.sender, pausedAt, now32(), pauseDuration + now32() - pausedAt);

				// erase `pausedAt`, effectively resuming the sale
				pausedAt = 0;
			}

			// erase the cumulative pause duration
			pauseDuration = 0;
		}
		// 0xFFFFFFFF, 32 bits
		if(_saleEnd != type(uint32).max) {
			saleEnd = _saleEnd;
		}
		// 0xFFFFFFFF, 32 bits
		if(_halvingTime != type(uint32).max) {
			halvingTime = _halvingTime;
		}
		// 0xFFFFFFFF, 32 bits
		if(_timeFlowQuantum != type(uint32).max) {
			timeFlowQuantum = _timeFlowQuantum;
		}
		// 0xFFFFFFFF, 32 bits
		if(_seqDuration != type(uint32).max) {
			seqDuration = _seqDuration;
		}
		// 0xFFFFFFFF, 32 bits
		if(_seqOffset != type(uint32).max) {
			seqOffset = _seqOffset;
		}
		// 0xFFFFFFFFFFFFFFFFFFFFFFFF, 96 bits
		if(_startPrices.length != 1 || _startPrices[0] != type(uint96).max) {
			startPrices = _startPrices;
		}

		// emit an event
		emit Initialized(msg.sender, saleStart, saleEnd, halvingTime, timeFlowQuantum, seqDuration, seqOffset, startPrices);
	}

	/**
	 * @notice Verifies if sale is in the active state, meaning that it is properly
	 *      initialized with the sale start/end times, sequence params, etc., and
	 *      that the current time is within the sale start/end bounds
	 *
	 * @notice Doesn't check if the plot data Merkle root `root` is set or not;
	 *      active sale state doesn't guarantee that an item can be actually bought
	 *
	 * @dev The sale is defined as active if all of the below conditions hold:
	 *      - sale start is now or in the past
	 *      - sale end is in the future
	 *      - halving time is not zero
	 *      - sequence duration is not zero
	 *      - there is at least one starting price set (zero price is valid)
	 *
	 * @return true if sale is active, false otherwise
	 */
	function isActive() public view virtual returns (bool) {
		// calculate sale state based on the internal sale params state and return
		return pausedAt == 0
			&& saleStart <= ownTime()
			&& ownTime() < saleEnd
			&& halvingTime > 0
			&& timeFlowQuantum > 0
			&& seqDuration > 0
			&& startPrices.length > 0;
	}

	/**
	 * @dev Restricted access function to pause running sale in case of emergency
	 *
	 * @dev Pausing/resuming doesn't affect sale "own time" and allows to resume the
	 *      sale process without "loosing" any items due to the time passed when paused
	 *
	 * @dev The sale is resumed using `resume()` function
	 *
	 * @dev Requires transaction sender to have `ROLE_PAUSE_MANAGER` role
	 */
	function pause() public virtual {
		// check the access permission
		require(isSenderInRole(ROLE_PAUSE_MANAGER), "access denied");

		// check if sale is not in the paused state already
		require(pausedAt == 0, "already paused");

		// do the pause, save the paused timestamp
		// note for tests: never set time to zero in tests
		pausedAt = now32();

		// emit an event
		emit Paused(msg.sender, now32());
	}

	/**
	 * @dev Restricted access function to resume previously paused sale
	 *
	 * @dev Pausing/resuming doesn't affect sale "own time" and allows to resume the
	 *      sale process without "loosing" any items due to the time passed when paused
	 *
	 * @dev Resuming the sale before it is scheduled to start doesn't have any effect
	 *      on the sale flow, and doesn't delay the sale start
	 *
	 * @dev Resuming the sale which was paused before the scheduled start delays the sale,
	 *      and moves scheduled sale start by the amount of time it was paused after the
	 *      original scheduled start
	 *
	 * @dev The sale is paused using `pause()` function
	 *
	 * @dev Requires transaction sender to have `ROLE_PAUSE_MANAGER` role
	 */
	function resume() public virtual {
		// check the access permission
		require(isSenderInRole(ROLE_PAUSE_MANAGER), "access denied");

		// check if the sale is in a paused state
		require(pausedAt != 0, "already running");

		// if sale has already started
		if(now32() > saleStart) {
			// update the cumulative sale pause duration, taking into account that
			// if sale was paused before its planned start, pause duration counts only from the start
			// note: we deliberately subtract `pausedAt` from the current time first
			// to fail fast if `pausedAt` is bigger than current time (this can never happen by design)
			pauseDuration += now32() - (pausedAt < saleStart? saleStart: pausedAt);
		}

		// emit an event first - to log old `pausedAt` value
		emit Resumed(msg.sender, pausedAt, now32(), pauseDuration);

		// do the resume, erase the paused timestamp
		pausedAt = 0;
	}

	/**
	 * @dev Restricted access function to update the sale beneficiary address, the address
	 *      can be set, updated, or "unset" (deleted, set to zero)
	 *
	 * @dev Setting the address to non-zero value effectively activates funds withdrawal
	 *      mechanism via the push pattern
	 *
	 * @dev Setting the address to zero value effectively deactivates funds withdrawal
	 *      mechanism via the push pattern (pull mechanism can be used instead)
	 */
	function setBeneficiary(address payable _beneficiary) public virtual {
		// check the access permission
		require(isSenderInRole(ROLE_WITHDRAWAL_MANAGER), "access denied");

		// update the beneficiary address
		beneficiary = _beneficiary;

		// emit an event
		emit BeneficiaryUpdated(msg.sender, _beneficiary);
	}

	/**
	 * @dev Restricted access function to withdraw funds on the contract balance,
	 *      sends funds back to transaction sender
	 *
	 * @dev Withdraws both ETH and sILV balances if `_ethOnly` is set to false,
	 *      withdraws only ETH is `_ethOnly` is set to true
	 *
	 * @param _ethOnly a flag indicating whether to withdraw sILV or not
	 */
	function withdraw(bool _ethOnly) public virtual {
		// delegate to `withdrawTo`
		withdrawTo(payable(msg.sender), _ethOnly);
	}

	/**
	 * @dev Restricted access function to withdraw funds on the contract balance,
	 *      sends funds to the address specified
	 *
	 * @dev Withdraws both ETH and sILV balances if `_ethOnly` is set to false,
	 *      withdraws only ETH is `_ethOnly` is set to true
	 *
	 * @param _to an address to send funds to
	 * @param _ethOnly a flag indicating whether to withdraw sILV or not
	 */
	function withdrawTo(address payable _to, bool _ethOnly) public virtual {
		// check the access permission
		require(isSenderInRole(ROLE_WITHDRAWAL_MANAGER), "access denied");

		// verify withdrawal address is set
		require(_to != address(0), "recipient not set");

		// ETH value to send
		uint256 ethBalance = address(this).balance;

		// sILV value to send
		uint256 sIlvBalance = _ethOnly? 0: ERC20(sIlvContract).balanceOf(address(this));

		// verify there is a balance to send
		require(ethBalance > 0 || sIlvBalance > 0, "zero balance");

		// if there is ETH to send
		if(ethBalance > 0) {
			// send the entire balance to the address specified
			_to.transfer(ethBalance);
		}

		// if there is sILV to send
		if(sIlvBalance > 0) {
			// send the entire balance to the address specified
			ERC20(sIlvContract).transfer(_to, sIlvBalance);
		}

		// emit en event
		emit Withdrawn(msg.sender, _to, ethBalance, sIlvBalance);
	}

	/**
	 * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
	 *      the tokens are rescued via `transfer` function call on the
	 *      contract address specified and with the parameters specified:
	 *      `_contract.transfer(_to, _value)`
	 *
	 * @dev Doesn't allow to rescue sILV tokens, use withdraw/withdrawTo instead
	 *
	 * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
	 *
	 * @param _contract smart contract address to execute `transfer` function on
	 * @param _to to address in `transfer(_to, _value)`
	 * @param _value value to transfer in `transfer(_to, _value)`
	 */
	function rescueErc20(address _contract, address _to, uint256 _value) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

		// verify rescue manager is not trying to withdraw sILV:
		// we have a withdrawal manager to help with that
		require(_contract != sIlvContract, "sILV access denied");

		// perform the transfer as requested, without any checks
		ERC20(_contract).safeTransfer(_to, _value);
	}

	/**
	 * @notice Determines the dutch auction price value for a token in a given
	 *      sequence `sequenceId`, given tier `tierId`, now (block.timestamp)
	 *
	 * @dev Adjusts current time for the sale pause duration `pauseDuration`, using
	 *      own time `ownTime()`
	 *
	 * @dev Throws if `now` is outside the [saleStart, saleEnd + pauseDuration) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 * @return current price of the token specified
	 */
	function tokenPriceNow(uint32 sequenceId, uint16 tierId) public view virtual returns (uint256) {
		// delegate to `tokenPriceAt` using adjusted current time as `t`
		return tokenPriceAt(sequenceId, tierId, ownTime());
	}

	/**
	 * @notice Determines the dutch auction price value for a token in a given
	 *      sequence `sequenceId`, given tier `tierId`, at a given time `t` (own time)
	 *
	 * @dev Throws if `t` is outside the [saleStart, saleEnd) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 * @param t unix timestamp of interest, time to evaluate the price at (own time)
	 * @return price of the token specified at some unix timestamp `t` (own time)
	 */
	function tokenPriceAt(uint32 sequenceId, uint16 tierId, uint32 t) public view virtual returns (uint256) {
		// calculate sequence sale start
		uint32 seqStart = saleStart + sequenceId * seqOffset;
		// calculate sequence sale end
		uint32 seqEnd = seqStart + seqDuration;

		// verify `t` is in a reasonable bounds [saleStart, saleEnd)
		require(saleStart <= t && t < saleEnd, "invalid time");

		// ensure `t` is in `[seqStart, seqEnd)` bounds; no price exists outside the bounds
		require(seqStart <= t && t < seqEnd, "invalid sequence");

		// verify the initial price is set (initialized) for the tier specified
		require(startPrices.length > tierId, "invalid tier");

		// convert `t` from "absolute" to "relative" (within a sequence)
		t -= seqStart;

		// apply the time flow quantum: make `t` multiple of quantum
		t /= timeFlowQuantum;
		t *= timeFlowQuantum;

		// calculate the price based on the derived params - delegate to `price`
		return price(startPrices[tierId], halvingTime, t);
	}

	/**
	 * @dev Calculates dutch auction price after the time of interest has passed since
	 *      the auction has started
	 *
	 * @dev The price is assumed to drop exponentially, according to formula:
	 *      p(t) = p0 * 2^(-t/t0)
	 *      The price halves every t0 seconds passed from the start of the auction
	 *
	 * @dev Calculates with the precision p0 * 2^(-1/256), meaning the price updates
	 *      every t0 / 256 seconds
	 *      For example, if halving time is one hour, the price updates every 14 seconds
	 *
	 * @param p0 initial price (wei)
	 * @param t0 price halving time (seconds)
	 * @param t elapsed time (seconds)
	 * @return price after `t` seconds passed, `p = p0 * 2^(-t/t0)`
	 */
	function price(uint256 p0, uint256 t0, uint256 t) public pure virtual returns (uint256) {
		// perform very rough price estimation first by halving
		// the price as many times as many t0 intervals have passed
		uint256 p = p0 >> t / t0;

		// if price halves (decreases by 2 times) every t0 seconds passed,
		// than every t0 / 2 seconds passed it decreases by sqrt(2) times (2 ^ (1/2)),
		// every t0 / 2 seconds passed it decreases 2 ^ (1/4) times, and so on

		// we've prepared a small cheat sheet here with the pre-calculated values for
		// the roots of the degree of two 2 ^ (1 / 2 ^ n)
		// for the resulting function to be monotonically decreasing, it is required
		// that (2 ^ (1 / 2 ^ n)) ^ 2 <= 2 ^ (1 / 2 ^ (n - 1))
		// to emulate floating point values, we present them as nominator/denominator
		// roots of the degree of two nominators:
		uint56[8] memory sqrNominator = [
			1_414213562373095, // 2 ^ (1/2)
			1_189207115002721, // 2 ^ (1/4)
			1_090507732665257, // 2 ^ (1/8) *
			1_044273782427413, // 2 ^ (1/16) *
			1_021897148654116, // 2 ^ (1/32) *
			1_010889286051700, // 2 ^ (1/64)
			1_005429901112802, // 2 ^ (1/128) *
			1_002711275050202  // 2 ^ (1/256)
		];
		// roots of the degree of two denominator:
		uint56 sqrDenominator =
			1_000000000000000;

		// perform up to 8 iterations to increase the precision of the calculation
		// dividing the halving time `t0` by two on every step
		for(uint8 i = 0; i < sqrNominator.length && t > 0 && t0 > 1; i++) {
			// determine the reminder of `t` which requires the precision increase
			t %= t0;
			// halve the `t0` for the next iteration step
			t0 /= 2;
			// if elapsed time `t` is big enough and is "visible" with `t0` precision
			if(t >= t0) {
				// decrease the price accordingly to the roots of the degree of two table
				p = p * sqrDenominator / sqrNominator[i];
			}
			// if elapsed time `t` is big enough and is "visible" with `2 * t0` precision
			// (this is possible sometimes due to rounding errors when halving `t0`)
			if(t >= 2 * t0) {
				// decrease the price again accordingly to the roots of the degree of two table
				p = p * sqrDenominator / sqrNominator[i];
			}
		}

		// return the result
		return p;
	}

	/**
	 * @notice Sells a plot of land (Land ERC721 token) from the sale to executor.
	 *      Executor must supply the metadata for the land plot and a Merkle tree proof
	 *      for the metadata supplied.
	 *
	 * @notice Mints the token bought immediately on L1 as part of the buy transaction
	 *
	 * @notice Metadata for all the plots is stored off-chain and is publicly available
	 *      to buy plots and to generate Merkle proofs
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the plot data collection elements via `web3.utils.soliditySha3`, making sure
	 *         the packing order and types are exactly as defined in `PlotData` struct
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed collection, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given plot data element the proof is constructed by hashing it (as in step 1),
	 *         and querying the MerkleTree for a proof, providing the hashed plot data element as a leaf
	 *
	 * @dev Requires FEATURE_L1_SALE_ACTIVE feature to be enabled
	 *
	 * @dev Throws if current time is outside the [saleStart, saleEnd + pauseDuration) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @dev See also: https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
	 *
	 * @param plotData plot data to buy
	 * @param proof Merkle proof for the plot data supplied
	 */
	function buyL1(PlotData memory plotData, bytes32[] memory proof) public virtual payable {
		// verify L1 sale is active
		require(isFeatureEnabled(FEATURE_L1_SALE_ACTIVE), "L1 sale disabled");

		// execute all the validations, process payment, construct the land plot
		(LandLib.PlotStore memory plot, uint256 pEth, uint256 pIlv) = _buy(plotData, proof);

		// mint the token in L1 with metadata - delegate to `mintWithMetadata`
		LandERC721Metadata(targetNftContract).mintWithMetadata(msg.sender, plotData.tokenId, plot);

		// emit an event
		emit PlotBoughtL1(msg.sender, plotData.tokenId, plotData.sequenceId, plot, pEth, pIlv);
	}

	/**
	 * @notice Sells a plot of land (Land ERC721 token) from the sale to executor.
	 *      Executor must supply the metadata for the land plot and a Merkle tree proof
	 *      for the metadata supplied.
	 *
	 * @notice Doesn't mint the token bought immediately on L1 as part of the buy transaction,
	 *      only `PlotBoughtL2` event is emitted instead, which is picked by off-chain process
	 *      and then minted in L2
	 *
	 * @notice Metadata for all the plots is stored off-chain and is publicly available
	 *      to buy plots and to generate Merkle proofs
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the plot data collection elements via `web3.utils.soliditySha3`, making sure
	 *         the packing order and types are exactly as defined in `PlotData` struct
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed collection, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given plot data element the proof is constructed by hashing it (as in step 1),
	 *         and querying the MerkleTree for a proof, providing the hashed plot data element as a leaf
	 *
	 * @dev Requires FEATURE_L2_SALE_ACTIVE feature to be enabled
	 *
	 * @dev Throws if current time is outside the [saleStart, saleEnd + pauseDuration) bounds,
	 *      or if it is outside the sequence bounds (sequence lasts for `seqDuration`),
	 *      or if the tier specified is invalid (no starting price is defined for it)
	 *
	 * @dev See also: https://docs.openzeppelin.com/contracts/4.x/api/utils#MerkleProof
	 *
	 * @param plotData plot data to buy
	 * @param proof Merkle proof for the plot data supplied
	 */
	function buyL2(PlotData memory plotData, bytes32[] memory proof) public virtual payable {
		// verify L2 sale is active
		require(isFeatureEnabled(FEATURE_L2_SALE_ACTIVE), "L2 sale disabled");

		// buying in L2 requires EOA buyer, otherwise we cannot guarantee L2 mint:
		// an address which doesn't have private key cannot be registered with IMX
		// note: should be used with care, see https://github.com/ethereum/solidity/issues/683
		require(msg.sender == tx.origin, "L2 sale requires EOA");

		// execute all the validations, process payment, construct the land plot
		(LandLib.PlotStore memory plot, uint256 pEth, uint256 pIlv) = _buy(plotData, proof);

		// note: token is not minted in L1, it will be picked by the off-chain process and minted in L2

		// emit an event
		emit PlotBoughtL2(msg.sender, plotData.tokenId, plotData.sequenceId, plot, plot.pack(), pEth, pIlv);
	}

	/**
	 * @dev Auxiliary function used in both `buyL1` and `buyL2` functions to
	 *      - execute all the validations required,
	 *      - process payment,
	 *      - generate random seed to derive internal land structure (landmark and sites), and
	 *      - construct the `LandLib.PlotStore` data structure representing land plot bought
	 *
	 * @dev See `buyL1` and `buyL2` functions for more details
	 */
	function _buy(
		PlotData memory plotData,
		bytes32[] memory proof
	) internal virtual returns (
		LandLib.PlotStore memory plot,
		uint256 pEth,
		uint256 pIlv
	) {
		// check if sale is active (and initialized)
		require(isActive(), "inactive sale");

		// make sure plot data Merkle root was set (sale has something on sale)
		require(root != 0x00, "empty sale");

		// verify the plot supplied is a valid/registered plot
		require(isPlotValid(plotData, proof), "invalid plot");

		// verify if token is not yet minted and mark it as minted
		_markAsMinted(plotData.tokenId);

		// process the payment, save the ETH/sILV lot prices
		// a note on reentrancy: `_processPayment` may execute a fallback function on the smart contract buyer,
		// which would be the last execution statement inside `_processPayment`; this execution is reentrancy safe
		// not only because 2,300 transfer function is used, but primarily because all the "give" logic is executed after
		// external call, while the "withhold" logic is executed before the external call
		(pEth, pIlv) = _processPayment(plotData.sequenceId, plotData.tierId);

		// generate the random seed to derive internal land structure (landmark and sites)
		// hash the token ID, block timestamp and tx executor address to get a seed
		uint256 seed = uint256(keccak256(abi.encodePacked(plotData.tokenId, now32(), msg.sender)));

		// allocate the land plot metadata in memory
		plot = LandLib.PlotStore({
			version: 1,
			regionId: plotData.regionId,
			x: plotData.x,
			y: plotData.y,
			tierId: plotData.tierId,
			size: plotData.size,
			// use generated seed to derive the Landmark Type ID, seed is considered "used" after that
			landmarkTypeId: LandLib.getLandmark(seed, plotData.tierId),
			elementSites: 3 * plotData.tierId,
			fuelSites: plotData.tierId < 2? plotData.tierId: 3 * (plotData.tierId - 1),
			// store low 160 bits of the "used" seed in the plot structure
			seed: uint160(seed)
		});

		// return the results as a tuple
		return (plot, pEth, pIlv);
	}

	/**
	 * @dev Verifies if token is minted and marks it as minted
	 *
	 * @dev Throws if token is already minted
	 *
	 * @param tokenId token ID to check and mark as minted
	 */
	function _markAsMinted(uint256 tokenId) internal virtual {
		// calculate bit location to set in `mintedTokens`
		// slot index
		uint256 i = tokenId / 256;
		// bit location within the slot
		uint256 j = tokenId % 256;

		// verify bit `j` at slot `i` is not set
		require(mintedTokens[i] >> j & 0x1 == 0, "already minted");
		// set bit `j` at slot index `i`
		mintedTokens[i] |= 0x1 << j;
	}

	/**
	 * @dev Verifies if token is minted
	 *
	 * @param tokenId token ID to check if it's minted
	 */
	function exists(uint256 tokenId) public view returns(bool) {
		// calculate bit location to check in `mintedTokens`
		// slot index: i = tokenId / 256
		// bit location within the slot: j = tokenId % 256

		// verify if bit `j` at slot `i` is set
		return mintedTokens[tokenId / 256] >> tokenId % 256 & 0x1 == 1;
	}

	/**
	 * @dev Charges tx executor in ETH/sILV, based on if ETH is supplied in the tx or not:
	 *      - if ETH is supplied, charges ETH only (throws if value supplied is not enough)
	 *      - if ETH is not supplied, charges sILV only (throws if sILV transfer fails)
	 *
	 * @dev Sends the change (for ETH payment - if any) back to transaction executor
	 *
	 * @dev Internal use only, throws on any payment failure
	 *
	 * @param sequenceId ID of the sequence token is sold in
	 * @param tierId ID of the tier token belongs to (defines token rarity)
	 */
	function _processPayment(uint32 sequenceId, uint16 tierId) internal virtual returns (uint256 pEth, uint256 pIlv) {
		// determine current token price
		pEth = tokenPriceNow(sequenceId, tierId);

		// current land sale version doesn't support free tiers (ID: 0)
		require(pEth != 0, "unsupported tier");

		// if ETH is not supplied, try to process sILV payment
		if(msg.value == 0) {
			// convert price `p` to ILV/sILV
			pIlv = LandSalePriceOracle(priceOracle).ethToIlv(pEth);

			// LandSaleOracle implementation guarantees the price to have meaningful value,
			// we still check "close to zero" price case to be extra safe
			require(pIlv > 1_000, "price conversion error");

			// verify sender sILV balance and allowance to improve error messaging
			// note: `transferFrom` would fail anyway, but sILV deployed into the mainnet
			//       would just fail with "arithmetic underflow" without any hint for the cause
			require(ERC20(sIlvContract).balanceOf(msg.sender) >= pIlv, "not enough funds available");
			require(ERC20(sIlvContract).allowance(msg.sender, address(this)) >= pIlv, "not enough funds supplied");

			// if beneficiary address is set, transfer the funds directly to the beneficiary
			// otherwise, transfer the funds to the sale contract for the future pull withdrawal
			// note: sILV.transferFrom always throws on failure and never returns `false`, however
			//       to keep this code "copy-paste safe" we do require it to return `true` explicitly
			require(
				ERC20(sIlvContract).transferFrom(msg.sender, beneficiary != address(0)? beneficiary: address(this), pIlv),
				"ERC20 transfer failed"
			);

			// no need for the change processing here since we're taking the amount ourselves

			// return ETH price and sILV price actually charged
			return (pEth, pIlv);
		}

		// process ETH payment otherwise

		// ensure amount of ETH send
		require(msg.value >= pEth, "not enough ETH");

		// if beneficiary address is set
		if(beneficiary != address(0)) {
			// transfer the funds directly to the beneficiary
			// note: beneficiary cannot be a smart contract with complex fallback function
			//       by design, therefore we're using the 2,300 gas transfer
			beneficiary.transfer(pEth);
		}
		// if beneficiary address is not set, funds remain on
		// the sale contract address for the future pull withdrawal

		// if there is any change sent in the transaction
		// (most of the cases there will be a change since this is a dutch auction)
		if(msg.value > pEth) {
			// transfer the change back to the transaction executor (buyer)
			// note: calling the sale contract by other smart contracts with complex fallback functions
			//       is not supported by design, therefore we're using the 2,300 gas transfer
			payable(msg.sender).transfer(msg.value - pEth);
		}

		// return the ETH price charged
		return (pEth, 0);
	}

	/**
	 * @notice Current time adjusted to count for the total duration sale was on pause
	 *
	 * @dev If sale operates in a normal way, without emergency pausing involved, this
	 *      is always equal to the current time;
	 *      if sale is paused for some period of time, this duration is subtracted, the
	 *      sale "slows down", and behaves like if it had a delayed start
	 *
	 * @return sale own time, current time adjusted by `pauseDuration`
	 */
	function ownTime() public view virtual returns (uint32) {
		// subtract total pause duration from the current time (if any) and return
		return now32() - pauseDuration;
	}

	/**
	 * @dev Testing time-dependent functionality may be difficult;
	 *      we override time in the helper test smart contract (mock)
	 *
	 * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
	 */
	function now32() public view virtual returns (uint32) {
		// return current block timestamp
		return uint32(block.timestamp);
	}
}
