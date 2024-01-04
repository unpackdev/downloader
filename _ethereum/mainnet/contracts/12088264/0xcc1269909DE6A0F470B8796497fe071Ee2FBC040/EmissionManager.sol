//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Operatable.sol";
import "./Debouncable.sol";
import "./Timeboundable.sol";
import "./SyntheticToken.sol";
import "./IEmissionManager.sol";
import "./ITokenManager.sol";
import "./IBondManager.sol";
import "./IBoardroom.sol";

/// Emission manager expands supply when the price goes up
contract EmissionManager is
    IEmissionManager,
    ReentrancyGuard,
    Operatable,
    Debouncable,
    Timeboundable
{
    using SafeMath for uint256;

    /// Stable fund address
    address public stableFund;
    /// Development fund address
    address public devFund;
    /// LiquidBoardroom contract
    IBoardroom public liquidBoardroom;
    /// VeBoardroom contract
    IBoardroom public veBoardroom;
    /// UniswapBoardroom contract
    IBoardroom public uniswapBoardroom;

    /// TokenManager contract
    ITokenManager public tokenManager;
    /// BondManager contract
    IBondManager public bondManager;

    /// Threshold for positive rebase
    uint256 public threshold = 105;
    /// Threshold for positive rebase
    uint256 public maxRebase = 200;
    /// Development fund allocation rate (in percentage points)
    uint256 public devFundRate = 2;
    /// Stable fund allocation rate (in percentage points)
    uint256 public stableFundRate = 69;
    /// LiquidBoardroom allocation rate (in percentage points)
    uint256 public liquidBoardroomRate = 75;
    /// VeBoardroom allocation rate (in percentage points)
    uint256 public veBoardroomRate = 0;

    /// Pauses positive rebases
    bool public pausePositiveRebase;

    /// Create new Emission manager
    /// @param startTime Start of the operations
    /// @param period The period between positive rebases
    constructor(uint256 startTime, uint256 period)
        public
        Debouncable(period)
        Timeboundable(startTime, 0)
    {}

    // --------- Modifiers ---------

    /// Checks if contract was initialized properly and ready for use
    modifier initialized() {
        require(isInitialized(), "EmissionManager: not initialized");
        _;
    }

    // --------- View ---------

    function uniswapBoardroomRate() public view returns (uint256) {
        return uint256(100).sub(veBoardroomRate).sub(liquidBoardroomRate);
    }

    /// Checks if contract was initialized properly and ready for use
    function isInitialized() public view returns (bool) {
        return
            (address(tokenManager) != address(0)) &&
            (address(bondManager) != address(0)) &&
            (address(stableFund) != address(0)) &&
            (address(devFund) != address(0)) &&
            (address(uniswapBoardroom) != address(0)) &&
            (address(liquidBoardroom) != address(0)) &&
            (stableFundRate > 0) &&
            (devFundRate > 0) &&
            (threshold > 100) &&
            (maxRebase > 100);
    }

    /// The amount for positive rebase of the synthetic token
    /// @param syntheticTokenAddress The address of the synthetic token
    function positiveRebaseAmount(address syntheticTokenAddress)
        public
        view
        initialized
        returns (uint256)
    {
        uint256 oneSyntheticUnit =
            tokenManager.oneSyntheticUnit(syntheticTokenAddress);
        uint256 oneUnderlyingUnit =
            tokenManager.oneUnderlyingUnit(syntheticTokenAddress);

        uint256 rebasePriceUndPerUnitSyn =
            tokenManager.averagePrice(syntheticTokenAddress, oneSyntheticUnit);
        uint256 thresholdUndPerUnitSyn =
            threshold.mul(oneUnderlyingUnit).div(100);
        if (rebasePriceUndPerUnitSyn < thresholdUndPerUnitSyn) {
            return 0;
        }
        uint256 maxRebaseAmountUndPerUnitSyn =
            maxRebase.mul(oneUnderlyingUnit).div(100);
        rebasePriceUndPerUnitSyn = Math.min(
            rebasePriceUndPerUnitSyn,
            maxRebaseAmountUndPerUnitSyn
        );
        SyntheticToken syntheticToken = SyntheticToken(syntheticTokenAddress);
        uint256 supply =
            syntheticToken.totalSupply().sub(
                syntheticToken.balanceOf(address(bondManager))
            );
        return
            supply.mul(rebasePriceUndPerUnitSyn.sub(oneUnderlyingUnit)).div(
                oneUnderlyingUnit
            );
    }

    // --------- Public ---------

    /// Makes positive rebases for all eligible tokens
    function makePositiveRebase()
        public
        nonReentrant
        initialized
        debounce
        inTimeBounds
    {
        require(!pausePositiveRebase, "EmissionManager: Rebases are paused");
        address[] memory tokens = tokenManager.allTokens();
        for (uint32 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0)) {
                _makeOnePositiveRebase(tokens[i]);
            }
        }
    }

    // --------- Owner (Timelocked) ---------

    /// Set new dev fund
    /// @param _devFund New dev fund address
    function setDevFund(address _devFund) public onlyOwner {
        devFund = _devFund;
        emit DevFundChanged(msg.sender, _devFund);
    }

    /// Set new stable fund
    /// @param _stableFund New stable fund address
    function setStableFund(address _stableFund) public onlyOwner {
        stableFund = _stableFund;
        emit StableFundChanged(msg.sender, _stableFund);
    }

    /// Set new boardroom
    /// @param _boardroom New boardroom address
    function setLiquidBoardroom(address _boardroom) public onlyOwner {
        liquidBoardroom = IBoardroom(_boardroom);
        emit LiquidBoardroomChanged(msg.sender, _boardroom);
    }

    /// Set new boardroom
    /// @param _boardroom New boardroom address
    function setVeBoardroom(address _boardroom) public onlyOwner {
        veBoardroom = IBoardroom(_boardroom);
        emit VeBoardroomChanged(msg.sender, _boardroom);
    }

    /// Set new boardroom
    /// @param _boardroom New boardroom address
    function setUniswapBoardroom(address _boardroom) public onlyOwner {
        uniswapBoardroom = IBoardroom(_boardroom);
        emit UniswapBoardroomChanged(msg.sender, _boardroom);
    }

    /// Set new TokenManager
    /// @param _tokenManager New TokenManager address
    function setTokenManager(address _tokenManager) public onlyOwner {
        tokenManager = ITokenManager(_tokenManager);
        emit TokenManagerChanged(msg.sender, _tokenManager);
    }

    /// Set new BondManager
    /// @param _bondManager New BondManager address
    function setBondManager(address _bondManager) public onlyOwner {
        bondManager = IBondManager(_bondManager);
        emit BondManagerChanged(msg.sender, _bondManager);
    }

    /// Set new dev fund rate
    /// @param _devFundRate New dev fund rate
    function setDevFundRate(uint256 _devFundRate) public onlyOwner {
        devFundRate = _devFundRate;
        emit DevFundRateChanged(msg.sender, _devFundRate);
    }

    /// Set new stable fund rate
    /// @param _stableFundRate New stable fund rate
    function setStableFundRate(uint256 _stableFundRate) public onlyOwner {
        stableFundRate = _stableFundRate;
        emit StableFundRateChanged(msg.sender, _stableFundRate);
    }

    /// Set new stable fund rate
    /// @param _veBoardroomRate New stable fund rate
    function setVeBoardroomRate(uint256 _veBoardroomRate) public onlyOwner {
        veBoardroomRate = _veBoardroomRate;
        emit VeBoardroomRateChanged(msg.sender, _veBoardroomRate);
    }

    /// Set new stable fund rate
    /// @param _liquidBoardroomRate New stable fund rate
    function setLiquidBoardroomRate(uint256 _liquidBoardroomRate)
        public
        onlyOwner
    {
        liquidBoardroomRate = _liquidBoardroomRate;
        emit LiquidBoardroomRateChanged(msg.sender, _liquidBoardroomRate);
    }

    /// Set new threshold
    /// @param _threshold New threshold
    function setThreshold(uint256 _threshold) public onlyOwner {
        threshold = _threshold;
        emit ThresholdChanged(msg.sender, _threshold);
    }

    /// Set new maxRebase
    /// @param _maxRebase New maxRebase
    function setMaxRebase(uint256 _maxRebase) public onlyOwner {
        maxRebase = _maxRebase;
        emit MaxRebaseChanged(msg.sender, _maxRebase);
    }

    // --------- Operator (immediate) ---------

    /// Pauses / unpauses positive rebases
    /// @param pause Sets the pause / unpause
    function setPausePositiveRebase(bool pause) public onlyOperator {
        pausePositiveRebase = pause;
        emit PositiveRebasePaused(msg.sender, pause);
    }

    /// Make positive rebase for one token
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @dev The caller must ensure `managedToken` and `initialized` properties
    function _makeOnePositiveRebase(address syntheticTokenAddress) internal {
        tokenManager.updateOracle(syntheticTokenAddress);
        SyntheticToken syntheticToken = SyntheticToken(syntheticTokenAddress);
        uint256 amount = positiveRebaseAmount(syntheticTokenAddress);
        if (amount == 0) {
            return;
        }
        emit PositiveRebaseTotal(syntheticTokenAddress, amount);

        uint256 devFundAmount = amount.mul(devFundRate).div(100);
        tokenManager.mintSynthetic(
            syntheticTokenAddress,
            devFund,
            devFundAmount
        );
        emit DevFundFunded(syntheticTokenAddress, devFundAmount);
        amount = amount.sub(devFundAmount);

        uint256 stableFundAmount = amount.mul(stableFundRate).div(100);
        tokenManager.mintSynthetic(
            syntheticTokenAddress,
            stableFund,
            stableFundAmount
        );
        emit StableFundFunded(syntheticTokenAddress, stableFundAmount);
        amount = amount.sub(stableFundAmount);

        SyntheticToken bondToken =
            SyntheticToken(bondManager.bondIndex(syntheticTokenAddress));
        uint256 bondSupply = bondToken.totalSupply();
        uint256 bondPoolBalance = syntheticToken.balanceOf(address(this));
        uint256 bondShortage =
            Math.max(bondSupply, bondPoolBalance).sub(bondPoolBalance);
        uint256 bondAmount = Math.min(amount, bondShortage);
        if (bondAmount > 0) {
            tokenManager.mintSynthetic(
                syntheticTokenAddress,
                address(bondManager),
                bondAmount
            );
            emit BondDistributionFunded(syntheticTokenAddress, bondAmount);
        }
        amount = amount.sub(bondAmount);
        if (amount == 0) {
            return;
        }

        uint256 veBoardroomAmount = 0;
        if (veBoardroomRate > 0) {
            veBoardroomAmount = amount.mul(veBoardroomRate).div(100);
            tokenManager.mintSynthetic(
                syntheticTokenAddress,
                address(veBoardroom),
                veBoardroomAmount
            );
            veBoardroom.notifyTransfer(
                syntheticTokenAddress,
                veBoardroomAmount
            );
            emit VeBoardroomFunded(syntheticTokenAddress, veBoardroomAmount);
        }

        uint256 liquidBoardroomAmount = 0;
        if (liquidBoardroomRate > 0) {
            liquidBoardroomAmount = amount.mul(liquidBoardroomRate).div(100);
            tokenManager.mintSynthetic(
                syntheticTokenAddress,
                address(liquidBoardroom),
                liquidBoardroomAmount
            );
            liquidBoardroom.notifyTransfer(
                syntheticTokenAddress,
                liquidBoardroomAmount
            );
            emit LiquidBoardroomFunded(
                syntheticTokenAddress,
                liquidBoardroomAmount
            );
        }

        if (uniswapBoardroomRate() > 0) {
            uint256 uniswapBoardroomAmount =
                amount.sub(veBoardroomAmount).sub(liquidBoardroomAmount);
            tokenManager.mintSynthetic(
                syntheticTokenAddress,
                address(uniswapBoardroom),
                uniswapBoardroomAmount
            );
            uniswapBoardroom.notifyTransfer(
                syntheticTokenAddress,
                uniswapBoardroomAmount
            );
            emit UniswapBoardroomFunded(
                syntheticTokenAddress,
                uniswapBoardroomAmount
            );
        }
    }

    event DevFundChanged(address indexed operator, address newFund);
    event StableFundChanged(address indexed operator, address newFund);
    event LiquidBoardroomChanged(address indexed operator, address newBoadroom);
    event VeBoardroomChanged(address indexed operator, address newBoadroom);
    event UniswapBoardroomChanged(
        address indexed operator,
        address newBoadroom
    );
    event TokenManagerChanged(
        address indexed operator,
        address newTokenManager
    );
    event BondManagerChanged(address indexed operator, address newBondManager);
    event PositiveRebasePaused(address indexed operator, bool pause);

    event DevFundRateChanged(address indexed operator, uint256 newRate);
    event StableFundRateChanged(address indexed operator, uint256 newRate);
    event VeBoardroomRateChanged(address indexed operator, uint256 newRate);
    event LiquidBoardroomRateChanged(address indexed operator, uint256 newRate);
    event ThresholdChanged(address indexed operator, uint256 newThreshold);
    event MaxRebaseChanged(address indexed operator, uint256 newThreshold);
    event PositiveRebaseTotal(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event BondDistributionFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event LiquidBoardroomFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event VeBoardroomFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event UniswapBoardroomFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
    event DevFundFunded(address indexed syntheticTokenAddress, uint256 amount);
    event StableFundFunded(
        address indexed syntheticTokenAddress,
        uint256 amount
    );
}
