// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBeanstalkUpgradeable {
    event SetFertilizer(uint128 id, uint128 bpf);

    function addFertilizerOwner(uint128 id, uint128 amount, uint256 minLP) external payable;

    function balanceOfBatchFertilizer(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (IFertilizer.Balance[] memory);

    function balanceOfFertilized(
        address account,
        uint256[] memory ids
    ) external view returns (uint256 beans);

    function balanceOfFertilizer(
        address account,
        uint256 id
    ) external view returns (IFertilizer.Balance memory);

    function balanceOfUnfertilized(
        address account,
        uint256[] memory ids
    ) external view returns (uint256 beans);

    function beansPerFertilizer() external view returns (uint128 bpf);

    function claimFertilized(uint256[] memory ids, uint8 mode) external payable;

    function getActiveFertilizer() external view returns (uint256);

    function getCurrentHumidity() external view returns (uint128 humidity);

    function getEndBpf() external view returns (uint128 endBpf);

    function getFertilizer(uint128 id) external view returns (uint256);

    function getFertilizers() external view returns (FertilizerFacet.Supply[] memory fertilizers);

    function getFirst() external view returns (uint128);

    function getHumidity(uint128 _s) external pure returns (uint128 humidity);

    function getLast() external view returns (uint128);

    function getNext(uint128 id) external view returns (uint128);

    function isFertilizing() external view returns (bool);

    function mintFertilizer(uint128 amount, uint256 minLP, uint8 mode) external payable;

    function payFertilizer(address account, uint256 amount) external payable;

    function remainingRecapitalization() external view returns (uint256);

    function totalFertilizedBeans() external view returns (uint256 beans);

    function totalFertilizerBeans() external view returns (uint256 beans);

    function totalUnfertilizedBeans() external view returns (uint256 beans);

    event AddUnripeToken(
        address indexed unripeToken,
        address indexed underlyingToken,
        bytes32 merkleRoot
    );
    event ChangeUnderlying(address indexed token, int256 underlying);
    event Chop(address indexed account, address indexed token, uint256 amount, uint256 underlying);
    event Pick(address indexed account, address indexed token, uint256 amount);

    function _getPenalizedUnderlying(
        address unripeToken,
        uint256 amount,
        uint256 supply
    ) external view returns (uint256 redeem);

    function addUnripeToken(
        address unripeToken,
        address underlyingToken,
        bytes32 root
    ) external payable;

    function balanceOfPenalizedUnderlying(
        address unripeToken,
        address account
    ) external view returns (uint256 underlying);

    function balanceOfUnderlying(
        address unripeToken,
        address account
    ) external view returns (uint256 underlying);

    function chop(
        address unripeToken,
        uint256 amount,
        uint8 fromMode,
        uint8 toMode
    ) external payable returns (uint256 underlyingAmount);

    function getPenalizedUnderlying(
        address unripeToken,
        uint256 amount
    ) external view returns (uint256 redeem);

    function getPenalty(address unripeToken) external view returns (uint256 penalty);

    function getPercentPenalty(address unripeToken) external view returns (uint256 penalty);

    function getRecapFundedPercent(address unripeToken) external view returns (uint256 percent);

    function getRecapPaidPercent() external view returns (uint256 penalty);

    function getTotalUnderlying(address unripeToken) external view returns (uint256 underlying);

    function getUnderlying(
        address unripeToken,
        uint256 amount
    ) external view returns (uint256 redeem);

    function getUnderlyingPerUnripeToken(
        address unripeToken
    ) external view returns (uint256 underlyingPerToken);

    function getUnderlyingToken(
        address unripeToken
    ) external view returns (address underlyingToken);

    function isUnripe(address unripeToken) external view returns (bool unripe);

    function pick(
        address token,
        uint256 amount,
        bytes32[] memory proof,
        uint8 mode
    ) external payable;

    function picked(address account, address token) external view returns (bool);

    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);

    function facetAddresses() external view returns (address[] memory facetAddresses_);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function claimOwnership() external;

    function owner() external view returns (address owner_);

    function ownerCandidate() external view returns (address ownerCandidate_);

    function transferOwnership(address _newOwner) external;

    event Pause(uint256 timestamp);
    event Unpause(uint256 timestamp, uint256 timePassed);

    function pause() external payable;

    function unpause() external payable;

    function addLiquidity(
        address pool,
        address registry,
        uint256[] memory amounts,
        uint256 minAmountOut,
        uint8 fromMode,
        uint8 toMode
    ) external payable;

    function exchange(
        address pool,
        address registry,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        uint8 fromMode,
        uint8 toMode
    ) external payable;

    function exchangeUnderlying(
        address pool,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        uint8 fromMode,
        uint8 toMode
    ) external payable;

    function removeLiquidity(
        address pool,
        address registry,
        uint256 amountIn,
        uint256[] memory minAmountsOut,
        uint8 fromMode,
        uint8 toMode
    ) external payable;

    function removeLiquidityImbalance(
        address pool,
        address registry,
        uint256[] memory amountsOut,
        uint256 maxAmountIn,
        uint8 fromMode,
        uint8 toMode
    ) external payable;

    function removeLiquidityOneToken(
        address pool,
        address registry,
        address toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        uint8 fromMode,
        uint8 toMode
    ) external payable;

    function advancedPipe(
        AdvancedPipeCall[] memory pipes,
        uint256 value
    ) external payable returns (bytes[] memory results);

    function etherPipe(
        PipeCall memory p,
        uint256 value
    ) external payable returns (bytes memory result);

    function multiPipe(PipeCall[] memory pipes) external payable returns (bytes[] memory results);

    function pipe(PipeCall memory p) external payable returns (bytes memory result);

    function readPipe(PipeCall memory p) external view returns (bytes memory result);

    function advancedFarm(
        AdvancedFarmCall[] memory data
    ) external payable returns (bytes[] memory results);

    function farm(bytes[] memory data) external payable returns (bytes[] memory results);

    event InternalBalanceChanged(address indexed user, address indexed token, int256 delta);
    event TokenApproval(
        address indexed owner,
        address indexed spender,
        address token,
        uint256 amount
    );

    function approveToken(address spender, address token, uint256 amount) external payable;

    function decreaseTokenAllowance(
        address spender,
        address token,
        uint256 subtractedValue
    ) external returns (bool);

    function getAllBalance(
        address account,
        address token
    ) external view returns (Storage.Rain memory b);

    function getAllBalances(
        address account,
        address[] memory tokens
    ) external view returns (Storage.Rain[] memory balances);

    function getBalance(address account, address token) external view returns (uint256 balance);

    function getBalances(
        address account,
        address[] memory tokens
    ) external view returns (uint256[] memory balances);

    function getExternalBalance(
        address account,
        address token
    ) external view returns (uint256 balance);

    function getExternalBalances(
        address account,
        address[] memory tokens
    ) external view returns (uint256[] memory balances);

    function getInternalBalance(
        address account,
        address token
    ) external view returns (uint256 balance);

    function getInternalBalances(
        address account,
        address[] memory tokens
    ) external view returns (uint256[] memory balances);

    function increaseTokenAllowance(
        address spender,
        address token,
        uint256 addedValue
    ) external returns (bool);

    function permitToken(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function tokenAllowance(
        address account,
        address spender,
        address token
    ) external view returns (uint256);

    function tokenPermitDomainSeparator() external view returns (bytes32);

    function tokenPermitNonces(address owner) external view returns (uint256);

    function transferInternalTokenFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount,
        uint8 toMode
    ) external payable;

    function transferToken(
        address token,
        address recipient,
        uint256 amount,
        uint8 fromMode,
        uint8 toMode
    ) external payable;

    function unwrapEth(uint256 amount, uint8 mode) external payable;

    function wrapEth(uint256 amount, uint8 mode) external payable;

    function batchTransferERC1155(
        address token,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) external payable;

    function permitERC20(
        address token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function permitERC721(
        address token,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig
    ) external payable;

    function transferERC1155(address token, address to, uint256 id, uint256 value) external payable;

    function transferERC721(address token, address to, uint256 id) external payable;

    event Harvest(address indexed account, uint256[] plots, uint256 beans);
    event PodListingCancelled(address indexed account, uint256 index);
    event Sow(address indexed account, uint256 index, uint256 beans, uint256 pods);

    function harvest(uint256[] memory plots, uint8 mode) external payable;

    function harvestableIndex() external view returns (uint256);

    function maxTemperature() external view returns (uint256);

    function plot(address account, uint256 index) external view returns (uint256);

    function podIndex() external view returns (uint256);

    function remainingPods() external view returns (uint256);

    function sow(
        uint256 beans,
        uint256 minTemperature,
        uint8 mode
    ) external payable returns (uint256 pods);

    function sowWithMin(
        uint256 beans,
        uint256 minTemperature,
        uint256 minSoil,
        uint8 mode
    ) external payable returns (uint256 pods);

    function temperature() external view returns (uint256);

    function totalHarvestable() external view returns (uint256);

    function totalHarvested() external view returns (uint256);

    function totalPods() external view returns (uint256);

    function totalSoil() external view returns (uint256);

    function totalUnharvestable() external view returns (uint256);

    function yield() external view returns (uint32);

    event CompleteFundraiser(uint32 indexed id);
    event CreateFundraiser(uint32 indexed id, address payee, address token, uint256 amount);
    event FundFundraiser(address indexed account, uint32 indexed id, uint256 amount);

    function createFundraiser(address payee, address token, uint256 amount) external payable;

    function fund(uint32 id, uint256 amount, uint8 mode) external payable returns (uint256);

    function fundingToken(uint32 id) external view returns (address);

    function fundraiser(uint32 id) external view returns (Storage.Fundraiser memory);

    function numberOfFundraisers() external view returns (uint32);

    function remainingFunding(uint32 id) external view returns (uint256);

    function totalFunding(uint32 id) external view returns (uint256);

    event PlotTransfer(address indexed from, address indexed to, uint256 indexed id, uint256 pods);
    event PodApproval(address indexed owner, address indexed spender, uint256 pods);
    event PodListingCreated(
        address indexed account,
        uint256 index,
        uint256 start,
        uint256 amount,
        uint24 pricePerPod,
        uint256 maxHarvestableIndex,
        uint256 minFillAmount,
        bytes pricingFunction,
        uint8 mode,
        uint8 pricingType
    );
    event PodListingFilled(
        address indexed from,
        address indexed to,
        uint256 index,
        uint256 start,
        uint256 amount,
        uint256 costInBeans
    );
    event PodOrderCancelled(address indexed account, bytes32 id);
    event PodOrderCreated(
        address indexed account,
        bytes32 id,
        uint256 amount,
        uint24 pricePerPod,
        uint256 maxPlaceInLine,
        uint256 minFillAmount,
        bytes pricingFunction,
        uint8 priceType
    );
    event PodOrderFilled(
        address indexed from,
        address indexed to,
        bytes32 id,
        uint256 index,
        uint256 start,
        uint256 amount,
        uint256 costInBeans
    );

    function allowancePods(address owner, address spender) external view returns (uint256);

    function approvePods(address spender, uint256 amount) external payable;

    function cancelPodListing(uint256 index) external payable;

    function cancelPodOrder(
        uint24 pricePerPod,
        uint256 maxPlaceInLine,
        uint256 minFillAmount,
        uint8 mode
    ) external payable;

    function cancelPodOrderV2(
        uint256 maxPlaceInLine,
        uint256 minFillAmount,
        bytes memory pricingFunction,
        uint8 mode
    ) external payable;

    function createPodListing(
        uint256 index,
        uint256 start,
        uint256 amount,
        uint24 pricePerPod,
        uint256 maxHarvestableIndex,
        uint256 minFillAmount,
        uint8 mode
    ) external payable;

    function createPodListingV2(
        uint256 index,
        uint256 start,
        uint256 amount,
        uint256 maxHarvestableIndex,
        uint256 minFillAmount,
        bytes memory pricingFunction,
        uint8 mode
    ) external payable;

    function createPodOrder(
        uint256 beanAmount,
        uint24 pricePerPod,
        uint256 maxPlaceInLine,
        uint256 minFillAmount,
        uint8 mode
    ) external payable returns (bytes32 id);

    function createPodOrderV2(
        uint256 beanAmount,
        uint256 maxPlaceInLine,
        uint256 minFillAmount,
        bytes memory pricingFunction,
        uint8 mode
    ) external payable returns (bytes32 id);

    function fillPodListing(
        Listing.PodListing memory l,
        uint256 beanAmount,
        uint8 mode
    ) external payable;

    function fillPodListingV2(
        Listing.PodListing memory l,
        uint256 beanAmount,
        bytes memory pricingFunction,
        uint8 mode
    ) external payable;

    function fillPodOrder(
        Order.PodOrder memory o,
        uint256 index,
        uint256 start,
        uint256 amount,
        uint8 mode
    ) external payable;

    function fillPodOrderV2(
        Order.PodOrder memory o,
        uint256 index,
        uint256 start,
        uint256 amount,
        bytes memory pricingFunction,
        uint8 mode
    ) external payable;

    function getAmountBeansToFillOrderV2(
        uint256 placeInLine,
        uint256 amountPodsFromOrder,
        bytes memory pricingFunction
    ) external pure returns (uint256 beanAmount);

    function getAmountPodsFromFillListingV2(
        uint256 placeInLine,
        uint256 podListingAmount,
        uint256 fillBeanAmount,
        bytes memory pricingFunction
    ) external pure returns (uint256 amount);

    function podListing(uint256 index) external view returns (bytes32);

    function podOrder(
        address account,
        uint24 pricePerPod,
        uint256 maxPlaceInLine,
        uint256 minFillAmount
    ) external view returns (uint256);

    function podOrderById(bytes32 id) external view returns (uint256);

    function podOrderV2(
        address account,
        uint256 maxPlaceInLine,
        uint256 minFillAmount,
        bytes memory pricingFunction
    ) external view returns (uint256);

    function transferPlot(
        address sender,
        address recipient,
        uint256 id,
        uint256 start,
        uint256 end
    ) external payable;

    function bdv(address token, uint256 amount) external view returns (uint256);

    function beanToBDV(uint256 amount) external pure returns (uint256);

    function curveToBDV(uint256 amount) external view returns (uint256);

    function unripeBeanToBDV(uint256 amount) external view returns (uint256);

    function unripeLPToBDV(uint256 amount) external view returns (uint256);

    event Convert(
        address indexed account,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount
    );
    event RemoveDeposits(
        address indexed account,
        address indexed token,
        uint32[] seasons,
        uint256[] amounts,
        uint256 amount
    );

    function convert(
        bytes memory convertData,
        uint32[] memory crates,
        uint256[] memory amounts
    )
        external
        payable
        returns (
            uint32 toSeason,
            uint256 fromAmount,
            uint256 toAmount,
            uint256 fromBdv,
            uint256 toBdv
        );

    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getMaxAmountIn(
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn);

    event AddDeposit(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount,
        uint256 bdv
    );
    event AddWithdrawal(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount
    );
    event ClaimPlenty(address indexed account, uint256 plenty);
    event DepositApproval(
        address indexed owner,
        address indexed spender,
        address token,
        uint256 amount
    );
    event Plant(address indexed account, uint256 beans);
    event RemoveDeposit(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount
    );
    event RemoveWithdrawal(
        address indexed account,
        address indexed token,
        uint32 season,
        uint256 amount
    );
    event RemoveWithdrawals(
        address indexed account,
        address indexed token,
        uint32[] seasons,
        uint256 amount
    );
    event SeedsBalanceChanged(address indexed account, int256 delta);
    event StalkBalanceChanged(address indexed account, int256 delta, int256 deltaRoots);

    function approveDeposit(address spender, address token, uint256 amount) external payable;

    function balanceOfEarnedBeans(address account) external view returns (uint256 beans);

    function balanceOfEarnedSeeds(address account) external view returns (uint256);

    function balanceOfEarnedStalk(address account) external view returns (uint256);

    function balanceOfGrownStalk(address account) external view returns (uint256);

    function balanceOfPlenty(address account) external view returns (uint256 plenty);

    function balanceOfRainRoots(address account) external view returns (uint256);

    function balanceOfRoots(address account) external view returns (uint256);

    function balanceOfSeeds(address account) external view returns (uint256);

    function balanceOfSop(
        address account
    ) external view returns (SiloExit.AccountSeasonOfPlenty memory sop);

    function balanceOfStalk(address account) external view returns (uint256);

    function claimPlenty() external payable;

    function claimWithdrawal(address token, uint32 season, uint8 mode) external payable;

    function claimWithdrawals(address token, uint32[] memory seasons, uint8 mode) external payable;

    function decreaseDepositAllowance(
        address spender,
        address token,
        uint256 subtractedValue
    ) external returns (bool);

    function deposit(address token, uint256 amount, uint8 mode) external payable;

    function depositAllowance(
        address account,
        address spender,
        address token
    ) external view returns (uint256);

    function depositPermitDomainSeparator() external view returns (bytes32);

    function depositPermitNonces(address owner) external view returns (uint256);

    function enrootDeposit(address token, uint32 _season, uint256 amount) external;

    function enrootDeposits(
        address token,
        uint32[] memory seasons,
        uint256[] memory amounts
    ) external;

    function getDeposit(
        address account,
        address token,
        uint32 season
    ) external view returns (uint256, uint256);

    function getTotalDeposited(address token) external view returns (uint256);

    function getTotalWithdrawn(address token) external view returns (uint256);

    function getWithdrawal(
        address account,
        address token,
        uint32 season
    ) external view returns (uint256);

    function increaseDepositAllowance(
        address spender,
        address token,
        uint256 addedValue
    ) external returns (bool);

    function lastSeasonOfPlenty() external view returns (uint32);

    function lastUpdate(address account) external view returns (uint32);

    function permitDeposit(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function permitDeposits(
        address owner,
        address spender,
        address[] memory tokens,
        uint256[] memory values,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function plant() external payable returns (uint256 beans);

    function tokenSettings(address token) external view returns (Storage.SiloSettings memory);

    function totalEarnedBeans() external view returns (uint256);

    function totalRoots() external view returns (uint256);

    function totalSeeds() external view returns (uint256);

    function totalStalk() external view returns (uint256);

    function transferDeposit(
        address sender,
        address recipient,
        address token,
        uint32 season,
        uint256 amount
    ) external payable returns (uint256 bdv);

    function transferDeposits(
        address sender,
        address recipient,
        address token,
        uint32[] memory seasons,
        uint256[] memory amounts
    ) external payable returns (uint256[] memory bdvs);

    function update(address account) external payable;

    function withdrawDeposit(address token, uint32 season, uint256 amount) external payable;

    function withdrawDeposits(
        address token,
        uint32[] memory seasons,
        uint256[] memory amounts
    ) external payable;

    function withdrawFreeze() external view returns (uint8);

    event DewhitelistToken(address indexed token);
    event WhitelistToken(address indexed token, bytes4 selector, uint256 seeds, uint256 stalk);

    function dewhitelistToken(address token) external payable;

    function whitelistToken(
        address token,
        bytes4 selector,
        uint32 stalk,
        uint32 seeds
    ) external payable;

    event Incentivization(address indexed account, uint256 beans);
    event Reward(uint32 indexed season, uint256 toField, uint256 toSilo, uint256 toFertilizer);
    event SeasonOfPlenty(uint256 indexed season, uint256 amount, uint256 toField);
    event Soil(uint32 indexed season, uint256 soil);
    event Sunrise(uint256 indexed season);
    event WeatherChange(uint256 indexed season, uint256 caseId, int8 change);

    function abovePeg() external view returns (bool);

    function gm(address account, uint8 mode) external payable returns (uint256);

    function paused() external view returns (bool);

    function plentyPerRoot(uint32 season) external view returns (uint256);

    function poolDeltaB(address pool) external view returns (int256);

    function rain() external view returns (Storage.Rain memory);

    function season() external view returns (uint32);

    function seasonTime() external view returns (uint32);

    function sunrise() external payable returns (uint256);

    function sunriseBlock() external view returns (uint32);

    function time() external view returns (Storage.Season memory);

    function totalDeltaB() external view returns (int256 deltaB);

    function weather() external view returns (Storage.Weather memory);
}

struct AdvancedPipeCall {
    address target;
    bytes callData;
    bytes clipboard;
}

struct PipeCall {
    address target;
    bytes data;
}

struct AdvancedFarmCall {
    bytes callData;
    bytes clipboard;
}

interface IFertilizer {
    struct Balance {
        uint128 amount;
        uint128 lastBpf;
    }
}

interface FertilizerFacet {
    struct Supply {
        uint128 endBpf;
        uint256 supply;
    }
}

interface TokenFacet {
    struct Rain {
        uint256 deprecated;
        uint256 pods;
        uint256 roots;
    }
}

interface Storage {
    struct Rain {
        uint256 deprecated;
        uint256 pods;
        uint256 roots;
    }

    struct Fundraiser {
        address payee;
        address token;
        uint256 total;
        uint256 remaining;
        uint256 start;
    }

    struct SiloSettings {
        bytes4 selector;
        uint32 seeds;
        uint32 stalk;
    }

    struct Season {
        uint32 current;
        uint32 lastSop;
        uint8 withdrawSeasons;
        uint32 lastSopSeason;
        uint32 rainStart;
        bool raining;
        bool fertilizing;
        uint32 sunriseBlock;
        bool abovePeg;
        uint256 start;
        uint256 period;
        uint256 timestamp;
    }

    struct Weather {
        uint256[2] deprecated;
        uint128 lastDSoil;
        uint32 lastSowTime;
        uint32 thisSowTime;
        uint32 t;
    }
}

interface Listing {
    struct PodListing {
        address account;
        uint256 index;
        uint256 start;
        uint256 amount;
        uint24 pricePerPod;
        uint256 maxHarvestableIndex;
        uint256 minFillAmount;
        uint8 mode;
    }
}

interface Order {
    struct PodOrder {
        address account;
        uint24 pricePerPod;
        uint256 maxPlaceInLine;
        uint256 minFillAmount;
    }
}

interface SiloExit {
    struct AccountSeasonOfPlenty {
        uint32 lastRain;
        uint32 lastSop;
        uint256 roots;
        uint256 plentyPerRoot;
        uint256 plenty;
    }
}
