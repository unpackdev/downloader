/**
                                                                       ,----,
                                                                     ,/   .`|
  ,----..    ,--,                                                  ,`   .'  :
 /   /   \ ,--.'|                                                ;    ;     /
|   :     :|  | :     ,---.           .---.      ,---,         .'___,/    ,'  ,---.           .---.      ,---,
.   |  ;. /:  : '    '   ,'\         /. ./|  ,-+-. /  |        |    :     |  '   ,'\         /. ./|  ,-+-. /  |
.   ; /--` |  ' |   /   /   |     .-'-. ' | ,--.'|'   |        ;    |.';  ; /   /   |     .-'-. ' | ,--.'|'   |
;   | ;    '  | |  .   ; ,. :    /___/ \: ||   |  ,"' |        `----'  |  |.   ; ,. :    /___/ \: ||   |  ,"' |
|   : |    |  | :  '   | |: : .-'.. '   ' .|   | /  | |            '   :  ;'   | |: : .-'.. '   ' .|   | /  | |
.   | '___ '  : |__'   | .; :/___/ \:     '|   | |  | |            |   |  ''   | .; :/___/ \:     '|   | |  | |
'   ; : .'||  | '.'|   :    |.   \  ' .\   |   | |  |/             '   :  ||   :    |.   \  ' .\   |   | |  |/
'   | '/  :;  :    ;\   \  /  \   \   ' \ ||   | |--'              ;   |.'  \   \  /  \   \   ' \ ||   | |--'
|   :    / |  ,   /  `----'    \   \  |--" |   |/                  '---'     `----'    \   \  |--" |   |/
 \   \ .'   ---`-'              \   \ |    '---'                                        \   \ |    '---'
  `---`                          '---"                                                   '---"

Its 🤡 clown's 🤡
.
all the
.
.
way
.
.
.
down
.
.
.
.
**/

// SPDX-License-Identifier: CLOWNWARE
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ClownToken.sol";
import "./IClownTownStaking.sol";

contract ClownTownStaking is Ownable, IClownTownStaking {
  using SafeERC20 for IERC20;

  event Stake(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 amountEth, uint256 amountClown);

  uint256 public accEthPerClown1e30;
  uint256 public accClownPerClown1e30;
  uint256 public totalClownStaked;

  int256 public clownVersion = 12345;

  ClownToken public clownToken;

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebtEth;
    uint256 rewardDebtClown;
  }

  mapping(address => UserInfo) public userInfos;

  constructor(ClownToken _clownToken) {
    clownToken = _clownToken;
  }

  function addEthReward() external payable {
    if (msg.value > 0 && totalClownStaked > 0) {
      accEthPerClown1e30 += (msg.value * 1e30 / totalClownStaked);
    }
  }

  function removeEthReward(uint256 _amount) public onlyOwner {
    if (totalClownStaked > 0) {
      accEthPerClown1e30 -= (_amount * 1e30 / totalClownStaked);
    }
    payable(msg.sender).transfer(_amount);
  }

  function postProcessClownReward(uint256 _amount) external {
    require(msg.sender==address(clownToken));

    if (_amount > 0 && totalClownStaked > 0) {
      accClownPerClown1e30 += (_amount * 1e30 / totalClownStaked);
    }
  }

  function removeClownReward(uint256 _amount) public onlyOwner {
    if (totalClownStaked > 0) {
      accClownPerClown1e30 -= (_amount * 1e30 / totalClownStaked);
    }
    IERC20(clownToken).safeTransfer(address(msg.sender), _amount);
  }

  function pendingEthReward(address _user) external view returns (uint256) {
    UserInfo storage user = userInfos[_user];
    return (user.amount * accEthPerClown1e30 / 1e30) - user.rewardDebtEth;
  }

  function pendingClownReward(address _user) external view returns (uint256) {
    UserInfo storage user = userInfos[_user];
    return (user.amount * accClownPerClown1e30 / 1e30) - user.rewardDebtClown;
  }

  function stake(uint256 _amount) public {
    require(_amount > 0);

    IERC20(clownToken).safeTransferFrom(
      address(msg.sender),
      address(this),
      _amount);

    UserInfo storage user = userInfos[msg.sender];
    payAndUpdateUser(user, user.amount + _amount);
    totalClownStaked += _amount;

    emit Stake(msg.sender, _amount);
  }

  function claim() public {
    UserInfo storage user = userInfos[msg.sender];
    payAndUpdateUser(user, user.amount);
  }

  function unstake(uint256 _amount) public {
    require(_amount > 0);
    UserInfo storage user = userInfos[msg.sender];
    require(user.amount >= _amount);

    payAndUpdateUser(user, user.amount - _amount);
    totalClownStaked -= _amount;

    IERC20(clownToken).safeTransfer(
      address(msg.sender),
      _amount);

    emit Unstake(msg.sender, _amount);
  }

  function payAndUpdateUser(UserInfo storage user, uint256 newAmount) internal {
    uint256 pendingEth = (user.amount * accEthPerClown1e30 / 1e30) - user.rewardDebtEth;
    if (pendingEth > 0) {
      payable(msg.sender).transfer(pendingEth);
    }

    uint256 pendingClown = (user.amount * accClownPerClown1e30 / 1e30) - user.rewardDebtClown;
    if (pendingClown > 0) {
      IERC20(clownToken).safeTransfer(address(msg.sender), pendingClown);
    }

    user.amount = newAmount;
    user.rewardDebtEth = newAmount * accEthPerClown1e30 / 1e30;
    user.rewardDebtClown = newAmount * accClownPerClown1e30 / 1e30;

    if (pendingEth > 0 || pendingClown > 0) {
      emit RewardPaid(msg.sender, pendingEth, pendingClown);
    }
  }
}
