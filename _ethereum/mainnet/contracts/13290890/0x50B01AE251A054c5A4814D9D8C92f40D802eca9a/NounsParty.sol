// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IFracTokenVault.sol";
import "./IFracVaultFactory.sol";
import "./INounsAuctionHouse.sol";
import "./INounsParty.sol";
import "./INounsToken.sol";

/**
 * @title NounsParty contract
 * @author twitter.com/devloper_eth
 * @notice Nouns party is an effort aimed at making community-driven nouns bidding easier, more interactive, and more likely to win than today's strategies.
 */
// solhint-disable max-states-count
contract NounsParty is
	INounsParty,
	Initializable,
	OwnableUpgradeable,
	PausableUpgradeable,
	ReentrancyGuardUpgradeable,
	UUPSUpgradeable
{
	uint256 private constant ETH1_1000 = 1_000_000_000_000_000; // 0.001 eth
	uint256 private constant ETH1_10 = 100_000_000_000_000_000; // 0.1 eth

	/// @dev post fractionalized token fee
	uint256 public nounsPartyFee;

	/// @dev max increase in percent for bids
	uint256 public bidIncrease;
	uint256 public nounsAuctionHouseBidIncrease;

	uint256 public currentNounId;
	uint256 public currentBidAmount;

	/**
	 * @dev poolWriteCursor is a global cursor indicating where to write in `pool`.
	 *      For each new deposit to `pool` it will increase by 1.
	 *      Read more in deposit().
	 */
	uint256 private poolWriteCursor;

	/// @dev poolReadCursor is a "global" cursor indicating which position to read next from the pool.
	uint256 private poolReadCursor;

	/// @notice the balance of all deposits
	uint256 public depositBalance;

	/// @dev use deposits() to read pool
	mapping(uint256 => Deposit) private pool;

	/// @notice claims has information about who can claim NOUN tokens after a successful auction
	/// @dev claims is populated in _depositsToClaims()
	mapping(address => TokenClaim[]) public claims;

	/// @notice map nounIds to fractional.art token vaults,  mapping(nounId) => fracTokenVaultAddress
	/// @dev only holds mappings for won auctions, but stores it forever. mappings aren't deleted. TokenClaims rely on fracTokenVaults - addresses should never change after first write.
	mapping(uint256 => address) public fracTokenVaults;

	address public fracVaultFactoryAddress;
	address public nounsPartyCuratorAddress;
	address public nounsPartyTreasuryAddress;
	address public nounsTokenAddress;

	INounsAuctionHouse public nounsAuctionHouse;
	INounsToken public nounsToken;
	IFracVaultFactory public fracVaultFactory;

	bool public activeAuction;
	bool public allowBid;

	function initialize(
		address _nounsAuctionHouseAddress,
		address _nounsTokenAddress,
		address _fracVaultFactoryAddress,
		address _nounsPartyCuratorAddress,
		address _nounsPartyTreasuryAddress,
		uint256 _nounsAuctionHouseBidIncrease
	) public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
		__ReentrancyGuard_init();
		__Pausable_init();

		require(_nounsAuctionHouseAddress != address(0), "zero nounsAuctionHouseAddress");
		require(_nounsTokenAddress != address(0), "zero nounsTokenAddress");
		require(_fracVaultFactoryAddress != address(0), "zero fracVaultFactoryAddress");
		require(_nounsPartyCuratorAddress != address(0), "zero nounsPartyCuratorAddress");
		require(_nounsPartyTreasuryAddress != address(0), "zero nounsPartyTreasuryAddress");

		nounsTokenAddress = _nounsTokenAddress;
		nounsPartyCuratorAddress = _nounsPartyCuratorAddress;
		fracVaultFactoryAddress = _fracVaultFactoryAddress;
		nounsPartyTreasuryAddress = _nounsPartyTreasuryAddress;
		nounsAuctionHouse = INounsAuctionHouse(_nounsAuctionHouseAddress);
		nounsToken = INounsToken(_nounsTokenAddress);
		fracVaultFactory = IFracVaultFactory(_fracVaultFactoryAddress);

		poolWriteCursor = 1; // must start at 1
		poolReadCursor = 1; // must start at 1

		_resetActiveAuction();

		allowBid = true;

		nounsPartyFee = 25; // 2.5%

		/// @dev min bid increase percentages
		bidIncrease = 30; // 3%
		nounsAuctionHouseBidIncrease = _nounsAuctionHouseBidIncrease; // 2% in mainnet, 5% in rinkeby (Sep 2021)
	}

	/// @notice Puts ETH into our bidding pool.
	/// @dev Using `pool` and `poolWriteCursor` we keep track of deposit ordering over time.
	function deposit() external payable nonReentrant whenNotPaused {
		require(msg.sender != address(0), "zero msg.sender");

		// Verify deposit amount to ensure fractionalizing will produce whole numbers.
		require(msg.value % ETH1_1000 == 0, "Must be in 0.001 ETH increments");

		// v0 asks for a 0.1 eth minimum deposit.
		// v1 will ask for 0.001 eth as minimum deposit.
		require(msg.value >= ETH1_10, "Minimum deposit is 0.1 ETH");

		// v0 caps the number of deposits at 250, to prevent too costly settle calls.
		// v1 will lift this cap.
		require(poolWriteCursor - poolReadCursor < 250, "Too many deposits");

		// Create a new deposit and add it to the pool.
		Deposit memory d = Deposit({ owner: msg.sender, amount: msg.value });
		pool[poolWriteCursor] = d;

		// poolWriteCursor is never reset and continuously increases over the lifetime of this contract.
		// Solidity checks for overflows, in which case the deposit would safely revert and a new contract would have to be deployed.
		// But hey, poolWriteCursor is of type uint256 which is a really really really big number (2^256-1 to be exact).
		// Considering that the minimum bid is 0.001 ETH + gas cost, which would make a DOS attack very expensive at current price rates,
		// we should never see poolWriteCursor overflow.
		// Ah, poolReadCursor which follows poolWriteCursor faces the same fate.
		//
		// Why not use an array you might ask? Our logic would cause gaps in our array to form over time,
		// causing unnecessary/expensive index lookups and shifts. `pool` is essentially a mapping turned
		// into an ordered array, using poolWriteCursor as sequential index.
		poolWriteCursor++;

		// Increase deposit balance
		depositBalance = depositBalance + msg.value;

		emit LogDeposit(msg.sender, msg.value);
	}

	/// @notice Bid for the given noun's auction.
	/// @dev Bid amounts don't have to be in 0.001 ETH increments, just deposits.
	function bid() external payable nonReentrant whenNotPaused {
		require(allowBid, "Bidding disabled");

		_trySettle();

		(uint256 nounId, uint256 amount) = calcBidAmount();

		require(!activeAuction || currentNounId == nounId, "Settle previous auction first");

		currentBidAmount = amount;

		// first time bidding on this noun?
		if (!activeAuction) {
			activeAuction = true;
			currentNounId = nounId;
		}

		emit LogBid(nounId, currentBidAmount, msg.sender);
		nounsAuctionHouse.createBid{ value: currentBidAmount }(nounId);
	}

	/// @notice Settles an auction.
	/// @dev Needs to be called after every auction to determine if we won or lost, and create token claims if we won.
	function settle() external nonReentrant whenNotPaused {
		require(activeAuction, "Nothing to settle");
		NounStatus status = nounStatus(currentNounId);

		if (status == NounStatus.MINTED) {
			revert("Noun not sold yet");
		} else if (status == NounStatus.NOTFOUND) {
			revert("Noun not found");
		} else if (status == NounStatus.WON) {
			_settleWon();
		} else if (status == NounStatus.BURNED || status == NounStatus.LOST) {
			_settleLost();
		} else {
			revert("Unknown Noun Status");
		}
	}

	/// @dev will settle won or lost/burned auctions, if possible
	function _trySettle() private {
		if (activeAuction) {
			NounStatus status = nounStatus(currentNounId);
			if (status == NounStatus.WON) {
				_settleWon();
			} else if (status == NounStatus.BURNED || status == NounStatus.LOST) {
				_settleLost();
			}
		}
	}

	function _settleWon() private {
		emit LogSettleWon(currentNounId);

		// Turn NFT into ERC20 tokens
		(address fracTokenVaultAddress, uint256 fee) = _fractionalize(
			currentBidAmount, // bid amount
			currentNounId
		);

		fracTokenVaults[currentNounId] = fracTokenVaultAddress;
		_depositsToClaims(currentBidAmount, currentNounId);
		_resetActiveAuction();

		// Send fee to our treasury wallet.
		IFracTokenVault fracTokenVault = IFracTokenVault(fracTokenVaultAddress);
		require(fracTokenVault.transfer(nounsPartyTreasuryAddress, fee), "Fee transfer failed");
	}

	function _settleLost() private {
		emit LogSettleLost(currentNounId);
		_resetActiveAuction();
	}

	function _resetActiveAuction() private {
		activeAuction = false;
		currentNounId = 0;
		currentBidAmount = 0;
	}

	/// @notice Claim tokens from won auctions
	/// @dev nonReentrant is very important here to prevent Reentrancy.
	function claim() external nonReentrant whenNotPaused {
		require(msg.sender != address(0), "zero msg.sender");

		// Iterate over all claims for msg.sender and transfer tokens.
		uint256 length = claims[msg.sender].length;
		for (uint256 index = 0; index < length; index++) {
			TokenClaim memory c = claims[msg.sender][index];
			address fracTokenVaultAddress = fracTokenVaults[c.nounId];
			require(fracTokenVaultAddress != address(0), "zero fracTokenVault address");

			emit LogClaim(msg.sender, c.nounId, fracTokenVaultAddress, c.tokens / uint256(1 ether));

			IFracTokenVault fracTokenVault = IFracTokenVault(fracTokenVaultAddress);
			require(fracTokenVault.transfer(msg.sender, c.tokens), "Token transfer failed");
		}

		// Check-Effects-Interactions pattern can't be followed in this case, hence nonReentrant
		// is so important for this function.
		delete claims[msg.sender];
	}

	/// @notice Withdraw deposits that haven't been used to bid on a noun.
	function withdraw() external payable whenNotPaused nonReentrant {
		require(msg.sender != address(0), "zero msg.sender");
		require(!auctionIsHot(), "Auction is hot");

		uint256 amount = 0;
		uint256 reserve = currentBidAmount;
		uint256 readCursor = poolReadCursor;
		while (readCursor <= poolWriteCursor) {
			uint256 x = pool[readCursor].amount;

			if (reserve == 0) {
				if (pool[readCursor].owner == msg.sender) {
					amount += x;
					delete pool[readCursor];
				}
			} else if (reserve >= x) {
				reserve -= x;
			} else {
				// reserve < x
				if (pool[readCursor].owner == msg.sender) {
					pool[readCursor].amount = reserve;
					amount += x - reserve;
				}
				reserve = 0;
			}

			readCursor++;
		}

		require(amount > 0, "Insufficient funds");
		depositBalance = depositBalance - amount;
		emit LogWithdraw(msg.sender, amount);
		_transferETH(msg.sender, amount);
	}

	/// @notice Returns an estimated withdrawable amount. Estimated because future bids might restrict withdrawals.
	function withdrawableAmount(address _owner) external view returns (uint256) {
		if (auctionIsHot()) {
			return 0;
		}

		uint256 amount = 0;
		uint256 reserve = currentBidAmount;
		uint256 readCursor = poolReadCursor;
		while (readCursor <= poolWriteCursor) {
			uint256 x = pool[readCursor].amount;
			if (reserve == 0) {
				if (pool[readCursor].owner == _owner) {
					amount += x;
				}
			} else if (reserve >= x) {
				reserve -= x;
			} else {
				// reserve < x
				if (pool[readCursor].owner == _owner) {
					amount += x - reserve;
				}
				reserve = 0;
			}

			readCursor++;
		}

		return amount;
	}

	/// @dev Iterates over all deposits in `pool` and creates `claims` which then allows users to claim their tokens.
	function _depositsToClaims(uint256 _amount, uint256 _nounId) private {
		// Decrease depositBalance by amount
		depositBalance = depositBalance - _amount;

		// Use a temporary cursor here (to save gas), but write back to poolReadCursor at the end.
		uint256 readCursor = poolReadCursor;

		// Read until we iterated through the pool, but also have an eye on amount.
		// We can stop iterating if we already "filled" _amount with enough deposits.
		while (readCursor <= poolWriteCursor && _amount > 0) {
			// Delete and skip if deposit is zero
			if (pool[readCursor].owner == address(0) || pool[readCursor].amount == 0) {
				delete pool[readCursor]; // delete deposit, it's already zero'd out anyway.
				readCursor++;
				continue; // to the next deposit
			}

			// Can we use the full deposit amount?
			if (pool[readCursor].amount <= _amount) {
				// Reduce amount by this deposit's amount
				_amount = _amount - pool[readCursor].amount;

				// Create a token claim for depositor.
				TokenClaim memory t0 = TokenClaim({
					tokens: pool[readCursor].amount * 1000, // full amount of deposit turned into tokens
					nounId: _nounId
				});
				claims[pool[readCursor].owner].push(t0);

				// Delete deposit, to prevent multiple claims.
				delete pool[readCursor];
				readCursor++;
				continue; // to the next deposit
			}

			// If we reach this line, we know:
			// 1) _amount is > 0 and
			// 2) pool[readCursor].amount > 0 and
			// 3) pool[readCursor].amount > _amount

			// Create a token claim for depositor, but only with partial amounts and tokens.
			TokenClaim memory t1 = TokenClaim({
				tokens: _amount * 1000, // remaining _amount turned into tokens
				nounId: _nounId
			});
			claims[pool[readCursor].owner].push(t1);

			// Don't forget to update the original deposit with the reduced amount.
			pool[readCursor].amount = pool[readCursor].amount - _amount;

			// The math only checks out, if _amount equals 0 at the end.
			// Which means we 100% "filled" _amount.
			_amount = _amount - _amount;
			assert(_amount == 0);

			// Do not advance poolReadCursor for deposits that still have a balance.
			// So no `readCursor++` here!

			// Also, since _amount is now 0, we will exit from the while loop now.
		}

		// Write our temporary readCursor back to the state variable.
		poolReadCursor = readCursor;
	}

	/// @dev Calls fractional.art's contracts to turn a noun NFT into fractionalized ERC20 tokens.
	/// @param _amount cost of the noun
	/// @param _nounId noun id
	/// @return tokenVaultAddress ERC20 vault address
	/// @return fee how many tokens we keep as fee
	function _fractionalize(uint256 _amount, uint256 _nounId) private returns (address tokenVaultAddress, uint256 fee) {
		require(_amount >= ETH1_1000, "Amount must be >= 0.001 ETH");

		// symbol = "Noun" + _nounId, like Noun13, Noun14, ...
		string memory symbol = string(abi.encodePacked("Noun", StringsUpgradeable.toString(_nounId)));

		// Calculate token supply by integer division: _amount * 1000 / 1e18
		// Integer divisions round towards zero.
		// For example: 1.9 tokens would turn into 1 token.
		// This can lead to a minimal value inflation of the total supply by at max 0.9999... tokens,
		// which again is so small it's neglectable.
		uint256 supply = uint256(_amount * 1000) / uint256(1 ether);
		require(supply >= 1, "Fractionalization failed");

		// Calculate fee based on supply by integer division.
		// Integer division means we don't charge a fee for bids 0.04 or less.
		// For bids above 0.04 we minimally decrease our effective fee to produce whole numbers where necessary.
		fee = uint256(supply * 1000 * nounsPartyFee) / uint256(1000000);

		uint256 adjustedSupply = supply + fee;

		emit LogFractionalize(_nounId, adjustedSupply, fee);

		// Approve fractional.art to take over our noun NFT.
		nounsToken.approve(fracVaultFactoryAddress, _nounId);

		// Let fractional.art create some ERC20 tokens for us.
		uint256 vaultNumber = fracVaultFactory.mint(
			symbol,
			symbol,
			nounsTokenAddress,
			_nounId,
			(adjustedSupply) * 1 ether, // convert back to wei (1 eth == 1e18)
			_amount * 5, // listPrice is the the initial price of the NFT
			0 // annual management fee (see our fee instead)
		);

		// Set our curator address.
		tokenVaultAddress = fracVaultFactory.vaults(vaultNumber);
		IFracTokenVault(tokenVaultAddress).updateCurator(nounsPartyCuratorAddress);

		return (tokenVaultAddress, fee * 1 ether); // convert back to wei
	}

	/// @notice Deposits returns all available deposits.
	/// @dev Deposits reads from `pool` using a temporary readCursor.
	/// @return A list of all available deposits.
	function deposits() external view returns (Deposit[] memory) {
		// Determine pool length so we can build a new fixed-size array.
		uint256 size = 0;
		uint256 readCursor = poolReadCursor;
		while (readCursor <= poolWriteCursor) {
			if (pool[readCursor].owner != address(0) && pool[readCursor].amount > 0) {
				size++;
			}
			readCursor++;
		}

		// Create a new fixed-size Deposit array.
		Deposit[] memory depos = new Deposit[](size);
		readCursor = poolReadCursor;
		uint256 cursor = 0;
		while (readCursor <= poolWriteCursor) {
			if (pool[readCursor].owner != address(0) && pool[readCursor].amount > 0) {
				depos[cursor] = pool[readCursor];
				cursor++;
			}
			readCursor++;
		}

		return depos;
	}

	/// @notice Indicates if a auction is about to start/live.
	/// @dev External because it "implements" the INounsParty interface.
	/// @return true if auction is live (aka hot).
	function auctionIsHot() public view returns (bool) {
		(, , , uint256 endTime, , bool settled) = nounsAuctionHouse.auction();

		// If auction has been settled, it can't be hot. Or we got a zero endTime?!
		if (settled || endTime == 0) {
			return false;
		}

		// Is this auction hot or not?
		// .......... [ -1 hour ............ endTime .. + 10 minutes ] ........
		// not hot    |--------------- hot --------------------------|  not hot
		// solhint-disable not-rely-on-time
		if (block.timestamp >= endTime - 1 hours && block.timestamp <= endTime + 10 minutes) {
			return true;
		}

		return false;
	}

	function calcBidAmount() public view returns (uint256 _nounId, uint256 _amount) {
		(uint256 nounId, uint256 amount, , , address bidder, bool settled) = nounsAuctionHouse.auction();

		require(nounId > 0, "zero noun");
		require(!settled, "Inactive auction");
		require(bidder != address(this), "Already winning");

		uint256 newBid = _round_eth1_1000(
			amount + ((amount * 1000 * (bidIncrease + nounsAuctionHouseBidIncrease)) / uint256(1000000))
		);

		if (newBid == 0) {
			newBid = ETH1_10;
		}

		if (newBid > depositBalance) {
			newBid = _round_eth1_1000(depositBalance);
		}

		uint256 minBid = amount + ((amount * 1000 * nounsAuctionHouseBidIncrease) / uint256(1000000));
		require(newBid >= minBid, "Insufficient funds");

		// Make sure we are bidding more than our previous bid.
		require(newBid > currentBidAmount, "Minimum bid not reached");

		// Make sure we bid at least 0.001 ETH to ensure best fractionalizations results.
		require(newBid >= ETH1_1000, "Minimum bid is 0.001 ETH");

		// We should never see this error, because we are always checking
		// depositBalance, not the contracts' balance. Checking just in case.
		require(address(this).balance >= newBid, "Insufficient balance");

		return (nounId, newBid);
	}

	/// @dev nonRevertingCalcBidAmountAfterSettle is like calcBidAmount but returns (0, 0) instead of reverting in case of an error.
	///      Why? Our frontend uses package `EthWorks/useDApp` which uses Multicall v1.
	///      Multicall v1 will fail if just one out of many calls fails.
	///      See also https://github.com/EthWorks/useDApp/issues/334.
	///      Please note that this workaround function does NOT affect
	///      the integrity or security of this contract.
	///      And yep, it's super annoying.
	function nonRevertingCalcBidAmountAfterSettle()
		external
		view
		returns (
			uint256 _nounId,
			uint256 _amount,
			string memory _message
		)
	{
		(uint256 nounId, uint256 amount, , , address bidder, bool settled) = nounsAuctionHouse.auction();

		if (nounId == 0) {
			return (0, 0, "zero noun");
		}
		if (settled) {
			return (0, 0, "Inactive auction");
		}
		if (bidder == address(this)) {
			return (0, 0, "Already winning");
		}

		uint256 newBid = _round_eth1_1000(
			amount + ((amount * 1000 * (bidIncrease + nounsAuctionHouseBidIncrease)) / uint256(1000000))
		);

		if (newBid == 0) {
			newBid = ETH1_10;
		}

		// simulate deposit balance in case we won the previous auction
		uint256 tmpDepositBalance = depositBalance;
		if (activeAuction) {
			NounStatus status = nounStatus(currentNounId);
			if (status == NounStatus.WON) {
				tmpDepositBalance -= currentBidAmount;
			}
		}

		if (newBid > tmpDepositBalance) {
			newBid = _round_eth1_1000(tmpDepositBalance);
		}

		uint256 minBid = amount + ((amount * 1000 * nounsAuctionHouseBidIncrease) / uint256(1000000));
		if (newBid < minBid) {
			return (0, 0, "Insufficient funds");
		}

		// Make sure we bid at least 0.001 ETH to ensure best fractionalizations results.
		if (newBid < ETH1_1000) {
			return (0, 0, "Minimum bid is 0.001 ETH");
		}

		// We should never see this error, because we are always checking
		// depositBalance, not the contracts' balance. Checking just in case.
		if (address(this).balance < newBid) {
			return (0, 0, "Insufficient balance");
		}

		return (nounId, newBid, "");
	}

	/// @dev round to next 0.001 ETH increment
	// solhint-disable-next-line func-name-mixedcase
	function _round_eth1_1000(uint256 amount) private pure returns (uint256) {
		return amount - (amount % ETH1_1000);
	}

	/// @dev Check the `ownerOf` a noun to check its status.
	/// @return NounStatus, which is either WON, BURNED, MINTED, LOST or NOTFOUND.
	function nounStatus(uint256 _nounId) public view returns (NounStatus) {
		// Life cycle of a noun, relevant in this context:
		// 1. A new noun is minted:
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/NounsToken.sol#L149
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/NounsToken.sol#L258
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/base/ERC721.sol#L321

		// 2. Auction is settled, meaning the noun is either burned (nobody bid on it) or transfered to highest bidder.
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/NounsAuctionHouse.sol#L221
		// https://github.com/nounsDAO/nouns-monorepo/blob/e075e881c4d5aa89344c8ab6bfc202650eb89370/packages/nouns-contracts/contracts/base/ERC721.sol#L182

		try nounsToken.ownerOf(_nounId) returns (address nounOwner) {
			if (nounOwner == address(this)) {
				// address(this) - that's us - won nounId.
				// Remember, using address(this) not contract's owner() here. Both are different.
				return NounStatus.WON;
			} else if (nounOwner == address(0)) {
				// nounId was burned
				// Nouns are burned if nobody bids, or the winner could also burn their noun.
				return NounStatus.BURNED;
			} else {
				if (nounOwner == nounsToken.minter()) {
					// nounId has been freshly minted and is still being auctioned off.
					return NounStatus.MINTED;
				} else {
					// We don't know noun's owner. That means we lost the auction.
					return NounStatus.LOST;
				}
			}
		} catch {
			// ownerOf reverted. that means the nounId does not exist, unless something else happened, like a failed transaction.
			return NounStatus.NOTFOUND;
		}
	}

	/// @notice Returns the number of open claims.
	/// @return Number of open claims.
	function claimsCount(address _address) external view returns (uint256) {
		return claims[_address].length;
	}

	/// @dev Update nounsAuctionHouse.
	function setNounsAuctionHouseAddress(address _address) external nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		nounsAuctionHouse = INounsAuctionHouse(_address);
	}

	/// @dev Update the nounsTokenAddress address and nounsToken.
	function setNounsTokenAddress(address _address) external nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		nounsTokenAddress = _address;
		nounsToken = INounsToken(_address);
	}

	/// @dev Update the fracVaultFactoryAddress address and fracVaultFactory.
	function setFracVaultFactoryAddress(address _address) external nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		fracVaultFactoryAddress = _address;
		fracVaultFactory = IFracVaultFactory(_address);
	}

	/// @dev Update the nounsPartyCuratorAddress address.
	function setNounsPartyCuratorAddress(address _address) external nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		nounsPartyCuratorAddress = _address;
	}

	/// @dev Update the nounsPartyTreasuryAddress address.
	function setNounsPartyTreasuryAddress(address _address) external nonReentrant whenPaused onlyOwner {
		require(_address != address(0), "zero address");
		nounsPartyTreasuryAddress = _address;
	}

	/// @dev Update the nouns party fee.
	function setNounsPartyFee(uint256 _fee) external nonReentrant whenPaused onlyOwner {
		emit LogSetNounsPartyFee(_fee);
		nounsPartyFee = _fee;
	}

	/// @dev Update bid increase. No pause required.
	function setBidIncrease(uint256 _bidIncrease) external nonReentrant onlyOwner {
		require(_bidIncrease > 0, "Must be > 0");
		emit LogBidIncrease(_bidIncrease);
		bidIncrease = _bidIncrease;
	}

	/// @dev Update nounsAuctionHouse's bid increase. No pause required.
	function setNounsAuctionHouseBidIncrease(uint256 _bidIncrease) external nonReentrant onlyOwner {
		require(_bidIncrease > 0, "Must be > 0");
		emit LogNounsAuctionHouseBidIncrease(_bidIncrease);
		nounsAuctionHouseBidIncrease = _bidIncrease;
	}

	/// @dev Update allowBid. No pause required.
	function setAllowBid(bool _allow) external nonReentrant onlyOwner {
		emit LogAllowBid(_allow);
		allowBid = _allow;
	}

	/// @dev Pause the contract, freezing core functionalities to prevent bad things from happening in case of emergency.
	function pause() external nonReentrant onlyOwner {
		emit LogPause();
		_pause();
	}

	/// @dev Unpause the contract.
	function unpause() external nonReentrant onlyOwner {
		emit LogUnpause();
		_unpause();
	}

	/// @dev Authorize OpenZepplin's upgrade function, guarded by onlyOwner.
	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {} // solhint-disable-line no-empty-blocks

	/// @dev Transfer ETH and revert if unsuccessful. Only forward 30,000 gas to the callee.
	function _transferETH(address _to, uint256 _value) private {
		(bool success, ) = _to.call{ value: _value, gas: 30_000 }(new bytes(0)); // solhint-disable-line avoid-low-level-calls
		require(success, "Transfer failed");
	}

	/// @dev Allow contract to receive Eth. For example when we are outbid.
	receive() external payable {} // solhint-disable-line no-empty-blocks
}
