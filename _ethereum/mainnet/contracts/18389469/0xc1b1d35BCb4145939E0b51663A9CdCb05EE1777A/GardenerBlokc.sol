// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IGardenerBlokc.sol";
import "./Counters.sol";
import "./Ownable.sol";

abstract contract GardenerBlokc is Ownable, IGardenerBlokc {
    using Counters for Counters.Counter;
    Counters.Counter private idGardeners;

    mapping(uint256 => Gardener) internal idToGardener;
    mapping(address => uint256) public gardenerAddressToId;
    mapping(address => bool) public isGardenerRegistered;
    mapping(string => bool) public isStrategyCreated;

    


    event StrategyCreated(address indexed gardener, uint256 strategyIndex);

    function registerGardener(
        string memory _username,
        address _addressGardener
    ) external {
        require(
            !isGardenerRegistered[_addressGardener],
            "Gardener is already registered"
        );
        uint256 newId = idGardeners.current();
        idGardeners.increment();
        Gardener storage gardener = idToGardener[newId];
        gardener.id = newId;
        gardener.gardenerAddress = _addressGardener;
        gardener.username = _username;
        isGardenerRegistered[_addressGardener] = true;
        gardenerAddressToId[_addressGardener] = newId;
    }

      function createStrategy(
        uint256 _minAmount,
        uint256 _maxAmount,
        string memory _strategyName,
        address[] memory _cryptos,
        uint8[] memory _percentages
    ) external {
        require(isGardenerRegistered[msg.sender], "Gardener is not registered");
        require(_minAmount > 0 && _maxAmount > _minAmount, "Invalid min/max amounts");
        require(_cryptos.length == _percentages.length, "Arrays must have equal length");
        
        uint8 totalPercentage;

        for (uint256 i = 0; i < _cryptos.length; i++) {
            totalPercentage += _percentages[i];
        }

        require(totalPercentage == 100, "Total percentage must be 100");

        Gardener storage gardener = idToGardener[gardenerAddressToId[msg.sender]];
        gardener.strategies.push(
            GardenerStrategy({
                minAmount: _minAmount,
                maxAmount: _maxAmount,
                strategyName : _strategyName,
                cryptos: _cryptos,
                percentages: _percentages
            })
        );
    }




    function viewAllStrategiesForGardener(address _gardenerAddress)
        external
        view
        returns (GardenerStrategy[] memory)
    {
        require(isGardenerRegistered[_gardenerAddress], "Gardener is not registered");
        uint256 idGardener = gardenerAddressToId[_gardenerAddress];
        Gardener storage gardener = idToGardener[idGardener];
        return gardener.strategies;
    }

    
   
    function getGardener(
        uint256 _gardenerId
    ) external view returns (Gardener memory) {
        require(_gardenerId < idGardeners.current(), "Gardener doesn't exist");
        Gardener memory gardener = idToGardener[_gardenerId];
        return gardener;
    }

    function getAllGardeners() external view returns (Gardener[] memory) {
        uint256 totalGardeners = idGardeners.current();
        Gardener[] memory allGardeners = new Gardener[](totalGardeners);
        for (uint256 i = 0; i < totalGardeners; i++) {
            allGardeners[i] = idToGardener[i];
        }
        return allGardeners;
    }


    function getGardensForGardener()
        external
        view
        returns (GardenersGardenData[] memory gardens)
    {
        require(isGardenerRegistered[msg.sender], "Gardener is not registered");
        uint256 idGardener = gardenerAddressToId[msg.sender];
        Gardener memory gardener = idToGardener[idGardener];
        return gardener.gardens;
    }


    function getIdGardener() external view returns (uint256 id) {
        require(isGardenerRegistered[msg.sender], "Gardener is not registered");
        uint256 idGardener = gardenerAddressToId[msg.sender];
        return idGardener;
    }
}
