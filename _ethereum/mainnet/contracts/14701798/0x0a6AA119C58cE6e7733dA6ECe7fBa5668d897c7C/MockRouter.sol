// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PowerIndexRouter.sol";
import "./WrappedPiErc20.sol";

contract MockRouter is PowerIndexRouter {
  event MockWrapperCallback(uint256 withdrawAmount);

  constructor(address _piToken, BasicConfig memory _basicConfig) public PowerIndexRouter(_piToken, _basicConfig) {}

  function piTokenCallback(address, uint256 _withdrawAmount) external payable virtual override {
    emit MockWrapperCallback(_withdrawAmount);
  }

  function execute(address destination, bytes calldata data) external {
    destination.call(data);
  }

  function drip(address _to, uint256 _amount) external {
    piToken.callExternal(
      address(WrappedPiErc20(address(piToken)).underlying()),
      IERC20(0).transfer.selector,
      abi.encode(_to, _amount),
      0
    );
  }
}
