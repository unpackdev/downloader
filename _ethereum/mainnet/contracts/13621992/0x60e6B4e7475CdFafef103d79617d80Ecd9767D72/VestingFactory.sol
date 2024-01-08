/*
  .oooooo.              o8o                           o8o                     
 d8P'  `Y8b             `"'                           `"'                     
888           .ooooo.  oooo  ooo. .oo.   oooo    ooo oooo   .oooo.o  .ooooo.  
888          d88' `88b `888  `888P"Y88b   `88.  .8'  `888  d88(  "8 d88' `88b 
888          888   888  888   888   888    `88..8'    888  `"Y88b.  888ooo888 
`88b    ooo  888   888  888   888   888     `888'     888  o.  )88b 888    .o 
 `Y8bood8P'  `Y8bod8P' o888o o888o o888o     `8'     o888o 8""888P' `Y8bod8P' 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./VestingProxy.sol";
import "./IVesting.sol";
import "./IVestingProxy.sol";

contract VestingFactory is Ownable {
  using SafeERC20 for IERC20;

  event VestingProxyDeployed(
    address indexed _creator,
    address indexed _vestingProxy
  );

  address payable public vesting;

  constructor(address payable _vesting) {
    require(_vesting != address(0), "ERR__VESTING_CANNOT_BE_ZERO_ADDRESS");
    vesting = _vesting;
  }

  function deployVestingProxy(
    address _tokenAddress,
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _totalTokens,
    uint256 _noOfMonths
  ) external returns (address) {
    address vestingProxy = address(
      new VestingProxy(
        vesting,
        abi.encodeWithSelector(
          IVesting(vesting).initialize.selector,
          msg.sender,
          _tokenAddress,
          _beneficiary,
          _start,
          _cliff,
          _totalTokens,
          _noOfMonths
        )
      )
    );
    emit VestingProxyDeployed(msg.sender, vestingProxy);
    IERC20(_tokenAddress).safeTransferFrom(
      msg.sender,
      vestingProxy,
      _totalTokens
    );
    return vestingProxy;
  }

  function setVestingImplAddress(address payable _vesting) external onlyOwner {
    require(_vesting != address(0), "ERR__VESTING_CANNOT_BE_ZERO_ADDRESS");
    vesting = _vesting;
  }

  function upgradeProxy(address _vestingProxy) external {
    require(
      msg.sender == IVesting(_vestingProxy).creator(),
      "ERR__UNAUTHORIZED"
    );
    require(
      vesting != IVestingProxy(_vestingProxy).vesting(),
      "ERR__VESTING_ALREADY_LATEST"
    );
    IVestingProxy(_vestingProxy).upgradeVesting(vesting);
  }
}
