// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12; 

import "./IERC721Receiver.sol";
import "./IOptionsProvider.sol";

interface IOptionsPool is IERC721Receiver {

    event RegisterOption(uint tokenId, uint premium);
    
    function optionsProvider() external returns (IOptionsProvider);
    function paidPremiums(uint tokenId) external returns (uint);

    function exercisableOption(uint tokenId) external view returns (bool);
    function isActiveOption(uint tokenId) external view returns (bool);
    function unlockOption(uint tokenId) external;
    function takeOptionFrom(address from, uint tokenId) external;
    function sendOptionTo(address to, uint tokenId) external;
    function exerciseOption(uint tokenId) external returns (uint profit);
    function depositOption(uint tokenId, uint premium) external;
}