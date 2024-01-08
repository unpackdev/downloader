// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IHTTPrivateSale {
    event MinChanged(
        address indexed owner,
        uint256 version,
        uint256 minBuyable
    );
    event MaxChanged(
        address indexed owner,
        uint256 version,
        uint256 maxBuyable
    );
    event RateChanged(address indexed owner, uint256 version, uint256 rate);
    event StatusChanged(address indexed owner, bool value);
    event SupplyChanged(address indexed owner, uint256 version, uint256 supply);
    event HttSold(
        address indexed buyer,
        uint256 version,
        uint256 amount,
        uint256 rate
    );

    struct Version {
        uint256 version;
        bool initialized;
        uint256 minBuyable;
        uint256 maxBuyable;
        uint256 totalSupply;
        uint256 soldSupply;
        uint256 rate;
    }

    function currentVersion() external view returns (Version memory);

    function addVersion(
        uint256 minBuyable,
        uint256 maxBuyable,
        uint256 supply,
        uint256 rate,
        bool enableVersion
    ) external;

    function enable(bool isEnable) external;

    function hasEnable() external view returns (bool);

    function setRate(uint256 rate) external;

    function buy() external payable;

    function boughtAmount() external view returns (uint256);

    function withdrawEth() external;

    function withdrawHTT() external;
}
