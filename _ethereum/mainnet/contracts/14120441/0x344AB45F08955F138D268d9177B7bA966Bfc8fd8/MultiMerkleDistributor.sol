// SPDX-License-Identifier: MIT
/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     (@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(   @@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@             @@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@(            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@(         @@(         @@(            @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@          @@          @@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @           @           @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@(            @@@         @@@         @@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@(     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */
pragma solidity =0.6.11;
pragma experimental ABIEncoderV2;

import "./IVestedNil.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

// Multi Merkle Distributor; based on the Uniswap Merkle Distributor.

contract MultiMerkleDistributor is AccessControl, Pausable {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeMath for uint256;

    address public nil;
    address public vnil;
    address public treasury;
    bytes32[] public merkleRoots;
    uint256 public vnilClaimed = 0;
    uint256 public vnilAllowance = 0;
    mapping(address => mapping(uint256 => uint256)) private claimedBitMap;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(address account, uint256 lastEpoch, uint256 nilAmount, uint256 vnilAmount);
    // This event is triggered whenever a call to #claim succeeds.
    event BatchClaimed(address account, uint256[] epochs, uint256[] nilAmounts, uint256[] vnilAmounts);
    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    /// @dev The identifier of the role which allows accounts to operate distributions.
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    constructor(
        address nil_,
        address vnil_,
        address treasury_,
        address dao
    ) public {
        require(address(vnil_) != address(0), "MasterMint:ILLEGAL_VNIL_ADDRESS");
        require(address(nil_) != address(0), "MasterMint:ILLEGAL_NIL_ADDRESS");
        require(address(treasury_) != address(0), "MasterMint:ILLEGAL_TREASURY_ADDRESS");
        require(address(dao) != address(0), "MasterMint:ILLEGAL_DAO_ADDRESS");
        _setupRole(OPERATOR_ROLE, dao);
        _setupRole(ADMIN_ROLE, dao);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        nil = nil_;
        vnil = vnil_;
        treasury = treasury_;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "MultiMerkleDistributor:ACCESS_DENIED");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "MultiMerkleDistributor:ACCESS_DENIED");
        _;
    }

    function isClaimed(address account, uint256 epoch) public view returns (bool) {
        uint256 claimedWordIndex = epoch / 256;
        uint256 claimedBitIndex = epoch % 256;
        uint256 claimedWord = claimedBitMap[account][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function getCurrentEpoch() external view returns (uint256) {
        return merkleRoots.length.sub(1);
    }

    function _setClaimed(address account, uint256 epoch) private {
        uint256 claimedWordIndex = epoch / 256;
        uint256 claimedBitIndex = epoch % 256;
        claimedBitMap[account][claimedWordIndex] = claimedBitMap[account][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claimBatch(
        address account,
        uint256[] calldata epochs,
        uint256[] calldata nilAmounts,
        uint256[] calldata vnilAmounts,
        bytes32[][] calldata merkleProofs
    ) external whenNotPaused {
        uint256 currentEpoch = merkleRoots.length.sub(1);
        require(nilAmounts.length == epochs.length, "MultiMerkleDistributor:WRONG_NIL_LENGTH");
        require(vnilAmounts.length == epochs.length, "MultiMerkleDistributor:WRONG_VNIL_LENGTH");
        require(merkleProofs.length == epochs.length, "MultiMerkleDistributor:WRONG_PROOFS_LENGTH");
        uint256 vnilAmount = 0;
        uint256 nilAmount = 0;
        for (uint256 i = 0; i < epochs.length; i++) {
            uint256 epochToClaim = epochs[i];
            require(epochToClaim <= currentEpoch, "MultiMerkleDistributor:INVALID_EPOCH");
            require(!isClaimed(account, epochToClaim), "MultiMerkleDistributor:EPOCH_ALREADY_CLAIMED");
            bytes32 node = keccak256(abi.encodePacked(account, epochToClaim, nilAmounts[i], vnilAmounts[i]));
            require(
                MerkleProof.verify(merkleProofs[i], merkleRoots[epochToClaim], node),
                "MultiMerkleDistributor:INVALID_PROOF"
            );
            _setClaimed(account, epochToClaim);
            vnilAmount = vnilAmount.add(vnilAmounts[i]);
            nilAmount = nilAmount.add(nilAmounts[i]);
        }
        emit BatchClaimed(account, epochs, nilAmounts, vnilAmounts);

        _distribute(account, nilAmount, vnilAmount);
    }

    function claimSingle(
        address account,
        uint256 epochToClaim,
        uint256 nilAmount,
        uint256 vnilAmount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        uint256 currentEpoch = merkleRoots.length.sub(1);
        require(epochToClaim <= currentEpoch, "MultiMerkleDistributor:INVALID_EPOCH");
        require(!isClaimed(account, epochToClaim), "MultiMerkleDistributor:EPOCH_ALREADY_CLAIMED");
        bytes32 node = keccak256(abi.encodePacked(account, epochToClaim, nilAmount, vnilAmount));
        require(
            MerkleProof.verify(merkleProof, merkleRoots[epochToClaim], node),
            "MultiMerkleDistributor:INVALID_PROOF"
        );
        _setClaimed(account, epochToClaim);
        _distribute(account, nilAmount, vnilAmount);
        emit Claimed(account, epochToClaim, nilAmount, vnilAmount);
    }

    function _distribute(
        address account,
        uint256 nilAmount,
        uint256 vnilAmount
    ) private {
        if (nilAmount > 0) {
            IERC20(nil).safeTransferFrom(treasury, account, nilAmount);
        }
        if (vnilAmount > 0) {
            vnilClaimed = vnilClaimed.add(vnilAmount);
            require(vnilClaimed <= vnilAllowance, "MultiMerkleDistributor:VNIL_ALLOWANCE_EXCEEDED");
            IVestedNil(vnil).mint(account, vnilAmount);
        }
    }

    function emergencySetRoot(
        uint256 epoch,
        bytes32 root,
        bool pause_
    ) external onlyOperator {
        merkleRoots[epoch] = root;
        if (pause_) {
            _pause();
        }
    }

    function addRoot(bytes32 root, bool pause_) external onlyOperator {
        merkleRoots.push(root);
        if (pause_) {
            _pause();
        }
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function resetVNilAllowance(uint256 allowance) external onlyAdmin {
        vnilAllowance = allowance;
        vnilClaimed = 0;
    }

    function increaseVNilAllowance(uint256 allowanceIncrement) external onlyAdmin {
        vnilAllowance += allowanceIncrement;
    }

    function addOperator(address operator) external onlyAdmin {
        grantRole(OPERATOR_ROLE, operator);
    }

    function setTreasury(address treasury_) external onlyAdmin {
        require(address(treasury_) != address(0), "MasterMint:ILLEGAL_TREASURY_ADDRESS");
        treasury = treasury_;
    }
}
