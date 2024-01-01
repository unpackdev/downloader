// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct GardenersGardenData {
    uint256 id;
    address userAddress;
    // string[] cryptos;`
    // uint8[] percentages;
}

struct Gardener {
    uint256 id;
    string username;
    address gardenerAddress;
    GardenersGardenData[] gardens;
    GardenerStrategy[] strategies; 
}

struct GardenerStrategy {
    uint256 minAmount;
    uint256 maxAmount;
    string strategyName;
    address[] cryptos;
    uint8[] percentages;
}
interface IGardenerBlokc {
    function registerGardener(
        string memory _username,
        address _addressGardener
    ) external;

      function createStrategy(
        uint256 _minAmount,
        uint256 _maxAmount,
        string memory _strategyName,
        address[] memory _cryptos,
        uint8[] memory _percentages
    ) external;



    function getGardener(
        uint256 _gardenerId
    ) external view returns (Gardener memory);

    function getAllGardeners() external view returns (Gardener[] memory);

    function getGardensForGardener()
        external
        view
        returns (GardenersGardenData[] memory gardens);

    function getIdGardener() external view returns (uint256 id);
}
