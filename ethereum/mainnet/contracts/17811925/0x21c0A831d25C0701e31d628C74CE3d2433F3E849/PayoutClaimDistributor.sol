// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.8.0;

import "./MerkleProof.sol";
import "./IERC20.sol";
import "./Ownable.sol";

/// @title PayoutClaimDistributor
/// @notice Through this contract, users could claim ERC20 token s/he is eligible to claim the rewards.
///      - The owner/deployer of the contract could set merkle root, distributor address or lock/unlock the distribution.
///      - Owner sets the ERC20 Token address (`token`) when deploying the contract, the owner also
///        sets distributor address (`distAddress`) through `setDistributorAddress` function from which to distribute the tokens.
///      - Owner should also approve the amount of ERC20 tokens allowed to distribute through this contract.
///      - For owner to set new merkle root through `setMerkleRoot` function, contract distribution should be locked though
///         `setLocked`.
///      - To enable distribution again, it should be unlocked with `setLocked` function.
///      - Users could claim the ERC20 token payout when the distributor is unlocked.

contract PayoutClaimDistributor is Ownable {
    using MerkleProof for bytes32[];

    event SetMerkleRoot(bytes32 indexed merkleRoot);
    event ClaimedPayout(address indexed account, uint256 amount, uint256 batch);
    event DistributionLocked(bool isLocked);
    event SetDistributorAddress(address indexed ownerAddress, address indexed distAddress);

    bytes32 public merkleRoot;
    IERC20 public token;
    address public distAddress;
    bool public isLocked;

    /*
     * Mapping for hash for (address, amount, batch) for claimed status
     */
    mapping(bytes32 => bool) public claimed;

    /// @dev Constructor for setting ERC token address on deployment
    /// @param token_ Address for token to distribute
    /// @dev `distAddress` deployer address will be distributor address by default
    constructor(IERC20 token_) Ownable(msg.sender) {
        token = token_;
        distAddress = msg.sender;
    }

    /// @notice Merkle Root for current period to use for payout.
    ///    - distributor contract should be locked before setting new merkle root
    /// @dev Owner sets merkle hash generated based on the payout set
    /// @dev Reverts if the distribution contract is not locked while setting new merkle root
    /// @dev Emits SetMerkleRoot event.
    /// @param merkleRoot_ bytes32 string of merkle root to set for specific period
    function setMerkleRoot(bytes32 merkleRoot_) public {
        _requireOwnership(_msgSender());
        require(isLocked, "Payout not locked");

        merkleRoot = merkleRoot_;
        emit SetMerkleRoot(merkleRoot_);
    }

    /// @notice Set locked/unlocked status  for PayoutClaim Distributor
    /// @dev Owner lock/unlock each time new merkle root is being generated
    /// @dev Emits DistributionLocked event.
    /// @param isLocked_ = true/false status
    function setLocked(bool isLocked_) public {
        _requireOwnership(_msgSender());
        isLocked = isLocked_;
        emit DistributionLocked(isLocked_);
    }

    /// @notice Distributor address in PayoutClaim Distributor
    /// @dev Wallet that holds token for distribution
    /// @dev Emits SetDistributorAddress event.
    /// @param distributorAddress Distributor address used for distribution of `token` token
    function setDistributorAddress(address distributorAddress) public {
        address msgSender = _msgSender();
        _requireOwnership(msgSender);

        distAddress = distributorAddress;
        emit SetDistributorAddress(msgSender, distributorAddress);
    }

    /// @notice Payout method that user calls to claim
    /// @dev Method user calls for claiming the payout for user
    /// @dev Emits ClaimedPayout event.
    /// @param account Address of the user to claim the payout
    /// @param amount Claimable amount of address
    /// @param batch Unique value for each new merkle root generating
    /// @param merkleProof Merkle proof of the user based on the merkle root
    function claimPayout(address account, uint256 amount, uint256 batch, bytes32[] calldata merkleProof) external {
        require(!isLocked, "Payout locked");

        bytes32 leafHash = keccak256(abi.encodePacked(account, amount, batch));

        require(!claimed[leafHash], "Payout already claimed");
        require(merkleProof.verify(merkleRoot, leafHash), "Invalid proof");

        claimed[leafHash] = true;

        IERC20(token).transferFrom(distAddress, account, amount);

        emit ClaimedPayout(account, amount, batch);
    }
}
