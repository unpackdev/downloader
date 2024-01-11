// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "ReentrancyGuard.sol";
import "IERC20Metadata.sol";
import "ITreasury.sol";
import "IVaderBond.sol";
import "SafelyOwnable.sol";

contract VaderBond is IVaderBond, SafelyOwnable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    enum PARAMETER {
        VESTING,
        PAYOUT,
        DEBT,
        MIN_PRICE
    }

    event Initialize(
        uint controlVariable,
        uint vestingTerm,
        uint minPrice,
        uint maxPayout,
        uint maxDebt,
        uint inititalDebt,
        uint lastDecay
    );
    event SetBondTerms(PARAMETER indexed param, uint input);
    event SetAdjustment(bool add, uint rate, uint target, uint buffer);
    event BondCreated(uint deposit, uint payout, uint expires);
    event BondRedeemed(address indexed recipient, uint payout, uint remaining);
    event BondPriceChanged(uint price, uint debtRatio);
    event ControlVariableAdjustment(
        uint initialBCV,
        uint newBCV,
        uint adjustment,
        bool addition
    );
    event TreasuryChanged(address treasury);

    uint8 private immutable PRINCIPAL_TOKEN_DECIMALS;
    uint8 private constant PAYOUT_TOKEN_DECIMALS = 18; // Vader has 18 decimals
    uint private constant MIN_PAYOUT = 10**PAYOUT_TOKEN_DECIMALS / 100; // 0.01
    uint private constant MAX_PERCENT_VESTED = 1e4; // 1 = 0.01%, 10000 = 100%
    uint private constant MAX_PAYOUT_DENOM = 1e5; // 100 = 0.1%, 100000 = 100%
    // roughly 36 hours (262 blocks / hour)
    uint private constant MIN_VESTING_TERMS = 10000;

    IERC20 public immutable payoutToken; // token paid for principal
    IERC20 public immutable principalToken; // inflow token
    ITreasury public treasury; // pays for and receives principal

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping(address => Bond) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds
    uint public lastDecay; // reference block for debt decay

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in blocks
        uint minPrice; // vs principal value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint maxDebt; // max debt, same decimals with payout token
    }
    // Info for bond holder
    struct Bond {
        uint payout; // payout token remaining to be paid
        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
    }
    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint buffer; // minimum length (in blocks) between adjustments
        uint lastBlock; // block when last adjustment made
    }

    constructor(
        address _treasury,
        address _payoutToken,
        address _principalToken
    ) {
        require(_treasury != address(0), "treasury = zero");
        treasury = ITreasury(_treasury);
        require(_payoutToken != address(0), "payout token = zero");
        payoutToken = IERC20(_payoutToken);
        require(_principalToken != address(0), "principal token = zero");
        principalToken = IERC20(_principalToken);

        PRINCIPAL_TOKEN_DECIMALS = IERC20Metadata(_principalToken).decimals();

        // vesting term set to > 0 so that debtDecay() doesn't fail
        terms.vestingTerm = MIN_VESTING_TERMS;
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initialize(
        uint _controlVariable,
        uint _vestingTerm,
        uint _minPrice,
        uint _maxPayout,
        uint _maxDebt,
        uint _initialDebt
    ) external override onlyOwner {
        require(currentDebt() == 0, "debt > 0");

        require(_controlVariable > 0, "cv = 0");
        require(_vestingTerm >= MIN_VESTING_TERMS, "vesting < min");
        // max payout must be < 1% of total supply of payout token
        require(_maxPayout <= MAX_PAYOUT_DENOM / 100, "max payout > 1%");

        terms = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minPrice: _minPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });

        totalDebt = _initialDebt;
        lastDecay = block.number;

        emit Initialize(
            _controlVariable,
            _vestingTerm,
            _minPrice,
            _maxPayout,
            _maxDebt,
            _initialDebt,
            block.number
        );
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _param PARAMETER
     *  @param _input uint
     */
    function setBondTerms(PARAMETER _param, uint _input) external onlyOwner {
        if (_param == PARAMETER.VESTING) {
            require(_input >= MIN_VESTING_TERMS, "vesting < min");
            terms.vestingTerm = _input;
        } else if (_param == PARAMETER.PAYOUT) {
            // max payout must be < 1% of total supply of payout token
            require(_input <= MAX_PAYOUT_DENOM / 100, "max payout > 1%");
            terms.maxPayout = _input;
        } else if (_param == PARAMETER.DEBT) {
            terms.maxDebt = _input;
        } else if (_param == PARAMETER.MIN_PRICE) {
            terms.minPrice = _input;
        }
        emit SetBondTerms(_param, _input);
    }

    /**
     *  @notice set control variable adjustment
     *  @param _add bool
     *  @param _rate uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment(
        bool _add,
        uint _rate,
        uint _target,
        uint _buffer
    ) external onlyOwner {
        require(_rate <= terms.controlVariable.mul(3) / 100, "rate > 3%");

        if (_add) {
            require(_target >= terms.controlVariable, "target < cv");
        } else {
            require(_target <= terms.controlVariable, "target > cv");
        }
        adjustment = Adjust({
            add: _add,
            rate: _rate,
            target: _target,
            buffer: _buffer,
            lastBlock: block.number
        });
        emit SetAdjustment(_add, _rate, _target, _buffer);
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay uint
     */
    function debtDecay() public view returns (uint decay) {
        uint blocksSinceLast = block.number.sub(lastDecay);
        decay = totalDebt.mul(blocksSinceLast).div(terms.vestingTerm);
        if (decay > totalDebt) {
            decay = totalDebt;
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() private {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = block.number;
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns (uint) {
        return totalDebt.sub(debtDecay());
    }

    /**
     *  @notice calculate current ratio of debt to payout token supply
     *  @notice protocols using DAO should be careful when quickly adding large %s to total supply
     *  @return uint
     */
    function debtRatio() public view returns (uint) {
        // NOTE: debt ratio is scaled up by 1e18
        // NOTE: fails if payoutToken.totalSupply() == 0
        return currentDebt().mul(1e18).div(payoutToken.totalSupply());
    }

    /**
     *  @notice calculate current bond premium
     *  @return price uint
     *  @dev price = 2 * 10 ** principal token decimals = 2 principal token to buy 1 bond
     */
    function bondPrice() public view returns (uint price) {
        // NOTE: debt ratio scaled up with 1e18, so divide by 1e18
        price = terms.controlVariable.mul(debtRatio()) / 1e18;
        if (price < terms.minPrice) {
            price = terms.minPrice;
        }
    }

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint) {
        return
            payoutToken.totalSupply().mul(terms.maxPayout) / MAX_PAYOUT_DENOM;
    }

    /**
     *  @notice calculate total interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint _value) public view returns (uint) {
        // NOTE: decimals of value must have payout token decimals
        // NOTE: bond price must have principal token decimals
        return _value.mul(10**PRINCIPAL_TOKEN_DECIMALS).div(bondPrice());
    }

    function min(uint x, uint y) private returns (uint) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) private returns (uint) {
        return x >= y ? x : y;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() private {
        uint blockCanAdjust = adjustment.lastBlock.add(adjustment.buffer);
        if (adjustment.rate > 0 && block.number >= blockCanAdjust) {
            uint cv = terms.controlVariable;
            uint target = adjustment.target;
            if (adjustment.add) {
                terms.controlVariable = min(cv.add(adjustment.rate), target);
                if (terms.controlVariable >= target) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = max(cv.sub(adjustment.rate), target);
                if (terms.controlVariable <= target) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastBlock = block.number;
            emit ControlVariableAdjustment(
                cv,
                terms.controlVariable,
                adjustment.rate,
                adjustment.add
            );
        }
    }

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     *  @dev Deposit resets vesting term for _depositor
     */
    function deposit(
        uint _amount,
        uint _maxPrice,
        address _depositor
    ) external override nonReentrant returns (uint) {
        require(_depositor != address(0), "depositor = zero");
        require(_amount > 0, "amount = 0");

        decayDebt();
        require(totalDebt <= terms.maxDebt, "max debt");
        require(_maxPrice >= bondPrice(), "bond price > max");

        uint value = treasury.valueOfToken(address(principalToken), _amount);
        uint payout = payoutFor(value);

        require(payout >= MIN_PAYOUT, "payout < min");
        require(payout <= maxPayout(), "payout > max");

        principalToken.safeTransferFrom(msg.sender, address(this), _amount);
        principalToken.approve(address(treasury), _amount);
        treasury.deposit(address(principalToken), _amount, payout);

        totalDebt = totalDebt.add(value);

        bondInfo[_depositor] = Bond({
            payout: bondInfo[_depositor].payout.add(payout),
            vesting: terms.vestingTerm,
            lastBlock: block.number
        });

        emit BondCreated(_amount, payout, block.number.add(terms.vestingTerm));

        uint price = bondPrice();
        // remove floor if price above min
        if (price > terms.minPrice && terms.minPrice > 0) {
            terms.minPrice = 0;
        }

        emit BondPriceChanged(price, debtRatio());

        adjust();
        return payout;
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested uint
     */
    function percentVestedFor(address _depositor)
        public
        view
        returns (uint percentVested)
    {
        Bond memory bond = bondInfo[_depositor];
        uint blocksSinceLast = block.number.sub(bond.lastBlock);
        uint vesting = bond.vesting;
        if (vesting > 0) {
            percentVested = blocksSinceLast.mul(MAX_PERCENT_VESTED).div(
                vesting
            );
        }
    }

    /**
     *  @notice calculate amount of payout token available for claim by depositor
     *  @param _depositor address
     *  @return uint
     */
    function pendingPayoutFor(address _depositor) external view returns (uint) {
        uint percentVested = percentVestedFor(_depositor);
        uint payout = bondInfo[_depositor].payout;
        if (percentVested >= MAX_PERCENT_VESTED) {
            return payout;
        } else {
            return payout.mul(percentVested) / MAX_PERCENT_VESTED;
        }
    }

    /**
     *  @notice redeem bond for user
     *  @return uint
     */
    function redeem(address _depositor) external nonReentrant returns (uint) {
        Bond memory info = bondInfo[_depositor];
        uint percentVested = percentVestedFor(_depositor);

        if (percentVested >= MAX_PERCENT_VESTED) {
            delete bondInfo[_depositor];
            emit BondRedeemed(_depositor, info.payout, 0);
            payoutToken.transfer(_depositor, info.payout);
            return info.payout;
        } else {
            uint payout = info.payout.mul(percentVested) / MAX_PERCENT_VESTED;

            bondInfo[_depositor] = Bond({
                payout: info.payout.sub(payout),
                vesting: info.vesting.sub(block.number.sub(info.lastBlock)),
                lastBlock: block.number
            });

            emit BondRedeemed(_depositor, payout, bondInfo[_depositor].payout);
            payoutToken.transfer(_depositor, payout);
            return payout;
        }
    }

    /**
     *  @notice owner can update treasury address
     *  @param _treasury address
     *  @dev allow new treasury to be zero address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(treasury), "no change");
        treasury = ITreasury(_treasury);
        emit TreasuryChanged(_treasury);
    }

    /**
     *  @notice allows owner to send lost tokens to owner
     *  @param _token address
     */
    function recover(address _token) external onlyOwner {
        require(_token != address(payoutToken), "protected");
        IERC20(_token).safeTransfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}
