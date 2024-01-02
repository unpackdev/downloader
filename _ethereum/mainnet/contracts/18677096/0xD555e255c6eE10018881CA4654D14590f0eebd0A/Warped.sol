// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IWarped.sol";

contract Warped is IWarped, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant FIRST_CLIFF_PERCENTAGE = 40;
    uint256 public constant SECOND_CLIFF_PERCENTAGE = 70;

    IERC20 public immutable token;
    bytes32 public merkleRoot;
    uint256 public start;
    uint256 public firstCliff;
    uint256 public secondCliff;
    bool public started;

    mapping(address => UserInfo) public info;

    constructor(address _token) {
        if (_token == address(0)) {
            revert AddressZero();
        }

        token = IERC20(_token);
    }

    function activateSale(uint256 _start, uint256 _amount, bytes32 _merkleRoot) external onlyOwner {
        if (_start < block.timestamp) {
            revert InvalidStart();
        }
        if (started) {
            revert AlreadyStarted(start);
        }

        if (_merkleRoot == bytes32(0)) {
            revert InvalidMerkleRoot();
        }

        token.safeTransferFrom(msg.sender, address(this), _amount);

        start = _start;
        firstCliff = start + 6 weeks;
        secondCliff = start + 12 weeks;
        started = true;
        merkleRoot = _merkleRoot;

        emit SaleActivated(_start, firstCliff, secondCliff);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function emergencyWithdraw(uint256 amountToWithdraw) external onlyOwner {
        token.safeTransfer(msg.sender, amountToWithdraw);
    }

    function claimedAmount(address _user) external view returns (uint256) {
        return info[_user].amountClaimed;
    }

    function claimedAll(address _user) external view returns (bool) {
        return info[_user].claimedAll;
    }

    function accountInfo(
        address _user
    ) external view returns (UserInfo memory) {
        return info[_user];
    }

    function getPeriod() public view returns (VestingPeriod) {
        uint256 timestamp = block.timestamp;

        if (!started || start > timestamp) {
            return VestingPeriod.DidntStart;
        } else if (timestamp < firstCliff) {
            return VestingPeriod.First;
        } else if (timestamp < secondCliff) {
            return VestingPeriod.Second;
        } else {
            return VestingPeriod.Third;
        }
    }

    function claim(uint256 amount, bytes32[] calldata merkleProof) external {
        if (!started) {
            revert DistributionIsntActive();
        }

        address user = msg.sender;
        bytes32 node = keccak256(abi.encodePacked(user, amount));
        bool isValidProof = MerkleProof.verifyCalldata(
            merkleProof,
            merkleRoot,
            node
        );

        if (!isValidProof) {
            revert InvalidProof();
        }

        UserInfo memory userInfo = info[user];

        if (userInfo.claimedAll) {
            revert AlreadyClaimedAllRewards(user);
        }

        VestingPeriod period = getPeriod();

        uint256 availableAmount;

        if (period == VestingPeriod.DidntStart) {
            revert DistributionDidntYetStart(start, block.timestamp);
        } else if (period == VestingPeriod.First) {
            availableAmount = (amount * FIRST_CLIFF_PERCENTAGE) / 100;
            userInfo.firstClaimTimestamp = block.timestamp;
        } else if (period == VestingPeriod.Second) {
            availableAmount = (amount * SECOND_CLIFF_PERCENTAGE) / 100;

            if (userInfo.firstClaimTimestamp == 0) {
                userInfo.firstClaimTimestamp = block.timestamp;
            }
            userInfo.secondClaimTimestamp = block.timestamp;
        } else {
            availableAmount = amount;

            if (userInfo.firstClaimTimestamp == 0) {
                userInfo.firstClaimTimestamp = block.timestamp;
            }
            if (userInfo.secondClaimTimestamp == 0) {
                userInfo.secondClaimTimestamp = block.timestamp;
            }

            userInfo.thirdClaimTimestamp = block.timestamp;
        }

        uint256 toTransfer = availableAmount - userInfo.amountClaimed;
        if (toTransfer == 0) {
            revert NothingToClaim();
        }

        userInfo.amountClaimed += toTransfer;
        if (userInfo.amountClaimed == amount) {
            userInfo.claimedAll = true;
        }

        info[user] = userInfo;

        token.safeTransfer(msg.sender, toTransfer);

        emit Claimed(user, toTransfer);
    }
}
