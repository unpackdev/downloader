// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeManager {
    
    function transferERC20(
        uint256 _bridgeId,
        uint256 _destinationNetworkId,
        address _tokenIn,
        uint256 _amount,
        address _destinationAddress,
        bytes calldata _data
    ) external;
    
    function getBridgeAddress(uint256 _bridgeId) external view returns (address);
    
    function isNetworkSupported(uint256 _bridgeId, uint256 _networkId) external view returns (bool);
    
}
