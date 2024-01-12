// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;
import "./ICurvePool.sol";
import "./IERC20.sol";
import "./ZeroCurveWrapper.sol";
import "./ICurveInt128.sol";
import "./ICurveInt256.sol";
import "./ICurveUInt128.sol";
import "./ICurveUInt256.sol";
import "./ICurveUnderlyingInt128.sol";
import "./ICurveUnderlyingInt256.sol";
import "./ICurveUnderlyingUInt128.sol";
import "./ICurveUnderlyingUInt256.sol";
import "./CurveLib.sol";

contract ZeroCurveFactory {
  event CreateWrapper(address _wrapper);

  function createWrapper(
    bool _underlying,
    uint256 _tokenInIndex,
    uint256 _tokenOutIndex,
    address _pool
  ) public payable {
    emit CreateWrapper(address(new ZeroCurveWrapper(_tokenInIndex, _tokenOutIndex, _pool, _underlying)));
  }

  fallback() external payable {
    /* no op */
  }
}
