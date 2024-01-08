//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

/**
 * @title bloXmove Cliffing and Vesting Contract.
 */
contract BloXmoveVesting is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    // The ERC20 bloXmove token
    IERC20 public immutable bloXmoveToken;
    // The allowed total amount of all grants (currently estimated 49000000 tokens).
    uint256 public immutable totalAmountOfGrants;
    // The current total amount of added grants.
    uint256 public storedAddedAmount = 0;

    struct Grant {
        address beneficiary;
        uint16 vestingDuration; // in days
        uint16 daysClaimed;
        uint256 vestingStartTime;
        uint256 amount;
        uint256 totalClaimed;
    }

    // The start time of all Grants.
    // starttime + cliffing time of Grant = starttime of vesting
    uint256 public immutable startTime;

    mapping(address => Grant) private tokenGrants;

    event GrantAdded(address indexed beneficiary);

    event GrantTokensClaimed(
        address indexed beneficiary,
        uint256 amountClaimed
    );

    /**
     * @dev Constructor to set the address of the token contract
     * and the start time (timestamp in seconds).
     */
    constructor(
        address _bloXmoveToken,
        address _grantManagerAddr,
        uint256 _totalAmountOfGrants,
        uint256 _startTime
    ) {
        transferOwnership(_grantManagerAddr);
        bloXmoveToken = IERC20(_bloXmoveToken);
        totalAmountOfGrants = _totalAmountOfGrants;
        startTime = _startTime;
    }

    /**
     * @dev Not supported receive function.
     */
    receive() external payable {
        revert("Not supported receive function");
    }

    /**
     * @dev Not supported fallback function.
     */
    fallback() external payable {
        revert("Not supported fallback function");
    }

    /**
     * @dev Add Token Grant for the beneficiary.
     * @param _beneficiary the address of the account receiving the grant
     * @param _amount the amount (in 1/18 token) of the grant
     * @param _vestingDurationInDays the vesting period of the grant in days
     * @param _vestingCliffInDays the cliff period of the grant in days
     *
     * Emits a {GrantAdded} event indicating the beneficiary address.
     *
     * Requirements:
     *
     * - The msg.sender is the owner of the contract.
     * - The beneficiary has no other Grants.
     * - The given grant amount + other added grants is smaller or equal to the totalAmountOfGrants
     * - The amount vested per day (amount/vestingDurationInDays) is bigger than 0.
     * - The requirement described in function {calculateGrantClaim} for msg.sender.
     * - The contract can transfer token on behalf of the owner of the contract.
     */
    function addTokenGrant(
        address _beneficiary,
        uint256 _amount,
        uint16 _vestingDurationInDays,
        uint16 _vestingCliffInDays
    ) external onlyOwner {
        require(tokenGrants[_beneficiary].amount == 0, "Grant already exists!");
        storedAddedAmount = storedAddedAmount.add(_amount);
        require(
            storedAddedAmount <= totalAmountOfGrants,
            "Amount exceeds grants balance!"
        );
        uint256 amountVestedPerDay = _amount.div(_vestingDurationInDays);
        require(amountVestedPerDay > 0, "amountVestedPerDay is 0");
        require(
            bloXmoveToken.transferFrom(owner(), address(this), _amount),
            "transferFrom Error"
        );

        Grant memory grant = Grant({
            vestingStartTime: startTime + _vestingCliffInDays * 1 days,
            amount: _amount,
            vestingDuration: _vestingDurationInDays,
            daysClaimed: 0,
            totalClaimed: 0,
            beneficiary: _beneficiary
        });
        tokenGrants[_beneficiary] = grant;
        emit GrantAdded(_beneficiary);
    }

    /**
     * @dev Claim the available vested tokens.
     *
     * This function is called by the beneficiaries to claim their vested tokens.
     *
     * Emits a {GrantTokensClaimed} event indicating the beneficiary address and
     * the claimed amount.
     *
     * Requirements:
     *
     * - The vested amount to claim is bigger than 0
     * - The requirement described in function {calculateGrantClaim} for msg.sender
     * - The contract can transfer tokens to the beneficiary
     */
    function claimVestedTokens() external {
        uint16 daysVested;
        uint256 amountVested;
        (daysVested, amountVested) = calculateGrantClaim(_msgSender());
        require(amountVested > 0, "Vested is 0");
        Grant storage tokenGrant = tokenGrants[_msgSender()];
        tokenGrant.daysClaimed = uint16(tokenGrant.daysClaimed.add(daysVested));
        tokenGrant.totalClaimed = uint256(
            tokenGrant.totalClaimed.add(amountVested)
        );
        require(
            bloXmoveToken.transfer(tokenGrant.beneficiary, amountVested),
            "no tokens"
        );
        emit GrantTokensClaimed(tokenGrant.beneficiary, amountVested);
    }

    /**
     * @dev calculate the days and the amount vested for a particular claim.
     *
     * Requirements:
     *
     * - The Grant ist not fully claimed
     * - The current time is bigger than the starttime.
     *
     * @return a tuple of days vested and amount of vested tokens.
     */
    function calculateGrantClaim(address _beneficiary)
        private
        view
        returns (uint16, uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        require(tokenGrant.amount > 0, "no Grant");
        require(
            tokenGrant.totalClaimed < tokenGrant.amount,
            "Grant fully claimed"
        );
        // Check cliffing duration
        if (currentTime() < tokenGrant.vestingStartTime) {
            return (0, 0);
        }

        uint256 elapsedDays = currentTime()
            .sub(tokenGrant.vestingStartTime - 1 days)
            .div(1 days);

        // If over vesting duration, all tokens vested
        if (elapsedDays >= tokenGrant.vestingDuration) {
            // solve the uneven vest issue that could accure
            uint256 remainingGrant = tokenGrant.amount.sub(
                tokenGrant.totalClaimed
            );
            return (tokenGrant.vestingDuration, remainingGrant);
        } else {
            uint16 daysVested = uint16(elapsedDays.sub(tokenGrant.daysClaimed));
            uint256 amountVestedPerDay = tokenGrant.amount.div(
                uint256(tokenGrant.vestingDuration)
            );
            uint256 amountVested = uint256(daysVested.mul(amountVestedPerDay));
            return (daysVested, amountVested);
        }
    }

    /**
     * @dev Get the amount of tokens that are currently available to claim for a given beneficiary.
     * Reverts if there is no grant for the beneficiary.
     *
     * @return the amount of tokens that are currently available to claim, 0 if fully claimed.
     */
    function getCurrentAmountToClaim(address _beneficiary)
        public
        view
        returns (uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        require(tokenGrant.amount > 0, "no Grant");
        if (tokenGrant.totalClaimed == tokenGrant.amount) {
            return 0;
        }
        uint256 amountVested;
        (, amountVested) = calculateGrantClaim(_beneficiary);
        return amountVested;
    }

    /**
     * @dev Get the remaining grant amount for a given beneficiary.
     * @return the remaining grant amount.
     */
    function getRemainingGrant(address _beneficiary)
        public
        view
        returns (uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        return tokenGrant.amount.sub(tokenGrant.totalClaimed);
    }

    /**
     * @dev Get the vesting start time for a given beneficiary.
     * @return the start time.
     */
    function getVestingStartTime(address _beneficiary)
        public
        view
        returns (uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        return tokenGrant.vestingStartTime;
    }

    /**
     * @dev Get the grant amount for a given beneficiary.
     * @return the grant amount.
     */
    function getGrantAmount(address _beneficiary)
        public
        view
        returns (uint256)
    {
        Grant storage tokenGrant = tokenGrants[_beneficiary];
        return tokenGrant.amount;
    }

    /**
     * @dev Get the timestamp from the block set by the miners.
     * @return the current timestamp of the block.
     */
    function currentTime() private view returns (uint256) {
        return block.timestamp; // solhint-disable-line
    }
}
