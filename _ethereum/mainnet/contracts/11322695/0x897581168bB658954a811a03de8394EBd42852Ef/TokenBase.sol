// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EarnPool.sol";
import "./IPoolFarmExtended.sol";
import "./UniswapHelper.sol";

contract TokenBase is EarnPool, IPoolFarmExtended {
  using Address for address;
  using SafeMath for uint256;
  using Arrays for uint256[];
  using SafeERC20 for IERC20;

  UniswapHelper _helper;

  constructor (string memory name, string memory symbol, address fees, address helper) public EarnPool(name, symbol, true, fees) {
    _helper = UniswapHelper(helper);
  }

  function setHelper(address helper) onlyAdmin external {
    require(helper != address(0));
    _helper = UniswapHelper(helper);
  }

  function _harvestRewards() internal override {
    if (address(_farm) != address(0)) {
      _farm.harvest();
    }
  }

  function claimToToken(
    address to, 
    uint[] memory amounts,
    uint[] memory min
  ) external nonReentrant override {
    require(amounts.length == _rewards.length, 'amounts!=rewards');
    require(min.length == amounts.length, 'min!=rewards');
    mapping (IERC20 => uint256) storage owed = _owedRewards[msg.sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 amount = amounts[i];
      if (amount > 0) {
        uint256 rem = owed[token];
        require(amount <= rem, 'bad amount');
        owed[token] = rem.sub(amount);
        if (address(token) == to) {
          safeTransferReward(token, msg.sender, amount);
        } else {
          require(_helper.pathExists(address(token), to), 'bad token');
          string memory path = Path.path(address(token), to);
          amount = safeTransferReward(token, address(_helper), amount);
          if (amount > 0) {
            _helper.swap(path, amount, min[i], msg.sender);
          }
        }

      }
    }
  }

  function withdrawAll() nonReentrant external override virtual {
  }

  function withdraw(uint256 /* amount */) nonReentrant external override virtual {
  }

  function withdrawFees() onlyWithdrawal nonReentrant override virtual external {
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return EarnPool._tokenInUse(token);
  }

}
