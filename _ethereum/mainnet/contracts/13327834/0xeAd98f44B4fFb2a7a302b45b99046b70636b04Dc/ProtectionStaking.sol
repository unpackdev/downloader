pragma solidity 0.5.17;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Utils.sol";
import "./SafePeakToken.sol";
import "./IPeakToken.sol";
import "./IPeakDeFiFund.sol";
import "./IUniswapOracle.sol";
import "./IProtectionStaking.sol";


contract ProtectionStaking is IProtectionStaking, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafePeakToken for IPeakToken;

    address public sharesToken;

    IPeakDeFiFund public fund;
    IPeakToken public peakToken;
    IUniswapOracle public uniswapOracle;

    uint256 public mintedPeakTokens;
    uint256 public peakMintCap = 5000000 * PEAK_PRECISION; // default 300 million PEAK
    uint256 internal constant PEAK_PRECISION = 10**8;
    uint256 internal constant USDC_PRECISION = 10**6;
    uint256 internal constant PERCENTS_DECIMALS = 10**20;

    mapping(address => uint256) public peaks;
    mapping(address => uint256) public shares;
    mapping(address => uint256) public startProtectTimestamp;
    mapping(address => uint256) internal _lastClaimTimestamp;
    mapping(address => uint256) public lastClaimAmount;

    event ClaimCompensation(
        address investor,
        uint256 amount,
        uint256 timestamp
    );
    event RequestProtection(
        address investor,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(address investor, uint256 amount, uint256 timestamp);
    event ProtectShares(address investor, uint256 amount, uint256 timestamp);
    event WithdrawShares(address investor, uint256 amount, uint256 timestamp);
    event ChangePeakMintCap(uint256 newAmmount);

    modifier during(IPeakDeFiFund.CyclePhase phase) {
        require(fund.cyclePhase() == phase, "wrong phase");
        if (fund.cyclePhase() == IPeakDeFiFund.CyclePhase.Intermission) {
            require(fund.isInitialized(), "fund not initialized");
        }
        _;
    }

    modifier ifNoCompensation() {
        uint256 peakPriceInUsdc = _getPeakPriceInUsdc();
        uint256 compensationAmount = _calculateCompensating(
            msg.sender,
            peakPriceInUsdc
        );
        require(compensationAmount == 0, "have compensation");
        _;
    }

    constructor(
        address payable _fundAddr,
        address _peakTokenAddr,
        address _sharesTokenAddr,
        address _uniswapOracle
    ) public {
        __initReentrancyGuard();
        require(_fundAddr != address(0));
        require(_peakTokenAddr != address(0));

        fund = IPeakDeFiFund(_fundAddr);
        peakToken = IPeakToken(_peakTokenAddr);
        uniswapOracle = IUniswapOracle(_uniswapOracle);
        sharesToken = _sharesTokenAddr;
    }

    function() external {}

    function _lostFundAmount(address _investor)
        internal
        view
        returns (uint256 lostFundAmount)
    {
        uint256 totalLostFundAmount = fund.totalLostFundAmount();
        uint256 investorLostFundAmount = lastClaimAmount[_investor];
        lostFundAmount = totalLostFundAmount.sub(investorLostFundAmount);
    }

    function _calculateCompensating(address _investor, uint256 _peakPriceInUsdc)
        internal
        view
        returns (uint256)
    {
        uint256 totalFundsAtManagePhaseStart = fund
        .totalFundsAtManagePhaseStart();
        uint256 totalShares = fund.totalSharesAtLastManagePhaseStart();
        uint256 managePhaseStartTime = fund.startTimeOfLastManagementPhase();
        uint256 lostFundAmount = _lostFundAmount(_investor);
        uint256 sharesAmount = shares[_investor];
        if (
            fund.cyclePhase() != IPeakDeFiFund.CyclePhase.Intermission ||
            managePhaseStartTime < _lastClaimTimestamp[_investor] ||
            managePhaseStartTime < startProtectTimestamp[_investor] ||
            mintedPeakTokens >= peakMintCap ||
            peaks[_investor] == 0 ||
            lostFundAmount == 0 ||
            totalShares == 0 ||
            _peakPriceInUsdc == 0 ||
            sharesAmount == 0
        ) {
            return 0;
        }
        uint256 sharesInUsdcAmount = sharesAmount
        .mul(totalFundsAtManagePhaseStart)
        .div(totalShares);
        uint256 peaksInUsdcAmount = peaks[_investor].mul(_peakPriceInUsdc).div(
            PEAK_PRECISION
        );
        uint256 protectedPercent = PERCENTS_DECIMALS;
        if (peaksInUsdcAmount < sharesInUsdcAmount) {
            protectedPercent = peaksInUsdcAmount.mul(PERCENTS_DECIMALS).div(
                sharesInUsdcAmount
            );
        }
        uint256 ownLostFundInUsd = lostFundAmount.mul(sharesAmount).div(
            totalShares
        );
        uint256 compensationInUSDC = ownLostFundInUsd.mul(protectedPercent).div(
            PERCENTS_DECIMALS
        );
        uint256 compensationInPeak = compensationInUSDC.mul(PEAK_PRECISION).div(
            _peakPriceInUsdc
        );
        if (peakMintCap - mintedPeakTokens < compensationInPeak) {
            compensationInPeak = peakMintCap - mintedPeakTokens;
        }
        return compensationInPeak;
    }

    function calculateCompensating(address _investor, uint256 _peakPriceInUsdc)
        public
        view
        returns (uint256)
    {
        return _calculateCompensating(_investor, _peakPriceInUsdc);
    }

    function updateLastClaimAmount() internal {
        lastClaimAmount[msg.sender] = fund.totalLostFundAmount();
    }

    function claimCompensation()
        external
        during(IPeakDeFiFund.CyclePhase.Intermission)
        nonReentrant
    {
        uint256 peakPriceInUsdc = _getPeakPriceInUsdc();
        uint256 compensationAmount = _calculateCompensating(
            msg.sender,
            peakPriceInUsdc
        );
        require(compensationAmount > 0, "not have compensation");
        _lastClaimTimestamp[msg.sender] = block.timestamp;
        peakToken.mint(msg.sender, compensationAmount);
        mintedPeakTokens = mintedPeakTokens.add(compensationAmount);
        require(
            mintedPeakTokens <= peakMintCap,
            "ProtectionStaking: reached cap"
        );
        updateLastClaimAmount();
        emit ClaimCompensation(msg.sender, compensationAmount, block.timestamp);
    }

    function requestProtection(uint256 _amount)
        external
        during(IPeakDeFiFund.CyclePhase.Intermission)
        nonReentrant
        ifNoCompensation
    {
        require(_amount > 0, "amount is 0");
        peakToken.safeTransferFrom(msg.sender, address(this), _amount);
        peaks[msg.sender] = peaks[msg.sender].add(_amount);
        startProtectTimestamp[msg.sender] = block.timestamp;
        updateLastClaimAmount();
        emit RequestProtection(msg.sender, _amount, block.timestamp);
    }

    function withdraw(uint256 _amount) external ifNoCompensation {
        require(
            peaks[msg.sender] >= _amount,
            "insufficient fund in Peak Token"
        );
        require(_amount > 0, "amount is 0");
        peaks[msg.sender] = peaks[msg.sender].sub(_amount);
        peakToken.safeTransfer(msg.sender, _amount);
        updateLastClaimAmount();
        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

    function protectShares(uint256 _amount)
        external
        nonReentrant
        during(IPeakDeFiFund.CyclePhase.Intermission)
        ifNoCompensation
    {
        require(_amount > 0, "amount is 0");
        IERC20(sharesToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        startProtectTimestamp[msg.sender] = block.timestamp;
        shares[msg.sender] = shares[msg.sender].add(_amount);
        updateLastClaimAmount();
        emit ProtectShares(msg.sender, _amount, block.timestamp);
    }

    function withdrawShares(uint256 _amount)
        external
        nonReentrant
        ifNoCompensation
    {
        require(
            shares[msg.sender] >= _amount,
            "insufficient fund in Share Token"
        );
        require(_amount > 0, "amount is 0");
        shares[msg.sender] = shares[msg.sender].sub(_amount);
        IERC20(sharesToken).safeTransfer(msg.sender, _amount);
        emit WithdrawShares(msg.sender, _amount, block.timestamp);
    }

    function setPeakMintCap(uint256 _amount) external onlyOwner {
        peakMintCap = _amount;
        emit ChangePeakMintCap(_amount);
    }

    function _getPeakPriceInUsdc() internal returns (uint256) {
        uniswapOracle.update();
        uint256 priceInUSDC = uniswapOracle.consult(
            address(peakToken),
            PEAK_PRECISION
        );
        if (priceInUSDC == 0) {
            return USDC_PRECISION.mul(3).div(10);
        }
        return priceInUSDC;
    }
}
