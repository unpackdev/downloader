// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IRewardsAirdropWithLock.sol";

/**
 * @title Ruler RewardsAirdropWithLock contract
 * @author crypto-pumpkin
 * This contract handles multiple rounds of airdrops. It also can (does not have to) enforce a lock up window for claiming. Meaning if the user claimed before the lock up ends, it will charge a penalty.
 */
contract RewardsAirdropWithLock is IRewardsAirdropWithLock, Ownable {
  using SafeERC20 for IERC20;

  address public override penaltyReceiver;
  uint256 public constant override claimWindow = 120 days;
  uint256 public constant BASE = 1e18;

  AirdropRound[] private airdropRounds;
  // roundsIndex => merkleIndex => mask
  mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMaps;

  modifier onlyNotDisabled(uint256 _roundInd) {
    require(!airdropRounds[_roundInd].disabled, "RWL: Round disabled");
    _;
  }

  constructor(address _penaltyReceiver) {
    penaltyReceiver = _penaltyReceiver;
  }

  function updatePaneltyReceiver(address _new) external override onlyOwner {
    require(_new != address(0), "RWL: penaltyReceiver is 0");
    emit UpdatedPenaltyReceiver(penaltyReceiver, _new);
    penaltyReceiver = _new;
  }

  /**
   * @notice add an airdrop round
   * @param _token, the token to drop
   * @param _merkleRoot, the merkleRoot of the airdrop round
   * @param _lockWindow, the amount of time in secs that the rewards are locked, if claim before lock ends, a lockRate panelty is charged. 0 means no lock up period and _lockRate is ignored.
   * @param _lockRate, the lockRate to charge if claim before lock ends, 40% lock rate means u only get 60% of the amount if claimed before 1 month (the lock window)
   * @param _total, the total amount to be dropped
   */
  function addAirdrop(
    address _token,
    bytes32 _merkleRoot,
    uint256 _lockWindow,
    uint256 _lockRate,
    uint256 _total
  ) external override onlyOwner returns (uint256) {
    require(_token != address(0), "RWL: token is 0");
    require(_total > 0, "RWL: total is 0");
    require(_merkleRoot.length > 0, "RWL: empty merkle");

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _total);
    airdropRounds.push(AirdropRound(
      _token,
      _merkleRoot,
      false,
      block.timestamp,
      _lockWindow,
      _lockRate,
      _total,
      0
    ));
    uint256 index = airdropRounds.length - 1;
    emit AddedAirdrop(index, _token, _total);
    return index;
  }

  function updateRoundStatus(uint256 _roundInd, bool _disabled) external override onlyOwner {
    emit UpdatedRoundStatus(_roundInd, airdropRounds[_roundInd].disabled, _disabled);
    airdropRounds[_roundInd].disabled = _disabled;
  }

  function claim(
    uint256 _roundInd,
    uint256 _merkleInd,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override onlyNotDisabled(_roundInd) {
    require(!isClaimed(_roundInd, _merkleInd), "RWL: Already claimed");
    AirdropRound memory airdropRound = airdropRounds[_roundInd];
    require(block.timestamp <= airdropRound.startTime + claimWindow, "RWL: Too late");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(_merkleInd, account, amount));
    require(MerkleProof.verify(merkleProof, airdropRound.merkleRoot, node), "RWL: Invalid proof");

    // Mark it claimed and send the token.
    airdropRounds[_roundInd].totalClaimed = airdropRound.totalClaimed + amount;
    _setClaimed(_roundInd, _merkleInd);

    // calculate penalty if any
    uint256 claimableAmount = amount;
    if (block.timestamp < airdropRound.startTime + airdropRound.lockWindow) {
      uint256 penalty = airdropRound.lockRate * amount / BASE;
      IERC20(airdropRound.token).safeTransfer(penaltyReceiver, penalty);
      claimableAmount -= penalty;
    }

    IERC20(airdropRound.token).safeTransfer(account, claimableAmount);
    emit Claimed(_roundInd, _merkleInd, account, claimableAmount, amount);
  }

  // collect any token send by mistake, collect target after 120 days
  function collectDust(uint256[] calldata _roundInds) external onlyOwner {
    for (uint256 i = 0; i < _roundInds.length; i ++) {
      AirdropRound memory airdropRound = airdropRounds[_roundInds[i]];
      require(block.timestamp > airdropRound.startTime + claimWindow || airdropRound.disabled, "RWL: Not ready");
      airdropRounds[_roundInds[i]].disabled = true;
      uint256 toCollect = airdropRound.total - airdropRound.totalClaimed;
      IERC20(airdropRound.token).safeTransfer(owner(), toCollect);
    }
  }

  function isClaimed(uint256 _roundInd, uint256 _merkleInd) public view override returns (bool) {
    uint256 claimedWordIndex = _merkleInd / 256;
    uint256 claimedBitIndex = _merkleInd % 256;
    uint256 claimedWord = claimedBitMaps[_roundInd][claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function getAllAirdropRounds() external view override returns (AirdropRound[] memory) {
    return airdropRounds;
  }

  function getAirdropRoundsLength() external view override returns (uint256) {
    return airdropRounds.length;
  }

  function getAirdropRounds(uint256 _startInd, uint256 _endInd) external view override returns (AirdropRound[] memory) {
    AirdropRound[] memory roundsResults = new AirdropRound[](_endInd - _startInd);
    AirdropRound[] memory roundsCopy = airdropRounds;
    uint256 resultInd;
    for (uint256 i = _startInd; i < _endInd; i++) {
      roundsResults[resultInd] = roundsCopy[i];
      resultInd++;
    }
    return roundsResults;
  }

  function _setClaimed(uint256 _roundInd, uint256 _merkleInd) private {
    uint256 claimedWordIndex = _merkleInd / 256;
    uint256 claimedBitIndex = _merkleInd % 256;
    claimedBitMaps[_roundInd][claimedWordIndex] = claimedBitMaps[_roundInd][claimedWordIndex] | (1 << claimedBitIndex);
  }
}