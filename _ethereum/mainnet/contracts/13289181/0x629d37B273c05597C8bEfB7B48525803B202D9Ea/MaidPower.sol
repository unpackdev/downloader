// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./IMaids.sol";
import "./ISushiGirlsLingerieGIrls.sol";

abstract contract MaidPower is Ownable {
    uint256 public lpTokenToMaidPower = 1000;   //1000 : 1LP(1e18 as wei) => 1Power
    address public immutable sushiGirls;
    address public immutable lingerieGirls;

    event ChangeLPTokenToMaidPower(uint256 value);

    constructor(address _sushiGirls, address _lingerieGirls) {
        sushiGirls = _sushiGirls;
        lingerieGirls = _lingerieGirls;
    }

    function changeLPTokenToMaidPower(uint256 value) external onlyOwner {
        lpTokenToMaidPower = value;
        emit ChangeLPTokenToMaidPower(value);
    }

    function powerOfMaids(IMaids maids, uint256 id) public view returns (uint256) {
        uint256 originPower;
        uint256 supportedLPAmount;

        if (address(maids) == sushiGirls) {
            (originPower, supportedLPAmount,) = ISushiGirls(sushiGirls).sushiGirls(id);
        } else if (address(maids) == lingerieGirls) {
            (originPower, supportedLPAmount,) = ILingerieGirls(lingerieGirls).lingerieGirls(id);
        } else {
            (originPower, supportedLPAmount) = maids.powerAndLP(id);
        }

        return originPower + (supportedLPAmount * lpTokenToMaidPower) / 1e21;
    }
}
