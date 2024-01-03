// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;

import "./Crowdsale.sol";
import "./PausableCrowdsale.sol";
import "./CappedCrowdsale.sol";
import "./TimedCrowdsale.sol";
import "./FinalizableCrowdsale.sol";
import "./Ownable.sol";
import "./IERC777.sol";

contract HyperHoldingCrowdsalePhase2 is Crowdsale, CappedCrowdsale, TimedCrowdsale, FinalizableCrowdsale, PausableCrowdsale, Ownable {

    uint256 private _changeableRate;
    IERC777 __token;

    constructor()
        Ownable()
        FinalizableCrowdsale()
        PausableCrowdsale()
        CappedCrowdsale(
          600000 * 10 ** 18      // total cap, in wei
        )
        TimedCrowdsale(
          1609959600,              // opening time in unix epoch seconds
          1612558800  // closing time in unix epoch seconds
        )
        Crowdsale(
          7666,                    // rate, in TKNbits ( (ETH price in USD) /  (Token price in USD) )
          0x230660DD3beF18cCeCD529786944050E11b99681, // wallet to send Ether
          IERC20(0x63Ba6efA6f7F69c4774Cff0A6DaC8f3C77dD81B8) // the token
        ) public
    {
      _changeableRate = 7666; 
      __token = IERC777(0x63Ba6efA6f7F69c4774Cff0A6DaC8f3C77dD81B8);
    }

    event RateChanged(uint256 newRate);

    function setRate(uint256 newRate) public onlyOwner {
        require(newRate > 0, "Crowdsale: rate is 0");
        _changeableRate = newRate;
        emit RateChanged(newRate);
    }

    function rate() public view returns (uint256) {     
          return _changeableRate;
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_changeableRate);
    }

    function _finalization() internal {
        _deliverTokens(wallet(), __token.balanceOf(address(this)));
    }

}