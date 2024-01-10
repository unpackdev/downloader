// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

//import "./MerkleProof.sol"; // OZ: MerkleProof
import "./Owned.sol";
import "./TransferHelper.sol";
import "./MerkleProof.sol"; // OZ: MerkleProof

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount ) external returns (bool);
}

/// @title MerkleClaim
/// @notice Allows a held ERC20 to be claimable by members of a merkle tree
/// @author Anish Agnihotri <contact@anishagnihotri.com>
/// @author Jack Corddry https://github.com/corddry
contract MerkleClaim is Owned{

  /// ============ Immutable storage ============

  /// @notice ERC20-claimee inclusion root
  bytes32 public immutable merkleRoot;

  /// @notice Contract address of airdropped token
  IERC20 public immutable token;

  address public timelock_address;

  /// ============ Mutable storage ============

  /// @notice Mapping of addresses who have claimed tokens
  mapping(address => bool) public hasClaimed;

  /// ============ Errors ============

  /// @notice Thrown if address has already claimed
  error AlreadyClaimed();
  /// @notice Thrown if address/amount are not part of Merkle tree
  error NotInMerkle();
  /// @notice Thrown if claim contract doesn't have enough tokens to payout
  error notEnoughRewards();

  /// ============ Modifiers ============

  modifier onlyByOwnGov() {
    require(msg.sender == owner || msg.sender == timelock_address, "Not owner or timelock");
    _;
  }

  /// ============ Constructor ============

  /// @notice Creates a new MerkleClaimERC20 contract
  /// @param _erc20Address of token to be airdropped
  /// @param _merkleRoot of claimees
  constructor(
    address _erc20Address,
    bytes32 _merkleRoot,
    address _owner_address,
    address _timelock_address
  ) Owned(_owner_address)
  {
    merkleRoot = _merkleRoot;
    token = IERC20(_erc20Address);
    timelock_address = _timelock_address;
  }

  /// ============ Events ============

  /// @notice Emitted after a successful token claim
  /// @param to recipient of claim
  /// @param amount of tokens claimed
  event Claim(address indexed to, uint256 amount);

  /// @notice Emitted after a successful token recovery
  /// @param token address being recovered
  /// @param amount of tokens recoverd
  event Recovered(address token, uint256 amount);

  /// ============ Functions ============

  /// @notice Allows claiming tokens if address is part of merkle tree
  /// @param to address of claimee
  /// @param amount of tokens owed to claimee
  /// @param proof merkle proof to prove address and amount are in tree
  function claim(address to, uint256 amount, bytes32[] calldata proof) external {
    // Throw if address has already claimed tokens
    if (hasClaimed[to]) revert AlreadyClaimed();

    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    // Throw if the contract doesn't hold enough tokens for claimee
    if (amount > token.balanceOf(address(this))) revert notEnoughRewards();

    // Set address to claimed
    hasClaimed[to] = true;

    // Award tokens to address
    token.transfer(to, amount);

    // Emit claim event
    emit Claim(to, amount);
  }

    /// ============ Permissioned Functions ============
  
    function setTimelock(address _new_timelock_address) external onlyByOwnGov {
      timelock_address = _new_timelock_address;
    }
    
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        // Can only be triggered by owner or governance
        TransferHelper.safeTransfer(tokenAddress, owner, tokenAmount);
        
        emit Recovered(tokenAddress, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }
}

