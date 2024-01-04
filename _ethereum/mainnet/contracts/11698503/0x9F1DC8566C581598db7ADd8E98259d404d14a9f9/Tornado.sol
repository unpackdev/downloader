// https://tornado.cash
/*
* d888888P                                           dP              a88888b.                   dP
*    88                                              88             d8'   `88                   88
*    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
*    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
*    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
*    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
* ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
*/

pragma solidity 0.5.17;

import "./MerkleTreeWithHistory.sol";
import "./Counter.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) public returns(bool);
}

interface IReward {
  function stake(bytes32 _nullifierHash) external;
  function withdraw(bytes32 _nullifierHash, address payable _recipient) external;
}

contract Tornado is MerkleTreeWithHistory, ReentrancyGuard {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _stakedCounter;

  uint256 public denomination;
  mapping(bytes32 => bool) public nullifierHashes;
  // we store all commitments just to prevent accidental deposits with the same commitment
  mapping(bytes32 => bool) public commitments;
  IVerifier public verifier;
  IReward public rewarder;
  mapping(address => mapping(bytes32 => bool)) public stakedNullifierHashes;
  mapping(bytes32 => address) public stakedNullifierHashOwner;

  // reserve pool address
  address public reserve;

  // operator can update snark verification key
  // after the final trusted setup ceremony operator rights are supposed to be transferred to zero address
  address public operator;
  modifier onlyOperator {
    require(msg.sender == operator, "Only operator can call this function.");
    _;
  }

  address public governance;
  modifier onlyGovernance {
    require(msg.sender == governance, "Only governance can call this function.");
    _;
  }

  uint public withdrawalFee = 50;
  uint constant public withdrawalMax = 10000;

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);
  event StakedWithdrawal(address indexed recipient, bytes32 nullifierHash, uint256 timestamp);
  event UnstakedWithdrawal(address indexed recipient, bytes32 nullifierHash);

  /**
    @dev The constructor
    @param _verifier the address of SNARK verifier for this contract
    @param _denomination transfer amount for each deposit
    @param _merkleTreeHeight the height of deposits' Merkle Tree
    @param _operator operator address (see operator comment above)
  */
  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _operator,
    address _governance,
    address _reserve
  ) MerkleTreeWithHistory(_merkleTreeHeight) public {
    require(_denomination > 0, "denomination should be greater than 0");
    verifier = _verifier;
    operator = _operator;
    governance = _governance;
    denomination = _denomination;
    reserve = _reserve;
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    _processDeposit();
    emit Deposit(_commitment, insertedIndex, block.timestamp);
  }

  /** @dev this function is defined in a child contract */
  function _processDeposit() internal;

  /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) external payable nonReentrant {
    uint256 _withdraw_fee = denomination.mul(withdrawalFee).div(withdrawalMax);
    require(_withdraw_fee + _fee <= denomination, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _fee, _refund]), "Invalid withdraw proof");

    nullifierHashes[_nullifierHash] = true;
    _processWithdraw(_recipient, _withdraw_fee, _relayer, _fee, _refund);
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
  }

  function stakeWithdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient) external payable nonReentrant {
    uint256 _withdraw_fee = denomination.mul(withdrawalFee).div(withdrawalMax);
    require(_withdraw_fee <= denomination, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(address(0)), 0, 0]), "Invalid withdraw proof");

    nullifierHashes[_nullifierHash] = true;
    rewarder.stake(_nullifierHash);
    stakedNullifierHashOwner[_nullifierHash] = _recipient;
    stakedNullifierHashes[_recipient][_nullifierHash] = true;
    _stakedCounter.increment();
    emit StakedWithdrawal(_recipient, _nullifierHash, block.timestamp);
  }

  function unstakeAndWithdraw(bytes32 _nullifierHash) external payable nonReentrant {
    require(stakedNullifierHashes[msg.sender][_nullifierHash]);
    uint256 _withdraw_fee = denomination.mul(withdrawalFee).div(withdrawalMax);
    require(_withdraw_fee <= denomination, "Fee exceeds transfer value");
    _processWithdraw(msg.sender, _withdraw_fee, address(0), 0, 0);
    emit Withdrawal(msg.sender, _nullifierHash, address(0), 0);
    rewarder.withdraw(_nullifierHash, msg.sender);
    stakedNullifierHashes[msg.sender][_nullifierHash] = false;
    _stakedCounter.decrement();
    emit UnstakedWithdrawal(msg.sender, _nullifierHash);
  }

  /** @dev this function is defined in a child contract */
  function _processWithdraw(address payable _recipient, uint256 _withdraw_fee, address payable _relayer, uint256 _fee, uint256 _refund) internal;

  /** @dev whether a note is already spent */
  function isSpent(bytes32 _nullifierHash) public view returns(bool) {
    return nullifierHashes[_nullifierHash];
  }

  /** @dev whether an array of notes is already spent */
  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns(bool[] memory spent) {
    spent = new bool[](_nullifierHashes.length);
    for(uint i = 0; i < _nullifierHashes.length; i++) {
      if (isSpent(_nullifierHashes[i])) {
        spent[i] = true;
      }
    }
  }

  /**
    @dev allow operator to update SNARK verification keys. This is needed to update keys after the final trusted setup ceremony is held.
    After that operator rights are supposed to be transferred to zero address
  */
  function updateVerifier(address _newVerifier) external onlyOperator {
    verifier = IVerifier(_newVerifier);
  }

  function updateRewarder(address _newRewarder) external onlyOperator {
    rewarder = IReward(_newRewarder);
  }

  /** @dev operator can change his address */
  function changeOperator(address _newOperator) external onlyOperator {
    operator = _newOperator;
  }

  /** @dev get current staked count */
  function getStakedCount() public view returns (uint256) {
    return _stakedCounter.current();
  }

  /** @dev set governance address */
  function setGovernance(address _governance) external onlyGovernance {
    governance = _governance;
  }

  /** @dev set withdraw fee */
  function setWithdrawalFee(uint _withdrawalFee) external onlyGovernance {
    withdrawalFee = _withdrawalFee;
  }

  function setReserveAddress(address _newReserve) external onlyGovernance {
    reserve = _newReserve;
  }
}
