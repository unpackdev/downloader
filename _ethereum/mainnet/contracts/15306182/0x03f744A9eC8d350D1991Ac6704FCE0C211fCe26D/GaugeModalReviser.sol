// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./SafeMath.sol";

interface ILendFlareGaugeModel {
    struct GaugeModel {
        address gauge;
        uint256 weight;
        bool shutdown;
    }

    function gaugesLength() external view returns (uint256);

    function gaugeWeights(address _gauge) external view returns (GaugeModel memory);

    function getGaugeWeightShare(address _gauge) external view returns (uint256);

    function gauges(uint256) external view returns (address);

    function updateGaugeWeight(address _gauge, uint256 _newWeight) external;

    function toggleGauge(address _gauge, bool _state) external;

    function setOwner(address _owner) external;
}

contract GaugeModalReviser is Initializable {
    using SafeMath for uint256;

    uint256 private constant HUNDRED_PERCENT = 10000;

    address public owner;
    address public lendFlareGaugeModel;

    event SetOwner(address _owner, address _newOwner);
    event RevertOwner(address _newOwner);
    event UpdateGaugeWeight(address _gauge, uint256 _totalWeight, uint256 _newWeight);
    event UpdateBaseGauge(address _gauge, uint256 _totalWeight, uint256 _newWeight);

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() public initializer {}

    function initialize(address _gagueModel, address _owner) public initializer {
        lendFlareGaugeModel = _gagueModel;
        owner = _owner;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "GagueModalReviser: !authorized setOwner");

        emit SetOwner(owner, _owner);

        owner = _owner;
    }

    function updateAllGaugeWeight(address[] calldata _gauges, uint256[] calldata _weightPercents) external {
        require(msg.sender == owner, "GagueModalReviser: !authorized updateGaugeWeight");
        require(_gauges.length == _weightPercents.length, "GagueModalReviser: !length mismatch");

        uint256 totalPercent;

        for (uint256 i = 0; i < _weightPercents.length; i++) {
            totalPercent = totalPercent.add(_weightPercents[i]);
        }

        require(totalPercent == HUNDRED_PERCENT, "GagueModalReviser: !totalPercent");

        (uint256 totalWeight, uint256 gaugesLength) = _totalGaugeWeights(100e18);

        require(gaugesLength > 0, "GagueModalReviser: !gaugesLength");
        require(_gauges.length == gaugesLength, "GagueModalReviser: !Must all gauges");

        for (uint256 i = 0; i < _gauges.length; i++) {
            uint256 newWeight = totalWeight.mul(_weightPercents[i]).div(HUNDRED_PERCENT);

            ILendFlareGaugeModel(lendFlareGaugeModel).updateGaugeWeight(_gauges[i], newWeight);

            emit UpdateGaugeWeight(_gauges[i], totalWeight, newWeight);
        }
    }

    function updateBaseGauge(address _gauge) external {
        require(msg.sender == owner, "GagueModalReviser: !authorized updateBaseGauge");
        require(_gauge != address(0), "GagueModalReviser:: !_gauge");

        (uint256 totalWeight, uint256 newWeight) = _newWeight();

        ILendFlareGaugeModel(lendFlareGaugeModel).updateGaugeWeight(_gauge, newWeight);

        emit UpdateBaseGauge(_gauge, totalWeight, newWeight);
    }

    function getGauges() public view returns (ILendFlareGaugeModel.GaugeModel[] memory) {
        uint256 gaugesLength = ILendFlareGaugeModel(lendFlareGaugeModel).gaugesLength();

        ILendFlareGaugeModel.GaugeModel[] memory gauges = new ILendFlareGaugeModel.GaugeModel[](gaugesLength);

        for (uint256 i = 0; i < ILendFlareGaugeModel(lendFlareGaugeModel).gaugesLength(); i++) {
            address gague = ILendFlareGaugeModel(lendFlareGaugeModel).gauges(i);
            ILendFlareGaugeModel.GaugeModel memory gaugeModel = ILendFlareGaugeModel(lendFlareGaugeModel).gaugeWeights(gague);

            gauges[i] = gaugeModel;
        }

        return gauges;
    }

    function getGaugeWeightShare(address _gauge) public view returns (uint256) {
        return ILendFlareGaugeModel(lendFlareGaugeModel).getGaugeWeightShare(_gauge);
    }

    function _totalGaugeWeights(uint256 _weight) internal view returns (uint256, uint256) {
        uint256 totalWeight;
        uint256 gaugesLength;

        for (uint256 i = 0; i < ILendFlareGaugeModel(lendFlareGaugeModel).gaugesLength(); i++) {
            address gague = ILendFlareGaugeModel(lendFlareGaugeModel).gauges(i);
            ILendFlareGaugeModel.GaugeModel memory gaugeModel = ILendFlareGaugeModel(lendFlareGaugeModel).gaugeWeights(gague);

            if (!gaugeModel.shutdown) {
                if (_weight > 0) {
                    totalWeight = totalWeight.add(_weight);
                } else {
                    totalWeight = totalWeight.add(gaugeModel.weight);
                }

                gaugesLength++;
            }
        }

        return (totalWeight, gaugesLength);
    }

    function _newWeight() internal view returns (uint256, uint256) {
        (uint256 totalWeight, ) = _totalGaugeWeights(0);

        require(totalWeight > 0, "GagueModalReviser: !totalWeight");

        // target gauge weight = [10% / (1 - 10%)] * current total gauge weight
        return (totalWeight, uint256(1000).mul(HUNDRED_PERCENT).div(uint256(HUNDRED_PERCENT).sub(1000)).mul(totalWeight).div(HUNDRED_PERCENT));
    }

    function revertOwner(address _v) external {
        require(msg.sender == owner, "GagueModalReviser: !authorized revertOwner");
        require(_v != address(0), "GagueModalReviser:: !_v");

        ILendFlareGaugeModel(lendFlareGaugeModel).setOwner(_v);
        emit RevertOwner(_v);
    }
}
