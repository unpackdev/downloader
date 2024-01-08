// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Grant {
        address recipient;
        uint256 startTime;
        uint256 amount;
        uint256 vestingDuration;
        uint256 vestingCliff;
        uint256 daysClaimed;
        uint256 totalClaimed;
    }

    event GrantAdded(address indexed recipient);
    event GrantTokensClaimed(address indexed recipient, uint256 indexed amount);
    event WithdrawAllTokenGrant(address indexed recipient, uint256 indexed amount);
    event GrantRevoked(address indexed recipient, uint256 indexed amountVested, uint256 indexed amountNotVested);

    mapping(address => mapping(address => Grant)) public tokenGrants;
    mapping(address => uint256) public tokenAmountGrant;

    function addTokenGrant(address token, address _recipient, uint256 _startTime, uint256 _amount, uint256 _vestingDurationInDays, uint256 _vestingCliffInDays) public onlyOwner {
        require(_recipient != address(0), 'TokenVesting: beneficiary is the zero address');
        require(_vestingDurationInDays > 0, 'TokenVesting: duration is 0');

        uint256 amountVestedPerDay = _amount.div(_vestingDurationInDays);
        require(amountVestedPerDay > 0, 'TokenVesting: amountVestedPerDay > 0');

        // Transfer the grant tokens under the control of the vesting contract
        IERC20(token).safeTransferFrom(owner(), address(this), _amount);

        Grant memory grant = Grant({
            recipient: _recipient,
            startTime: _startTime == 0 ? block.timestamp : _startTime,
            amount: _amount,
            vestingDuration: _vestingDurationInDays,
            vestingCliff:_vestingCliffInDays,
            daysClaimed: 0,
            totalClaimed: 0
        });
        tokenAmountGrant[token] = tokenAmountGrant[token].add(_amount);
        tokenGrants[_recipient][token] = grant;

        emit GrantAdded(_recipient);
    }

    function addTokenGrants(address[] calldata tokens, address[] calldata _recipients, uint256[] calldata _startTimes, uint256[] calldata _amounts, uint256 _vestingDurationInDays, uint256 _vestingCliffInDays) external onlyOwner {
        uint256 arrLength = tokens.length;

        uint256 i;

        for (i < 0; i < arrLength; i++) {
            address token = tokens[i];
            address recipient = _recipients[i];
            uint256 startTime = _startTimes[i];
            uint256 amount = _amounts[i];
            addTokenGrant(token, recipient, startTime, amount, _vestingDurationInDays, _vestingCliffInDays);
        }
    }

    // Calculate the vested and unclaimed days and token availabel for _recipient to claim
    // Due to rounding errors once grant duration is reached, return the entire left grant amount
    // Return (0, 0) if cliff has not been reached
    function calculateGrantClaim(address token, address _recipient) public view returns (uint256, uint256) {
        Grant storage tokenGrant = tokenGrants[_recipient][token];

        if (tokenGrant.totalClaimed >= tokenGrant.amount) {
            return (0, 0);
        }

        if (block.timestamp < tokenGrant.startTime) {
            return (0, 0);
        }

        // Check cliff was reached

        uint256 elapsedTime = block.timestamp.sub(tokenGrant.startTime);

        uint256 elapsedDays = elapsedTime.div(1 days);

        if (elapsedDays <= tokenGrant.vestingCliff) {
            return (elapsedDays, 0);
        }

        elapsedDays = elapsedDays.sub(tokenGrant.vestingCliff);

        // If over vesting duration, all token vested
        if (elapsedDays >= tokenGrant.vestingDuration) {
            uint256 remainingGrant = tokenGrant.amount.sub(tokenGrant.totalClaimed);

            return (tokenGrant.vestingDuration, remainingGrant);
        } else {
            uint256 daysVested = elapsedDays.sub(tokenGrant.daysClaimed);
            uint256 amountVestedPerDay = tokenGrant.amount.div(tokenGrant.vestingDuration);
            uint256 amountVested = daysVested.mul(amountVestedPerDay);
            return (elapsedDays, amountVested);
        }
    }

    // Allow a grant recipient to claim their vested token
    function claimVestedToken(address token) external {
        uint256 daysVested;
        uint256 amountVested;
        (daysVested, amountVested) = calculateGrantClaim(token, msg.sender);
        require(amountVested > 0, "TokenVesting: Vested is 0");

        Grant storage tokenGrant = tokenGrants[msg.sender][token];

        IERC20(token).safeTransfer(tokenGrant.recipient, amountVested);

        tokenGrant.daysClaimed = daysVested;
        tokenGrant.totalClaimed = tokenGrant.totalClaimed.add(amountVested);
        tokenAmountGrant[token] = tokenAmountGrant[token].sub(amountVested);

        emit GrantTokensClaimed(tokenGrant.recipient, amountVested);
    }

    // Transfer all token to admin address when contract fail
    function withdrawAllTokenGrant(address token, address recipient) external onlyOwner {
        uint256 amountWithdraw = tokenAmountGrant[token];

        IERC20(token).safeTransfer(recipient, amountWithdraw);

        emit WithdrawAllTokenGrant(recipient, amountWithdraw);
    }

    // Terminate token grant, transferring all vested tokens to the _recipient
    // and return all non-vested token to the contract owner
    function revokeTokenGrant(address token, address _recipient) external onlyOwner {
        Grant storage tokenGrant = tokenGrants[_recipient][token];

        uint256 daysVested;
        uint256 amountVested;
        
        (daysVested, amountVested) = calculateGrantClaim(token, _recipient);


        uint256 amountNotVested = (tokenGrant.amount.sub(tokenGrant.totalClaimed).sub(amountVested));

        IERC20(token).safeTransfer(owner(), amountNotVested);

        IERC20(token).safeTransfer(_recipient, amountVested);

        tokenGrant.recipient = address(0);
        tokenGrant.startTime = 0;
        tokenGrant.amount = 0;
        tokenGrant.vestingDuration = 0;
        tokenGrant.vestingCliff = 0;
        tokenGrant.daysClaimed = 0;
        tokenGrant.totalClaimed = 0;

        emit GrantRevoked(_recipient, amountVested, amountNotVested);
    }
}