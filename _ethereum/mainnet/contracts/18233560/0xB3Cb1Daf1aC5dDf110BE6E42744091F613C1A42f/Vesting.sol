// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract VestingVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMath for uint256;

    struct Grant {
        uint256 startTime;
        uint256 amount;
        uint256 vestingDuration;
        uint256 monthsClaimed;
        uint256 totalClaimed;
        address recipient;
    }

    event GrantAdded(address indexed recipient);
    event GrantTokensClaimed(address indexed recipient, uint256 amountClaimed);
    event GrantRevoked(
        address recipient,
        uint256 amountVested,
        uint256 amountNotVested
    );
    event GrantUpdateAmount(
        address recipient,
        uint256 tokenAmount,
        uint256 amount
    );
    event UpdateIntervalTime(uint256 _intervalTime);

    IERC20Upgradeable public token;

    mapping(address => mapping(uint256 => Grant)) private tokenGrants;

    address public crowdsale_address;
    uint256 public intervalTime;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(IERC20Upgradeable _token) public initializer {
        require(address(_token) != address(0));
        token = _token;
        intervalTime = 2628003;
        __Ownable_init_unchained();
        __Context_init_unchained();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function addCrowdsaleAddress(address crowdsaleAddress) external onlyOwner {
        require(
            crowdsaleAddress != address(0),
            "ERC20: transfer from the zero address"
        );
        crowdsale_address = crowdsaleAddress;
    }

    function addTokenGrant(
        address _recipient,
        uint256 _amount,
        uint256 _vestingDurationInMonths, //9
        uint256 _lockDurationInMonths, //1
        uint256 crowdsaleRound //1
    ) external {
        // require(tokenGrants[_recipient].amount == 0, "Grant already exists, must revoke first.");
        require(
            _vestingDurationInMonths <= 25 * 12,
            "Duration greater than 25 years"
        );
        require(_lockDurationInMonths <= 10 * 12, "Lock greater than 10 years");
        require(_amount != 0, "Grant amount cannot be 0");
        uint256 amountVestedPerMonth = _amount.div(_vestingDurationInMonths);
        require(amountVestedPerMonth > 0, "amountVestedPerMonth < 0");

        if (tokenGrants[_recipient][crowdsaleRound].amount == 0) {
            Grant memory grant = Grant({
                startTime: currentTime().add(
                    (_lockDurationInMonths).mul(intervalTime)
                ),
                amount: _amount,
                vestingDuration: _vestingDurationInMonths,
                monthsClaimed: 0,
                totalClaimed: 0,
                recipient: _recipient
            });
            tokenGrants[_recipient][crowdsaleRound] = grant;
            emit GrantAdded(_recipient);
        } else {
            Grant storage tokenGrant = tokenGrants[_recipient][crowdsaleRound];
            require(
                tokenGrant.monthsClaimed < tokenGrant.vestingDuration,
                "Grant fully claimed"
            );
            tokenGrant.amount = uint256(tokenGrant.amount.add(_amount));
            emit GrantUpdateAmount(_recipient, tokenGrant.amount, _amount);
        }

        // token.approve(_recipient, address(this), _amount);
        // Transfer the grant tokens under the control of the vesting contract
        // token.transferFrom(_recipient, address(this), _amount);
    }

    /// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
    function claimVestedTokens(uint256 crowdsaleRound) external {
        uint256 monthsVested;
        uint256 amountVested;
        (monthsVested, amountVested) = calculateGrantClaim(
            msg.sender,
            crowdsaleRound
        );
        require(amountVested > 0, "Vested is 0");

        Grant storage tokenGrant = tokenGrants[msg.sender][crowdsaleRound];
        tokenGrant.monthsClaimed = uint256(
            tokenGrant.monthsClaimed.add(monthsVested)
        );
        tokenGrant.totalClaimed = uint256(
            tokenGrant.totalClaimed.add(amountVested)
        );

        emit GrantTokensClaimed(tokenGrant.recipient, amountVested);
        token.transfer(tokenGrant.recipient, amountVested);
    }

    function getTotalGrantClaimed(
        address _recipient,
        uint256 crodsaleRound
    ) external view returns (uint256, uint256) {
        Grant storage tokenGrant = tokenGrants[_recipient][crodsaleRound];
        return (tokenGrant.monthsClaimed, tokenGrant.totalClaimed);
    }

    /// @notice Terminate token grant transferring all vested tokens to the `_recipient`
    /// and returning all non-vested tokens to the contract owner
    /// Secured to the contract owner only
    /// @param _recipient address of the token grant recipient
    function revokeTokenGrant(
        address _recipient,
        uint256 crowdsaleRound
    ) external {
        Grant storage tokenGrant = tokenGrants[_recipient][crowdsaleRound];
        uint256 monthsVested;
        uint256 amountVested;
        (monthsVested, amountVested) = calculateGrantClaim(
            _recipient,
            crowdsaleRound
        );

        uint256 amountNotVested = (
            tokenGrant.amount.sub(tokenGrant.totalClaimed)
        ).sub(amountVested);

        delete tokenGrants[_recipient][crowdsaleRound];

        emit GrantRevoked(_recipient, amountVested, amountNotVested);

        // only transfer tokens if amounts are non-zero.
        // Negative cases are covered by upperbound check in addTokenGrant and overflow protection using SafeMath
        if (amountNotVested > 0) {
            token.transfer(crowdsale_address, amountNotVested);
        }
        if (amountVested > 0) {
            token.transfer(_recipient, amountVested);
        }
    }

    function getGrantStartTime(
        address _recipient,
        uint256 crowdsaleRound
    ) external view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[_recipient][crowdsaleRound];
        return tokenGrant.startTime;
    }

    function getGrantAmount(
        address _recipient,
        uint256 crowdsaleRound
    ) external view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[_recipient][crowdsaleRound];
        return tokenGrant.amount;
    }

    /// @notice Calculate the vested and unclaimed months and tokens available for `_grantId` to claim
    /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
    /// Returns (0, 0) if lock duration has not been reached
    function calculateGrantClaim(
        address _recipient,
        uint256 crowdsaleRound
    ) public view returns (uint256, uint256) {
        Grant storage tokenGrant = tokenGrants[_recipient][crowdsaleRound];

        require(
            tokenGrant.totalClaimed < tokenGrant.amount,
            "Grant fully claimed"
        );

        // Check if lock duration was reached by comparing the current time with the startTime. If lock duration hasn't been reached, return 0, 0
        if (currentTime() < tokenGrant.startTime) {
            return (0, 0);
        }

        // Elapsed months is the number of months since the startTime (after lock duration is complete)
        // We add 1 to the calculation as any time after the unlock timestamp counts as the first elapsed month.
        // For example: lock duration of 0 and current time at day 1, counts as elapsed month of 1
        // Lock duration of 1 month and current time at day 31, counts as elapsed month of 2
        // This is to accomplish the design that the first batch of vested tokens are claimable immediately after unlock.
        uint256 elapsedMonths = currentTime()
            .sub(tokenGrant.startTime)
            .div(intervalTime)
            .add(1);
        // If over vesting duration, all tokens vested
        if (elapsedMonths > tokenGrant.vestingDuration) {
            uint256 remainingGrant = tokenGrant.amount.sub(
                tokenGrant.totalClaimed
            );
            uint256 balanceMonth = tokenGrant.vestingDuration.sub(
                tokenGrant.monthsClaimed
            );
            return (balanceMonth, remainingGrant);
        } else {
            uint256 monthsVested = uint256(
                elapsedMonths.sub(tokenGrant.monthsClaimed)
            );
            uint256 amountVestedPerMonth = (
                tokenGrant.amount.sub(tokenGrant.totalClaimed)
            ).div(
                    uint256(
                        tokenGrant.vestingDuration.sub(tokenGrant.monthsClaimed)
                    )
                );
            uint256 amountVested = uint256(
                monthsVested.mul(amountVestedPerMonth)
            );
            return (monthsVested, amountVested);
        }
    }

    /**
     * @dev update the time gap between the distribution
     * @param _intervalTime update the time in seconds
     */
    function updateIntervalTime(uint256 _intervalTime) external onlyOwner {
        intervalTime = _intervalTime;
        emit UpdateIntervalTime(intervalTime);
    }

    function currentTime() private view returns (uint256) {
        return block.timestamp;
    }

    function remainingToken(
        address _recipient,
        uint256 crowdsaleRound
    ) external view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[_recipient][crowdsaleRound];
        return tokenGrant.amount.sub(tokenGrant.totalClaimed);
    }
    
    /**
    @dev - To find the next claim date for the user
    @param - _recipient - to whom we need to find next claim date
     */

    function nextClaimDate(
        address _recipient,
        uint256 crowdsaleRound
    ) external view returns (uint256) {
        Grant storage tokenGrant = tokenGrants[_recipient][crowdsaleRound];
        if (tokenGrant.startTime == 0) {
            return 0;
        }
        uint256 startTimeOfUser = tokenGrant.startTime;
        uint256 finalDate = startTimeOfUser +
            ((tokenGrant.vestingDuration - 1) * intervalTime);
        if (block.timestamp > finalDate) {
            return finalDate;
        }
        if(block.timestamp < startTimeOfUser){
            return startTimeOfUser;
        }
        uint256 j = 1;
        for (uint i = 0; i < j; i++) {
            startTimeOfUser += intervalTime;
            if (startTimeOfUser > block.timestamp) {
                return startTimeOfUser;
            } else {
                j++;
            }
        }
        return 0;
    }
      /**
     * @dev Change the base token address of the token
     * @param newToken address of the token.
     */
    function changeToken(
        IERC20Upgradeable newToken
    ) external virtual onlyOwner {
        require(
            address(newToken) != address(0),
            "Token: Address cant be zero address"
        );
        token = newToken;
    }
}
