// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;
import "./DataTypes.sol";
import "./IPool.sol";


interface IAssetRegistry {
    function assets(bytes6) external view returns (address);
}

interface ISeriesRegistry {
    function series(bytes6) external view returns (DataTypes.Series memory);
}

interface IOracleRegistry {
    function spotOracles(bytes6, bytes6) external view returns (DataTypes.SpotOracle memory);
}

interface IJoinRegistry {
    function joins(bytes6) external view returns (IJoin);
}

interface IPoolRegistry {
    function pools(bytes6) external view returns (IPool);
}