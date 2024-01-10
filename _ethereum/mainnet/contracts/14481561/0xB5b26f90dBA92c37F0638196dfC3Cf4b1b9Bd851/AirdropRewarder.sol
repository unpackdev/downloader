// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.13;
pragma abicoder v2;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract AirdropRewarder is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public safeAddress;

    mapping(address => bytes32) private merkleRoots;
    mapping(address => mapping(address => uint256)) private totalRewardsClaimed; // per 1) user and 2) reward token

    event MerkleRootSetForToken(bytes32 _merkleRoot, address _rewardToken);
    event SafeAddressSet(address _safeAddress);
    event RewardsClaimed(address _user, address[] _rewardsToken, uint256[] _rewardsAmout);
    event RewardTerminated(address _rewardAddress);

    function initialize(address _safeAddress) external initializer {
        __Ownable_init();
        safeAddress = _safeAddress;
        emit SafeAddressSet(_safeAddress);
    }

    function setMerkleRoot(bytes32 _merkleRoot, address _rewardToken) external onlyOwner {
        merkleRoots[_rewardToken] = _merkleRoot;
        emit MerkleRootSetForToken(_merkleRoot, _rewardToken);
    }

    function claim(
        address _user,
        address[] calldata rewardTokens,
        uint256[] calldata _totalClaimableAmounts,
        bytes32[][] calldata _merkleProofs
    ) external {
        uint256 rewardTokenLength = rewardTokens.length;
        require(
            rewardTokenLength == _merkleProofs.length && rewardTokenLength == _totalClaimableAmounts.length,
            "ERR:INVALID ARGS LENGTH"
        );
        for (uint256 i = 0; i < rewardTokenLength; i++) {
            uint256 totalClaimableAmount = _totalClaimableAmounts[i];
            address rewardAddress = rewardTokens[i];
            require(rewardAddress != address(0), "Invalid Address");
            // Verify the merkle proof.
            bytes32 node = keccak256(abi.encodePacked(_user, totalClaimableAmount));
            require(
                MerkleProofUpgradeable.verify(_merkleProofs[i], merkleRoots[rewardAddress], node),
                "ERR:WRONG MERKLE PROOF"
            );
            uint256 claimableAmount = totalClaimableAmount - totalRewardsClaimed[_user][rewardAddress];

            if (claimableAmount > 0) {
                totalRewardsClaimed[_user][rewardAddress] = totalClaimableAmount;
                IERC20Upgradeable(rewardAddress).safeTransfer(_user, claimableAmount);
            }

            emit RewardsClaimed(_user, rewardTokens, _totalClaimableAmounts);
        }
    }

    function setSafeAddress(address _safeAddress) external onlyOwner {
        safeAddress = _safeAddress;
        emit SafeAddressSet(_safeAddress);
    }

    function terminateReward(address _rewardAddress) public onlyOwner {
        require(_rewardAddress != address(0), "Invalid Address");
        require(
            IERC20Upgradeable(_rewardAddress).transfer(
                safeAddress,
                IERC20Upgradeable(_rewardAddress).balanceOf(address(this))
            ),
            "ERR:TOKEN TRANSFER FAILED"
        );
        emit RewardTerminated(_rewardAddress);
    }

    function getAmountsClaimedForUser(address _user, address[] calldata _rewardToken)
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = _rewardToken.length;
        uint256[] memory amountsClaimed = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            amountsClaimed[i] = totalRewardsClaimed[_user][_rewardToken[i]];
        }
        return amountsClaimed;
    }
}
