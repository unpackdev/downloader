// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./INonfungiblePositionManager.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IGenesisGroup.sol";
import "./ICore.sol";
import "./IRewardsDistributor.sol";
import "./IOrchestrator.sol";
import "./IRing.sol";

// solhint-disable-next-line max-states-count
contract CoreOrchestrator is Ownable {
    address public admin;

    // ----------- Uniswap Addresses -----------
    address public constant USDC_USDT_UNI_POOL =
        address(0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf);
    address public constant USDC_DAI_UNI_POOL =
        address(0x6c6Bc977E13Df9b0de53b251522280BB72383700);
    address public constant NFT =
        address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address public constant ROUTER =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);


    address public constant USDC =
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant USDT =
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public constant DAI =
        address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address public usdcRusdPool;
    address public usdtRusdPool;
    address public daiRusdPool;
    address public ringRusdPool;

    // ----------- Time periods -----------
    uint256 public constant TOKEN_TIMELOCK_RELEASE_WINDOW = 3 * 365 days;

    uint256 public constant DAO_TIMELOCK_DELAY = 1 days;

    uint256 public constant STAKING_REWARDS_DURATION = 2 * 365 days;

    uint256 public constant STAKING_REWARDS_DRIP_FREQUENCY = 1 weeks;

    uint32 public constant UNI_ORACLE_TWAP_DURATION = 10 minutes; // 10 min twap

    uint256 public constant BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY = 1 days; // 1 day duration

    // ----------- Params -----------
    uint256 public constant RING_KEEPER_INCENTIVE = 100e18;

    uint256 public constant MIN_REWEIGHT_DISTANCE_BPS = 100;

    bool public constant USDC_PER_USDT_IS_PRICE_0 = USDT < USDC; // for the USDT_USDC pair
    bool public constant USDC_PER_DAI_IS_PRICE_0 = DAI < USDC; // for the DAI_USDC pair

    uint256 public ringSupply;
    uint256 public constant IDO_RING_PERCENTAGE = 1;
    uint256 public constant STAKING_RING_PERCENTAGE = 10;

    uint256 public constant RING_GRANTS_AMT = 60_000_000e18;
    uint256[3] public RING_TIMELOCK_AMTS = [
        uint256(150_000_000e18),
        uint256(150_000_000e18),
        uint256(130_000_000e18)
    ];

    // ----------- Orchestrators -----------
    IPCVDepositOrchestrator private pcvDepositOrchestrator;
    IUSDCPCVDepositOrchestrator private usdcPCVDepositOrchestrator;
    IBondingCurveOrchestrator private bcOrchestrator;
    IControllerOrchestrator private controllerOrchestrator;
    IIDOOrchestrator private idoOrchestrator;
    IGenesisOrchestrator private genesisOrchestrator;
    IGovernanceOrchestrator private governanceOrchestrator;
    IStakingOrchestrator private stakingOrchestrator;

    // ----------- Deployed Contracts -----------
    ICore public core;
    address public rusd;
    address public ring;

    address public usdcUniswapPCVDeposit;
    address public usdtUniswapPCVDeposit;
    address public daiUniswapPCVDeposit;
    address public usdcBondingCurve;
    address public usdtBondingCurve;
    address public daiBondingCurve;

    address public usdcUniswapOracle;
    address public usdtUniswapOracle;
    address public daiUniswapOracle;

    address public usdcUniswapPCVController;
    address public usdtUniswapPCVController;
    address public daiUniswapPCVController;

    address public ido;
    address public timelockedDelegator;
    address[] public timelockedDelegators;

    address public genesisGroup;

    address public ringStakingRewards;
    address public ringRewardsDistributor;

    address public governorAlpha;
    address public timelock;

    constructor(
        address _pcvDepositOrchestrator,
        address _usdcPCVDepositOrchestrator,
        address _bcOrchestrator,
        address _controllerOrchestrator,
        address _idoOrchestrator,
        address _genesisOrchestrator,
        address _governanceOrchestrator,
        address _stakingOrchestrator,
        address _admin
    ) {
        require(_admin != address(0), "CoreOrchestrator: no admin");

        pcvDepositOrchestrator = IPCVDepositOrchestrator(
            _pcvDepositOrchestrator
        );
        usdcPCVDepositOrchestrator = IUSDCPCVDepositOrchestrator(
            _usdcPCVDepositOrchestrator
        );
        bcOrchestrator = IBondingCurveOrchestrator(_bcOrchestrator);
        idoOrchestrator = IIDOOrchestrator(_idoOrchestrator);
        controllerOrchestrator = IControllerOrchestrator(
            _controllerOrchestrator
        );
        genesisOrchestrator = IGenesisOrchestrator(_genesisOrchestrator);
        governanceOrchestrator = IGovernanceOrchestrator(
            _governanceOrchestrator
        );
        stakingOrchestrator = IStakingOrchestrator(_stakingOrchestrator);

        admin = _admin;
    }

    function initCore(address _core) public onlyOwner {
        core = ICore(_core);

        core.init();
        core.grantGuardian(admin);

        ring = address(core.ring());
        rusd = address(core.rusd());
        ringSupply = IERC20(ring).totalSupply();
    }

    function initPoolUSDC() public onlyOwner {
        usdcRusdPool = INonfungiblePositionManager(NFT).createAndInitializePoolIfNecessary(
            rusd < USDC ? rusd : USDC, rusd < USDC ? USDC : rusd, 500, rusd < USDC ? 79228162514264337593543 : 79228162514264337593543950336000000
        );
    }

    function initPoolUSDT() public onlyOwner {
        usdtRusdPool = INonfungiblePositionManager(NFT).createAndInitializePoolIfNecessary(
            rusd < USDT ? rusd : USDT, rusd < USDT ? USDT : rusd, 500, rusd < USDT ? 79228162514264337593543 : 79228162514264337593543950336000000
        );
    }

     function initPoolDAI() public onlyOwner {
        daiRusdPool = INonfungiblePositionManager(NFT).createAndInitializePoolIfNecessary(
            rusd < DAI ? rusd : DAI, rusd < DAI ? DAI : rusd, 500, 79228162514264337593543950336
        );
    }

    function initPoolGovernanceToken() public onlyOwner {
        ringRusdPool = INonfungiblePositionManager(NFT).createAndInitializePoolIfNecessary(
            ring < rusd ? ring : rusd, ring < rusd ? rusd : ring, 3000, ring < rusd ? 17715955711429571029610171616 : 354319114228591420592203432321
        );
    }

    function initPCVDepositUSDC() public onlyOwner() {
        (int24 usdcTickLower, int24 usdcTickUpper) = rusd < USDC ? (-276530, -276130) : (int24(276120), int24(276520));
        (usdcUniswapPCVDeposit, usdcUniswapOracle) = usdcPCVDepositOrchestrator.init(
            address(core),
            usdcRusdPool,
            NFT,
            ROUTER,
            UNI_ORACLE_TWAP_DURATION,
            usdcTickLower,
            usdcTickUpper
        );
        core.grantMinter(usdcUniswapPCVDeposit);
        usdcPCVDepositOrchestrator.detonate();
    }

    function initPCVDepositUSDT() public onlyOwner() {
        (int24 usdtTickLower, int24 usdtTickUpper) = rusd < USDT ? (-276530, -276130) : (int24(276120), int24(276520));
        (usdtUniswapPCVDeposit, usdtUniswapOracle) = pcvDepositOrchestrator.init(
            address(core),
            usdtRusdPool,
            NFT,
            ROUTER,
            USDC_USDT_UNI_POOL,
            UNI_ORACLE_TWAP_DURATION,
            USDC_PER_USDT_IS_PRICE_0,
            usdtTickLower,
            usdtTickUpper
        );
        core.grantMinter(usdtUniswapPCVDeposit);
    }

    function initPCVDepositDAI() public onlyOwner() {
        (daiUniswapPCVDeposit, daiUniswapOracle) = pcvDepositOrchestrator.init(
            address(core),
            daiRusdPool,
            NFT,
            ROUTER,
            USDC_DAI_UNI_POOL,
            UNI_ORACLE_TWAP_DURATION,
            USDC_PER_DAI_IS_PRICE_0,
            -200,
            200
        );
        core.grantMinter(daiUniswapPCVDeposit);
        pcvDepositOrchestrator.detonate();
    }

    function initBondingCurve() public onlyOwner {
        usdcBondingCurve = bcOrchestrator.init(
            address(core),
            usdcUniswapOracle,
            usdcUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            USDC
        );
        core.grantMinter(usdcBondingCurve);

        usdtBondingCurve = bcOrchestrator.init(
            address(core),
            usdtUniswapOracle,
            usdtUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            USDT
        );
        core.grantMinter(usdtBondingCurve);

        daiBondingCurve = bcOrchestrator.init(
            address(core),
            daiUniswapOracle,
            daiUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            DAI
        );
        core.grantMinter(daiBondingCurve);
        bcOrchestrator.detonate();
    }

    function initControllerUSDC() public onlyOwner {
        usdcUniswapPCVController = controllerOrchestrator.init(
            address(core),
            usdcUniswapOracle,
            usdcUniswapPCVDeposit,
            usdcRusdPool,
            NFT,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(usdcUniswapPCVController);
        core.grantPCVController(usdcUniswapPCVController);
    }

    function initControllerUSDT() public onlyOwner {
        usdtUniswapPCVController = controllerOrchestrator.init(
            address(core),
            usdtUniswapOracle,
            usdtUniswapPCVDeposit,
            usdtRusdPool,
            NFT,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(usdtUniswapPCVController);
        core.grantPCVController(usdtUniswapPCVController);
    }

    function initControllerDAI() public onlyOwner {
        daiUniswapPCVController = controllerOrchestrator.init(
            address(core),
            daiUniswapOracle,
            daiUniswapPCVDeposit,
            daiRusdPool,
            NFT,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(daiUniswapPCVController);
        core.grantPCVController(daiUniswapPCVController);
        controllerOrchestrator.detonate();
    }

    function initIDO() public onlyOwner {
        (ido, timelockedDelegator) = idoOrchestrator.init(
            address(core),
            admin,
            ring,
            ringRusdPool,
            NFT,
            ROUTER,
            TOKEN_TIMELOCK_RELEASE_WINDOW
        );
        core.grantMinter(ido);
        core.grantBurner(ido);

        core.allocateRing(ido, (ringSupply * IDO_RING_PERCENTAGE) / 100);

        idoOrchestrator.detonate();
    }

    function initTimelocks(address[] memory _timelockedDelegators) public onlyOwner {
        require(timelockedDelegators.length == 0, "Already initialized");

        uint256 length = RING_TIMELOCK_AMTS.length;
        require(_timelockedDelegators.length == length, "Length mismatch");

        for (uint i = 0; i < length; i++) {
            core.allocateRing(
                _timelockedDelegators[i],
                RING_TIMELOCK_AMTS[i]
            );
        }

        core.allocateRing(
            admin,
            RING_GRANTS_AMT
        );

        timelockedDelegators = _timelockedDelegators;
    }

    function initGenesis() public onlyOwner {
        (genesisGroup) = genesisOrchestrator.init(
            address(core),
            ido
        );
        core.setGenesisGroup(genesisGroup);

        genesisOrchestrator.detonate();
    }

    function initStaking() public onlyOwner {
        (ringStakingRewards, ringRewardsDistributor) = stakingOrchestrator.init(
            address(core),
            rusd,
            ring,
            STAKING_REWARDS_DURATION,
            STAKING_REWARDS_DRIP_FREQUENCY,
            RING_KEEPER_INCENTIVE
        );

        core.allocateRing(
            ringRewardsDistributor,
            (ringSupply * STAKING_RING_PERCENTAGE) / 100
        );
        core.grantMinter(ringRewardsDistributor);

        IRewardsDistributor(ringRewardsDistributor).setStakingContract(ringStakingRewards);

        stakingOrchestrator.detonate();
    }

    function initGovernance() public onlyOwner {
        (governorAlpha, timelock) = governanceOrchestrator.init(
            ring,
            admin,
            DAO_TIMELOCK_DELAY
        );
        governanceOrchestrator.detonate();
        core.grantGovernor(timelock);
        IRing(ring).setMinter(timelock);
    }

    function renounceGovernor() public onlyOwner {
        core.revokeGovernor(address(this));
        renounceOwnership();
    }
}
