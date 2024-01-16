// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IBaseGateway.sol";
import "./IUniswapV3SwapRouter.sol";
import "./IWeth.sol";
import "./BaseGatewayEthereum.sol";
import "./StakeCurveConvex.sol";
import "./LotteryVRF.sol";
import "./ERC721PayWithEther.sol";
import "./IPancakePair.sol";
import "./ICurvePool.sol";

contract InvestNFTGatewayEthereum is BaseGatewayEthereum {
    using SafeERC20 for IERC20;

    struct TokenLotteryInfo {
        address nft;
        uint256 id;
    }
    mapping(address => uint256) public poolsTotalRewards;
    mapping(address => mapping(uint256 => uint256)) public lotteryRewards;
    bytes32[] public lotteryList;
    mapping(bytes32 => TokenLotteryInfo) public tokenLotteryInfo;
    VRFv2Consumer public VRFConsumer;
    mapping(uint256 => mapping(address => bool)) public requestIds;
    mapping(uint256 => uint256[]) private winnerBoard;
    mapping(address => address) private hotpotPoolToCurvePool;
    uint256 public redeemableTime;

    function initialize(
        string memory _name,
        address _wrapperNativeToken,
        address _stablecoin,
        address _rewardToken,
        address _operator,
        IUniswapV3SwapRouter _router,
        uint256 _redeemableTime
    ) external override {
        require(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("")), "Already initialized");
        super.initializePausable(_operator);
        super.initializeReentrancyGuard();

        name = _name;
        wrapperNativeToken = _wrapperNativeToken;
        stablecoin = _stablecoin;
        rewardToken= _rewardToken;
        operator = _operator;
        router = _router;
        redeemableTime = _redeemableTime;
    }

    function initNftData(address _nft, address _poolBase, address _poolLottery, bool _increaseable, uint256 _delta) external onlyOwner override {
        if (_poolBase != address(0)) {
            contractInfo[_nft].poolAddressBase = _poolBase;
        }
        if (_poolLottery != address(0)) {
            contractInfo[_nft].poolAddressLottery = _poolLottery;
        }
        contractInfo[_nft].increaseable = _increaseable;
        contractInfo[_nft].delta = _delta;
        contractInfo[_nft].active = true;
    }

    function deposit(uint256 _tokenId) external nonReentrant supportInterface(msg.sender) payable override {
        require(contractInfo[msg.sender].active == true, "NFT data didn't be set yet");
        IWETH(wrapperNativeToken).deposit{ value: msg.value }();
        IWETH(wrapperNativeToken).approve(address(router), msg.value);

        uint256 stablecoinAmount = convertExactWEthToStablecoin(msg.value, 0);

        // update fomulaBase balance
        address fomulaBase =  contractInfo[msg.sender].poolAddressBase;
        poolsWeights[fomulaBase] = poolsWeights[fomulaBase] + stablecoinAmount;
        poolsBalances[fomulaBase] = poolsBalances[fomulaBase] + stablecoinAmount;

        updateInfo(msg.sender, _tokenId, stablecoinAmount);
        emit Deposit(msg.sender, _tokenId, stablecoinAmount);
    }

    function batchDeposit(uint256 _idFrom, uint256 _offset) external nonReentrant supportInterface(msg.sender) payable override {
        require(contractInfo[msg.sender].active == true, "NFT data didn't be set yet");
        IWETH(wrapperNativeToken).deposit{ value: msg.value }();
        IWETH(wrapperNativeToken).approve(address(router), msg.value);

        uint256 totalStablecoinAmount = convertExactWEthToStablecoin(msg.value, 0);

        // update fomulaBase balance
        address fomulaBase =  contractInfo[msg.sender].poolAddressBase;
        poolsWeights[fomulaBase] = poolsWeights[fomulaBase] + totalStablecoinAmount;
        poolsBalances[fomulaBase] = poolsBalances[fomulaBase] + totalStablecoinAmount;
        uint256 stablecoinAmount = totalStablecoinAmount / _offset;
        for (uint i = 0; i < _offset; i++) {
            updateInfo(msg.sender, _idFrom + i, stablecoinAmount);
            emit Deposit(msg.sender, _idFrom + i, stablecoinAmount);
        }
    }

    function updateInfo(address _nft, uint256 _tokenId, uint256 _weight) internal {
        bytes32 infoHash = keccak256(abi.encodePacked(_nft, _tokenId));
        // update token info
        tokenInfo[infoHash].weightsFomulaBase = tokenInfo[infoHash].weightsFomulaBase + _weight;
        tokenInfo[infoHash].weightsFomulaLottery = tokenInfo[infoHash].weightsFomulaLottery + BASE_WEIGHTS;
        tokenInfo[infoHash].amounts = tokenInfo[infoHash].amounts + 1;

        // update contract info
        contractInfo[_nft].weightsFomulaBase = contractInfo[_nft].weightsFomulaBase + _weight;
        contractInfo[_nft].weightsFomulaLottery = contractInfo[_nft].weightsFomulaLottery + BASE_WEIGHTS;
        contractInfo[_nft].amounts = contractInfo[_nft].amounts + 1;

        TokenLotteryInfo memory info;
        info.nft = _nft;
        info.id = _tokenId;
        tokenLotteryInfo[infoHash] = info;
        lotteryList.push(infoHash);
    }

    function baseValue(address _nft, uint256 _tokenId) public view override returns (uint256, uint256) {
        bytes32 infoHash = keccak256(abi.encodePacked(_nft, _tokenId));
        address fomulaBase =  contractInfo[_nft].poolAddressBase;
        uint256 tokenWeightsBase = tokenInfo[infoHash].weightsFomulaBase;
        uint256 poolsWeightBase = poolsWeights[fomulaBase];

        ICurvePool curvePool = ICurvePool(hotpotPoolToCurvePool[fomulaBase]);
        uint256 lpVirtualPrice = curvePool.get_virtual_price();
        StakeCurveConvex hotpotPool = StakeCurveConvex(payable(fomulaBase));
        // LP from invested stablecoin
        uint256 lpAmount = hotpotPool.balanceOf(address(this));
        uint256 lpTotalPrice = lpAmount * lpVirtualPrice / 1e18;

        uint256 tokenBalanceBase = lpTotalPrice * tokenWeightsBase / poolsWeightBase;
        return (tokenWeightsBase, tokenBalanceBase);
    }

    function tokenReward(address _nft, uint256 _tokenId) public view override returns (uint256)  {
        return lotteryRewards[_nft][_tokenId];
    }

    function redeem(address _nft, uint256 _tokenId, bool _isToken0) external override {
        require(block.timestamp >= redeemableTime, "Redeemable until redeemableTime");

        bytes32 infoHash = keccak256(abi.encodePacked(_nft, _tokenId));
        address fomulaBase =  contractInfo[_nft].poolAddressBase;
        address fomulaLottery =  contractInfo[_nft].poolAddressLottery;

        uint256 stablecoinTotal = IERC20(stablecoin).balanceOf(address(this));
        uint256 lpAmount = StakeCurveConvex(payable(fomulaBase)).balanceOf(address(this));

        StakeCurveConvex(payable(fomulaBase)).withdraw(_isToken0, 0, lpAmount * tokenInfo[infoHash].weightsFomulaBase / poolsWeights[fomulaBase]);

        uint256 tokenBalanceBase = IERC20(stablecoin).balanceOf(address(this)) - stablecoinTotal;

        require(poolsBalances[fomulaBase] == 0, "Should be invested first");
        require(poolsWeights[fomulaBase] >= tokenInfo[infoHash].weightsFomulaBase, "poolsWeightsBase insufficent");

        poolsWeights[fomulaBase] = poolsWeights[fomulaBase] - tokenInfo[infoHash].weightsFomulaBase;

        if (poolsWeights[fomulaLottery] > tokenInfo[infoHash].weightsFomulaLottery) {
            poolsWeights[fomulaLottery] = poolsWeights[fomulaLottery] - BASE_WEIGHTS;
        }

        contractInfo[_nft].weightsFomulaBase = contractInfo[_nft].weightsFomulaBase - tokenInfo[infoHash].weightsFomulaBase;
        contractInfo[_nft].weightsFomulaLottery = contractInfo[_nft].weightsFomulaLottery - BASE_WEIGHTS;
        contractInfo[_nft].amounts = contractInfo[_nft].amounts - 1;

        tokenInfo[infoHash].weightsFomulaBase = tokenInfo[infoHash].weightsFomulaBase - tokenInfo[infoHash].weightsFomulaBase;
        tokenInfo[infoHash].weightsFomulaLottery = tokenInfo[infoHash].weightsFomulaLottery - BASE_WEIGHTS;
        tokenInfo[infoHash].amounts = tokenInfo[infoHash].amounts - 1;
        
        IERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);
        
        IERC20(stablecoin).safeTransfer(msg.sender, tokenBalanceBase);

        uint256 lotteryRewardAmount = lotteryRewards[_nft][_tokenId];

        if (lotteryRewardAmount > 0) {
            lotteryRewards[_nft][_tokenId] = 0;

            IERC20(rewardToken).safeTransfer(msg.sender, lotteryRewardAmount);
        }

        emit Redeem(msg.sender, _tokenId, tokenBalanceBase);
    }

    function setPoolBalances(address pool, uint256 amount) external onlyOwner override {
        poolsBalances[pool] = amount;
    }

    function investWithERC20(address pool, bool isToken0, uint256 minReceivedTokenAmountSwap) external onlyOwner override {
        uint256 amount = poolsBalances[pool];
        IERC20(stablecoin).safeApprove(pool, amount);
        poolsBalances[pool] = 0;
        StakeCurveConvex(payable(pool)).stake(isToken0, amount, minReceivedTokenAmountSwap);
    }

    function getReward(address pool) external onlyOwner override {
        uint256 rewardsBefore = IERC20(rewardToken).balanceOf(address(this));

        StakeCurveConvex(payable(pool)).getReward();

        uint256 rewardsAfter = IERC20(rewardToken).balanceOf(address(this));

        poolsTotalRewards[pool] = poolsTotalRewards[pool] + rewardsAfter - rewardsBefore;
    }

    function setVRFConsumer(address vrf) external onlyOwner override {
        VRFConsumer = VRFv2Consumer(vrf);
    }

    function getNFTTotalSupply(ERC721PayWithEther _nft) internal view returns (uint256) {
        return _nft.totalSupply();
    }

    function getRandomWord(uint256 _index) internal view returns (uint256) {
        return VRFConsumer.s_randomWords(_index);
    }

    function getRequestId() public view override returns (uint256) {
        return VRFConsumer.s_requestId();
    }

    function setRandomPrizeWinners(address pool, uint256 totalWinner) external onlyOwner override {
        uint256 requestId = getRequestId();
        require(requestIds[requestId][pool] == false, "requestId be used");

        uint256 totalCandidate = lotteryList.length;
        uint256 prizePerWinner = poolsTotalRewards[pool] > 0 ? poolsTotalRewards[pool] / totalWinner : 0;

        uint256 prizeTotal;
        for (uint256 index = 0; index < totalWinner; index++) {

            uint256 randomWord = getRandomWord(index);
            uint256 winnerIndex = randomWord % totalCandidate;
            bytes32 winnerInfoHash = lotteryList[winnerIndex];
            TokenLotteryInfo memory winnerInfo = tokenLotteryInfo[winnerInfoHash];
            bytes32 infoHash = keccak256(abi.encodePacked(winnerInfo.nft, winnerInfo.id));

            if (tokenInfo[infoHash].weightsFomulaLottery > 0) {
                lotteryRewards[winnerInfo.nft][winnerInfo.id] = lotteryRewards[winnerInfo.nft][winnerInfo.id] + prizePerWinner;
                winnerBoard[requestId].push(winnerIndex);
                prizeTotal = prizeTotal + prizePerWinner;
                emit SelectWinner(winnerInfo.nft, winnerInfo.id, prizePerWinner);
            }
        }

        poolsTotalRewards[pool] = poolsTotalRewards[pool] - prizeTotal;
        requestIds[requestId][pool] = true;
    }
    function getWinnerBoard(uint256 requestId) external view override returns (uint256[] memory) {
        return winnerBoard[requestId];
    }

    function setHotpotPoolToCurvePool(address hotpotPoolAddress, address curvePoolAddress) external onlyOwner override {
        hotpotPoolToCurvePool[hotpotPoolAddress] = curvePoolAddress;
    }

    function getHotpotPoolToCurvePool(address hotpotPoolAddress) external view override returns (address) {
        return hotpotPoolToCurvePool[hotpotPoolAddress];
    }

    function setRedeemableTime(uint256 timestamp) external onlyOwner override {
        redeemableTime = timestamp;
    }
    event SelectWinner(address _nft, uint256 _tokenId, uint256 _amounts);
}