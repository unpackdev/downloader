// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./TransferHelper.sol";
import "./TickMath.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IERC20.sol";
import "./Ownable.sol";

interface Cycliq is IERC20 {
    function mint(address account, uint256 amount) external;
}

interface IStakingContract {
    function fund(uint256 duration) external payable;
}

contract Bonding is Ownable {
    uint24 public constant poolFee = 10000;

    uint24 public bondPct = 115;
    uint24 public constant lockTerm = 1 weeks;

    address public immutable cliq;
    IUniswapV2Router02 public immutable uniswapV2Router02;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    IUniswapV3Pool public immutable v3LP;
    IStakingContract public immutable stakingContract;

    address private marketing = 0xcf57ff60410d32d52357772363cd4CD57e70D312;
    address private community = 0xa3297BD4CfB1AC966b6Cdc7e81FD239016Bd6Fc2;

    uint256 private v3LpPct = 60;
    uint256 private stakingPct = 20;
    uint256 private marketingPct = 15;
    uint256 private communityPct = 5;

    uint256 public treasuryForV3LP;
    uint256 public treasuryForStaking;

    address[] public uniV2PairPath;
    address public weth;

    bool public live;

    struct BondInfo {
        uint256 lockedAmount;
        uint256 deadline;
        bool claim;
    }

    mapping(address => BondInfo[]) public userBonds;
    mapping(address => uint256) public userBondEth;

    uint256 public totalBondAmount;
    uint256 public totalLockedAmount;
    bool public wethBaseInV3LP;

    event V3LPCreated(
        uint256 tokenId,
        int24 minTick,
        int24 maxTick,
        uint256 fund
    );

    event V3LPIncreased(uint256 tokenId, uint256 fund);

    event FundToStaking(uint256 duration, uint256 fund);

    constructor(
        IUniswapV2Router02 _uniswapV2Router02,
        INonfungiblePositionManager _nonfungiblePositionManager,
        address _cliq,
        IUniswapV3Pool _v3LP,
        IStakingContract _stakingContract
    ) {
        cliq = _cliq;
        uniswapV2Router02 = _uniswapV2Router02;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        v3LP = IUniswapV3Pool(_v3LP);
        stakingContract = _stakingContract;

        uniV2PairPath = new address[](2);
        uniV2PairPath[0] = _uniswapV2Router02.WETH();
        uniV2PairPath[1] = _cliq;

        weth = _uniswapV2Router02.WETH();

        wethBaseInV3LP = IUniswapV3Pool(_v3LP).token0() == weth ? true : false;

        TransferHelper.safeApprove(
            weth,
            address(_nonfungiblePositionManager),
            uint256(-1)
        );
        TransferHelper.safeApprove(
            _cliq,
            address(_nonfungiblePositionManager),
            uint256(-1)
        );
    }

    receive() external payable {}

    function getCliqPerEth(uint256 ethAmount) public view returns (uint256) {
        return uniswapV2Router02.getAmountsOut(ethAmount, uniV2PairPath)[1];
    }

    function bond() external payable {
        require(live, "bonding is not live yet.");
        require(msg.value > 0, "bonding amount is 0.");
        uint256 orgBuyableCliqAmount = getCliqPerEth(msg.value);

        uint256 userCliqAmount = (orgBuyableCliqAmount * bondPct) / 100;
        uint256 userCliqInstantOutAmount = userCliqAmount / 2;
        uint256 userCliqLockAmount = userCliqAmount - userCliqInstantOutAmount;

        totalBondAmount += userCliqAmount;
        totalLockedAmount += userCliqLockAmount;

        userBonds[msg.sender].push(
            BondInfo(userCliqLockAmount, block.timestamp + lockTerm, false)
        );

        userBondEth[msg.sender] += msg.value;

        Cycliq(cliq).mint(msg.sender, userCliqInstantOutAmount);

        payable(marketing).transfer((msg.value * marketingPct) / 100);
        payable(community).transfer((msg.value * communityPct) / 100);
        treasuryForStaking += (msg.value * stakingPct) / 100;
        treasuryForV3LP += (msg.value * v3LpPct) / 100;
    }

    function bondCount(address addr) external view returns (uint256) {
        return userBonds[addr].length;
    }

    function unlock(uint256 bondIndex) external {
        require(bondIndex < userBonds[msg.sender].length, "out range.");
        BondInfo storage bondInfo = userBonds[msg.sender][bondIndex];
        require(!bondInfo.claim, "Already unlocked.");

        totalLockedAmount -= bondInfo.lockedAmount;
        bondInfo.claim = true;

        if (block.timestamp >= bondInfo.deadline) {
            Cycliq(cliq).mint(msg.sender, bondInfo.lockedAmount);
        } else {
            Cycliq(cliq).mint(
                msg.sender,
                bondInfo.lockedAmount / 2
            );
        }
    }

    function createV3SingleSidedLP()
        external
        onlyOwner
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        uint256 fundForV3LP = treasuryForV3LP + (address(this).balance - treasuryForV3LP - treasuryForStaking) / 2;

        IWETH(weth).deposit{value: fundForV3LP}();

        int24 tickSpacing = v3LP.tickSpacing();
        int24 currentTick;
        (, currentTick, , , , , ) = v3LP.slot0();

        int24 minTick = wethBaseInV3LP
            ? currentTick + (tickSpacing * 5)
            : TickMath.MIN_TICK;
        int24 maxTick = wethBaseInV3LP
            ? TickMath.MAX_TICK
            : currentTick - (tickSpacing * 5);

        minTick = (minTick / tickSpacing) * tickSpacing;
        maxTick = (maxTick / tickSpacing) * tickSpacing;

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: wethBaseInV3LP ? weth : cliq,
                token1: wethBaseInV3LP ? cliq : weth,
                fee: poolFee,
                tickLower: minTick,
                tickUpper: maxTick,
                amount0Desired: wethBaseInV3LP ? fundForV3LP : 0,
                amount1Desired: wethBaseInV3LP ? 0 : fundForV3LP,
                amount0Min: 0,
                amount1Min: 0,
                recipient: owner(),
                deadline: block.timestamp
            });
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
            .mint(params);

        treasuryForStaking = address(this).balance;
        treasuryForV3LP = 0;
        emit V3LPCreated(tokenId, minTick, maxTick, fundForV3LP);
    }

    function increaseV3SingleSidedLP(
        uint256 tokenId
    )
        external
        onlyOwner
        returns (uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        uint256 fundForV3LP = treasuryForV3LP + (address(this).balance - treasuryForV3LP - treasuryForStaking) / 2;

        IWETH(weth).deposit{value: fundForV3LP}();

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: wethBaseInV3LP ? fundForV3LP : 0,
                    amount1Desired: wethBaseInV3LP ? 0 : fundForV3LP,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        (liquidity, amount0, amount1) = nonfungiblePositionManager
            .increaseLiquidity(params);

        treasuryForStaking = address(this).balance;
        treasuryForV3LP = 0;
        emit V3LPIncreased(tokenId, fundForV3LP);
    }

    function fundToStaking(uint256 duration) external onlyOwner {
        uint256 fundForStaking = treasuryForStaking + (address(this).balance - treasuryForV3LP - treasuryForStaking) / 2;
        stakingContract.fund{value: fundForStaking}(duration);
        treasuryForV3LP = address(this).balance;
        treasuryForStaking = 0;
        emit FundToStaking(duration, fundForStaking);
    }

    function setLive() external onlyOwner {
        if(!live) {
            live = true;
        }
    }

    function setBondPct(uint24 _bondPct) external onlyOwner {
        bondPct = _bondPct;
    }
}
