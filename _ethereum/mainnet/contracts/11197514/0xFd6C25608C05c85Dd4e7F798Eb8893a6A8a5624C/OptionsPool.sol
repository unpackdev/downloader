// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Create2.sol";
import "./IERC20.sol";
import "./SafeMathInt.sol";
import "./RebaseableToken.sol";
import "./IPriceOracleGetter.sol";
import "./IMinimalBPool.sol";

// import "./console.sol";

contract OptionsPool {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint256 public upsLiquidated;
    uint256 public downsLiquidated;

    RebaseableToken public up;
    RebaseableToken public down;

    address private owner;

    IPriceOracleGetter public oracle;

    /**
        This is the price returned by the oracle at the
        beginning of thise epoch.
     */
    uint256 public epochStartPrice;

    /**
        This is the blockNumber of the start of this epoch
     */
    uint256 public epochStart;
    /**
        The current epoch
     */
    uint256 public epoch = 1; // 1 index the epoch as we often check for epoch + 1 and also "epoch not defined" for liquidations, etc - and 0 is the same as undefined
    /**
        How many blocks should this epoch last?
     */
    uint256 public epochLength;

    IERC20 public underlying;

    /**
        The token which ups and downs convert into
     */
    IERC20 public payoutToken;

    IMinimalBPool public espool;

    uint8 public multiplier;

    // uint256 public rake = 0; // the amount this pool charges for in percentage as 18 decimal precision integer

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }

    modifier checkEpoch {
        if (block.number >= epochStart.add(epochLength)) {
            endEpoch();
        }
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function testForEnd() public checkEpoch {}

    function createUpAndDown()
        internal
        returns (address upAddr, address downAddr)
    {
        bytes memory bytecode = type(RebaseableToken).creationCode;
        bytes32 upSalt = keccak256(abi.encodePacked(address(this), int8(0)));
        // console.logBytes32(upSalt);
        bytes32 downSalt = keccak256(abi.encodePacked(address(this), int8(1)));
        upAddr = Create2.deploy(0, upSalt, bytecode);
        downAddr = Create2.deploy(0, downSalt, bytecode);

        RebaseableToken(upAddr).initialize("UpDownUp", "udUp", address(this));
        RebaseableToken(downAddr).initialize(
            "UpDownDown",
            "udDn",
            address(this)
        );
        setTokens(upAddr, downAddr);

        return (upAddr, downAddr);
    }

    // following the pattern of uniswap so there can be a pool factory
    function initialize(
        address owner_,
        address payoutToken_,
        uint256 epochLength_,
        uint8 multiplier_,
        address oracle_,
        address underlying_
    ) public isOwner {
        owner = owner_;
        payoutToken = IERC20(payoutToken_);
        oracle = IPriceOracleGetter(oracle_);
        epochStart = block.number;
        epochLength = epochLength_;
        multiplier = multiplier_;
        underlying = IERC20(underlying_);
        epochStartPrice = oracle.getAssetPrice(underlying_);
        createUpAndDown();
    }

    function setESPool(address espool_) public isOwner {
        espool = IMinimalBPool(espool_);
    }

    function setTokens(address up_, address down_) internal isOwner {
        up = RebaseableToken(up_);
        down = RebaseableToken(down_);
    }

    function setOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    /**
        calculate the percent change defined as an 18 precision decimal (1e18 is 100%)
     */
    function percentChangeMax100(uint256 diff, uint256 base)
        internal
        view
        returns (uint256)
    {
        if (base == 0) {
            return 0; // ignore zero price
        }
        uint256 percent = (diff * 10**18).mul(10**18).div(base.mul(10**18)).mul(uint256(multiplier));
        if (percent >= 10**18) {
            percent = uint256(10**18).sub(1);
        }
        return percent;
    }

    function endEpoch() internal {
        updatePrice(oracle.getAssetPrice(address(underlying)));
    }

    // function logPool() internal view {
    //     uint256 pool_ = payoutToken.balanceOf(address(this));
    //     console.log("pool: ", pool_, pool_.div(10**18));
    //     console.log("ups: ", up.totalSupply());
    //     console.log("downs: ", down.totalSupply());
    //     int256 upDownDiff = int256(pool_.mul(200))
    //         .sub(int256(up.totalSupply()))
    //         .sub(int256(down.totalSupply()));
    //     console.log("Diff : ");
    //     console.logInt(upDownDiff);
    // }

    function liquidationAdjustments(
        uint256 pool_,
        uint256 upBal,
        uint256 downBal
    ) internal view returns (uint256 adjustedUp, uint256 adjustedDown) {
        if (upsLiquidated == 0 && downsLiquidated == 0) {
            return (upBal, downBal);
        }
        if (upBal == 0 && downBal == 0) {
            return (0,0);
        }
        // console.log("ups liquidated ", upsLiquidated);
        // console.log("downs liquidated ", downsLiquidated);
        // first add back in the liquidated
        adjustedUp = upBal + upsLiquidated;
        adjustedDown = downBal + downsLiquidated;
        
        uint256 diff = adjustedUp.add(adjustedDown).sub(pool_.mul(200));
        uint256 halfDiff = diff.div(2);

        // console.log("diff from pool to remove equally: ", halfDiff.div(10**18));
        // but now we will rebase down to the current pool size
        uint256 upToRemove = halfDiff;
        uint256 downToRemove = diff.sub(halfDiff);

        if (upToRemove > adjustedUp) {
            downToRemove += upToRemove.sub(adjustedUp);
            upToRemove = adjustedUp;
        }

        if (downToRemove > adjustedDown) {
            upToRemove += downToRemove.sub(adjustedDown);
            downToRemove = adjustedDown;
        }

        if (upToRemove > adjustedUp) {
            upToRemove = adjustedUp;
            // console.log("hit edge case :", downToRemove);
        }

        adjustedUp = adjustedUp.sub(upToRemove);
        adjustedDown = adjustedDown.sub(downToRemove);

        return (adjustedUp, adjustedDown);
    }

    function updatePrice(uint256 newPrice_) internal {
        // console.log(
        //     "--------> ending epoch: ",
        //     epoch,
        //     epochStartPrice,
        //     newPrice_
        // );
        uint256 pool_ = payoutToken.balanceOf(address(this));
        // logPool();
        uint newEpoch = epoch + 1;

        if (pool_ == 0) {
            up.rebase(newEpoch, int256(up.totalSupply()) * -1);
            down.rebase(newEpoch, int256(down.totalSupply()) * -1);
            epochStartPrice = newPrice_;
            epochStart = block.number;
            epoch = newEpoch;
            upsLiquidated = 0;
            downsLiquidated = 0;
            updateEsPool();
            return;
        }
        uint256 upTotal = up.totalSupply();
        uint256 downTotal = down.totalSupply();

        (uint256 adjustedUp, uint256 adjustedDown) = liquidationAdjustments(pool_, upTotal, downTotal);

        upsLiquidated = 0;
        downsLiquidated = 0;

        // console.log("---- real rebase begins ---");

        uint256 currentPrice = epochStartPrice;

        uint256 diff;
        if (newPrice_ > currentPrice) {
            diff = newPrice_.sub(currentPrice);
        } else {
            diff = currentPrice.sub(newPrice_);
        }

        uint256 percent = percentChangeMax100(diff, currentPrice);
        int256 baseUp = int256(adjustedUp).sub(int256(upTotal));
        int256 baseDown = int256(adjustedDown).sub(int256(downTotal));

        if (newPrice_ > currentPrice) {
            int256 take = int256(adjustedDown.mul(percent).div(10**18));
            up.rebase(newEpoch, baseUp.add(take));
            down.rebase(newEpoch, baseDown.sub(take));
        } else {
            int256 take = int256(adjustedUp.mul(percent).div(10**18));
            down.rebase(newEpoch, baseDown.add(take));
            up.rebase(newEpoch, baseUp.sub(take));
        }
        // logPool();
        updateEsPool();
        epochStartPrice = newPrice_;
        epoch = newEpoch;
        epochStart = block.number;
    }

    function updateEsPool() internal {
        if (address(espool) != address(0)) {
            espool.resyncWeights(address(up), address(down));
        }
    }

    /**
        The user wants out of the pool and so at the end of this epoch we will
        let them cash out.
     */
    function settle() public checkEpoch {
        // TODO: set lockedAt and only allow a liquidate then
        up.settle(msg.sender);
        down.settle(msg.sender);
    }

    // TODO: this provides an arbitrage opportunity to withdraw
    // before the end of a period. This should be a lockup.
    function liquidate() public checkEpoch {
        // TODO: only allow this after the lockout period

        address user_ = msg.sender;
        uint256 upBal = up.balanceOf(user_);
        uint256 downBal = down.balanceOf(user_);

        up.liquidate(address(user_));
        down.liquidate(address(user_));

        upsLiquidated += upBal;
        downsLiquidated += downBal;
        // console.log(
        //     "liquidating (ups/downs): ",
        //     upBal.div(10**18),
        //     downBal.div(10**18)
        // );
        uint256 totalPayout = upBal.add(downBal).div(200);
        // console.log(
        //     "liquidate payout to ",
        //     msg.sender,
        //     totalPayout.div(10**18)
        // );

        uint256 fee = totalPayout.div(1000); // 10 basis points fee
        uint256 toUser = totalPayout.sub(fee);
        require(payoutToken.transfer(user_, toUser));
        uint poolBal = payoutToken.balanceOf(address(this));
        if (fee > poolBal) {
            payoutToken.transfer(owner, poolBal);
            return;
        }
        require(payoutToken.transfer(owner, fee));
    }

    function deposit(uint256 amount) public checkEpoch {
        require(payoutToken.transferFrom(msg.sender, address(this), amount));

        // console.log(
        //     "at deposit time: ",
        //     up.totalSupply().div(10**18),
        //     down.totalSupply().div(10**18)
        // );

        require(up.mint(msg.sender, amount.mul(100)));
        require(down.mint(msg.sender, amount.mul(100)));
    }
}
