// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IFlyzTreasury.sol";
import "./IFlyzStaking.sol";
import "./IFlyzBondingCalculator.sol";
import "./IsFlyzERC20.sol";

import "./Ownable.sol";
import "./ERC20.sol";

import "./FixedPoint.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./SafeERC20.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract FlyzETHLPBondDepository is Ownable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 deposit,
        uint256 indexed payout,
        uint256 indexed expires,
        uint256 indexed priceInUSD,
        uint256 gonsPayout
    );
    event BondRedeemed(
        address indexed recipient,
        uint256 payout,
        uint256 remaining
    );
    event BondPriceChanged(
        uint256 indexed priceInUSD,
        uint256 indexed internalPrice,
        uint256 indexed debtRatio
    );
    event ControlVariableAdjustment(
        uint256 initialBCV,
        uint256 newBCV,
        uint256 adjustment,
        bool addition
    );

    /* ======== STATE VARIABLES ======== */

    address public immutable FLYZ; // token given as payment for bond
    address public immutable sFLYZ; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints FLYZ when receives principle
    address public immutable staking; // to auto-stake payout
    address public immutable bondCalculator; // calculates value of LP tokens
    address public immutable DAO; // receives loss share from bond

    AggregatorV3Interface internal priceFeed;

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    uint256 public totalDebt; // total value of outstanding bonds; used for pricing
    uint256 public lastDecay; // reference block for debt decay

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 vestingTerm; // in blocks
        uint256 minimumPrice; // vs principle value. 4 decimals (1500 = 0.15)
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // FLYZ remaining to be paid
        uint256 vesting; // Blocks left to vest
        uint256 lastTimestamp; // Last interaction
        uint256 pricePaid; // In DAI, for front end viewing
        uint256 gonsPayout; // sFLYZ gons remaining to be paid
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint256 buffer; // minimum length (in blocks) between adjustments
        uint256 lastBlock; // block when last adjustment made
    }

    /* ======== INITIALIZATION ======== */

    constructor(
        address _FLYZ,
        address _sFLYZ,
        address _principle,
        address _treasury,
        address _staking,
        address _bondCalucator,
        address _DAO,
        address _feed
    ) {
        require(_FLYZ != address(0));
        FLYZ = _FLYZ;
        require(_sFLYZ != address(0));
        sFLYZ = _sFLYZ;
        require(_principle != address(0));
        principle = _principle;
        require(_treasury != address(0));
        treasury = _treasury;
        require(_DAO != address(0));
        DAO = _DAO;
        require(_staking != address(0));
        staking = _staking;
        require(_bondCalucator != address(0));
        bondCalculator = _bondCalucator;
        require(_feed != address(0));
        priceFeed = AggregatorV3Interface(_feed);
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _maxDebt,
        uint256 _initialDebt
    ) external onlyOwner {
        require(terms.controlVariable == 0, 'Bonds must be initialized from 0');
        terms = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.timestamp;
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER {
        VESTING,
        PAYOUT,
        DEBT,
        MINPRICE
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms(PARAMETER _parameter, uint256 _input)
        external
        onlyOwner
    {
        if (_parameter == PARAMETER.VESTING) {
            // 0
            require(_input >= 10000, 'Vesting must be longer than 36 hours');
            terms.vestingTerm = _input;
        } else if (_parameter == PARAMETER.PAYOUT) {
            // 1
            require(_input <= 1000, 'Payout cannot be above 1 percent');
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.DEBT) {
            // 2
            terms.maxDebt = _input;
        } else if (_parameter == PARAMETER.MINPRICE) {
            terms.minimumPrice = _input;
        }
    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment(
        bool _addition,
        uint256 _increment,
        uint256 _target,
        uint256 _buffer
    ) external onlyOwner {
        require(
            _increment <= Math.max(terms.controlVariable.mul(25).div(1000), 1),
            'Increment too large'
        );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastBlock: block.number
        });
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256) {
        require(_depositor != address(0), 'Invalid address');

        decayDebt();
        require(totalDebt <= terms.maxDebt, 'Max capacity reached');

        uint256 priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint256 nativePrice = _bondPrice();

        require(
            _maxPrice >= nativePrice,
            'Slippage limit: more than max price'
        ); // slippage protection

        uint256 value = IFlyzTreasury(treasury).valueOfToken(
            principle,
            _amount
        );
        uint256 payout = payoutFor(value); // payout to bonder is computed

        require(payout >= 10000000, 'Bond too small'); // must be > 0.01 FLYZ ( underflow protection )
        require(payout <= maxPayout(), 'Bond too large'); // size protection because there is no slippage

        IERC20(principle).safeTransferFrom(msg.sender, treasury, _amount);
        IFlyzTreasury(treasury).mintRewards(address(this), payout);
        IFlyzTreasury(treasury).mintRewards(DAO, payout);

        // total debt is increased
        totalDebt = totalDebt.add(value);

        // stake FLYZ
        IERC20(FLYZ).approve(staking, payout);
        IFlyzStaking(staking).stake(payout, address(this));
        IFlyzStaking(staking).claim(address(this));

        // depositor info is stored
        uint256 stakeGons = IsFlyzERC20(sFLYZ).gonsForBalance(payout);
        bondInfo[_depositor] = Bond({
            payout: bondInfo[_depositor].payout.add(payout),
            vesting: terms.vestingTerm,
            lastTimestamp: block.timestamp,
            pricePaid: priceInUSD,
            gonsPayout: bondInfo[_depositor].gonsPayout.add(stakeGons)
        });

        // indexed events are emitted
        emit BondCreated(
            _amount,
            payout,
            block.timestamp.add(terms.vestingTerm),
            priceInUSD,
            stakeGons
        );
        emit BondPriceChanged(bondPriceInUSD(), _bondPrice(), debtRatio());

        adjust(); // control variable is adjusted
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */
    function redeem(address _recipient, bool _stake)
        external
        returns (uint256)
    {
        Bond memory info = bondInfo[_recipient];
        uint256 percentVested = percentVestedFor(_recipient); // (blocks since last interaction / vesting term remaining)

        require(percentVested >= 10000, 'not fully vested'); // if fully vested

        delete bondInfo[_recipient]; // delete user info
        uint256 _amount = IsFlyzERC20(sFLYZ).balanceForGons(info.gonsPayout);
        emit BondRedeemed(_recipient, _amount, 0); // emit bond data
        IERC20(sFLYZ).transfer(_recipient, _amount); // pay user everything due
        return _amount;
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint256 blockCanAdjust = adjustment.lastBlock.add(adjustment.buffer);
        if (adjustment.rate != 0 && block.timestamp >= blockCanAdjust) {
            uint256 initial = terms.controlVariable;
            if (adjustment.add) {
                terms.controlVariable = terms.controlVariable.add(
                    adjustment.rate
                );
                if (terms.controlVariable >= adjustment.target) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub(
                    adjustment.rate
                );
                if (terms.controlVariable <= adjustment.target) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastBlock = block.number;
            emit ControlVariableAdjustment(
                initial,
                terms.controlVariable,
                adjustment.rate,
                adjustment.add
            );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = block.timestamp;
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint256) {
        return IERC20(FLYZ).totalSupply().mul(terms.maxPayout).div(100000);
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint256 _value) public view returns (uint256) {
        return
            FixedPoint.fraction(_value, bondPrice()).decode112with18().div(
                1e14
            );
    }

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns (uint256 price_) {
        price_ = _rawBondPrice();
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns (uint256 price_) {
        price_ = _rawBondPrice();
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        } else if (terms.minimumPrice != 0) {
            terms.minimumPrice = 0;
        }
    }

    function _rawBondPrice() internal view returns (uint256) {
        return terms.controlVariable.mul(debtRatio()).div(1e7);
    }

    /**
     *  @notice get asset price from chainlink
     */
    function assetPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     *  @notice converts bond price to USD value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns (uint256 price_) {
        price_ = bondPrice()
            .mul(IFlyzBondingCalculator(bondCalculator).markdown(principle))
            .mul(uint256(assetPrice()))
            .div(1e12);
    }

    /**
     *  @notice calculate current ratio of debt to FLYZ supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns (uint256 debtRatio_) {
        uint256 supply = IERC20(FLYZ).totalSupply();
        debtRatio_ = FixedPoint
            .fraction(currentDebt().mul(1e9), supply)
            .decode112with18()
            .div(1e18);
    }

    /**
     *  @notice debt ratio in same terms as reserve bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns (uint256) {
        return
            debtRatio()
                .mul(IFlyzBondingCalculator(bondCalculator).markdown(principle))
                .div(1e9);
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns (uint256) {
        return totalDebt.sub(debtDecay());
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns (uint256 decay_) {
        uint256 timestampSinceLast = block.timestamp.sub(lastDecay);
        decay_ = totalDebt.mul(timestampSinceLast).div(terms.vestingTerm);
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor)
        public
        view
        returns (uint256 percentVested_)
    {
        Bond memory bond = bondInfo[_depositor];
        uint256 timestampSinceLast = block.timestamp.sub(bond.lastTimestamp);
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = timestampSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of FLYZ available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_)
    {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = bondInfo[_depositor].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or FLYZ) to the DAO
     *  @return bool
     */
    function recoverLostToken(address _token) external returns (bool) {
        require(_token != FLYZ);
        require(_token != sFLYZ);
        IERC20(_token).safeTransfer(
            DAO,
            IERC20(_token).balanceOf(address(this))
        );
        return true;
    }
}
