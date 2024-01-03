// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import "./IERC20.sol";
import "./Address.sol";
import "./IWETH.sol";

import "./IJusDeFi.sol";
import "./IJDFIStakingPool.sol";
import "./StakingPool.sol";

contract JDFIStakingPool is IJDFIStakingPool, StakingPool {
  using Address for address payable;

  address private immutable _jusdefi;
  // _airdropToken cannot be immutable because it is referenced in _beforeTokenTransfer
  address private _airdropToken;
  address private immutable _weth;
  address private immutable _devStakingPool;

  mapping (address => uint) private _lockedBalances;

  uint private constant JDFI_PER_ETH = 4;

  constructor (
    address airdropToken,
    uint initialSupply,
    address weth,
    address devStakingPool
  ) ERC20('Staked JDFI', 'JDFI/S') {
    _jusdefi = msg.sender;
    _airdropToken = airdropToken;
    _weth = weth;
    _devStakingPool = devStakingPool;

    _addToWhitelist(airdropToken);
    _addToWhitelist(msg.sender);

    // initialSupply is minted before receipt of JDFI; see JusDeFi constructor
    _mint(msg.sender, initialSupply);

    // approve devStakingPool to spend WETH
    IERC20(weth).approve(devStakingPool, type(uint).max);
  }

  /**
   * @notice query locked balance of an address
   * @param account address to query
   * @return uint locked balance of account
   */
  function lockedBalanceOf (address account) public view returns (uint) {
    return _lockedBalances[account];
  }

  /**
   * @notice stake earned rewards without incurring burns
   */
  function compound () external {
    uint amount = rewardsOf(msg.sender);
    _clearRewards(msg.sender);
    _mint(msg.sender, amount);
  }

  /**
   * @notice deposit and stake JDFI
   * @param amount quantity of JDFI to stake
   */
  function stake (uint amount) override external {
    IJusDeFi(_jusdefi).transferFrom(msg.sender, address(this), amount);
    _mint(msg.sender, amount);
  }

  /**
   * @notice unstake and withdraw JDFI
   * @param amount quantity of tokens to unstake
   */
  function unstake (uint amount) override external {
    _burn(msg.sender, amount);
    IJusDeFi(_jusdefi).burnAndTransfer(msg.sender, amount);
  }

  /**
   * @notice withdraw earned JDFI rewards
   */
  function withdraw () external {
    IJusDeFi(_jusdefi).burnAndTransfer(msg.sender, rewardsOf(msg.sender));
    _clearRewards(msg.sender);
  }

  /**
   * @notice deposit ETH to free locked token balance, at a rate of 1:4
   */
  function unlock () external payable {
    // fee pool address not available at deployment time, so fetch dynamically
    address payable feePool = IJusDeFi(_jusdefi)._feePool();
    require(feePool != address(0), 'JusDeFi: liquidity event still in progress');

    uint amount = msg.value * JDFI_PER_ETH;
    require(_lockedBalances[msg.sender] >= amount, 'JusDeFi: insufficient locked balance');
    _lockedBalances[msg.sender] -= amount;

    uint dev = msg.value / 2;

    // staking pool contract designed to work with ERC20, so convert to WETH
    IWETH(_weth).deposit{ value: dev }();
    IStakingPool(_devStakingPool).distributeRewards(dev);

    feePool.sendValue(address(this).balance);
  }

  /**
   * @notice distribute rewards to stakers
   * @param amount quantity to distribute
   */
  function distributeRewards (uint amount) override external {
    IJusDeFi(_jusdefi).transferFrom(msg.sender, address(this), amount);
    _distributeRewards(amount);
  }

  /**
   * @notice OpenZeppelin ERC20 hook: prevent transfer of locked tokens
   * @param from sender
   * @param to recipient
   * @param amount quantity transferred
   */
  function _beforeTokenTransfer (address from, address to, uint amount) override internal {
    super._beforeTokenTransfer(from, to, amount);

    uint locked = lockedBalanceOf(from);

    require(
      locked == 0 || balanceOf(from) - locked >= amount,
      'JusDeFi: amount exceeds unlocked balance'
    );

    if (from == _airdropToken) {
      _lockedBalances[to] += amount;
    }
  }
}
