// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";


interface IERC20Mintable {
    function mint(address account_, uint256 amount_) external;
}

interface IERC20Deci {
    function decimals() external view returns (uint8);
}

interface IStaking {
    function stakeOnBehalf(uint256 amount, address onBehalf) external;
}

contract BondDepository is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 deposit,
        uint256 indexed payout,
        uint256 indexed nativePrice
    );
    event TermsChanged(PARAMETER indexed parameter, uint256 value);

    /* ======== STATE VARIABLES ======== */

    address public immutable RPLC; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable DAO; // receives profit share from bond

    address public staking; // to auto-stake payout

    Terms public terms; // stores terms for new bonds

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint256 principlePrice; // stable USD price of principle, 9 decimals
        uint256 minimumPrice; // vs principle value, 1600 = 16.00, 125 = 1.25
        uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint256 tokenPrice; // token price so how many RPLC you get for one principle
    }

    /* ======== INITIALIZATION ======== */

    constructor(
        address _RPLC,
        address _principle,
        address _DAO
    ) {
        require(_RPLC != address(0));
        RPLC = _RPLC;
        require(_principle != address(0));
        principle = _principle;
        require(_DAO != address(0));
        DAO = _DAO;
    }

    /**
     *  @notice initializes bond parameters
     *  @param _minimumPrice uint
     *  @param _fee uint
     *  @param _principlePricce uint
     */
    function initializeBondTerms(
        uint256 _minimumPrice,
        uint256 _fee,
        uint256 _principlePricce,
        uint256 _tokenPrice
    ) external onlyOwner {
        terms = Terms({
            minimumPrice: _minimumPrice,
            fee: _fee,
            principlePrice: _principlePricce,
            tokenPrice: _tokenPrice
        });
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER {
        FEE,
        PRINCIPLE_PRICE,
        TOKEN_PRICE
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
        if (_parameter == PARAMETER.FEE) {
            // 0
            terms.fee = _input;
        } else if (_parameter == PARAMETER.PRINCIPLE_PRICE) {
            // 1
            require(_input >= terms.minimumPrice, "below minimum price");
            terms.principlePrice = _input;
        } else if (_parameter == PARAMETER.TOKEN_PRICE) {
            // 2
            terms.tokenPrice = _input;
        }

        emit TermsChanged(_parameter, _input);
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    function setStaking(address _staking) external onlyOwner {
        require(_staking != address(0));
        staking = _staking;
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint256 _amount,
        address _depositor,
        bool _stake
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(_depositor != address(0), "Invalid address");
        require(_amount > 0, "Amount is 0");

        uint256 value = ((_amount * ((terms.principlePrice * 1e9) / terms.tokenPrice))/1e9) /10 **(IERC20Deci(principle).decimals()-IERC20Deci(RPLC).decimals());

        uint256 fee = (value * terms.fee) / 10000;
        uint256 payout = value - fee;

        IERC20(principle).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(principle).safeTransfer(DAO, _amount);

        IERC20Mintable(RPLC).mint(address(this), value);

        if (fee != 0) {
            // fee is transferred to dao
            IERC20(RPLC).safeTransfer(DAO, fee);
        }

        stakeOrSend(_depositor, _stake, payout);

        // indexed events are emitted
        emit BondCreated(_amount, payout, terms.tokenPrice);

        return terms.tokenPrice;
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend(
        address _recipient,
        bool _stake,
        uint256 _amount
    ) internal returns (uint256) {
        if (!_stake) {
            // if user does not want to stake
            IERC20(RPLC).safeTransfer(_recipient, _amount); // send payout
        } else {
            IERC20(RPLC).safeIncreaseAllowance(staking, _amount);
            IStaking(staking).stakeOnBehalf(_amount, _recipient);
        }
        return _amount;
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice calculate current bond price
     *  @return price_ uint
     */
    function bondPrice() public view returns (uint256 price_) {
        price_ = terms.tokenPrice;
    }

    function principlePrice() public view returns (uint256 price_) {
        price_ = terms.principlePrice;
    }

    function principlePriceInUSD() public view returns (uint256 price_) {
        price_ = principlePrice() / (10**IERC20Deci(RPLC).decimals() / 100);
    }

    /**
     *  @notice converts bond price to DAI/FRAC/USDT etc value with 2 decimal places, 2000 = 20.00
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns (uint256 price_) {
        price_ = bondPrice() / (10**IERC20Deci(RPLC).decimals() / 100);
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or RPLC) to the DAO
     *  @return bool
     */
    function recoverLostToken(address _token) external returns (bool) {
        require(_token != RPLC);
        require(_token != principle);
        IERC20(_token).safeTransfer(
            DAO,
            IERC20(_token).balanceOf(address(this))
        );
        return true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
