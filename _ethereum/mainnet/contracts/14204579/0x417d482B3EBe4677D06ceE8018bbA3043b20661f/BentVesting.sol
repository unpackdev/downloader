// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Errors.sol";

contract BentVesting is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    event CreateVesting(
        uint256 indexed vestingId,
        address indexed user,
        uint256 amount,
        uint256 startEpoch,
        uint256 durationInEpoch
    );
    event Claim(
        uint256 indexed vestingId,
        address indexed user,
        uint256 amount
    );

    struct Vesting {
        address user;
        uint256 amount; // bent token amount in wei
        uint256 startEpoch; // start time in epoch
        uint256 durationInEpoch; // duration in epoch
        uint256 claimedAmount;
    }

    uint256 public startTime;
    uint256 public epochLength;
    IERC20 public bent;
    Vesting[] public vestings;
    mapping(address => uint256[]) private _vestingsByAddress;

    constructor(
        address _bent,
        uint256 _startTime,
        uint256 _epochLength
    ) Ownable() {
        bent = IERC20(_bent);
        startTime = _startTime;
        epochLength = _epochLength;
    }

    function currentEpoch() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        }

        return (block.timestamp - startTime) / epochLength + 1;
    }

    function createVesting(
        address user,
        uint256 amount,
        uint256 startEpoch,
        uint256 durationInEpoch
    ) external onlyOwner {
        require(
            user != address(0) && !user.isContract(),
            Errors.INVALID_ADDRESS
        );
        require(amount > 0, Errors.INVALID_AMOUNT);
        require(
            startEpoch > currentEpoch() && durationInEpoch > 0,
            Errors.INVALID_REQUEST
        );

        vestings.push(
            Vesting({
                user: user,
                amount: amount,
                startEpoch: startEpoch,
                durationInEpoch: durationInEpoch,
                claimedAmount: 0
            })
        );
        _vestingsByAddress[user].push(vestings.length - 1);

        emit CreateVesting(
            vestings.length - 1,
            user,
            amount,
            startEpoch,
            durationInEpoch
        );
    }

    function vestingsByAddress(address user)
        external
        view
        returns (uint256[] memory)
    {
        return _vestingsByAddress[user];
    }

    function claimable(uint256 vestingId) external view returns (uint256) {
        require(vestingId < vestings.length, Errors.INVALID_INDEX);

        return _claimable(vestingId);
    }

    function _claimable(uint256 vestingId) internal view returns (uint256) {
        Vesting memory vesting = vestings[vestingId];

        uint256 current = currentEpoch();

        if (current < vesting.startEpoch) {
            return 0;
        }

        uint256 vestedAmount = ((currentEpoch() - vesting.startEpoch + 1) *
            vesting.amount) / vesting.durationInEpoch;

        if (vestedAmount > vesting.amount) {
            vestedAmount = vesting.amount;
        }

        return vestedAmount - vesting.claimedAmount;
    }

    function claim(uint256 vestingId) external {
        require(vestingId < vestings.length, Errors.INVALID_INDEX);

        Vesting storage vesting = vestings[vestingId];
        require(msg.sender == vesting.user, Errors.UNAUTHORIZED);

        uint256 claimAmount = _claimable(vestingId);
        require(claimAmount > 0, Errors.ZERO_AMOUNT);

        vesting.claimedAmount += claimAmount;

        bent.safeTransfer(vesting.user, claimAmount);

        emit Claim(vestingId, vesting.user, claimAmount);
    }
}
