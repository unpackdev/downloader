// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;

import "./SafeMath.sol";

contract LendFlareGaugeModel {
    using SafeMath for uint256;

    struct GaugeModel {
        address gauge;
        uint256 weight;
        bool shutdown;
    }

    address[] public gauges;
    address public owner;
    address public supplyExtraReward;

    mapping(address => GaugeModel) public gaugeWeights;

    event AddGaguge(address indexed gauge, uint256 weight);
    event ToggleGauge(address indexed gauge, bool enabled);
    event UpdateGaugeWeight(address indexed gauge, uint256 weight);
    event SetOwner(address owner);

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "LendFlareGaugeModel: caller is not the owner"
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    constructor() public {
        owner = msg.sender;
    }

    function setSupplyExtraReward(address _v) public onlyOwner {
        require(_v != address(0), "!_v");

        supplyExtraReward = _v;
    }

    // default = 100000000000000000000 weight(%) = 100000000000000000000 * 1e18/ total * 100
    function addGauge(address _gauge, uint256 _weight) public {
        require(
            msg.sender == supplyExtraReward,
            "LendFlareGaugeModel: !authorized addGauge"
        );

        gauges.push(_gauge);

        gaugeWeights[_gauge] = GaugeModel({
            gauge: _gauge,
            weight: _weight,
            shutdown: false
        });
    }

    function updateGaugeWeight(address _gauge, uint256 _newWeight)
        public
        onlyOwner
    {
        require(_gauge != address(0), "LendFlareGaugeModel:: !_gauge");
        require(
            gaugeWeights[_gauge].gauge == _gauge,
            "LendFlareGaugeModel: !found"
        );

        gaugeWeights[_gauge].weight = _newWeight;

        emit UpdateGaugeWeight(_gauge, gaugeWeights[_gauge].weight);
    }

    function toggleGauge(address _gauge, bool _state) public {
        require(
            msg.sender == supplyExtraReward,
            "LendFlareGaugeModel: !authorized toggleGauge"
        );

        gaugeWeights[_gauge].shutdown = _state;

        emit ToggleGauge(_gauge, _state);
    }

    function getGaugeWeightShare(address _gauge) public view returns (uint256) {
        uint256 totalWeight;

        for (uint256 i = 0; i < gauges.length; i++) {
            if (!gaugeWeights[gauges[i]].shutdown) {
                totalWeight = totalWeight.add(gaugeWeights[gauges[i]].weight);
            }
        }

        return gaugeWeights[_gauge].weight.mul(1e18).div(totalWeight);
    }

    function gaugesLength() public view returns (uint256) {
        return gauges.length;
    }
}
