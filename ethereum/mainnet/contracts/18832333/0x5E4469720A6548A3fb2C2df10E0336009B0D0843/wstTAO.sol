// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./wTAO.sol";
import "./ReentrancyGuard.sol";

interface IERC20 {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

contract WSTTaoV1 is
  Initializable,
  ERC20Upgradeable,
  OwnableUpgradeable,
  ReentrancyGuard
{
  struct UserRequest {
    address user;
    uint256 requestIndex;
  }
  uint256 public exchangeRate; // 1 * 10^18
  uint256 public unstakingFee;
  // Calculated based on the fee needed to bridge
  uint256 public stakingFee;
  uint256 public minStakingAmt;
  wTAO public wrappedToken;
  uint256 public maxDepositPerRequest;
  bool public isPaused;
  string public nativeWalletReceiver;
  uint256 public maxUnstakeRequests;
  event UserUnstakeRequested(
    address indexed user,
    uint256 idx,
    uint256 requestTimestamp,
    uint256 wstAmount,
    uint256 outTaoAmt
  );
  event AdminUnstakeApproved(
    address indexed user,
    uint256 idx,
    uint256 approvedTimestamp
  );
  event UserUnstake(
    address indexed user,
    uint256 idx,
    uint256 unstakeTimestamp
  );
  event UserStake(
    address indexed user,
    uint256 stakeTimestamp,
    uint256 inTaoAmt,
    uint256 wstAmount
  );
  struct UnstakeRequest {
    uint256 amount;
    uint256 taoAmt;
    bool isReadyForUnstake;
    uint256 timestamp;
  }

  function initialize(address initialOwner) public initializer {
    __ERC20_init("Tensorplex Staked TAO", "plxTAO");

    __Ownable_init(initialOwner);
    exchangeRate = 1 ether;
    maxDepositPerRequest = 50 ether; // Max 50 tao per request
    // Set so that there can only be 30 unstake requests at any point of time
    maxUnstakeRequests = 30;
    isPaused = true;
    minStakingAmt = 0;
    stakingFee = 0;
    unstakingFee = 0;
  }

  function setMinStakingAmt(uint256 _minStakingAmt) public onlyOwner {
    minStakingAmt = _minStakingAmt;
  }

  function setStakingFee(uint256 _stakingFee) public onlyOwner {
    stakingFee = _stakingFee;
  }

  function setMaxDepositPerRequest(uint256 _maxDepositPerRequest)
    public
    onlyOwner
  {
    maxDepositPerRequest = _maxDepositPerRequest;
  }

  function setMaxUnstakeRequest(uint256 _maxUnstakeRequests) public onlyOwner {
    maxUnstakeRequests = _maxUnstakeRequests;
  }

  function decimals() public view virtual override returns (uint8) {
    return 9;
  }

  function setPaused(bool _isPaused) public onlyOwner {
    isPaused = _isPaused;
  }

  function setUnstakingFee(uint256 _unstakingFee) public onlyOwner {
    unstakingFee = _unstakingFee;
  }

  function setWTAO(address _wTAO) public onlyOwner {
    wrappedToken = wTAO(_wTAO);
  }

  function setNativeTokenReceiver(string memory _nativeWalletReceiver)
    public
    onlyOwner
  {
    nativeWalletReceiver = _nativeWalletReceiver;
  }

  mapping(address => UnstakeRequest[]) public unstakeRequests;

  function getWstTAObyWTAO(uint256 wtaoAmount) public view returns (uint256) {
    return (wtaoAmount * exchangeRate) / 1 ether;
  }

  function getWTAOByWstTAO(uint256 wstTaoAmount) public view returns (uint256) {
    return (wstTaoAmount * 1 ether) / exchangeRate;
  }

  function getWTAOByWstTAOAfterFee(uint256 wstTaoAmount)
    public
    view
    returns (uint256)
  {
    return ((wstTaoAmount - unstakingFee) * 1 ether) / exchangeRate;
  }

  function requestUnstake(uint256 wstTAOAmt) public nonReentrant {
    require(!isPaused, "Contract is paused");
    require(
      unstakeRequests[msg.sender].length < maxUnstakeRequests,
      "Maximum unstake requests exceeded"
    );
    require(wstTAOAmt > unstakingFee, "Invalid wstTAO amount");
    // Check if enough balance
    require(balanceOf(msg.sender) >= wstTAOAmt, "Insufficient wstTAO balance");
    uint256 outWTaoAmt = getWTAOByWstTAOAfterFee(wstTAOAmt);
    // Check that the nativeWalletReceiver is not an empty string
    require(
      bytes(nativeWalletReceiver).length > 0,
      "nativeWalletReceiver is empty"
    );
    // Check that wrappedToken is a valid address
    require(
      address(wrappedToken) != address(0),
      "wrappedToken address is invalid"
    );
    uint256 length = unstakeRequests[msg.sender].length;
    bool added = false;
    for (uint256 i = 0; i < length; i++) {
      if (unstakeRequests[msg.sender][i].amount == 0) {
        unstakeRequests[msg.sender][i] = UnstakeRequest({
          amount: wstTAOAmt,
          taoAmt: outWTaoAmt,
          isReadyForUnstake: false,
          timestamp: block.timestamp
        });
        added = true;
        emit UserUnstakeRequested(
          msg.sender,
          i,
          block.timestamp,
          wstTAOAmt,
          outWTaoAmt
        );
        break;
      }
    }

    if (!added) {
      unstakeRequests[msg.sender].push(
        UnstakeRequest({
          amount: wstTAOAmt,
          taoAmt: outWTaoAmt,
          isReadyForUnstake: false,
          timestamp: block.timestamp
        })
      );
      emit UserUnstakeRequested(
        msg.sender,
        length,
        block.timestamp,
        wstTAOAmt,
        outWTaoAmt
      );
    }

    // Perform burn
    _burn(msg.sender, wstTAOAmt);
  }

  function getUnstakeRequestByUser(address user)
    public
    view
    returns (UnstakeRequest[] memory)
  {
    return unstakeRequests[user];
  }

  function approveMultipleUnstakes(UserRequest[] memory requests)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < requests.length; i++) {
      UserRequest memory request = requests[i];
      require(
        request.requestIndex < unstakeRequests[request.user].length,
        "Invalid request index"
      );
      unstakeRequests[request.user][request.requestIndex]
        .isReadyForUnstake = true;
      emit AdminUnstakeApproved(
        request.user,
        request.requestIndex,
        block.timestamp
      );
    }
  }

  function approveUnstake(address user, uint256 requestIndex) public onlyOwner {
    require(
      requestIndex < unstakeRequests[user].length,
      "Invalid request index"
    );
    unstakeRequests[user][requestIndex].isReadyForUnstake = true;
    emit AdminUnstakeApproved(user, requestIndex, block.timestamp);
  }

  function unstake(uint256 requestIndex) public nonReentrant {
    require(!isPaused, "Contract is paused");
    require(
      requestIndex < unstakeRequests[msg.sender].length,
      "Invalid request index"
    );
    UnstakeRequest storage request = unstakeRequests[msg.sender][requestIndex];
    require(request.amount > 0, "No unstake request found");
    require(request.isReadyForUnstake, "Unstake not approved yet");

    // Transfer wTAO tokens back to the user
    uint256 amountToTransfer = request.taoAmt;

    // Perform ERC20 transfer
    bool transferSuccessful = wrappedToken.transfer(
      msg.sender,
      amountToTransfer
    );
    require(transferSuccessful, "wTAO transfer failed");

    // Update state to false
    delete unstakeRequests[msg.sender][requestIndex];

    // Process the unstake event
    emit UserUnstake(msg.sender, requestIndex, block.timestamp);
  }

  function updateExchangeRate(uint256 newRate) public onlyOwner {
    require(newRate > 0, "Exchange rate must be greater than 0");
    exchangeRate = newRate;
  }

  function calculateAmtAfterFee(uint256 wtaoAmount)
    public
    view
    returns (uint256)
  {
    // Minus by the unstaking fee
    return wtaoAmount - stakingFee;
  }

  function wrap(uint256 wtaoAmount) public nonReentrant {
    require(!isPaused, "Contract is paused");
    require(
      maxDepositPerRequest >= wtaoAmount,
      "Deposit amount exceeds maximum"
    );
    // Check that the nativeWalletReceiver is not an empty string
    require(
      bytes(nativeWalletReceiver).length == 48,
      "nativeWalletReceiver must be of length 48"
    );
    // Check that wrappedToken is a valid address
    require(
      address(wrappedToken) != address(0),
      "wrappedToken address is invalid"
    );
    require(
      wrappedToken.balanceOf(msg.sender) >= wtaoAmount,
      "Insufficient wTAO balance"
    );
    // Ensure that at least 0.125 TAO is being bridged
    // based on the smart contract
    require(wtaoAmount > minStakingAmt, "Does not meet minimum staking amount");
    require(
      wtaoAmount > stakingFee,
      "wTAO amount must be more than staking fee"
    );

    uint256 wrapAmountAfterFee = calculateAmtAfterFee(wtaoAmount);
    require(
      wrappedToken.transferFrom(msg.sender, address(this), wtaoAmount),
      "Transfer failed"
    );
    uint256 wstTAOAmount = getWstTAObyWTAO(wrapAmountAfterFee);
    emit UserStake(msg.sender, block.timestamp, wtaoAmount, wstTAOAmount);

    // Perform token transfers
    _mint(msg.sender, wstTAOAmount);
    bool success = wrappedToken.bridgeBack(wtaoAmount, nativeWalletReceiver);
    require(success, "Bridge back failed");
  }

  function mint(address account, uint256 amount) public onlyOwner {
    // Add any necessary access controls here (like onlyOwner or onlyMinter)
    _mint(account, amount);
  }

  function safePullERC20(
    address tokenAddress,
    address to,
    uint256 amount
  ) public onlyOwner {
    require(to != address(0), "Recipient address cannot be 0");
    require(amount > 0, "Amount must be greater than 0");

    IERC20 token = IERC20(tokenAddress);
    uint256 balance = token.balanceOf(address(this));
    require(balance >= amount, "Not enough tokens in contract");

    bool success = token.transfer(to, amount);
    require(success, "Token transfer failed");
  }

  function pullNativeToken(address to, uint256 amount) public onlyOwner {
    require(to != address(0), "Recipient address cannot be 0");
    require(amount > 0, "Amount must be greater than 0");

    uint256 balance = address(this).balance;
    require(balance >= amount, "Not enough native tokens in contract");

    // bool success = payable(to).send(amount);
    (bool success, ) = to.call{ value: amount }("");
    require(success, "Native token transfer failed");
  }

  function deposit() external payable {
    require(msg.value > 0, "Must send ETH");
  }
}
