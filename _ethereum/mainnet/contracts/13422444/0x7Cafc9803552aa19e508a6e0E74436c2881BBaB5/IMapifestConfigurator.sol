// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ManifestAdmin.sol";

abstract contract IMapifestConfigurator {
    uint8 public valueAmountSplitByPercentage;
    uint8 public pinPriceSplitByPercentage;

    function getMessagePrice() external view virtual returns (uint256);

    function getImagePrice() external view virtual returns (uint256);

    function getVideoPrice() external view virtual returns (uint256);

    function getProfilePrice() external view virtual returns (uint256);

    function getPinBasePrice(uint256 _decimal)
        external
        view
        virtual
        returns (uint256);
}
