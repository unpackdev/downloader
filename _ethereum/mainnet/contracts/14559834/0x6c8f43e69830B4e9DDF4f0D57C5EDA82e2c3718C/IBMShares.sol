//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IDividends.sol";
import "./IKillswitch.sol";

interface IBMShares is IDividends, IERC20, IKillswitch {
    function mintForHoney(address for_, uint256 amount, uint256 value) external;
    function mintForEth(address for_, uint256 amount) external payable;

    function getPriceEth() external view returns (uint256);
    function getPriceHoney() external view returns (uint256);

    function availableForEth() external view returns (uint256);

    function setPriceEth(uint256 price) external;
    function setPriceHoney(uint256 price) external;
}
