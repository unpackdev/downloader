// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;
import "./Crowdsale.sol";
contract TimeBank is Crowdsale {
    using SafeMath for uint256;
    address timeGuardian;
    uint256 private _changeableRate;
    constructor(
        uint256 initialRate,    // the hour rate
        address payable wallet,
        IERC20 token
    )
        Crowdsale(initialRate, wallet, token)
    {
        timeGuardian = msg.sender;
        _changeableRate = initialRate;
    }

      function setRate(uint256 newRate) public
  {
    require(msg.sender == timeGuardian, "you are not the Time guardian");
    _changeableRate = newRate;
  }
    function rate() public override view returns (uint256) {
    return _changeableRate;
  }

  function _getTokenAmount(uint256 weiAmount) internal override  view returns (uint256) {
    return weiAmount.mul(_changeableRate);
  }

}