// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./EthStarterFarming.sol";

interface IEthStarterStaking {
    function accountLpInfos(address, address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IEthExternalStaking {
    function balanceOf(address) external view returns (uint256);
}

contract EthStarterInfo is Ownable {
    using SafeMath for uint256;

    uint256[] private devFeePercentage = [5, 2, 2];
    uint256 private minDevFeeInWei = 5 ether; // min fee amount going to dev AND BSCS hodlers
    address[] private presaleAddresses; // track all presales created

    mapping(address => uint256) private minInvestorBSCSBalance; // min amount to investors HODL BSCS balance
    mapping(address => uint256) private minInvestorGuaranteedBalance;

    uint256 private minStakeTime = 1 minutes;
    uint256 private minUnstakeTime = 3 days;
    uint256 private creatorUnsoldClaimTime = 3 days;

    address[] private swapRouters = [
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
    ]; // Array of Routers
    address[] private swapFactorys = [
        address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
    ]; // Array of Factorys

    mapping(address => bytes32) private initCodeHash; // Mapping of INIT_CODE_HASH

    mapping(address => address) private lpAddresses; // TOKEN + START Pair Addresses

    address private starterSwapRouter =
        address(0x0000000000000000000000000000000000000000); // StarterSwap Router
    address private starterSwapFactory =
        address(0x0000000000000000000000000000000000000000); // StarterSwap Factory
    bytes32 private starterSwapICH =
        0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5; // StarterSwap InitCodeHash

    uint256 private starterSwapLPPercent = 0; // Liquidity will go StarterSwap

    address private weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address private startFactoryAddress;
    mapping(address => uint256) private investmentLimit;

    mapping(address => bool) private starterDevs;
    mapping(address => bool) private presaleCreatorDevs;

    address private startVestingAddress =
        address(0x0000000000000000000000000000000000000000);

    mapping(address => uint256) private minYesVotesThreshold; // minimum number of yes votes needed to pass

    mapping(address => uint256) private minCreatorStakedBalance;

    mapping(address => bool) private blacklistedAddresses;

    mapping(address => bool) public auditorWhitelistedAddresses; // addresses eligible to perform audits

    IEthStarterStaking public starterStakingPool;
    EthStarterFarming public starterLPFarm;
    IEthExternalStaking public starterExternalStaking;

    uint256 private devPresaleTokenFee = 2;
    address private devPresaleAllocationAddress =
        address(0x0000000000000000000000000000000000000000);

    constructor(
        address _starterStakingPool,
        address payable _starterLPFarm,
        address _starterExternalStaking
    ) public {
        starterStakingPool = IEthStarterStaking(_starterStakingPool);
        starterLPFarm = EthStarterFarming(_starterLPFarm);
        starterExternalStaking = IEthExternalStaking(_starterExternalStaking);

        starterDevs[address(0xf7e925818a20E5573Ee0f3ba7aBC963e17f2c476)] = true; // Chef
        starterDevs[address(0xcc887c71ABeB5763E896859B11530cc7942c7Bd5)] = true; // Cocktologist

        initCodeHash[
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        ] = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f; //Uniswap V2 INIT_CODE_HASH

        lpAddresses[weth] = address(0x9E2B254c7D6AD24aFb334A75cE21e216A9AA25fc); // WETH -> WETH+START LP Addresses

        lpAddresses[
            address(0x1d7Ca62F6Af49ec66f6680b8606E634E55Ef22C1)
        ] = address(0x1d7Ca62F6Af49ec66f6680b8606E634E55Ef22C1); // START => START address

        minYesVotesThreshold[weth] = 1000 * 1e18;

        minInvestorBSCSBalance[weth] = 3.5 * 1e18;

        minInvestorGuaranteedBalance[weth] = 35 * 1e18;

        investmentLimit[weth] = 1000 * 1e18;

        minCreatorStakedBalance[weth] = 3.5 * 1e18;
    }

    modifier onlyFactory() {
        require(
            startFactoryAddress == msg.sender ||
                owner == msg.sender ||
                starterDevs[msg.sender],
            "onlyFactoryOrDev"
        );
        _;
    }

    modifier onlyStarterDev() {
        require(
            owner == msg.sender || starterDevs[msg.sender],
            "onlyStarterDev"
        );
        _;
    }

    function getCakeV2LPAddress(
        address tokenA,
        address tokenB,
        uint256 swapIndex
    ) public view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        swapFactorys[swapIndex],
                        keccak256(abi.encodePacked(token0, token1)),
                        initCodeHash[swapFactorys[swapIndex]] // init code hash
                    )
                )
            )
        );
    }

    function getStarterSwapLPAddress(address tokenA, address tokenB)
        public
        view
        returns (address pair)
    {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        starterSwapFactory,
                        keccak256(abi.encodePacked(token0, token1)),
                        starterSwapICH // init code hash
                    )
                )
            )
        );
    }

    function getStarterDev(address _dev) external view returns (bool) {
        return starterDevs[_dev];
    }

    function setStarterDevAddress(address _newDev) external onlyOwner {
        starterDevs[_newDev] = true;
    }

    function removeStarterDevAddress(address _oldDev) external onlyOwner {
        starterDevs[_oldDev] = false;
    }

    function getPresaleCreatorDev(address _dev) external view returns (bool) {
        return presaleCreatorDevs[_dev];
    }

    function setPresaleCreatorDevAddress(address _newDev)
        external
        onlyStarterDev
    {
        presaleCreatorDevs[_newDev] = true;
    }

    function removePresaleCreatorDevAddress(address _oldDev)
        external
        onlyStarterDev
    {
        presaleCreatorDevs[_oldDev] = false;
    }

    function getBscsFactoryAddress() external view returns (address) {
        return startFactoryAddress;
    }

    function setBscsFactoryAddress(address _newFactoryAddress)
        external
        onlyStarterDev
    {
        startFactoryAddress = _newFactoryAddress;
    }

    function getBscsStakingPool() external view returns (address) {
        return address(starterStakingPool);
    }

    function setBscsStakingPool(address _starterStakingPool)
        external
        onlyStarterDev
    {
        starterStakingPool = IEthStarterStaking(_starterStakingPool);
    }

    function setStarterLPFarmPool(address payable _starterLPFarm)
        external
        onlyStarterDev
    {
        starterLPFarm = EthStarterFarming(_starterLPFarm);
    }

    function setStarterExternalStaking(address _starterExternalStaking)
        external
        onlyStarterDev
    {
        starterExternalStaking = IEthExternalStaking(_starterExternalStaking);
    }

    function addPresaleAddress(address _presale)
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(_presale);
        return presaleAddresses.length - 1;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getPresaleAddress(uint256 bscsId) external view returns (address) {
        return presaleAddresses[bscsId];
    }

    function setPresaleAddress(uint256 bscsId, address _newAddress)
        external
        onlyStarterDev
    {
        presaleAddresses[bscsId] = _newAddress;
    }

    function getDevFeePercentage(uint256 presaleType)
        external
        view
        returns (uint256)
    {
        return devFeePercentage[presaleType];
    }

    function setDevFeePercentage(uint256 presaleType, uint256 _devFeePercentage)
        external
        onlyStarterDev
    {
        devFeePercentage[presaleType] = _devFeePercentage;
    }

    function getMinDevFeeInWei() external view returns (uint256) {
        return minDevFeeInWei;
    }

    function setMinDevFeeInWei(uint256 _minDevFeeInWei)
        external
        onlyStarterDev
    {
        minDevFeeInWei = _minDevFeeInWei;
    }

    function getMinInvestorBSCSBalance(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minInvestorBSCSBalance[tokenAddress];
    }

    function setMinInvestorBSCSBalance(
        address tokenAddress,
        uint256 _minInvestorBSCSBalance
    ) external onlyStarterDev {
        minInvestorBSCSBalance[tokenAddress] = _minInvestorBSCSBalance;
    }

    function getMinYesVotesThreshold(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minYesVotesThreshold[tokenAddress];
    }

    function setMinYesVotesThreshold(
        address tokenAddress,
        uint256 _minYesVotesThreshold
    ) external onlyStarterDev {
        minYesVotesThreshold[tokenAddress] = _minYesVotesThreshold;
    }

    function getMinCreatorStakedBalance(address fundingTokenAddress)
        external
        view
        returns (uint256)
    {
        return minCreatorStakedBalance[fundingTokenAddress];
    }

    function setMinCreatorStakedBalance(
        address fundingTokenAddress,
        uint256 _minCreatorStakedBalance
    ) external onlyStarterDev {
        minCreatorStakedBalance[fundingTokenAddress] = _minCreatorStakedBalance;
    }

    function getMinInvestorGuaranteedBalance(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return minInvestorGuaranteedBalance[tokenAddress];
    }

    function setMinInvestorGuaranteedBalance(
        address tokenAddress,
        uint256 _minInvestorGuaranteedBalance
    ) external onlyStarterDev {
        minInvestorGuaranteedBalance[
            tokenAddress
        ] = _minInvestorGuaranteedBalance;
    }

    function getMinStakeTime() external view returns (uint256) {
        return minStakeTime;
    }

    function setMinStakeTime(uint256 _minStakeTime) external onlyStarterDev {
        minStakeTime = _minStakeTime;
    }

    function getMinUnstakeTime() external view returns (uint256) {
        return minUnstakeTime;
    }

    function setMinUnstakeTime(uint256 _minUnstakeTime)
        external
        onlyStarterDev
    {
        minUnstakeTime = _minUnstakeTime;
    }

    function getCreatorUnsoldClaimTime() external view returns (uint256) {
        return creatorUnsoldClaimTime;
    }

    function setCreatorUnsoldClaimTime(uint256 _creatorUnsoldClaimTime)
        external
        onlyStarterDev
    {
        creatorUnsoldClaimTime = _creatorUnsoldClaimTime;
    }

    function getSwapRouter(uint256 index) external view returns (address) {
        return swapRouters[index];
    }

    function setSwapRouter(uint256 index, address _swapRouter)
        external
        onlyStarterDev
    {
        swapRouters[index] = _swapRouter;
    }

    function addSwapRouter(address _swapRouter) external onlyStarterDev {
        swapRouters.push(_swapRouter);
    }

    function getSwapFactory(uint256 index) external view returns (address) {
        return swapFactorys[index];
    }

    function setSwapFactory(uint256 index, address _swapFactory)
        external
        onlyStarterDev
    {
        swapFactorys[index] = _swapFactory;
    }

    function addSwapFactory(address _swapFactory) external onlyStarterDev {
        swapFactorys.push(_swapFactory);
    }

    function getInitCodeHash(address _swapFactory)
        external
        view
        returns (bytes32)
    {
        return initCodeHash[_swapFactory];
    }

    function setInitCodeHash(address _swapFactory, bytes32 _initCodeHash)
        external
        onlyStarterDev
    {
        initCodeHash[_swapFactory] = _initCodeHash;
    }

    function getStarterSwapRouter() external view returns (address) {
        return starterSwapRouter;
    }

    function setStarterSwapRouter(address _starterSwapRouter)
        external
        onlyStarterDev
    {
        starterSwapRouter = _starterSwapRouter;
    }

    function getStarterSwapFactory() external view returns (address) {
        return starterSwapFactory;
    }

    function setStarterSwapFactory(address _starterSwapFactory)
        external
        onlyStarterDev
    {
        starterSwapFactory = _starterSwapFactory;
    }

    function getStarterSwapICH() external view returns (bytes32) {
        return starterSwapICH;
    }

    function setStarterSwapICH(bytes32 _initCodeHash) external onlyStarterDev {
        starterSwapICH = _initCodeHash;
    }

    function getStarterSwapLPPercent() external view returns (uint256) {
        return starterSwapLPPercent;
    }

    function setStarterSwapLPPercent(uint256 _starterSwapLPPercent)
        external
        onlyStarterDev
    {
        starterSwapLPPercent = _starterSwapLPPercent;
    }

    function getWETH() external view returns (address) {
        return weth;
    }

    function setWETH(address _weth) external onlyStarterDev {
        weth = _weth;
    }

    function getVestingAddress() external view returns (address) {
        return startVestingAddress;
    }

    function setVestingAddress(address _newVesting) external onlyStarterDev {
        startVestingAddress = _newVesting;
    }

    function getInvestmentLimit(address tokenAddress)
        external
        view
        returns (uint256)
    {
        return investmentLimit[tokenAddress];
    }

    function setInvestmentLimit(address tokenAddress, uint256 _limit)
        external
        onlyStarterDev
    {
        investmentLimit[tokenAddress] = _limit;
    }

    function getLpAddress(address tokenAddress) public view returns (address) {
        return lpAddresses[tokenAddress];
    }

    function setLpAddress(address tokenAddress, address lpAddress)
        external
        onlyStarterDev
    {
        lpAddresses[tokenAddress] = lpAddress;
    }

    function getStartLpStaked(address lpAddress, address payable sender)
        public
        view
        returns (uint256)
    {
        uint256 balance;
        uint256 lastStakedTimestamp;
        (balance, lastStakedTimestamp, ) = starterStakingPool.accountLpInfos(
            lpAddress,
            address(sender)
        );
        uint256 totalHodlerBalance = 0;
        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            totalHodlerBalance = totalHodlerBalance.add(balance);
        }

        // add LP farm mining to balance
        balance = 0;

        (balance, , , , ) = starterLPFarm.accountInfos(address(sender));

        uint256 externalBalance = starterExternalStaking.balanceOf(
            address(sender)
        );

        return totalHodlerBalance + balance + externalBalance;
    }

    function getTotalStartLpStaked(address lpAddress)
        public
        view
        returns (uint256)
    {
        return ERC20(lpAddress).balanceOf(address(starterStakingPool));
    }

    function getStaked(address fundingTokenAddress, address payable sender)
        public
        view
        returns (uint256)
    {
        return getStartLpStaked(getLpAddress(fundingTokenAddress), sender);
    }

    function getTotalStaked(address fundingTokenAddress)
        public
        view
        returns (uint256)
    {
        return getTotalStartLpStaked(getLpAddress(fundingTokenAddress));
    }

    function getDevPresaleTokenFee() public view returns (uint256) {
        return devPresaleTokenFee;
    }

    function setDevPresaleTokenFee(uint256 _devPresaleTokenFee)
        external
        onlyStarterDev
    {
        devPresaleTokenFee = _devPresaleTokenFee;
    }

    function getDevPresaleAllocationAddress() public view returns (address) {
        return devPresaleAllocationAddress;
    }

    function setDevPresaleAllocationAddress(
        address _devPresaleAllocationAddress
    ) external onlyStarterDev {
        devPresaleAllocationAddress = _devPresaleAllocationAddress;
    }

    function isBlacklistedAddress(address _sender) public view returns (bool) {
        return blacklistedAddresses[_sender];
    }

    function addBlacklistedAddresses(address[] calldata _blacklistedAddresses)
        external
        onlyStarterDev
    {
        for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
            blacklistedAddresses[_blacklistedAddresses[i]] = true;
        }
    }

    function removeBlacklistedAddresses(
        address[] calldata _blacklistedAddresses
    ) external onlyStarterDev {
        for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
            blacklistedAddresses[_blacklistedAddresses[i]] = false;
        }
    }

    function isAuditorWhitelistedAddress(address _sender)
        public
        view
        returns (bool)
    {
        return auditorWhitelistedAddresses[_sender];
    }

    function addAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyStarterDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function removeAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyStarterDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = false;
        }
    }
}
