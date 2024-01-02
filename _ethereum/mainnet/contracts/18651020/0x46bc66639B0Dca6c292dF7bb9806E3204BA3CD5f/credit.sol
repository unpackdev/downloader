// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "./ReentrancyGuard.sol";
import "./Ownable2Step.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./AsterfiStaking.sol";

contract CreditToken is Ownable2Step, ReentrancyGuard {
  using Address for address;
  AsterFiStaking private stakingContract;

  address private constant ASTERFI_STAKING_CONTRACT =
    0xa737CeC05f054e4f82d585e82fBbF9d3286CB5CC;

  address public sipherToken = 0xE985A820e4862a0C1f8c10D23433509FB9465f6E;

  uint256 public constant REWARD_AMOUNT = 10_000_000;
  uint256 public constant REWARD_AMOUNT_PER_PERIOD = 2_500_000;
  uint256 public minimumSwapAmount = 100;
  uint256 public howMuchCreditEqualOneToken = 100;
  uint8 public constant TOTAL_REWARD_STEPS = 4;

  string private constant NAME = 'Credit Token';
  string private constant SYMBOL = 'CREDIT';
  uint64 private constant STAKING_PERIOD = 1 minutes;
  uint64 private constant REWARD_INTERVAL = 3 minutes;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  struct Reward {
    uint256 tokenId;
    uint8 remainingSteps;
    uint256 nextRewardAvailableAt;
    uint256 lastRewardClaimedAt;
    uint256 stakeAt;
  }

  mapping(address => mapping(uint256 => Reward)) public addressRewards;

  modifier validAmount(uint256 amount) {
    require(amount > 0, 'CREDIT: amount must be greater than 0');
    _;
  }

  constructor() {
    stakingContract = AsterFiStaking(ASTERFI_STAKING_CONTRACT);
  }

  function setHowMuchCreditEqualOneToken(
    uint256 _newHowMuchCreditEqualOneToken
  ) external onlyOwner {
    howMuchCreditEqualOneToken = _newHowMuchCreditEqualOneToken;
  }

  function setMinimumSwapAmount(
    uint256 _newMinimumSwapAmount
  ) external onlyOwner {
    minimumSwapAmount = _newMinimumSwapAmount;
  }

  function setSipherToken(address _sipherToken) external onlyOwner {
    require(
      _sipherToken.isContract(),
      'CREDIT: sipher token is not contract address'
    );
    sipherToken = _sipherToken;
  }

  function name() external pure returns (string memory) {
    return NAME;
  }

  function symbol() external pure returns (string memory) {
    return SYMBOL;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function getStakedTokensDetails(
    address _address
  ) public view returns (AsterFiStaking.Stake[] memory) {
    uint256[] memory stakedTokenIds = stakingContract.getStakedNFTs(_address);
    AsterFiStaking.Stake[] memory stakedTokens = new AsterFiStaking.Stake[](
      stakedTokenIds.length
    );

    for (uint256 i = 0; i < stakedTokenIds.length; ) {
      stakedTokens[i] = stakingContract.getStakeInfo(
        _address,
        stakedTokenIds[i]
      );
      unchecked {
        i++;
      }
    }

    return stakedTokens;
  }

  function getActiveStakedTokensReadyToCheckClaimReward(
    address _address
  ) external view returns (AsterFiStaking.Stake[] memory) {
    AsterFiStaking.Stake[] memory allStakedTokens = getStakedTokensDetails(
      _address
    );
    uint256 activeTokenCount = 0;
    AsterFiStaking.Stake[]
      memory activeStakedTokens = new AsterFiStaking.Stake[](
        allStakedTokens.length
      );

    for (uint256 i = 0; i < allStakedTokens.length; ) {
      AsterFiStaking.Stake memory stake = allStakedTokens[i];
      if (isStakedTokenReadyToClaimReward(_address, stake.tokenId)) {
        activeStakedTokens[activeTokenCount++] = stake;
      }
      unchecked {
        i++;
      }
    }

    AsterFiStaking.Stake[] memory result = new AsterFiStaking.Stake[](
      activeTokenCount
    );
    for (uint256 i = 0; i < activeTokenCount; ) {
      result[i] = activeStakedTokens[i];
      unchecked {
        i++;
      }
    }

    return result;
  }

  function claimReward(uint256 _tokenId) external nonReentrant {
    AsterFiStaking.Stake memory stakeInfo = stakingContract.getStakeInfo(
      msg.sender,
      _tokenId
    );
    require(
      stakeInfo.owner == msg.sender,
      'CREDIT: you are not the owner of this stake'
    );
    require(
      isStakedTokenReadyToClaimReward(msg.sender, _tokenId),
      'CREDIT: token is not ready to claim a reward'
    );

    _claimReward(
      msg.sender,
      _tokenId,
      REWARD_AMOUNT_PER_PERIOD,
      stakeInfo.stakedAt
    );

    emit ClaimReward(
      msg.sender,
      _tokenId,
      REWARD_AMOUNT_PER_PERIOD,
      block.timestamp,
      block.timestamp + REWARD_INTERVAL,
      stakeInfo.stakedAt
    );
  }

  function _claimReward(
    address _address,
    uint256 _tokenId,
    uint256 _rewardAmount,
    uint256 _stakeAt
  ) internal {
    Reward memory reward = getReward(_address, _tokenId);
    uint8 remainingStep;

    if (reward.remainingSteps == 0 || reward.stakeAt != _stakeAt) {
      remainingStep = TOTAL_REWARD_STEPS - 1;
    } else {
      remainingStep = reward.remainingSteps - 1;
    }

    addressRewards[_address][_tokenId] = Reward({
      tokenId: _tokenId,
      remainingSteps: remainingStep,
      lastRewardClaimedAt: block.timestamp,
      nextRewardAvailableAt: block.timestamp + REWARD_INTERVAL,
      stakeAt: _stakeAt
    });

    _mint(_address, _rewardAmount);
  }

  function getReward(
    address _address,
    uint256 _tokenId
  ) public view returns (Reward memory) {
    Reward storage reward = addressRewards[_address][_tokenId];

    AsterFiStaking.Stake memory stake = stakingContract.getStakeInfo(
      _address,
      _tokenId
    );

    if (stake.stakedAt + STAKING_PERIOD < block.timestamp && stake.active) {
      return reward;
    }

    return Reward(0, 0, 0, 0, 0);
  }

  function getRewardsOf(
    address _address
  ) external view returns (Reward[] memory) {
    uint256[] memory stakedTokenIds = stakingContract.getStakedNFTs(_address);
    Reward[] memory allRewards = new Reward[](stakedTokenIds.length);

    for (uint256 i = 0; i < stakedTokenIds.length; ) {
      allRewards[i] = getReward(_address, stakedTokenIds[i]);
      unchecked {
        i++;
      }
    }

    return allRewards;
  }

  function getRewardsForBatch(
    address _address,
    uint256[] memory tokenIds
  ) external view returns (Reward[] memory) {
    Reward[] memory batchRewards = new Reward[](tokenIds.length);

    for (uint256 i = 0; i < tokenIds.length; ) {
      batchRewards[i] = getReward(_address, tokenIds[i]);
      unchecked {
        i++;
      }
    }

    return batchRewards;
  }

  function getAvailableTokensIdForReward(
    address _address
  ) external view returns (uint256[] memory) {
    uint256[] memory stakedTokenIds = stakingContract.getStakedNFTs(_address);

    uint256[] memory tokensAvailable = new uint256[](stakedTokenIds.length);

    uint256 availableCount = 0;

    for (uint256 i = 0; i < stakedTokenIds.length; ) {
      uint256 tokenId = stakedTokenIds[i];
      if (isStakedTokenReadyToClaimReward(_address, tokenId)) {
        tokensAvailable[availableCount++] = tokenId;
      }
      unchecked {
        i++;
      }
    }

    assembly {
      mstore(tokensAvailable, availableCount)
    }

    return tokensAvailable;
  }

  function isStakedTokenReadyToClaimReward(
    address _address,
    uint256 _tokenId
  ) public view returns (bool) {
    Reward memory reward = getReward(_address, _tokenId);

    AsterFiStaking.Stake memory stake = stakingContract.getStakeInfo(
      _address,
      _tokenId
    );

    if (reward.nextRewardAvailableAt == 0 && reward.lastRewardClaimedAt == 0) {
      return stake.stakedAt + STAKING_PERIOD < block.timestamp && stake.active;
    }

    return
      stake.stakedAt + STAKING_PERIOD < block.timestamp &&
      stake.active &&
      block.timestamp > reward.nextRewardAvailableAt;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function _mint(address account, uint256 amount) private validAmount(amount) {
    _totalSupply += amount;
    _balances[account] += amount;

    emit Mint(account, amount);
  }

  function _burn(address account, uint256 amount) private validAmount(amount) {
    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, 'CREDIT: burn amount exceeds balance');

    _balances[account] = accountBalance - amount;
    _totalSupply -= amount;

    emit Burn(account, amount);
  }

  function swap(uint256 amount) external nonReentrant validAmount(amount) {
    require(sipherToken != address(0), 'CREDIT: sipher token not set');
    require(balanceOf(msg.sender) >= amount, 'CREDIT: insufficient fund');
    require(
      amount >= minimumSwapAmount,
      'CREDIT: amount must be greater than minimum swap amount'
    );

    IERC20 token = IERC20(sipherToken);

    uint256 amountOut = (amount * 10 ** 18) / howMuchCreditEqualOneToken;

    require(
      token.balanceOf(address(this)) >= amountOut,
      'CREDIT: insufficient sipher balance in the contract'
    );

    _burn(msg.sender, amount);

    token.transfer(address(this), amountOut);
    emit Swap(msg.sender, amount);
  }

  function withdrawSipher(
    uint256 amount
  ) external onlyOwner validAmount(amount) {
    IERC20 token = IERC20(sipherToken);
    require(
      token.balanceOf(address(this)) >= amount,
      'CREDIT: insufficient balance in the contract'
    );
    token.transfer(owner(), amount);
  }

  function withdraw(uint256 amount) external onlyOwner validAmount(amount) {
    require(address(this).balance >= amount, 'Tiny: insufficient balance');

    payable(owner()).transfer(amount);
  }

  receive() external payable {}

  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  event ClaimReward(
    address indexed _address,
    uint256 indexed _tokenId,
    uint256 rewardAmount,
    uint256 claimedAt,
    uint256 nextClaimAt,
    uint256 stakedAt
  );
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);
  event Swap(address indexed account, uint256 amount);
}
