// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.6;

import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./Babylonian.sol";
import "./TREE.sol";
import "./TREERebaser.sol";
import "./ITREERewards.sol";
import "./IOmniBridge.sol";

contract TREEReserve is ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  /**
    Modifiers
   */

  modifier onlyRebaser {
    require(msg.sender == address(rebaser), "TREEReserve: not rebaser");
    _;
  }

  modifier onlyGov {
    require(msg.sender == gov, "TREEReserve: not gov");
    _;
  }

  /**
    Events
   */
  event SellTREE(uint256 treeSold, uint256 reserveTokenReceived);
  event BurnTREE(
    address indexed sender,
    uint256 burnTreeAmount,
    uint256 receiveReserveTokenAmount
  );
  event SetGov(address _newValue);
  event SetCharity(address _newValue);
  event SetLPRewards(address _newValue);
  event SetUniswapPair(address _newValue);
  event SetUniswapRouter(address _newValue);
  event SetOmniBridge(address _newValue);
  event SetCharityCut(uint256 _newValue);
  event SetRewardsCut(uint256 _newValue);

  /**
    Public constants
   */
  /**
    @notice precision for decimal calculations
   */
  uint256 public constant PRECISION = 10**18;
  /**
    @notice Uniswap takes 0.3% fee, gamma = 1 - 0.3% = 99.7%
   */
  uint256 public constant UNISWAP_GAMMA = 997 * 10**15;
  /**
    @notice the minimum value of charityCut
   */
  uint256 public constant MIN_CHARITY_CUT = 10**17; // 10%
  /**
    @notice the maximum value of charityCut
   */
  uint256 public constant MAX_CHARITY_CUT = 5 * 10**17; // 50%
  /**
    @notice the minimum value of rewardsCut
   */
  uint256 public constant MIN_REWARDS_CUT = 5 * 10**15; // 0.5%
  /**
    @notice the maximum value of rewardsCut
   */
  uint256 public constant MAX_REWARDS_CUT = 10**17; // 10%

  /**
    System parameters
   */
  /**
    @notice the address that has governance power over the reserve params
   */
  address public gov;
  /**
    @notice the address that will store the TREE donation, NEEDS TO BE ON L2 CHAIN
   */
  address public charity;
  /**
    @notice the proportion of rebase income given to charity
   */
  uint256 public charityCut;
  /**
    @notice the proportion of rebase income given to LPRewards
   */
  uint256 public rewardsCut;

  /**
    External contracts
   */
  TREE public immutable tree;
  ERC20 public immutable reserveToken;
  TREERebaser public rebaser;
  ITREERewards public lpRewards;
  IUniswapV2Pair public uniswapPair;
  IUniswapV2Router02 public uniswapRouter;
  IOmniBridge public omniBridge;

  constructor(
    uint256 _charityCut,
    uint256 _rewardsCut,
    address _tree,
    address _gov,
    address _charity,
    address _reserveToken,
    address _lpRewards,
    address _uniswapPair,
    address _uniswapRouter,
    address _omniBridge
  ) public {
    charityCut = _charityCut;
    rewardsCut = _rewardsCut;

    tree = TREE(_tree);
    gov = _gov;
    charity = _charity;
    reserveToken = ERC20(_reserveToken);
    lpRewards = ITREERewards(_lpRewards);
    uniswapPair = IUniswapV2Pair(_uniswapPair);
    uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    omniBridge = IOmniBridge(_omniBridge);
  }

  function initContracts(address _rebaser) external onlyOwner {
    require(_rebaser != address(0), "TREE: invalid rebaser");
    require(address(rebaser) == address(0), "TREE: rebaser already set");
    rebaser = TREERebaser(_rebaser);
  }

  /**
    @notice distribute minted TREE to TREERewards and TREEGov, and sell the rest
    @param mintedTREEAmount the amount of TREE minted
   */
  function handlePositiveRebase(uint256 mintedTREEAmount)
    external
    onlyRebaser
    nonReentrant
  {
    // sell remaining TREE for reserveToken
    uint256 rewardsCutAmount = mintedTREEAmount.mul(rewardsCut).div(PRECISION);
    uint256 remainingTREEAmount = mintedTREEAmount.sub(rewardsCutAmount);
    (uint256 treeSold, uint256 reserveTokenReceived) = _sellTREE(
      remainingTREEAmount
    );

    // handle unsold TREE
    if (treeSold < remainingTREEAmount) {
      // the TREE going to rewards should be decreased if there's unsold TREE
      // to maintain the ratio between charityCut and rewardsCut
      uint256 newRewardsCutAmount = rewardsCutAmount.mul(treeSold).div(remainingTREEAmount);
      uint256 burnAmount = remainingTREEAmount.sub(treeSold).add(rewardsCutAmount).sub(newRewardsCutAmount);
      rewardsCutAmount = newRewardsCutAmount;

      // burn unsold TREE
      tree.reserveBurn(address(this), burnAmount);
    }

    // send reserveToken to charity
    uint256 charityCutAmount = reserveTokenReceived.mul(charityCut).div(
      PRECISION.sub(rewardsCut)
    );
    reserveToken.safeIncreaseAllowance(address(omniBridge), charityCutAmount);
    omniBridge.relayTokens(address(reserveToken), charity, charityCutAmount);

    // send TREE to TREERewards
    tree.transfer(address(lpRewards), rewardsCutAmount);
    lpRewards.notifyRewardAmount(rewardsCutAmount);

    // emit event
    emit SellTREE(treeSold, reserveTokenReceived);
  }

  function burnTREE(uint256 amount) external nonReentrant {
    require(!Address.isContract(msg.sender), "TREEReserve: not EOA");

    uint256 treeSupply = tree.totalSupply();

    // burn TREE for msg.sender
    tree.reserveBurn(msg.sender, amount);

    // give reserveToken to msg.sender based on quadratic shares
    uint256 reserveTokenBalance = reserveToken.balanceOf(address(this));
    uint256 deserveAmount = reserveTokenBalance.mul(amount.mul(amount)).div(
      treeSupply.mul(treeSupply)
    );
    reserveToken.safeTransfer(msg.sender, deserveAmount);

    // emit event
    emit BurnTREE(msg.sender, amount, deserveAmount);
  }

  /**
    Utilities
   */
  /**
    @notice create a sell order for TREE
    @param amount the amount of TREE to sell
    @return treeSold the amount of TREE sold
            reserveTokenReceived the amount of reserve tokens received
   */
  function _sellTREE(uint256 amount)
    internal
    returns (uint256 treeSold, uint256 reserveTokenReceived)
  {
    (uint256 token0Reserves, uint256 token1Reserves, ) = uniswapPair
      .getReserves();
    // the max amount of TREE that can be sold such that
    // the price doesn't go below the peg
    uint256 maxSellAmount = _uniswapMaxSellAmount(
      token0Reserves,
      token1Reserves
    );
    treeSold = amount > maxSellAmount ? maxSellAmount : amount;
    tree.increaseAllowance(address(uniswapRouter), treeSold);
    address[] memory path = new address[](2);
    path[0] = address(tree);
    path[1] = address(reserveToken);
    uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
      treeSold,
      1,
      path,
      address(this),
      block.timestamp
    );
    reserveTokenReceived = amounts[1];
  }

  function _uniswapMaxSellAmount(uint256 token0Reserves, uint256 token1Reserves)
    internal
    view
    returns (uint256 result)
  {
    // the max amount of TREE we can sell brings the price down to the peg
    // maxSellAmount = (sqrt(R_tree * R_reserveToken) - R_tree) / UNISWAP_GAMMA
    result = Babylonian.sqrt(token0Reserves.mul(token1Reserves));
    if (address(tree) < address(reserveToken)) {
      // TREE is token0 of the Uniswap pair
      result = result.sub(token0Reserves);
    } else {
      // TREE is token1 of the Uniswap pair
      result = result.sub(token1Reserves);
    }
    result = result.mul(PRECISION).div(UNISWAP_GAMMA);
  }

  /**
    Param setters
   */
  function setGov(address _newValue) external onlyGov {
    require(_newValue != address(0), "TREEReserve: address is 0");
    gov = _newValue;
    emit SetGov(_newValue);
  }

  function setCharity(address _newValue) external onlyGov {
    require(_newValue != address(0), "TREEReserve: address is 0");
    charity = _newValue;
    emit SetCharity(_newValue);
  }

  function setLPRewards(address _newValue) external onlyGov {
    require(_newValue != address(0), "TREEReserve: address is 0");
    lpRewards = ITREERewards(_newValue);
    emit SetLPRewards(_newValue);
  }

  function setUniswapPair(address _newValue) external onlyGov {
    require(_newValue != address(0), "TREEReserve: address is 0");
    uniswapPair = IUniswapV2Pair(_newValue);
    emit SetUniswapPair(_newValue);
  }

  function setUniswapRouter(address _newValue) external onlyGov {
    require(_newValue != address(0), "TREEReserve: address is 0");
    uniswapRouter = IUniswapV2Router02(_newValue);
    emit SetUniswapRouter(_newValue);
  }

  function setOmniBridge(address _newValue) external onlyGov {
    require(_newValue != address(0), "TREEReserve: address is 0");
    omniBridge = IOmniBridge(_newValue);
    emit SetOmniBridge(_newValue);
  }

  function setCharityCut(uint256 _newValue) external onlyGov {
    require(
      _newValue >= MIN_CHARITY_CUT && _newValue <= MAX_CHARITY_CUT,
      "TREEReserve: value out of range"
    );
    charityCut = _newValue;
    emit SetCharityCut(_newValue);
  }

  function setRewardsCut(uint256 _newValue) external onlyGov {
    require(
      _newValue >= MIN_REWARDS_CUT && _newValue <= MAX_REWARDS_CUT,
      "TREEReserve: value out of range"
    );
    rewardsCut = _newValue;
    emit SetRewardsCut(_newValue);
  }
}
