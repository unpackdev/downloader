// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Address.sol";

/**
  @notice VirtueZapperContract provides a function where people can directly send it ETH and receive
    VIRTUE.
*/
contract VirtueZapperContract {
  IERC20 public immutable virtueToken;
  IdolMainLike public immutable idolMain;
  IERC20 public immutable steth;

  constructor (
    address _virtueTokenAddress,
    address _idolMainAddress,
    address _stethAddress
  ) {
    virtueToken = IERC20(_virtueTokenAddress);
    idolMain = IdolMainLike(_idolMainAddress);
    steth = IERC20(_stethAddress);
    require(steth.approve(address(idolMain), 2**255-1), "Returned false when approving IdolMain to transfer steth");
  }

  function swapForVirtue(uint _minVirtue) external payable {
    Address.sendValue(payable(address(steth)), address(this).balance);
    idolMain.getVirtue(steth.balanceOf(address(this)), _minVirtue);
    require(virtueToken.transfer(msg.sender, virtueToken.balanceOf(address(this))), "Returned false when calling virtueToken.transfer");
  }
}

interface IERC20 {
  function balanceOf(address _account) external returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function approve(address _spender, uint256 _amount) external returns (bool);
}

interface IdolMainLike {
  function getVirtue(uint _stethAmt, uint _minVirtue) external;
}
