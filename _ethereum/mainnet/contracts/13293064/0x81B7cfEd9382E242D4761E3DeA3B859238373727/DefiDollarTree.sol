// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Initializable.sol";

contract DefiDollarTree is Initializable, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ROOT_PROPOSER_ROLE = keccak256("ROOT_PROPOSER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public merkleRoot;
    mapping(address => mapping(address => uint256)) public claimed;

    event RootUpdated(
        bytes32 indexed root,
        uint256 blockNumber
    );
    event Claimed(address indexed user, address indexed token, uint256 amount, uint256 blockNumber);

    modifier onlyRootProposer() {
        require(hasRole(ROOT_PROPOSER_ROLE, msg.sender), "onlyRootProposer");
        _;
    }

    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, msg.sender), "onlyPauser");
        _;
    }

    function initialize(address governance) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, governance); // The admin can edit all role permissions
        _setupRole(PAUSER_ROLE, msg.sender); // deployer
        _setupRole(ROOT_PROPOSER_ROLE, msg.sender); // deployer
    }

    /// @notice Claim specifiedrewards for a set of tokens at a given cycle number
    /// @notice Can choose to skip certain tokens by setting amount to claim to zero for that token index
    function claim(
        address[] calldata tokens,
        uint256[] calldata cumulativeAmounts,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        _verifyClaimProof(tokens, cumulativeAmounts, merkleProof);

        bool claimedAny = false; // User must claim at least 1 token by the end of the function

        // Claim each token
        for (uint256 i = 0; i < tokens.length; i++) {
            // Run claim and register claimedAny if a claim occurs
            if (_tryClaim(msg.sender, tokens[i], cumulativeAmounts[i])) {
                claimedAny = true;
            }
        }

        // If no tokens were claimed, revert
        if (claimedAny == false) {
            revert("No tokens to claim");
        }
    }

    /// @dev Get the number of tokens claimable for an account, given a list of tokens and latest cumulativeAmounts data
    function getClaimed(
        address user,
        address[] memory tokens
    ) public view returns (uint256[] memory userClaimed) {
        userClaimed = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            userClaimed[i] = _getClaimed(user, tokens[i]);
        }
    }

    /// ===== Internal Helper Functions =====

    function _verifyClaimProof(
        address[] calldata tokens,
        uint256[] calldata cumulativeAmounts,
        bytes32[] calldata merkleProof
    ) internal view {
        bytes32 node = keccak256(abi.encode(msg.sender, tokens, cumulativeAmounts));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");
    }

    function _tryClaim(
        address account,
        address token,
        uint256 cumulativeClaimable
    ) internal returns (bool claimAttempted) {
        // If none claimable for token or none specifed to claim, skip this token
        if (cumulativeClaimable == 0) {
            return false;
        }

        uint256 claimedBefore = _getClaimed(account, token);
        uint256 toClaim = cumulativeClaimable - claimedBefore;

        // If none claimable, don't attempt to claim
        if (toClaim == 0) {
            return false;
        }

        _setClaimed(account, token, cumulativeClaimable);

        IERC20(token).safeTransfer(account, toClaim);

        emit Claimed(account, token, toClaim, block.number);
        return true;
    }

    function _setClaimed(
        address account,
        address token,
        uint256 amount
    ) internal {
        claimed[account][token] = amount;
    }

    function _getClaimed(address account, address token) internal view returns (uint256) {
        return claimed[account][token];
    }

     /// ===== Admin Functions =====

    function setRoot(bytes32 root) external whenNotPaused onlyRootProposer {
        merkleRoot = root;
        emit RootUpdated(root, block.number);
    }

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }
}
