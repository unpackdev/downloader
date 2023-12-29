// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// libraries
import "./DataTypes.sol";

interface IUniversalLiquidatorRegistry {
    function getPath(address _sellToken, address _buyToken) external view returns (DataTypes.SwapInfo[] memory);

    function setPath(bytes32 _dex, address[] memory _paths) external;

    function setIntermediateToken(address[] memory _token) external;

    function addDex(bytes32 _name, address _address) external;

    function changeDexAddress(bytes32 _name, address _address) external;

    function getAllDexes() external view returns (bytes32[] memory);

    function getAllIntermediateTokens() external view returns (address[] memory);
}
