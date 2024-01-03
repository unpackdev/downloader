/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */

pragma solidity 0.5.15;



/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */


/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */

interface IShardGovernor {
	function claimInitialShotgun(
		address payable initialClaimantAddress,
		uint initialClaimantBalance
	) external payable returns (bool);

	function transferShards(
		address recipient,
		uint amount
	) external;

	function enactShotgun() external;
	function offererAddress() external view returns (address);
	function checkLock() external view returns (bool);
	function checkShotgunState() external view returns (bool);
	function getNftRegistryAddress() external view returns (address);
	function getNftTokenIds() external view returns (uint256[] memory);
	function getOwner() external view returns (address);
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */



interface IShardRegistry {
	function mint(address, uint256) external returns (bool);
	function pause() external;
	function unpause() external;
	function burn(uint256) external;
	function transfer(address, uint256) external returns (bool);
	function cap() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function totalSupply() external view returns (uint256);
}

/**
	* @title Contract managing Shotgun Clause lifecycle
	* @author Joel Hubert (Metalith.io)
	* @dev OpenZeppelin contracts are not ready for 0.6.0 yet, using 0.5.16.
	* @dev This contract is deployed once a Shotgun is initiated by calling the Registry.
	*/

contract ShotgunClause {

	using SafeMath for uint256;

	IShardGovernor private _shardGovernor;
	IShardRegistry private _shardRegistry;

	enum ClaimWinner { None, Claimant, Counterclaimant }
	ClaimWinner private _claimWinner = ClaimWinner.None;

	uint private _deadlineTimestamp;
	uint private _initialOfferInWei;
	uint private _pricePerShardInWei;
	address payable private _initialClaimantAddress;
	uint private _initialClaimantBalance;
	bool private _shotgunEnacted = false;
	uint private _counterWeiContributed;
	address[] private _counterclaimants;
	mapping(address => uint) private _counterclaimContribs;

	event Countercommit(address indexed committer, uint indexed weiAmount);
	event EtherCollected(address indexed collector, uint indexed weiAmount);

	constructor(
		address payable initialClaimantAddress,
		uint initialClaimantBalance,
		address shardRegistryAddress
	) public payable {
		_shardGovernor = IShardGovernor(msg.sender);
		_shardRegistry = IShardRegistry(shardRegistryAddress);
		_deadlineTimestamp = now.add(1 * 14 days);
		_initialClaimantAddress = initialClaimantAddress;
		_initialClaimantBalance = initialClaimantBalance;
		_initialOfferInWei = msg.value;
		_pricePerShardInWei = (_initialOfferInWei.mul(10**18)).div(_shardRegistry.cap().sub(_initialClaimantBalance));
		_claimWinner = ClaimWinner.Claimant;
	}

	/**
		* @notice Contribute Ether to the counterclaim for this Shotgun.
		* @dev Automatically enacts Shotgun once enough Ether is raised and
		returns initial claimant's Ether offer.
		*/
	function counterCommitEther() external payable {
		require(
			_shardRegistry.balanceOf(msg.sender) > 0,
			"[counterCommitEther] Account does not own Shards"
		);
		require(
			msg.value > 0,
			"[counterCommitEther] Ether is required"
		);
		require(
			_initialClaimantAddress != address(0),
			"[counterCommitEther] Initial claimant does not exist"
		);
		require(
			msg.sender != _initialClaimantAddress,
			"[counterCommitEther] Initial claimant cannot countercommit"
		);
		require(
			!_shotgunEnacted,
			"[counterCommitEther] Shotgun already enacted"
		);
		require(
			now < _deadlineTimestamp,
			"[counterCommitEther] Deadline has expired"
		);
		require(
			msg.value + _counterWeiContributed <= getRequiredWeiForCounterclaim(),
			"[counterCommitEther] Ether exceeds goal"
		);
		if (_counterclaimContribs[msg.sender] == 0) {
			_counterclaimants.push(msg.sender);
		}
		_counterclaimContribs[msg.sender] = _counterclaimContribs[msg.sender].add(msg.value);
		_counterWeiContributed = _counterWeiContributed.add(msg.value);
		emit Countercommit(msg.sender, msg.value);
		if (_counterWeiContributed == getRequiredWeiForCounterclaim()) {
			_claimWinner = ClaimWinner.Counterclaimant;
			enactShotgun();
		}
	}

	/**
		* @notice Collect ether from completed Shotgun.
		* @dev Called by Shard Registry after burning caller's Shards.
		* @dev For counterclaimants, returns both the proportional worth of their
		Shards in Ether AND any counterclaim contributions they have made.
		* @dev alternative: OpenZeppelin PaymentSplitter
		*/
	function collectEtherProceeds(uint balance, address payable caller) external {
		require(
			msg.sender == address(_shardRegistry),
			"[collectEtherProceeds] Caller not authorized"
		);
		if (_claimWinner == ClaimWinner.Claimant && caller != _initialClaimantAddress) {
			uint weiProceeds = (_pricePerShardInWei.mul(balance)).div(10**18);
			weiProceeds = weiProceeds.add(_counterclaimContribs[caller]);
			_counterclaimContribs[caller] = 0;
			(bool success, ) = address(caller).call.value(weiProceeds)("");
			require(success, "[collectEtherProceeds] Transfer failed.");
			emit EtherCollected(caller, weiProceeds);
		} else if (_claimWinner == ClaimWinner.Counterclaimant && caller == _initialClaimantAddress) {
			uint amount = (_pricePerShardInWei.mul(_initialClaimantBalance)).div(10**18);
			amount = amount.add(_initialOfferInWei);
			_initialClaimantBalance = 0;
			(bool success, ) = address(caller).call.value(amount)("");
			require(success, "[collectEtherProceeds] Transfer failed.");
			emit EtherCollected(caller, amount);
		}
	}

	/**
		* @notice Use by successful counterclaimants to collect Shards from initial claimant.
		*/
	function collectShardProceeds() external {
		require(
			_shotgunEnacted && _claimWinner == ClaimWinner.Counterclaimant,
			"[collectShardProceeds] Shotgun has not been enacted or invalid winner"
		);
		require(
			_counterclaimContribs[msg.sender] != 0,
			"[collectShardProceeds] Account has not participated in counterclaim"
		);
		uint proportionContributed = (_counterclaimContribs[msg.sender].mul(10**18)).div(_counterWeiContributed);
		_counterclaimContribs[msg.sender] = 0;
		uint shardsToReceive = (proportionContributed.mul(_initialClaimantBalance)).div(10**18);
		_shardGovernor.transferShards(msg.sender, shardsToReceive);
	}

	function deadlineTimestamp() external view returns (uint256) {
		return _deadlineTimestamp;
	}

	function shotgunEnacted() external view returns (bool) {
		return _shotgunEnacted;
	}

	function initialClaimantAddress() external view returns (address) {
		return _initialClaimantAddress;
	}

	function initialClaimantBalance() external view returns (uint) {
		return _initialClaimantBalance;
	}

	function initialOfferInWei() external view returns (uint256) {
		return _initialOfferInWei;
	}

	function pricePerShardInWei() external view returns (uint256) {
		return _pricePerShardInWei;
	}

	function claimWinner() external view returns (ClaimWinner) {
		return _claimWinner;
	}

	function counterclaimants() external view returns (address[] memory) {
		return _counterclaimants;
	}

	function getCounterclaimantContribution(address counterclaimant) external view returns (uint) {
		return _counterclaimContribs[counterclaimant];
	}

	function counterWeiContributed() external view returns (uint) {
		return _counterWeiContributed;
	}

	function getContractBalance() external view returns (uint) {
		return address(this).balance;
	}

	function shardGovernor() external view returns (address) {
		return address(_shardGovernor);
	}

	function getRequiredWeiForCounterclaim() public view returns (uint) {
		return (_pricePerShardInWei.mul(_initialClaimantBalance)).div(10**18);
	}

	/**
		* @notice Initiate Shotgun enactment.
		* @dev Automatically called if enough Ether is raised by counterclaimants,
		or manually called if deadline expires without successful counterclaim.
		*/
	function enactShotgun() public {
		require(
			!_shotgunEnacted,
			"[enactShotgun] Shotgun already enacted"
		);
		require(
			_claimWinner == ClaimWinner.Counterclaimant ||
			(_claimWinner == ClaimWinner.Claimant && now > _deadlineTimestamp),
			"[enactShotgun] Conditions not met to enact Shotgun Clause"
		);
		_shotgunEnacted = true;
		_shardGovernor.enactShotgun();
	}
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */



interface IShardOffering {
	function claimShards(address) external;
	function wrapUpOffering() external;
	function hasClaimedShards(address) external view returns (bool);
	function offeringCompleted() external view returns (bool);
	function offeringDeadline() external view returns (uint);
	function getSubEther(address) external view returns (uint);
	function getSubShards(address) external view returns (uint);
	function offererShardAmount() external view returns (uint);
	function totalShardsClaimed() external view returns (uint);
	function liqProviderCutInShards() external view returns (uint);
	function artistCutInShards() external view returns (uint);
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */




interface IFactory {

	function newSet(
		uint liqProviderCutInShards,
		uint artistCutInShards,
		uint pricePerShardInWei,
		uint shardAmountOffered,
		uint offeringDeadline,
		uint256 cap,
		string calldata name,
		string calldata symbol,
		bool shotgunDisabled
	) external returns (IShardRegistry, IShardOffering);
}
/* solhint-disable no-mix-tabs-and-spaces */
/* solhint-disable indent */


interface IUniswapExchange {
	function removeLiquidity(
		uint256 uniTokenAmount,
		uint256 minEth,
		uint256 minTokens,
		uint256 deadline
	) external returns(
		uint256, uint256
	);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);
}

/**
	* @title Contract managing Shard lifecycle (NFT custody + Shard issuance and redemption)
	* @author Joel Hubert (Metalith.io)
	* @dev OpenZeppelin contracts are not ready for 0.6.0 yet, using 0.5.15.
	* @dev This contract owns the Registry, Offering and any Shotgun contracts,
	* making it the gateway for core state changes.
	*/

contract ShardGovernor is IERC721Receiver {

  using SafeMath for uint256;

	// Equals `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

	IShardRegistry private _shardRegistry;
	IShardOffering private _shardOffering;
	ShotgunClause private _currentShotgunClause;
	address payable private _offererAddress;
	address[] private _nftRegistryAddresses;
	address payable private _niftexWalletAddress;
	address payable private _artistWalletAddress;
	uint256[] private _tokenIds;

	enum ClaimWinner { None, Claimant, Counterclaimant }
	address[] private _shotgunAddressArray;
	mapping(address => uint) private _shotgunMapping;
	uint private _shotgunCounter;

	event NewShotgun(address indexed shotgun);
	event ShardsClaimed(address indexed claimant, uint indexed shardAmount);
	event NftRedeemed(address indexed redeemer);
	event ShotgunEnacted(address indexed enactor);
	event ShardsCollected(address indexed collector, uint indexed shardAmount, address indexed shotgun);

	/**
		* @dev Checks whether offerer indeed owns the relevant NFT.
		* @dev Offering deadline starts ticking on deployment, but offerer needs to transfer
		* NFT to this contract before anyone can contribute.
		*/
  constructor(
  	address[] memory nftRegistryAddresses,
  	address payable offererAddress,
  	uint256[] memory tokenIds,
  	address payable niftexWalletAddress,
  	address payable artistWalletAddress
	) public {
		for (uint x = 0; x < tokenIds.length; x++) {
			require(
				IERC721(nftRegistryAddresses[x]).ownerOf(tokenIds[x]) == offererAddress,
				"Offerer is not owner of tokenId"
			);
		}

		_nftRegistryAddresses = nftRegistryAddresses;
		_niftexWalletAddress = niftexWalletAddress;
		_artistWalletAddress = artistWalletAddress;
		_tokenIds = tokenIds;
		_offererAddress = offererAddress;
	}

	/**
		* @dev Used to receive ether from the pullLiquidity function.
		*/
	function() external payable { }

	function deploySubcontracts(
		uint liqProviderCutInShards,
		uint artistCutInShards,
		uint pricePerShardInWei,
		uint shardAmountOffered,
		uint offeringDeadline,
		uint256 cap,
		string calldata name,
		string calldata symbol,
		bool shotgunDisabled,
		address factoryAddress
	) external {
		require(
			msg.sender == _niftexWalletAddress,
			"[deploySubcontracts] Unauthorized call"
		);

		require(
			address(_shardRegistry) == address(0) && address(_shardOffering) == address(0),
			"[deploySubcontracts] Contract(s) exist"
		);

		IFactory factory = IFactory(factoryAddress);
		(_shardRegistry, _shardOffering) = factory.newSet(
			liqProviderCutInShards,
			artistCutInShards,
			pricePerShardInWei,
			shardAmountOffered,
			offeringDeadline,
			cap,
			name,
			symbol,
			shotgunDisabled
		);
	}

	/**
		* @notice Issues Shards upon completion of Offering.
		* @dev Cap should equal totalSupply when all Shards have been claimed.
		* @dev The Offerer may close an undersubscribed Offering once the deadline has
		* passed and claim the remaining Shards.
		*/
	function checkOfferingAndIssue() external {
		require(
			_shardRegistry.totalSupply() != _shardRegistry.cap(),
			"[checkOfferingAndIssue] Shards have already been issued"
		);
		require(
			!_shardOffering.hasClaimedShards(msg.sender),
			"[checkOfferingAndIssue] You have already claimed your Shards"
		);
		require(
			_shardOffering.offeringCompleted() ||
			(now > _shardOffering.offeringDeadline() && !_shardOffering.offeringCompleted()),
			"Offering not completed or deadline not expired"
		);
		if (_shardOffering.offeringCompleted()) {
			if (_shardOffering.getSubEther(msg.sender) != 0) {
				_shardOffering.claimShards(msg.sender);
				uint subShards = _shardOffering.getSubShards(msg.sender);
				bool success = _shardRegistry.mint(msg.sender, subShards);
				require(success, "[checkOfferingAndIssue] Mint failed");
				emit ShardsClaimed(msg.sender, subShards);
			} else if (msg.sender == _offererAddress) {
				_shardOffering.claimShards(msg.sender);
				uint offShards = _shardOffering.offererShardAmount();
				bool success = _shardRegistry.mint(msg.sender, offShards);
				require(success, "[checkOfferingAndIssue] Mint failed");
				emit ShardsClaimed(msg.sender, offShards);
			}
		} else {
			_shardOffering.wrapUpOffering();
			uint remainingShards = _shardRegistry.cap().sub(_shardOffering.totalShardsClaimed());
			remainingShards = remainingShards
				.sub(_shardOffering.liqProviderCutInShards())
				.sub(_shardOffering.artistCutInShards());
			bool success = _shardRegistry.mint(_offererAddress, remainingShards);
			require(success, "[checkOfferingAndIssue] Mint failed");
			emit ShardsClaimed(msg.sender, remainingShards);
		}
	}

	/**
		* @notice Used by NIFTEX to claim predetermined amount of shards in offering in order
		* to bootstrap liquidity on Uniswap-type exchange.
		*/
	/* function claimLiqProviderShards() external {
		require(
			msg.sender == _niftexWalletAddress,
			"[claimLiqProviderShards] Unauthorized caller"
		);
		require(
			!_shardOffering.hasClaimedShards(msg.sender),
			"[claimLiqProviderShards] You have already claimed your Shards"
		);
		require(
			_shardOffering.offeringCompleted(),
			"[claimLiqProviderShards] Offering not completed"
		);
		_shardOffering.claimShards(_niftexWalletAddress);
		uint cut = _shardOffering.liqProviderCutInShards();
		bool success = _shardRegistry.mint(_niftexWalletAddress, cut);
		require(success, "[claimLiqProviderShards] Mint failed");
		emit ShardsClaimed(msg.sender, cut);
	} */

	function mintReservedShards(address _beneficiary) external {
		bool niftex;
		if (_beneficiary == _niftexWalletAddress) niftex = true;
		require(
			niftex ||
			_beneficiary == _artistWalletAddress,
			"[mintReservedShards] Unauthorized beneficiary"
		);
		require(
			!_shardOffering.hasClaimedShards(_beneficiary),
			"[mintReservedShards] Shards already claimed"
		);
		_shardOffering.claimShards(_beneficiary);
		uint cut;
		if (niftex) {
			cut = _shardOffering.liqProviderCutInShards();
		} else {
			cut = _shardOffering.artistCutInShards();
		}
		bool success = _shardRegistry.mint(_beneficiary, cut);
		require(success, "[mintReservedShards] Mint failed");
		emit ShardsClaimed(_beneficiary, cut);
	}

	/**
		* @notice In the unlikely case that one account accumulates all Shards,
		* they can be redeemed directly for the underlying NFT.
		*/
	function redeem() external {
		require(
			_shardRegistry.balanceOf(msg.sender) == _shardRegistry.cap(),
			"[redeem] Account does not own total amount of Shards outstanding"
		);
		// Disable contracts to improve compatibility with certain NFT projects
		require(
			msg.sender == tx.origin,
			"[redeem] Caller must be wallet"
		);
		for (uint x = 0; x < _tokenIds.length; x++) {
			IERC721(_nftRegistryAddresses[x]).safeTransferFrom(address(this), msg.sender, _tokenIds[x]);
		}
		emit NftRedeemed(msg.sender);
	}

	/**
		* @notice Creates a new Shotgun claim.
		* @dev This Function is called from the Shard Registry because the claimant's
		* Shards must be frozen until the Shotgun is resolved: if they lose the claim,
		* their Shards are automatically distributed to the counterclaimants.
		* @dev The Registry is paused while an active Shotgun claim exists to
		* let the process work in an orderly manner.
		* @param initialClaimantAddress wallet address of the person who initiated Shotgun.
		* @param initialClaimantBalance Shard balance of the person who initiated Shotgun.
		*/
	function claimInitialShotgun(
		address payable initialClaimantAddress,
		uint initialClaimantBalance
	) external payable returns (bool) {
		require(
			msg.sender == address(_shardRegistry),
			"[claimInitialShotgun] Caller not authorized"
		);
		_currentShotgunClause = (new ShotgunClause).value(msg.value)(
			initialClaimantAddress,
			initialClaimantBalance,
			address(_shardRegistry)
		);
		emit NewShotgun(address(_currentShotgunClause));
		_shardRegistry.pause();
		_shotgunAddressArray.push(address(_currentShotgunClause));
		_shotgunCounter++;
		_shotgunMapping[address(_currentShotgunClause)] = _shotgunCounter;
		return true;
	}

	/**
		* @notice Effects the results of a (un)successful Shotgun claim.
		* @dev This Function can only be called by a Shotgun contract in two scenarios:
		* - Counterclaimants raise enough ether to buy claimant out
		* - Shotgun deadline passes without successful counter-raise, claimant wins
		*/
	function enactShotgun() external {
		require(
			_shotgunMapping[msg.sender] != 0,
			"[enactShotgun] Invalid Shotgun Clause"
		);
		ShotgunClause _shotgunClause = ShotgunClause(msg.sender);
		address initialClaimantAddress = _shotgunClause.initialClaimantAddress();
		if (uint(_shotgunClause.claimWinner()) == uint(ClaimWinner.Claimant)) {
			_shardRegistry.burn(_shardRegistry.balanceOf(initialClaimantAddress));
			for (uint x = 0; x < _tokenIds.length; x++) {
				IERC721(_nftRegistryAddresses[x]).safeTransferFrom(address(this), initialClaimantAddress, _tokenIds[x]);
			}
			_shardRegistry.unpause();
			emit ShotgunEnacted(address(_shotgunClause));
		} else if (uint(_shotgunClause.claimWinner()) == uint(ClaimWinner.Counterclaimant)) {
			_shardRegistry.unpause();
			emit ShotgunEnacted(address(_shotgunClause));
		}
	}

	/**
		* @notice Transfer Shards to counterclaimants after unsuccessful Shotgun claim.
		* @dev This contract custodies the claimant's Shards when they claim Shotgun -
		* if they lose the claim these Shards must be transferred to counterclaimants.
		* This process is initiated by the relevant Shotgun contract.
		* @param recipient wallet address of the person receiving the Shards.
		* @param amount the amount of Shards to receive.
		*/
	function transferShards(address recipient, uint amount) external {
		require(
			_shotgunMapping[msg.sender] != 0,
			"[transferShards] Unauthorized caller"
		);
		bool success = _shardRegistry.transfer(recipient, amount);
		require(success, "[transferShards] Transfer failed");
		emit ShardsCollected(recipient, amount, msg.sender);
	}

	/**
		* @notice Allows liquidity providers to pull funds during shotgun.
		* @dev Requires Unitokens to be sent to the contract so the contract can
		* remove liquidity.
		* @param exchangeAddress address of the Uniswap pool.
		* @param liqProvAddress address of the liquidity provider.
		* @param uniTokenAmount liquidity tokens to redeem.
		* @param minEth minimum ether to withdraw.
		* @param minTokens minimum tokens to withdraw.
		* @param deadline deadline for the withdrawal.
		*/
	function pullLiquidity(
		address exchangeAddress,
		address liqProvAddress,
		uint256 uniTokenAmount,
		uint256 minEth,
		uint256 minTokens,
		uint256 deadline
	) public {
		require(msg.sender == _niftexWalletAddress, "[pullLiquidity] Unauthorized call");
		IUniswapExchange uniExchange = IUniswapExchange(exchangeAddress);
		uniExchange.transferFrom(liqProvAddress, address(this), uniTokenAmount);
		_shardRegistry.unpause();
		(uint ethAmount, uint tokenAmount) = uniExchange.removeLiquidity(uniTokenAmount, minEth, minTokens, deadline);
		(bool ethSuccess, ) = liqProvAddress.call.value(ethAmount)("");
		require(ethSuccess, "[pullLiquidity] ETH transfer failed.");
		bool tokenSuccess = _shardRegistry.transfer(liqProvAddress, tokenAmount);
		require(tokenSuccess, "[pullLiquidity] Token transfer failed");
		_shardRegistry.pause();
	}

	/**
		* @dev Utility function to check if a Shotgun is in progress.
		*/
	function checkShotgunState() external view returns (bool) {
		if (_shotgunCounter == 0) {
			return true;
		} else {
			ShotgunClause _shotgunClause = ShotgunClause(_shotgunAddressArray[_shotgunCounter - 1]);
			if (_shotgunClause.shotgunEnacted()) {
				return true;
			} else {
				return false;
			}
		}
	}

	function currentShotgunClause() external view returns (address) {
		return address(_currentShotgunClause);
	}

	function shardRegistryAddress() external view returns (address) {
		return address(_shardRegistry);
	}

	function shardOfferingAddress() external view returns (address) {
		return address(_shardOffering);
	}

	function getContractBalance() external view returns (uint) {
		return address(this).balance;
	}

	function offererAddress() external view returns (address payable) {
		return _offererAddress;
	}

	function shotgunCounter() external view returns (uint) {
		return _shotgunCounter;
	}

	function shotgunAddressArray() external view returns (address[] memory) {
		return _shotgunAddressArray;
	}

	function getNftRegistryAddresses() external view returns (address[] memory) {
		return _nftRegistryAddresses;
	}

	function getNftTokenIds() external view returns (uint256[] memory) {
		return _tokenIds;
	}

	function getOwner() external view returns (address) {
		return _niftexWalletAddress;
	}

	/**
		* @dev Utility function to check whether this contract owns the Sharded NFT.
		*/
	function checkLock() external view returns (bool) {
		if (address(_shardOffering) == address(0) || address(_shardRegistry) == address(0)) return false;

		for (uint x = 0; x < _tokenIds.length; x++) {
			address owner = IERC721(_nftRegistryAddresses[x]).ownerOf(_tokenIds[x]);
			if (owner != address(this)) {
				return false;
			}
		}

		return true;
	}

	/**
		* @notice Handle the receipt of an NFT.
		* @dev The ERC721 smart contract calls this function on the recipient
		* after a `safetransfer`. This function MAY throw to revert and reject the
		* transfer. Return of other than the magic value MUST result in the
		* transaction being reverted.
		* Note: the contract address is always the message sender.
		* @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
		*/
	function onERC721Received(address, address, uint256, bytes memory) public returns(bytes4) {
		return _ERC721_RECEIVED;
	}
}