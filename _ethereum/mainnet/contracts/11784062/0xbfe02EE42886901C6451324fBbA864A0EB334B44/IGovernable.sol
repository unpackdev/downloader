// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IGovernable {
    function gasToken() external view returns (address);
    function enableGasPromotion() external view returns (bool);
    function router() external view returns (address);
    
    function isMastermind(address _address) external view returns (bool);
    function isGovernor(address _address) external view returns (bool);
    function isPartner(address _address) external view returns (bool);
    function isUser(address _address) external view returns (bool);
}
