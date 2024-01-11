// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

// stake object declared global for interface
struct Stake {
	uint256 tokenId; // tokenID of $1CLB NFT
	uint256 startTime; // timestamp of when NFT was staked
	uint256 lastClaim; // timestamp of when last claim was made
	bool isStake; // needs a manual check to distinguish a default from an explicitly "all 0" record
}

// key token interface
interface IMembershipMiningProgram {
	function claim() external;

	function isEligible(address redeemer) external view returns (bool);
}

// key token interface
interface KeyIERC20 is IERC20 {
	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function decimals() external view returns (uint8);
}

// stakepool interface
interface StakePool {
	function getStakes(address owner) external view returns (Stake[] memory);
}

/// @custom:security-contact info@impact3.io
contract OneClub is
	ERC721,
	ERC721Enumerable,
	ERC721Burnable,
	EIP712,
	Pausable,
	Ownable,
	RoyaltiesV2Impl,
	ReentrancyGuard
{
	// defensive as not necessary from pragma ^0.8
	using SafeMath for uint256;

	// event emitted when referral has been paid
	event ReferralPaid(
		address indexed referrer,
		address indexed referee,
		uint256 amount
	);
	// event emitted when referral has been made
	event ReferralMade(address indexed referrer, address indexed referee);

	// State Variables
	uint256 private constant I3_ROYALTY_FEE = 11; // 11%
	uint256 private constant I3_REFERRAL_FEE = 5; // 5%
	uint256 private constant I3_EQUITY_FEE = 20; // 5%

	// cap the allocations for goldlists
	uint256 private constant _maxFreeAllocations = 750;

	// required for signing vouchers
	string private constant SIGNING_DOMAIN = 'OneClubSignerDomain';
	string private constant SIGNATURE_VERSION = '1';
	// support ERC2981 royalty standard
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	// whitelist invitations expiry
	uint256 private _invitationExpiry = 52 weeks; // default to 1 year

	// maximum supply of NFT
	uint256 private _maxSupply = 11111;
	// counter variable for goldlist allocations
	uint256 private _goldAllocations = 0;

	// track amount of staking pools
	uint256 private _stakingPoolCount = 0;

	// ambassador equity pool address
	address payable public equityPool;
	// payment splitter for royalty payouts
	address payable public paymentSplitter;
	// I3 treasury wallet
	address payable public i3Wallet;
	// voucher signer address
	address public signer;

	// initialisation variables
	bool public initialised = false;
	bool private revealed = false;

	// $KEY token
	KeyIERC20 public keyToken;
	// membership mining program address
	IMembershipMiningProgram public mmp;

	// IPFS CID initialised for unrevealed collection
	string private _cid = 'QmRDN1vtEzuTyJ19kf2yJf8JJ3WuonxME2mcn6PXGJEj5d';

	// track claimed tokens
	uint256[] public claimed;
	// counter variable to track claims
	uint256 public claimedCounter;

	// staking period => staking address
	mapping(uint256 => address) public stakePools;
	// enumerable id => staking period
	mapping(uint256 => uint256) public stakePeriods;
	// track whitelist allocations - X is whitelisted until Y
	mapping(address => uint256) public whiteList;
	// X was invited By Y
	mapping(address => address) public referrals;
	// track free mint allocations - X has Y allocations
	mapping(address => uint256) public goldList;

	// Royalty payout object
	struct RoyaltyPayout {
		address payable account;
		uint96 percentageBasisPoints;
	}

	// gold invite object
	struct GoldInvitation {
		address account;
		uint256 amount;
	}

	// voucher object
	struct Voucher {
		uint256 tokenId;
		uint256 stakePeriod;
		bytes signature;
	}

	// modifier to check if contract has been setup (after deployment)
	modifier isInitialised() {
		require(initialised == true, 'Contract has not yet been initialised');
		_;
	}

	// modifier to check if msg.sender holds an NFT or stakes an NFT
	modifier onlyHolder() {
		require(
			balanceOf(msg.sender) >= 1 || getStakePoolBalances(1)[0].isStake,
			'Caller is not an NFT holder'
		);
		_;
	}

	constructor()
		ERC721('OneClub', '1CLB')
		EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
	{}

	/** @dev Initialises the contract with depencancies
	 * @param _keyToken address of the $KEY contract.
	 * @param _paymentSplitter address of the royalty payment splitter contract.
	 * @param _treasury address of the I3 multisig.
	 * @param _stakePool1 address of the 3 month staking pool.
	 * @param _stakePool3 address of the 1 month staking pool.
	 * @param _stakePool6 address of the 6 month staking pool.
	 * @param _equityPool address of the ambassadors equity pool.
	 * @param _mmp address of the membership mining program.
	 * @param _signer address of the voucher signer.
	 */
	function initialise(
		address _keyToken,
		address _paymentSplitter,
		address _treasury,
		address _stakePool1,
		address _stakePool3,
		address _stakePool6,
		address _equityPool,
		address _mmp,
		address _signer
	) public onlyOwner {
		require(initialised == false, 'Contract is already initialised');
		setKeyToken(_keyToken);
		setPaymentSplitter(_paymentSplitter);
		setTreasury(_treasury);
		setStakingPool(_stakePool1, 1);
		setStakingPool(_stakePool3, 3);
		setStakingPool(_stakePool6, 6);
		setEquityPool(_equityPool);
		setMMP(_mmp);
		setSigner(_signer);
		initialised = true;
	}

	/** @dev Set the membership mining program contract
	 * @param _mmp address of the membership mining program contract.
	 */
	function setMMP(address _mmp) public onlyOwner {
		mmp = IMembershipMiningProgram(_mmp);
	}

	/** @dev Set $KEY token contract
	 * @param _keyToken address of the $KEY contract.
	 */
	function setKeyToken(address _keyToken) public onlyOwner {
		keyToken = KeyIERC20(_keyToken);
	}

	/** @dev Set the equity pool address
	 * @param _equityPool address of the equity manager contract.
	 */
	function setEquityPool(address _equityPool) public onlyOwner {
		equityPool = payable(_equityPool);
	}

	/** @dev Set the signer address
	 * @param _signer address of the voucher signer.
	 */
	function setSigner(address _signer) public onlyOwner {
		signer = _signer;
	}

	/** @dev Set the treasury address
	 * @param _wallet address of the multisig.
	 */
	function setTreasury(address _wallet) public onlyOwner {
		i3Wallet = payable(_wallet);
	}

	/** @dev Set or add a staking pool address
	 * @param _pool address of the staking pool.
	 * @param _period period in months.
	 */
	function setStakingPool(address _pool, uint256 _period) public onlyOwner {
		bool isReplacing = stakePools[_period] != address(0);
		stakePools[_period] = _pool;
		// keep track of staking periods to allow enumeration
		// but only increment if pool for period did not exist before
		if (!isReplacing) {
			stakePeriods[_stakingPoolCount] = _period;
			_stakingPoolCount++;
		}
	}

	/** @dev Set payment splitter address
	 * @param _paymentSplitter address of the payment splitter.
	 */
	function setPaymentSplitter(address _paymentSplitter) public onlyOwner {
		paymentSplitter = payable(_paymentSplitter);
	}

	/** @dev Return base IPFS URL for NFT artowkr
	 * @return BaseURI string of the IPFS gateway
	 */
	function _baseURI() internal pure override returns (string memory) {
		return 'https://ipfs.io/ipfs/';
	}

	/** @dev Pauses the contract
	 */
	function pause() public onlyOwner {
		_pause();
	}

	/** @dev Unpauses the contract
	 */
	function unpause() public onlyOwner {
		_unpause();
	}

	/** @dev Set expiry for the whitelist invitations
	 *	@param expiry in seconds
	 */
	function setInvitationExpiry(uint256 expiry) public onlyOwner {
		_invitationExpiry = expiry;
	}

	/** @dev Retrieve stake balance for a given pool
	 *	@param period in months
	 *	@return Stake list
	 */
	function getStakePoolBalance(uint256 period)
		public
		view
		returns (Stake[] memory)
	{
		return StakePool(stakePools[period]).getStakes(msg.sender);
	}

	/** @dev Retrieve stake balances for all pools
	 *	@param upto a specific limit of results
	 *	@return Stake list
	 */
	function getStakePoolBalances(uint256 upto)
		public
		view
		returns (Stake[] memory)
	{
		// initiate an array of stake objects
		Stake[] memory stakes = new Stake[](upto);
		uint256 counter = 0;
		// iterate over every staking pool and retrieve the balance of msg.sender
		for (uint256 i = 0; i < _stakingPoolCount; i++) {
			Stake[] memory poolStakes = StakePool(stakePools[stakePeriods[i]])
				.getStakes(msg.sender);
			// iterate over every result and add to list up until limit is hit
			for (uint256 j = 0; j < poolStakes.length; j++) {
				if (counter >= upto) return stakes;
				stakes[counter] = poolStakes[j];
				counter++;
			}
		}
		return stakes;
	}

	/** @dev Retrieve current mint price in WEI
	 *	@return Mint price in WEI
	 */
	function getFloorWeiPrice() public view returns (uint256) {
		// 0.25 ETH + (0.002 ETH * #holders)
		return 250000000000000000 + (2000000000000000 * totalSupply());
	}

	/** @dev Retrieve current keys required to invite
	 *	@return KEYs required in WEI
	 */
	function getKeysRequired() public view returns (uint256) {
		uint256 keysAmount = ((2 * (_maxSupply)) /
			(_maxSupply - totalSupply())) * (10**keyToken.decimals());
		// cap at 50 keys
		uint256 maxKeys = (50 * (10**keyToken.decimals()));
		return keysAmount >= maxKeys ? maxKeys : keysAmount;
	}

	/** @dev Invite a provided address
	 *	@param account address to invite
	 */
	function invite(address account)
		public
		whenNotPaused
		onlyHolder
		isInitialised
	{
		require(
			whiteList[account] == 0 && goldList[account] == 0,
			'Account already whitelisted or goldlisted'
		);

		uint256 keysRequired = getKeysRequired();

		require(
			keyToken.balanceOf(msg.sender) >= keysRequired,
			'Caller does not have enough keys'
		);

		// burn amount of tokens required for invitation
		// this should have been pre-approved before calling this function
		keyToken.burnFrom(msg.sender, keysRequired);

		// add msg.sender to referrals and referee to whitelist
		whiteList[account] = block.timestamp + _invitationExpiry;
		referrals[account] = msg.sender;

		// emit event
		emit ReferralMade(msg.sender, account);
	}

	/** @dev BatchInvite a number of addresses to save on intrinsic GAS
	 *	@param account list of invitees
	 */
	function batchInvite(address[] memory account)
		public
		whenNotPaused
		onlyHolder
		isInitialised
	{
		for (uint256 i = 0; i < account.length; i++) {
			invite(account[i]);
		}
	}

	/** @dev Reveal the final artwork
	 *	@param cid identifier of the IPFS path
	 *	@notice only callable once
	 */
	function reveal(string memory cid) public onlyOwner {
		require(!revealed, 'NFT already revealed');
		_cid = cid;
		revealed = true;
	}

	/** @dev Retrieve the path to the JSON metadata file
	 *	@param tokenId identifier of the token
	 *	@return URI to the JSON metadata file
	 */
	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(
			_exists(tokenId),
			'ERC721Metadata: URI query for nonexistent token'
		);

		string memory baseURI = _baseURI();

		// check if the token has been revealed, and if so
		// return the tokenID, else return a modulo of 2 (0 or 1)
		// to account for gender placeholders
		return
			bytes(baseURI).length > 0
				? string(
					abi.encodePacked(
						baseURI,
						_cid,
						'/',
						revealed
							? Strings.toString(tokenId)
							: Strings.toString(tokenId % 2)
					)
				)
				: '';
	}

	/** @dev Invite a list of members into the gold list
	 *	@param invitations list of GoldInvitations
	 */
	function goldInvite(GoldInvitation[] memory invitations)
		public
		whenNotPaused
		onlyOwner
		isInitialised
	{
		uint256 totalAllocations = 0;
		for (uint256 i = 0; i < invitations.length; i++) {
			totalAllocations += invitations[i].amount;
		}

		require(
			_goldAllocations.add(totalAllocations) < _maxFreeAllocations,
			'Max free allocations cap reached'
		);

		// iterate over all invitations provided and add to goldlist
		for (uint256 i = 0; i < invitations.length; i++) {
			totalAllocations += invitations[i].amount;
			goldList[invitations[i].account] = invitations[i].amount;
		}
		// increase allocation count to ensure cap
		_goldAllocations += totalAllocations;
	}

	/** @dev Mint to a provided address
	 *	@param redeemer address to mint to
	 *	@param voucher object signed by NFT signer address to ensure fair-play
	 */
	function safeMint(address redeemer, Voucher calldata voucher)
		public
		payable
		whenNotPaused
		isInitialised
	{
		// make sure signature is valid and get the address of the signer
		address _signer = _verify(voucher);
		require(_signer == signer, 'Invalid voucher signature');

		// Make sure NFT is not already minted
		require(!_exists(voucher.tokenId), 'Token has already been minted');

		bool isFreeMint = goldList[redeemer] > 0;
		string memory floorPrice = Strings.toString(getFloorWeiPrice());

		require(totalSupply() < _maxSupply, 'Maximum supply already minted');
		if (!isFreeMint) {
			require(
				msg.value >= getFloorWeiPrice(),
				string(
					abi.encodePacked(
						'requires at least ',
						floorPrice,
						' Wei to mint'
					)
				)
			);
		}
		require(
			whiteList[redeemer] >= block.timestamp || isFreeMint,
			'No valid whitelist or goldlist invitation'
		);

		if (mmp.isEligible(redeemer)) {
			(bool success0, bytes memory returnedData) = address(mmp)
				.call(abi.encodeWithSignature('claim(address)', redeemer));
			require(success0, extractRevertReason(returnedData));
		}

		// reduce amount that can be minted
		goldList[redeemer] = goldList[redeemer] == 0
			? 0
			: goldList[redeemer] - 1;
		// do not allow holder to mint again on same address
		whiteList[redeemer] = 0;

		// ensure stake pool contract can interact with contract
		for (uint256 i = 0; i < _stakingPoolCount; i++) {
			setApprovalForAll(address(stakePools[stakePeriods[i]]), true);
		}

		// check if NFT has stake period assigned
		if (voucher.stakePeriod > 0) {
			require(
				stakePools[voucher.stakePeriod] != address(0),
				'Staking pool for period does not exist'
			);
			// mint directly to assigned staking pool
			address pool = stakePools[voucher.stakePeriod];
			_safeMint(pool, voucher.tokenId);
			(bool success1, bytes memory returnedData) = pool.call(
				abi.encodeWithSignature(
					'goldStake(address,uint256)',
					redeemer,
					voucher.tokenId
				)
			);
			require(success1, extractRevertReason(returnedData));
		} else {
			_safeMint(redeemer, voucher.tokenId);
		}

		// track claimed tokens
		claimed.push(voucher.tokenId);
		claimedCounter++;

		// manage royalties and fees
		_setDefaultRoyalty(voucher.tokenId);

		uint256 remainingFee = msg.value;

		// check if a referral was made and pay 5% of mint fee
		if (referrals[redeemer] != address(0)) {
			address payable referrer = payable(referrals[redeemer]);
			uint256 referralFee = msg.value.mul(I3_REFERRAL_FEE).div(100);
			remainingFee = msg.value.sub(referralFee);

			(bool success2, ) = referrer.call{ value: referralFee }('');
			require(success2, 'Referral Fee transfer failed');
			emit ReferralPaid(referrals[redeemer], redeemer, referralFee);
		}

		// calculate equity pool fees
		uint256 equityPoolFee = msg.value.mul(I3_EQUITY_FEE).div(100);
		(bool success3, ) = equityPool.call{ value: equityPoolFee }('');
		require(success3, 'Equity Pool Fee transfer failed');

		// send remaining fees to treasury
		uint256 treasuryFee = remainingFee.sub(equityPoolFee);
		(bool success4, ) = i3Wallet.call{ value: treasuryFee }('');
		require(success4, 'Treasury Fee transfer failed');
	}

	/** @dev Extract revert reason
	 *	@param revertData in bytes
	 *	@return reason human-readable string
	 */
	function extractRevertReason(bytes memory revertData)
		internal
		pure
		returns (string memory reason)
	{
		uint256 l = revertData.length;
		if (l < 68) return '';
		uint256 t;
		assembly {
			revertData := add(revertData, 4)
			t := mload(revertData) // Save the content of the length slot
			mstore(revertData, sub(l, 4)) // Set proper length
		}
		reason = abi.decode(revertData, (string));
		assembly {
			mstore(revertData, t) // Restore the content of the length slot
		}
	}

	/** @dev Retrieve royalty information for given token and sales price
	 *	@param _tokenId of NFT
	 *	@param _salePrice sales price in WEI
	 *	@return receiver address and royaltyAmount in WEI
	 */
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
		external
		view
		returns (address receiver, uint256 royaltyAmount)
	{
		LibPart.Part[] memory _royalties = royalties[_tokenId];
		if (_royalties.length > 0) {
			return (
				_royalties[0].account,
				(_salePrice * _royalties[0].value) / 10000
			);
		}
		return (address(0), 0);
	}

	/** @dev Set default royalty during mint
	 *	@param _tokenId of NFT
	 */
	function _setDefaultRoyalty(uint256 _tokenId) private isInitialised {
		LibPart.Part[] memory _royalties = new LibPart.Part[](1);
		_royalties[0].value = uint96(I3_ROYALTY_FEE.mul(100));
		_royalties[0].account = paymentSplitter;
		_saveRoyalties(_tokenId, _royalties);
	}

	/** @dev Set royalty fees for a given tokenID
	 *	@param _tokenId of NFT
	 *	@param _payout object on who and how much to payout
	 */
	function setRoyalties(uint256 _tokenId, RoyaltyPayout memory _payout)
		public
		onlyOwner
	{
		LibPart.Part[] memory _royalties = new LibPart.Part[](1);
		_royalties[0].value = _payout.percentageBasisPoints;
		_royalties[0].account = _payout.account;
		_saveRoyalties(_tokenId, _royalties);
	}

	// The following functions are overrides required by Solidity.

	/** @dev Called before token transfer
	 *	@param from address
	 *	@param to address
	 *	@param tokenId identifier of NFT
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) whenNotPaused {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	/** @dev Retrieve whether a specific interface is supported for cross-compatiblity of royalty payouts
	 *	@param interfaceId identifier of interface
	 *	@return boolean value
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) return true;
		if (interfaceId == _INTERFACE_ID_ERC2981) return true;
		return super.supportsInterface(interfaceId);
	}

	/** @notice Verifies the signature for a given Voucher, returning the address of the signer.
	 * @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
	 * @param voucher An Voucher describing an unminted NFT.
	 */
	function _verify(Voucher calldata voucher) internal view returns (address) {
		bytes32 digest = _hash(voucher);
		return ECDSA.recover(digest, voucher.signature);
	}

	/** @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
	 * @param voucher A Voucher to hash.
	 */
	function _hash(Voucher calldata voucher) internal view returns (bytes32) {
		return
			_hashTypedDataV4(
				keccak256(
					abi.encode(
						keccak256(
							'Voucher(uint256 tokenId,uint256 stakePeriod)'
						),
						voucher.tokenId,
						voucher.stakePeriod
					)
				)
			);
	}
}
