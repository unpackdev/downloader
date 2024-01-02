//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./DaiLike.sol";
interface ISavingsDai {
    function dai() external returns(DaiLike); 
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
}
