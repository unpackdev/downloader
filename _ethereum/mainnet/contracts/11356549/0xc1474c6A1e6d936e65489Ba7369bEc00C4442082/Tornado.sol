// https://anon.credit
// https://anoncredit.eth.link
/*
* d888888P                                           dP              a88888b.                   dP
*    88                                              88             d8'   `88                   88
*    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
*    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
*    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
*    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
* ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
*
*
* "Full anonymity is not plausible."
* 
*/

pragma solidity 0.5.17;

import "./MerkleTreeWithHistory.sol";
import "./IERC20.sol";
import "./ERC20_Mintable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) public returns(bool);
}

contract Tornado is MerkleTreeWithHistory, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public denomination; // 100 ETH
  mapping(bytes32 => bool) public nullifierHashes;
  // we store all commitments just to prevent accidental deposits with the same commitment
  mapping(bytes32 => bool) public commitments;
  IVerifier public verifier;

  uint256 public _1e18 = 1000000000000000000;
  uint256 public startTime; // epoch time at contract deployment
  uint256 public growthPhaseEndTime; // epoch time of end of growth phase (00:00 PST, July 4th, 2021)
  uint256 public bonusRoundLength; // length of a period in seconds

  uint256 public totalDeposits; // total number of deposits
  uint256 public totalWithdrawals; // total number of withdrawals
  
  mapping(uint256 => BonusPool) public bonusPoolByRound;

  struct BonusPool {
    address creditToken; // credit token address for this round
    uint256 bonusCollected; // total accumulated bonus ETH
    uint256 bonusWithdrawn; // total ETH withdrawn from bonus pool
    uint256 bonusRolledOver; // total ETH rolled over from the previous round
  }
  
  uint256 public baseBonusRate; // % of deposit set aside for bonus pool (unit = bps)
  uint256 public growthBonusRate; // extra % of deposit set aside for growth phase bonus pool (unit = bps)
  ERC20_Mintable public bonusToken; // ANON token generated on every deposit
  address public stakingToken; // ETH/ANON token used to stake and earn bonus rewards

  mapping(address => Staker) public stakers;

  struct Staker {
    uint256 unlockRound;
    uint256 stakingTokenBalance;
  }

  modifier stakingActivated {
    require(stakingToken != address(0), "staking has not been activated");
    _;
  }
 
  uint256 public operatorBonusTokenShare; // the operator's share of bonus tokens issued (10%) (unit = bps)

  // operator can update snark verification key
  // after the final trusted setup ceremony operator rights are supposed to be transferred to zero address
  address public operator;
  modifier onlyOperator {
    require(msg.sender == operator, "Only operator can call this function.");
    _;
  }

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);
  event Stake(address indexed staker, uint256 amountToStake, uint256 creditsMinted);
  event AddToStake(address indexed staker, uint256 amountToStake, uint256 totalStake, uint256 creditsMinted);
  event Unstake(address indexed staker, uint256 amountUnstaked);
  event CollectBonus(address indexed staker, uint256 creditsToRedeem, uint256 bonusCollected);

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
    uint256 _baseBonusRate,
    uint256 _growthBonusRate,
    uint256 _growthPhaseEndTime,
    uint256 _bonusRoundLength,
    uint256 _operatorBonusTokenShare
  ) MerkleTreeWithHistory(_merkleTreeHeight) public {
    require(_denomination > 0, "denomination should be greater than 0");
    startTime = now;
    verifier = _verifier;
    operator = _operator;
    denomination = _denomination;
    baseBonusRate = _baseBonusRate;
    growthBonusRate = _growthBonusRate;
    growthPhaseEndTime = _growthPhaseEndTime;
    bonusRoundLength = _bonusRoundLength;
    operatorBonusTokenShare = _operatorBonusTokenShare;
    bonusToken = new ERC20_Mintable("anon", 18, "ANON");
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(address(bonusToken) != address(0), "token not deployed");
    require(!commitments[_commitment], "The commitment has been submitted");

    uint256 bonusRound = getCurrentBonusRound();

    uint256 depositReserve = _calcDepositReserve();
    uint256 bonusRate = baseBonusRate;

    if (bonusRound == 0) { // growth phase
      bonusRate = bonusRate.add(growthBonusRate);
    }

    uint256 depositBonus = denomination.add(depositReserve).mul(bonusRate).div(10000);
    uint256 depositAmount = denomination.add(depositReserve).add(depositBonus);
      
    require(msg.value >= depositAmount,"deposit amount is insufficient");

    BonusPool storage bonusPool = bonusPoolByRound[bonusRound];
    bonusPool.bonusCollected = bonusPool.bonusCollected.add(depositBonus);
    totalDeposits = totalDeposits.add(1);

    if (bonusRound == 0) { // growth phase
      bonusToken.mint(msg.sender, _1e18);
      bonusToken.mint(operator, _1e18.mul(operatorBonusTokenShare).div(10000));
    }

    uint256 refund = msg.value.sub(depositAmount);
    msg.sender.transfer(refund);

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;

    emit Deposit(_commitment, insertedIndex, block.timestamp);
  }

  function _calcDepositReserve() internal view returns (uint256) {
    uint256 anonSet = totalDeposits.sub(totalWithdrawals);
    return _calcReserveBondingCurve(anonSet);
  }

  function _calcWithdrawalReserve() internal view returns (uint256) {
    if (totalDeposits == totalWithdrawals) {
      return 0;
    }
    uint256 anonSet = totalDeposits.sub(totalWithdrawals).sub(1); // 1 less to match the deposit bonus
    return _calcReserveBondingCurve(anonSet);
  }

  function _calcReserveBondingCurve(uint256 anonSet) internal view returns (uint256) {
    if (anonSet <= 100) {
      // 0 -> 0%; 100 -> 3% (0.03 / anon)
      return denomination.mul(anonSet).mul(300).div(10000).div(100);
    } else if (anonSet > 100 && anonSet <= 1000) {
      // 100 -> 3%; 1,000 -> 12% (0.01 / anon)
      return (denomination.mul(2).add(denomination.mul(anonSet).mul(100).div(10000))).div(100);
    } else if (anonSet > 1000 && anonSet <= 10000) {
      // 1,000 -> 12%; 10,000 -> 39% (0.003 / anon)
      return (denomination.mul(9).add(denomination.mul(anonSet).mul(30).div(10000))).div(100);
    } else {
      // 10,000+ -> 39%
      return denomination.mul(39).div(100);
    }
  }

  /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _relayerFee, uint256 _refund) external payable nonReentrant {
    require(address(bonusToken) != address(0), "token not deployed");
    uint256 withdrawAmount = denomination.add(_calcWithdrawalReserve());
    require(_relayerFee <= withdrawAmount, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _relayerFee, _refund]), "Invalid withdraw proof");

    nullifierHashes[_nullifierHash] = true;
    
    // sanity checks
    require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
    require(_refund == 0, "Refund value is supposed to be zero for ETH instance");

    totalWithdrawals = totalWithdrawals.add(1);

    (bool success, ) = _recipient.call.value(withdrawAmount.sub(_relayerFee))("");
    require(success, "payment to _recipient did not go thru");

    if (_relayerFee > 0) {
      (success, ) = _relayer.call.value(_relayerFee)("");
      require(success, "payment to _relayer did not go thru");
    }
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _relayerFee);
  }

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

  // open a fresh stake
  function stake(uint256 amount) stakingActivated external {
    require(address(bonusToken) != address(0), "token not deployed");
    Staker storage staker = stakers[msg.sender];
    require(staker.stakingTokenBalance == 0, "user is already staked");
    require(IERC20(stakingToken).transferFrom(msg.sender, address(this), amount), "staking token transfer failed");

    uint256 bonusRound = getCurrentBonusRound();
    staker.unlockRound = bonusRound.add(1);

    BonusPool storage bonusPool = bonusPoolByRound[bonusRound];
    if (bonusPool.creditToken == address(0)) { // first stake in new round
      bonusPool.creditToken = address(new ERC20_Mintable("credit" , 18, "CREDIT"));
    }

    staker.stakingTokenBalance = staker.stakingTokenBalance.add(amount);
    uint256 timeRemaining = getBonusRoundEndingTime(bonusRound).sub(now);
    uint256 creditsToMint = amount.mul(timeRemaining).mul(timeRemaining);
    ERC20_Mintable(bonusPool.creditToken).mint(msg.sender, creditsToMint);
    emit Stake(msg.sender, amount, creditsToMint);
  }

  // add to an existing stake
  function addToStake(uint256 amount) external {
    require(address(bonusToken) != address(0), "token not deployed");
    Staker storage staker = stakers[msg.sender];
    require(staker.stakingTokenBalance > 0, "staker has no balance");
    require(IERC20(stakingToken).transferFrom(msg.sender, address(this), amount), "staking token transfer failed");

    uint256 bonusRound = getCurrentBonusRound();
    require(staker.unlockRound == bonusRound.add(1), "staker is not active in current round");

    BonusPool memory bonusPool = bonusPoolByRound[bonusRound];
    
    staker.stakingTokenBalance = staker.stakingTokenBalance.add(amount);
    uint256 timeRemaining = getBonusRoundEndingTime(bonusRound).sub(now);
    uint256 creditsToMint = amount.mul(timeRemaining).mul(timeRemaining);
    ERC20_Mintable(bonusPool.creditToken).mint(msg.sender, creditsToMint);
    emit AddToStake(msg.sender, amount, staker.stakingTokenBalance, creditsToMint);
  }

  // withdraw a stake
  function unstake() external {
    require(address(bonusToken) != address(0), "token not deployed");
    Staker storage staker = stakers[msg.sender];
    uint256 bonusRound = getCurrentBonusRound();

    uint256 tokensToUnstake = staker.stakingTokenBalance;
    staker.stakingTokenBalance = 0;

    require(staker.unlockRound <= bonusRound, "staker is locked in to the current round");
    require(IERC20(stakingToken).transfer(msg.sender, tokensToUnstake), "staking token transfer failed");
    emit Unstake(msg.sender, tokensToUnstake);
  }

  function stakerCollectBonus(uint256 creditsToRedeem) external {
    require(address(bonusToken) != address(0), "token not deployed");
    uint256 bonusRound = getCurrentBonusRound();
    require(bonusRound > 0, "no bonus rewards yet");

    BonusPool storage bonusPool = bonusPoolByRound[bonusRound.sub(1)];
    ERC20_Mintable credit = ERC20_Mintable(bonusPool.creditToken);

    require(credit.transferFrom(msg.sender, address(this), creditsToRedeem), "credit token transfer failed");

    if (bonusPool.bonusWithdrawn == 0 && bonusRound > 1) { // first staker to withdraw bonus
      // rollover any remaining balance from the previous bonus pool
      uint256 remainingBonusFromLastRound = getBonusRoundBalance(bonusRound.sub(2));
      bonusPool.bonusCollected = bonusPool.bonusCollected.add(remainingBonusFromLastRound);
      bonusPool.bonusRolledOver = remainingBonusFromLastRound;
      bonusPoolByRound[bonusRound.sub(2)].bonusWithdrawn = bonusPoolByRound[bonusRound.sub(2)].bonusCollected;
    }

    uint256 stakerBonus = bonusPool.bonusCollected.mul(creditsToRedeem).div(credit.totalSupply());
    bonusPool.bonusWithdrawn = bonusPool.bonusWithdrawn.add(stakerBonus);
    msg.sender.transfer(stakerBonus);
    emit CollectBonus(msg.sender, creditsToRedeem, stakerBonus);
  }

  function setStakingToken(address _stakingToken) external onlyOperator {
    require(stakingToken == address(0), "staking token already set");
    require(_stakingToken != address(0), "must provide staking token address");
    stakingToken = _stakingToken;
  }

  /** @dev operator can change his address */
  function changeOperator(address _newOperator) external onlyOperator {
    operator = _newOperator;
  }

  function getCurrentBonusRound() public view returns (uint256) {
    if (now < growthPhaseEndTime) {
      return 0;
    } else {
      return (now.sub(growthPhaseEndTime)).div(bonusRoundLength).add(1);
    }
  }

  function getBonusRoundEndingTime(uint256 bonusRound) public view returns (uint256) {
    if (bonusRound == 0) {
      return growthPhaseEndTime;
    } else {
      return growthPhaseEndTime.add((bonusRound).mul(bonusRoundLength));
    }
  }

  function getDepositAmount() public view returns (uint256) {
    uint256 bonusRound = getCurrentBonusRound();
    uint256 depositReserve = _calcDepositReserve();
    uint256 bonusRate = baseBonusRate;

    if (bonusRound == 0) { // growth phase
      bonusRate = bonusRate.add(growthBonusRate);
    }

    uint256 depositBonus = (denomination.add(depositReserve)).mul(bonusRate).div(10000);
    uint256 depositAmount = denomination.add(depositReserve).add(depositBonus);
    return depositAmount;
  }

  function getWithdrawalAmount() public view returns (uint256) {
    uint256 withdrawalReserve = _calcWithdrawalReserve();
    uint256 withdrawalAmount = denomination.add(withdrawalReserve);
    return withdrawalAmount;

  }

  function getReservePool() public view returns (uint256) {
    uint256 bonusRound = getCurrentBonusRound();
    uint256 totalBonusRoundBalance = getBonusRoundBalance(bonusRound);

    if (bonusRound > 0) {
      totalBonusRoundBalance = totalBonusRoundBalance.add(getBonusRoundBalance(bonusRound.sub(1)));
    }

    if (bonusRound > 1) { 
      totalBonusRoundBalance = totalBonusRoundBalance.add(getBonusRoundBalance(bonusRound.sub(2)));
    }

    return address(this).balance.sub(denomination.mul(totalDeposits.sub(totalWithdrawals))).sub(totalBonusRoundBalance);
  }

  function getBonusRoundBalance(uint256 bonusRound) public view returns (uint256) {
    BonusPool memory bonusPool = bonusPoolByRound[bonusRound];
    return bonusPool.bonusCollected.sub(bonusPool.bonusWithdrawn);
  }

  function getStakerCreditsByRound(address staker, uint256 bonusRound) public view returns (uint256) {
    BonusPool memory bonusPool = bonusPoolByRound[bonusRound];
    if (bonusPool.creditToken == address(0)) {
     return 0;
    }
    return ERC20_Mintable(bonusPool.creditToken).balanceOf(staker);
  }

  function getTotalCreditsByRound(uint256 bonusRound) public view returns (uint256) {
    BonusPool memory bonusPool = bonusPoolByRound[bonusRound];
    if (bonusPool.creditToken == address(0)) {
     return 0;
    }
    return ERC20_Mintable(bonusPool.creditToken).totalSupply();
  }

  function getDepositReserve() public view returns (uint256) {
    return _calcDepositReserve();
  }

  function getWithdrawalReserve() public view returns (uint256) {
    return _calcWithdrawalReserve();
  }

  function getReserveBondingCurve(uint256 anonSet) public view returns (uint256) {
    return _calcReserveBondingCurve(anonSet);
  }
}
