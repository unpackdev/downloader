// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ContractGuard.sol";
import "./IBoardroom.sol";
import "./IBasisAsset.sol";
import "./IOracle.sol";
import "./Operator.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";


contract Treasury is ContractGuard, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 2 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;
    uint256 public epochSupplyContractionLeft = 0;

    // exclusions from total supply
    address[] public excludedFromTotalSupply = [
        address(0)
    ];

    // core components
    address public peg_;
    address public sbond_;
    address public pbl_;

    address public boardroom;
    address public pegOracle;

    // price
    uint256 public pegPriceOne;
    uint256 public pegPriceCeiling;

    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    // 28 first epochs (1 week) with 4.5% expansion regardless of SRN price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochPegPrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;
    uint256 public mintingFactorForPayingDebt; // print extra SRN during debt phase

    address public daoFund;
    uint256 public daoFundSharedPercent;

    address public devFund;
    uint256 public devFundSharedPercent;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event RedeemedBonds(address indexed from, uint256 pegAmount, uint256 bondAmount);
    event BoughtBonds(address indexed from, uint256 pegAmount, uint256 bondAmount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getPegPrice() > pegPriceCeiling) ? 0 : getPegCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator {
        require(
                IBasisAsset(sbond_).operator() == address(this) &&
                Operator(boardroom).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getPegPrice() public view returns (uint256 pegPrice) {
        try IOracle(pegOracle).consult(peg_, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("getPegPrice() Treasury: failed to consult SRN price from the oracle");
        }
    }

    function getPegUpdatedPrice() public view returns (uint256 _pegPrice) {
        try IOracle(pegOracle).twap(peg_, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("getUpdatedPegPrice() Treasury: failed to consult SRN price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getBurnablePegLeft() public view returns (uint256 _burnablePegLeft) {
        uint256 _pegPrice = getPegPrice();
        if (_pegPrice <= pegPriceOne) {
            uint256 _pegSupply = getPegCirculatingSupply();
            uint256 _bondMaxSupply = _pegSupply.mul(maxDebtRatioPercent).div(10000);
            uint256 _bondSupply = IERC20(sbond_).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnablePeg = _maxMintableBond.mul(_pegPrice).div(1e18);
                _burnablePegLeft = Math.min(epochSupplyContractionLeft, _maxBurnablePeg);
            }
        }
    }

    function getRedeemableBonds() public view returns (uint256 _redeemableBonds) {
        uint256 _pegPrice = getPegPrice();
        if (_pegPrice > pegPriceCeiling) {
            uint256 _totalPeg = IERC20(peg_).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalPeg.mul(1e18).div(_rate);
            }
        }
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _pegPrice = getPegPrice();
        if (_pegPrice <= pegPriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = pegPriceOne.mul(2);
            } else {
                uint256 _bondAmount = pegPriceOne.mul(1e18).div(_pegPrice); // to burn 1 SRN
                uint256 _discountAmount = _bondAmount.sub(pegPriceOne).mul(discountPercent).div(10000);
                _rate = pegPriceOne.add(_discountAmount).mul(2);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _pegPrice = getPegPrice();
        if (_pegPrice > pegPriceCeiling) {
            uint256 _pegPricePremiumThreshold = pegPriceOne.mul(premiumThreshold).div(100);
            if (_pegPrice >= _pegPricePremiumThreshold) {
                //Price > $1.10
                uint256 _premiumAmount = _pegPrice.sub(pegPriceOne).mul(premiumPercent).div(10000);
                _rate = pegPriceOne.add(_premiumAmount).mul(2);
                if (maxPremiumRate > pegPriceOne && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = pegPriceOne.mul(2);
            }
        }
    }

    /* ========== GOVERNENCE ========== */

    function initialize(
        address _peg,
        address _sbond,
        address _pbl,
        address _pegOracle,
        address _boardroom,
        uint256 _startTime
    ) public notInitialized {
        peg_ = _peg;
        sbond_ = _sbond;
        pbl_ = _pbl;
        pegOracle = _pegOracle;
        boardroom = _boardroom;
        startTime = _startTime;

        pegPriceOne = (10**18);
        pegPriceCeiling = pegPriceOne.mul(101).div(100);

        // Dynamic max expansion percent
        supplyTiers = [0 ether, 33 ether, 45 ether, 70 ether, 135 ether, 240 ether, 292 ether, 365 ether];
        maxExpansionTiers = [50, 75, 125, 150, 100, 50, 38, 25];

        maxSupplyExpansionPercent = 300; // Upto 3.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn SRN and mint sbond)
        maxDebtRatioPercent = 3500; // Upto 35% supply of sbond to purchase

        premiumThreshold = 110;
        premiumPercent = 7000;

        // First 28 epochs with 4.5% expansion
        bootstrapEpochs = 1;

        bootstrapSupplyExpansionPercent = 50;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(peg_).balanceOf(address(this));

        initialized = true;
        operator = msg.sender;
        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setBoardoom(address _boardroom) external onlyOperator {
        boardroom = _boardroom;
    }

    function setPegToken(address _peg) external onlyOperator {
        peg_ = _peg;
    }

    function setPegOracle(address _pegOracle) external onlyOperator {
        pegOracle = _pegOracle;
    }

    function setPegPriceCeiling(uint256 _pegPriceCeiling) external onlyOperator {
        require(_pegPriceCeiling <= pegPriceOne.mul(120).div(100), "out of range"); // [$1.0, $1.2]
        pegPriceOne = _pegPriceCeiling;
        pegPriceCeiling = _pegPriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range"); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 7, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1], "Value has to be higher than previous tier's value");
        }
        if (_index < 6) {
            require(_value < supplyTiers[_index + 1], "Value has to be lower than next tier's value");
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 7, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000, "out of range"); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint256 _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range"); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 4000, "out of range"); // <= 40%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 1000, "out of range"); // <= 10%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= pegPriceCeiling, "_premiumThreshold exceeds pegPriceCeiling");
        require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000, "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updatePegPrice() internal {
        try IOracle(pegOracle).update() {} catch {}
    }

    function getPegCirculatingSupply() public view returns (uint256) {
        IERC20 pegErc20 = IERC20(peg_);
        uint256 totalSupply = pegErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            balanceExcluded = balanceExcluded.add(pegErc20.balanceOf(excludedFromTotalSupply[entryId]));
        }
        return totalSupply.sub(balanceExcluded);
    }

    function buyBonds(uint256 _pegAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator nonReentrant {
        require(_pegAmount > 0, "Treasury: cannot purchase bonds with zero amount");

        uint256 pegPrice = getPegPrice();
        require(pegPrice == targetPrice, "Treasury: SRN price moved");
        require(
            pegPrice < pegPriceOne, // price < $0.5
            "Treasury: pegPrice not eligible for bond purchase"
        );

        require(_pegAmount <= epochSupplyContractionLeft, "Treasury: not enough bond left to purchase");

        uint256 _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _bondAmount = _pegAmount.mul(_rate).div(1e18);
        uint256 pegSupply = getPegCirculatingSupply();
        uint256 newBondSupply = IERC20(sbond_).totalSupply().add(_bondAmount);
        require(newBondSupply <= pegSupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");

        IBasisAsset(peg_).burnFrom(msg.sender, _pegAmount);
        try IBasisAsset(sbond_).mint(msg.sender, _bondAmount) { } catch { revert("Treasury: bond minting failed"); }

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_pegAmount);
        _updatePegPrice();

        emit BoughtBonds(msg.sender, _pegAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

        uint256 pegPrice = getPegPrice();
        require(pegPrice == targetPrice, "Treasury: SRN price moved");
        require(
            pegPrice > pegPriceCeiling, // price > $1.01
            "Treasury: pegPrice not eligible for bond redeem"
        );

        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _pegAmount = _bondAmount.mul(_rate).div(1e18);
        require(IERC20(peg_).balanceOf(address(this)) >= _pegAmount, "Treasury: treasury has no more budget");

        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _pegAmount));

        IBasisAsset(sbond_).burnFrom(msg.sender, _bondAmount);
        IERC20(peg_).safeTransfer(msg.sender, _pegAmount);

        _updatePegPrice();

        emit RedeemedBonds(msg.sender, _pegAmount, _bondAmount);
    }

    function _sendToBoardroom(uint256 _amount) internal {
        try IBasisAsset(peg_).mint(address(this), _amount) { } catch { revert("_sendToBoardroom: failed to mint peg"); }

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(peg_).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(peg_).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(block.timestamp, _devFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount);

        IERC20(peg_).safeDecreaseAllowance(boardroom, 0);
        IERC20(peg_).safeIncreaseAllowance(boardroom, _amount);
        IBoardroom(boardroom).allocateSeigniorage(_amount);
        emit BoardroomFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _pegSupply) internal returns (uint256) {
        for (uint8 tierId = 6; tierId >= 0; --tierId) {
            if (_pegSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updatePegPrice();
        previousEpochPegPrice = getPegPrice();
        uint256 pegSupply = getPegCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            // 14 first epochs with 4.5% expansion
            _sendToBoardroom(pegSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochPegPrice > pegPriceCeiling) {
                // Expansion ($SRN Price > 1 $USDC): there is some seigniorage to be allocated
                uint256 bondSupply = IERC20(sbond_).totalSupply();
                uint256 _percentage = previousEpochPegPrice.sub(pegPriceOne);
                uint256 _savedForBond;
                uint256 _savedForBoardroom;
                uint256 _mse = _calculateMaxSupplyExpansionPercent(pegSupply).mul(1e14);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForBoardroom = pegSupply.mul(_percentage).div(1e18);
                } else {
                    // have not saved enough to pay debt, mint more
                    uint256 _seigniorage = pegSupply.mul(_percentage).div(1e18);
                    _savedForBoardroom = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForBoardroom);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                if (_savedForBoardroom > 0) {
                    _sendToBoardroom(_savedForBoardroom);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    try IBasisAsset(peg_).mint(address(this), _savedForBond) {} catch { revert("Treasury: peg minting failed"); }
                    emit TreasuryFunded(block.timestamp, _savedForBond);
                }
            }
        }
    }

    function addExcludedAddress(address _exclude) external onlyOperator {
        excludedFromTotalSupply.push(_exclude);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(peg_), "peg");
        require(address(_token) != address(sbond_), "bond");
        require(address(_token) != address(pbl_), "share");
        _token.safeTransfer(_to, _amount);
    }

    function boardroomSetOperator(address _operator) external onlyOperator {
        IBoardroom(boardroom).setOperator(_operator);
    }

    function boardroomSetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        IBoardroom(boardroom).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function boardroomAllocateSeigniorage(uint256 amount) external onlyOperator {
        IBoardroom(boardroom).allocateSeigniorage(amount);
    }

    function boardroomGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IBoardroom(boardroom).governanceRecoverUnsupported(_token, _amount, _to);
    }

    function pegTransferOwnership(address _owner) external onlyOperator {
        require(_owner != address(0), "transfer to null address");
        Ownable(peg_).transferOwnership(_owner);
    }
}