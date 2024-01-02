// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./console.sol";

contract Vesting is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    using SafeERC20 for IERC20;

    struct Allocation {
        uint256 timestamp;
        uint256 amount;
    }

    struct VestingSchedule {
        uint256 id; // Unique ID for the user
        address vault; // The vault's Ethereum address, it might be changed by admin in merkle tree root
        address user; // The recipient's Ethereum address, it might be changed by admin in merkle tree root
        uint256 total; // Total tokens allocated to the user
        uint256 claimed; // Total tokens claimed so far
        uint256 lastClaim; // Last time the user claimed tokens, as UNIX timestamp
    }

    address public immutable token;
    bytes32 public root;

    mapping(uint256 => VestingSchedule) internal userVestingSchedule;

    event RootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);
    event TokenClaimed(
        uint256 indexed id,
        address indexed user,
        address indexed vault,
        uint256 claimed,
        bytes32[] proof
    );
    event UserModifiedInVestingMerkleTree(
        uint256 indexed id,
        address oldAddress,
        address newAddress
    );
    event VaultModifiedInVestingMerkleTree(
        uint256 indexed id,
        address oldAddress,
        address newAddress
    );

    constructor(
        address _token,
        address _admin,
        bytes32 _root
    ) {
        require(_token != address(0), "Token address cannot be zero address");
        require(_admin != address(0), "Admin address cannot be zero address");
        token = _token;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        grantRole(OPERATOR_ROLE, _admin);
        root = _root;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not owner"
        );
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(OPERATOR_ROLE, msg.sender), 
        "Caller is not operator");
        _;
    }

    function updateRoot(bytes32 _root) external onlyAdmin {
        bytes32 oldRoot = root;

        root = _root;

        emit RootUpdated(oldRoot, root);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function claimToken(
        uint256 _id,
        address _vault,
        Allocation[] memory _allocations,
        bytes32[] memory _proof
    ) external nonReentrant whenNotPaused {
        VestingSchedule storage user = userVestingSchedule[_id];

        require(
            _verifyVestingUser(_id, msg.sender, _vault, _allocations, _proof),
            "Invalid merkle proof"
        );

        uint256 total = 0;
        for (uint256 i = 0; i < _allocations.length; i++) {
            total += _allocations[i].amount;
        }

        if (user.total == 0) {
            user.id = _id;
            user.user = msg.sender;
            user.vault = _vault;
            user.total = total;
            // Commit user changes to storage during first claim to save gas.
            userVestingSchedule[_id] = user;
        } else {
            if (user.total != total) {
                user.total = total;
            }
        }

        require(
            user.claimed < _getTotalAmount(_allocations, block.timestamp),
            "All tokens have already been claimed for this allocation"
        );

        /**
        @dev This conditional assignment block ensures that a user's 
        address is correctly updated in case of modifications by the admin.
        The _verifyVestingUser function is supposed to be called prior to this,
        which will perform necessary validations.
        If a user's address in the Merkle tree is modified by the admin, the user will still retain the same id.
        This block will handle that case.
        This condition checks if the user's address stored and the address of the message sender are not the same.
        If so, it updates the user's address in the contract to the new address (message sender).
        This mechanism is designed to ensure that the user's new address is accurately represented in the UI.
        */
        if (user.user != msg.sender) {
            // If user address was updated in merkle tree it will be updated in userVestingSchedule in last line of this function
            address currentUserAddress = user.user;
            user.user = msg.sender;
            emit UserModifiedInVestingMerkleTree(
                _id,
                currentUserAddress,
                msg.sender
            );
        }

        if (user.vault != _vault) {
            // If vault address was updated in merkle tree it will be updated in userVestingSchedule in last line of this function
            address currentVaultAddress = user.vault;
            user.vault = _vault;
            emit VaultModifiedInVestingMerkleTree(
                _id,
                currentVaultAddress,
                _vault
            );
        }

        uint256 amountVested = claimableToken(_id, _allocations);

        user.claimed = user.claimed + amountVested;
        user.lastClaim = block.timestamp;
        userVestingSchedule[_id] = user;
        IERC20(token).safeTransferFrom(user.vault, msg.sender, amountVested);
        emit TokenClaimed(_id, msg.sender, user.vault, amountVested, _proof);
    }

    function claimableToken(
        uint256 _id,
        Allocation[] memory _allocations
    ) internal view returns (uint256) {
        VestingSchedule memory user = userVestingSchedule[_id];
        uint256 totalAmount = _getTotalAmount(_allocations, block.timestamp);
        return totalAmount - user.claimed;
    }

    function getClaimedAmountByUser(uint256 _id) public view returns (uint256) {
        return userVestingSchedule[_id].claimed;
    }

    function getLastClaimByUser(uint256 _id) public view returns (uint256) {
        return userVestingSchedule[_id].lastClaim;
    }

    function _getTotalAmount(
        Allocation[] memory allocations,
        uint256 timestamp
    ) internal pure returns (uint256 total) {
        for (uint256 i = 0; i < allocations.length; i++) {
            if (allocations[i].timestamp < timestamp) {
                total += allocations[i].amount;
            }
        }
    }

    function _verifyVestingUser(
        uint256 _id,
        address _user,
        address _vault,
        Allocation[] memory _allocations,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(abi.encode(_id, _user, _vault, _allocations))
            )
        );

        return MerkleProof.verify(_proof, root, leaf);
    }
}
