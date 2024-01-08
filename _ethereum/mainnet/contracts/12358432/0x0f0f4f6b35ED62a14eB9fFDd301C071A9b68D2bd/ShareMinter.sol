// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./ERC165Checker.sol";
import "./FullMath.sol";
import "./IHEX.sol";
import "./MinterReceiver.sol";

/// @title HEX Share Minter
/// @author Sam Presnal - Staker
/// @dev Mint shares to any receiving contract that implements the
/// MinterReceiver abstract contract
/// @notice Minter rewards are claimable by ANY caller
/// if the 10 day grace period has expired
contract ShareMinter {
    IHEX public hexContract;

    uint256 private constant GRACE_PERIOD_DAYS = 10;
    uint256 private constant FEE_SCALE = 1000;

    struct Stake {
        uint16 shareRatePremium;
        uint24 unlockDay;
        address minter;
        MinterReceiver receiver;
    }
    mapping(uint40 => Stake) public stakes;

    mapping(address => uint256) public minterHeartsOwed;

    event MintShares(
        uint40 indexed stakeId,
        MinterReceiver indexed receiver,
        uint256 data0 //total shares | staked hearts << 72
    );
    event MintEarnings(uint40 indexed stakeId, MinterReceiver indexed receiver, uint72 hearts);
    event MinterWithdraw(address indexed minter, uint256 heartsWithdrawn);

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(IHEX _hex) {
        hexContract = _hex;
    }

    /// @notice Starts stake and mints shares to the specified receiver
    /// @param shareRatePremium Applies premium to share price between 0.0-99.9%
    /// @param receiver The contract to receive the newly minted shares
    /// @param supplier The reimbursement address for the supplier
    /// @param newStakedHearts Hearts to stake to the HEX contract
    /// @param newStakedDays Days in length of the stake
    function mintShares(
        uint16 shareRatePremium,
        MinterReceiver receiver,
        address supplier,
        uint256 newStakedHearts,
        uint256 newStakedDays
    ) external lock {
        require(shareRatePremium < FEE_SCALE, "PREMIUM_TOO_HIGH");
        require(
            ERC165Checker.supportsInterface(address(receiver), type(MinterReceiver).interfaceId),
            "UNSUPPORTED_RECEIVER"
        );

        //Transfer HEX to contract
        hexContract.transferFrom(msg.sender, address(this), newStakedHearts);

        //Start stake
        (uint40 stakeId, uint72 stakedHearts, uint72 stakeShares, uint24 unlockDay) =
            _startStake(newStakedHearts, newStakedDays);

        //Calculate minterShares and marketShares
        uint256 minterShares = FullMath.mulDiv(shareRatePremium, stakeShares, FEE_SCALE);
        uint256 marketShares = stakeShares - minterShares;

        //Mint shares to the market and store stake info for later
        receiver.onSharesMinted(stakeId, supplier, stakedHearts, uint72(marketShares));
        stakes[stakeId] = Stake(shareRatePremium, unlockDay, msg.sender, receiver);

        emit MintShares(stakeId, receiver, uint256(uint72(stakeShares)) | (uint256(uint72(stakedHearts)) << 72));
    }

    function _startStake(uint256 newStakedHearts, uint256 newStakedDays)
        internal
        returns (
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint24 unlockDay
        )
    {
        hexContract.stakeStart(newStakedHearts, newStakedDays);
        uint256 stakeCount = hexContract.stakeCount(address(this));
        (uint40 _stakeId, uint72 _stakedHearts, uint72 _stakeShares, uint16 _lockedDay, uint16 _stakedDays, , ) =
            hexContract.stakeLists(address(this), stakeCount - 1);
        return (_stakeId, _stakedHearts, _stakeShares, _lockedDay + _stakedDays);
    }

    /// @notice Ends stake, transfers hearts, and calls receiver onEarningsMinted
    /// @dev The stake must be mature in order to mint earnings
    /// @param stakeIndex Index of the stake to be ended
    /// @param stakeId StakeId of the stake to be ended
    function mintEarnings(uint256 stakeIndex, uint40 stakeId) external lock {
        //Ensure the stake has matured
        Stake memory stake = stakes[stakeId];
        uint256 currentDay = hexContract.currentDay();
        require(currentDay >= stake.unlockDay, "STAKE_NOT_MATURE");

        //Calculate minter earnings and market earnings
        uint256 heartsEarned = _endStake(stakeIndex, stakeId);
        uint256 minterEarnings = FullMath.mulDiv(stake.shareRatePremium, heartsEarned, FEE_SCALE);
        uint256 marketEarnings = heartsEarned - minterEarnings;

        //Transfer market earnings to receiver contract and notify
        MinterReceiver receiver = stake.receiver;
        hexContract.transfer(address(receiver), marketEarnings);
        receiver.onEarningsMinted(stakeId, uint72(marketEarnings));

        //Pay minter or record payment for claiming later
        _payMinterEarnings(currentDay, stake.unlockDay, stake.minter, minterEarnings);

        emit MintEarnings(stakeId, receiver, uint72(heartsEarned));

        delete stakes[stakeId];
    }

    function _endStake(uint256 stakeIndex, uint40 stakeId) internal returns (uint256 heartsEarned) {
        uint256 prevHearts = hexContract.balanceOf(address(this));
        hexContract.stakeEnd(stakeIndex, stakeId);
        uint256 newHearts = hexContract.balanceOf(address(this));
        heartsEarned = newHearts - prevHearts;
    }

    /// @notice The minter earnings are claimable by any caller
    /// if the grace period has expired. If the grace period has
    /// not expired and the minter is not the caller, then record
    /// the minter earnings. If the minter is the caller,
    /// they will get the earnings sent immediately.
    function _payMinterEarnings(
        uint256 currentDay,
        uint256 unlockDay,
        address minter,
        uint256 minterEarnings
    ) internal {
        uint256 lateDays = currentDay - unlockDay;
        if (msg.sender != minter && lateDays < GRACE_PERIOD_DAYS) {
            minterHeartsOwed[minter] += minterEarnings;
        } else {
            hexContract.transfer(msg.sender, minterEarnings);
        }
    }

    /// @notice Allow minter to withdraw earnings if applicable
    /// @dev Only applies when a non-minter ends a stake before
    /// the grace period has expired
    function minterWithdraw() external lock {
        uint256 heartsOwed = minterHeartsOwed[msg.sender];
        require(heartsOwed != 0, "NO_HEARTS_OWED");

        minterHeartsOwed[msg.sender] = 0;
        hexContract.transfer(msg.sender, heartsOwed);

        emit MinterWithdraw(msg.sender, heartsOwed);
    }
}
