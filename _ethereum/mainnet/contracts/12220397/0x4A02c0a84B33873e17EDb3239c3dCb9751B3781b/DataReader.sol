pragma solidity >=0.4.25 <0.7.0;
pragma experimental ABIEncoderV2;

// OpenZeppelin Base
import "./SafeMathUpgradeable.sol";
// Abstracts
import "./Manageable.sol";
import "./Staking.sol";
// Interfaces
import "./IAuctionData.sol";
import "./IStakingData.sol";
import "./IStakingV1.sol";
import "./IAuctionV1.sol";

contract DataReader is Initializable, Manageable {
    using SafeMathUpgradeable for uint256;

    struct StakeV1 {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 shares;
        uint256 firstPayout;
    }

    struct StakeV2 {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 shares;
        uint256 firstPayout;
        uint256 lastPayout;
        bool withdrawn;
        uint256 payout;
    }

    struct AuctionBid {
        uint256 eth;
        address ref;
    }

    IStakingData internal staking;
    IStakingV1 internal stakingV1;
    IAuctionData internal auction;
    IAuctionV1 internal auctionV1;

    function initialize(
        address _manager,
        address _staking,
        address _stakingV1,
        address _auction,
        address _auctionV1
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);

        staking = IStakingData(_staking);
        stakingV1 = IStakingV1(_stakingV1);
        auction = IAuctionData(_auction);
        auctionV1 = IAuctionV1(_auctionV1);
    }

    function getAuctionBidsV1(address account)
        external
        view
        returns (AuctionBid[] memory)
    {
        uint256[] memory v1BidsOfAccount = auctionV1.auctionsOf_(account);
        AuctionBid[] memory bids = new AuctionBid[](v1BidsOfAccount.length);

        for (uint256 i = 0; i < v1BidsOfAccount.length; i++) {
            (uint256 eth, address ref) =
                auctionV1.auctionBetOf(v1BidsOfAccount[i], account);

            if (v1BidsOfAccount[i] > auction.lastAuctionEventIdV1()) continue;

            bids[i] = AuctionBid({eth: eth, ref: ref});
        }

        return bids;
    }

    function getAuctionBidsV2(address account)
        external
        view
        returns (AuctionBid[] memory)
    {
        uint256[] memory v2BidsOfAccount = auction.auctionsOf_(account);
        AuctionBid[] memory bids = new AuctionBid[](v2BidsOfAccount.length);

        for (uint256 i = 0; i < v2BidsOfAccount.length; i++) {
            (uint256 eth, address ref) =
                auction.auctionBidOf(v2BidsOfAccount[i], account);

            bids[i] = AuctionBid({eth: eth, ref: ref});
        }

        return bids;
    }

    function getSessionsV2(address account)
        external
        view
        returns (StakeV2[] memory)
    {
        uint256[] memory v2SessionsOfAccount = staking.sessionsOf_(account);
        StakeV2[] memory stakes = new StakeV2[](v2SessionsOfAccount.length);
        for (uint256 i = 0; i < v2SessionsOfAccount.length; i++) {
            (
                uint256 amount,
                uint256 start,
                uint256 end,
                uint256 shares,
                uint256 firstPayout,
                uint256 lastPayout,
                bool withdrawn,
                uint256 payout
            ) = staking.sessionDataOf(account, v2SessionsOfAccount[i]);

            stakes[i] = StakeV2({
                amount: amount,
                start: start,
                end: end,
                shares: shares,
                firstPayout: firstPayout,
                lastPayout: lastPayout,
                withdrawn: withdrawn,
                payout: payout
            });
        }

        return stakes;
    }

    function getSessionsV1(address account)
        external
        view
        returns (StakeV1[] memory)
    {
        uint256[] memory v1SessionsOfAccount = stakingV1.sessionsOf_(account);
        StakeV1[] memory stakes = new StakeV1[](v1SessionsOfAccount.length);
        for (uint256 i = 0; i < v1SessionsOfAccount.length; i++) {
            if (v1SessionsOfAccount[i] > staking.lastSessionIdV1()) continue; //make sure we only take layer 1 stakes in consideration

            (
                uint256 amount,
                uint256 start,
                uint256 end,
                uint256 shares,
                uint256 firstPayout
            ) = stakingV1.sessionDataOf(account, v1SessionsOfAccount[i]);

            stakes[i] = StakeV1({
                amount: amount,
                start: start,
                end: end,
                shares: shares,
                firstPayout: firstPayout
            });
        }

        return stakes;
    }

    function getDaoShares(address account) external view returns (uint256) {
        uint256 totalShares;

        uint256[] memory v2SessionsOfAccount = staking.sessionsOf_(account);
        for (uint256 i = 0; i < v2SessionsOfAccount.length; i++) {
            (
                ,
                uint256 start,
                uint256 end,
                uint256 shares,
                ,
                ,
                bool withdrawn,

            ) = staking.sessionDataOf(account, v2SessionsOfAccount[i]);
            uint256 stakingDays = (end - start) / staking.stepTimestamp();

            if (withdrawn || stakingDays < 350) {
                continue;
            }

            totalShares = totalShares.add(shares);
        }

        uint256[] memory v1SessionsOfAccount = stakingV1.sessionsOf_(account);

        for (uint256 i = 0; i < v1SessionsOfAccount.length; i++) {
            (, , , uint256 sharesV2, , , , ) =
                staking.sessionDataOf(account, v1SessionsOfAccount[i]);

            if (sharesV2 != 0)
                //make sure the stake was not withdran.
                continue;

            if (v1SessionsOfAccount[i] > staking.lastSessionIdV1()) continue; //make sure we only take layer 1 stakes in consideration

            (, uint256 start, uint256 end, uint256 shares, ) =
                stakingV1.sessionDataOf(account, v1SessionsOfAccount[i]);

            uint256 stakingDays = (end - start) / staking.stepTimestamp();
            if (shares == 0 || stakingDays < 350) continue;

            totalShares = totalShares.add(shares); //calclate total shares
        }

        return totalShares;
    }
}
