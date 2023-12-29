// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// imported contracts and libraries
import "./Ownable.sol";

// interfaces
import "./IUniversalLiquidatorRegistry.sol";

// libraries
import "./DataTypes.sol";
import "./Errors.sol";

// constants and types
import "./ULRegistry.sol";

contract UniversalLiquidatorRegistry is Ownable, IUniversalLiquidatorRegistry, ULRegistryStorage {
    function getPath(address _sellToken, address _buyToken) public view override returns (DataTypes.SwapInfo[] memory) {
        if (paths[_sellToken][_buyToken].dex != bytes32(0)) {
            DataTypes.SwapInfo[] memory retPaths = new DataTypes.SwapInfo[](1);
            retPaths[0] = DataTypes.SwapInfo(dexesInfo[paths[_sellToken][_buyToken].dex], paths[_sellToken][_buyToken].paths);
            return retPaths;
        }

        for (uint256 idx; idx < _intermediateTokens.length;) {
            if (
                paths[_sellToken][_intermediateTokens[idx]].dex != bytes32(0)
                    && paths[_intermediateTokens[idx]][_buyToken].dex != bytes32(0)
            ) {
                // found the intermediateToken and intermediateDex
                DataTypes.SwapInfo[] memory retPaths = new DataTypes.SwapInfo[](
                    2
                );
                retPaths[0] = DataTypes.SwapInfo(
                    dexesInfo[paths[_sellToken][_intermediateTokens[idx]].dex], paths[_sellToken][_intermediateTokens[idx]].paths
                );
                retPaths[1] = DataTypes.SwapInfo(
                    dexesInfo[paths[_intermediateTokens[idx]][_buyToken].dex], paths[_intermediateTokens[idx]][_buyToken].paths
                );
                return retPaths;
            }
            unchecked {
                ++idx;
            }
        }
        revert Errors.PathsNotExist();
    }

    function setPath(bytes32 _dex, address[] memory _paths) external override onlyOwner {
        // dex should exist
        if (!_dexExists(_dex)) revert Errors.DexDoesNotExist();
        // path could also be an empty array
        if (_paths.length < 2) revert Errors.InvalidLength();

        // path can also be empty
        paths[_paths[0]][_paths[_paths.length - 1]] = DataTypes.PathInfo(_dex, _paths);
    }

    function setIntermediateToken(address[] memory _token) public override onlyOwner {
        _intermediateTokens = _token;
    }

    function addDex(bytes32 _name, address _dex) public override onlyOwner {
        if (_dexExists(_name)) revert Errors.DexExists();
        dexesInfo[_name] = _dex;
        _allDexes.push(_name);
    }

    function changeDexAddress(bytes32 _name, address _dex) public override onlyOwner {
        if (!_dexExists(_name)) revert Errors.DexDoesNotExist();
        dexesInfo[_name] = _dex;
    }

    function getAllDexes() public view override returns (bytes32[] memory) {
        uint256 totalDexes = 0;

        for (uint256 idx = 0; idx < _allDexes.length;) {
            if (dexesInfo[_allDexes[idx]] != address(0)) {
                totalDexes++;
            }
            unchecked {
                ++idx;
            }
        }

        bytes32[] memory retDexes = new bytes32[](totalDexes);
        uint256 retIdx = 0;

        for (uint256 idx; idx < _allDexes.length;) {
            if (dexesInfo[_allDexes[idx]] != address(0)) {
                retDexes[retIdx] = _allDexes[idx];
                retIdx++;
            }
            unchecked {
                ++idx;
            }
        }

        return retDexes;
    }

    function getAllIntermediateTokens() public view override returns (address[] memory) {
        return _intermediateTokens;
    }

    function _dexExists(bytes32 _name) internal view returns (bool) {
        return dexesInfo[_name] != address(0);
    }
}
