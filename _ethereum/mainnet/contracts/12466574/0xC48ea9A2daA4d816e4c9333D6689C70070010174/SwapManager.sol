// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./OracleSimple.sol";
import "./ISwapManager.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract SwapManager is ISwapManager {
    uint256 public constant override N_DEX = 2;
    /* solhint-disable */
    string[N_DEX] public DEXES = ["UNISWAP", "SUSHISWAP"];
    IUniswapV2Router02[N_DEX] public override ROUTERS = [
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F)
    ];
    IUniswapV2Factory[N_DEX] public FACTORIES = [
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f),
        IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac)
    ];
    /* solhint-enable */

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function bestOutputFixedInput(
        address _from,
        address _to,
        uint256 _amountIn
    )
        external
        view
        override
        returns (
            address[] memory path,
            uint256 amountOut,
            uint256 rIdx
        )
    {
        // Iterate through each DEX and evaluate the best output
        for (uint256 i = 0; i < N_DEX; i++) {
            (address[] memory tPath, uint256 tAmountOut) =
                bestPathFixedInput(_from, _to, _amountIn, i);
            if (tAmountOut > amountOut) {
                path = tPath;
                amountOut = tAmountOut;
                rIdx = i;
            }
        }
        return (path, amountOut, rIdx);
    }

    function bestPathFixedInput(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountOut) {
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        if (_from == WETH || _to == WETH) {
            amountOut = safeGetAmountsOut(_amountIn, path, _i)[path.length - 1];
            return (path, amountOut);
        }

        address[] memory pathB = new address[](3);
        pathB[0] = _from;
        pathB[1] = WETH;
        pathB[2] = _to;
        // is one of these WETH
        if (FACTORIES[_i].getPair(_from, _to) == address(0x0)) {
            // does a direct liquidity pair not exist?
            amountOut = safeGetAmountsOut(_amountIn, pathB, _i)[pathB.length - 1];
            path = pathB;
        } else {
            // if a direct pair exists, we want to know whether pathA or path B is better
            (path, amountOut) = comparePathsFixedInput(path, pathB, _amountIn, _i);
        }
    }

    function bestInputFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut
    )
        external
        view
        override
        returns (
            address[] memory path,
            uint256 amountIn,
            uint256 rIdx
        )
    {
        // Iterate through each DEX and evaluate the best input
        for (uint256 i = 0; i < N_DEX; i++) {
            (address[] memory tPath, uint256 tAmountIn) =
                bestPathFixedOutput(_from, _to, _amountOut, i);
            if (amountIn == 0 || tAmountIn < amountIn) {
                if (tAmountIn != 0) {
                    path = tPath;
                    amountIn = tAmountIn;
                    rIdx = i;
                }
            }
        }
    }

    function bestPathFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountIn) {
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        if (_from == WETH || _to == WETH) {
            amountIn = safeGetAmountsIn(_amountOut, path, _i)[0];
            return (path, amountIn);
        }

        address[] memory pathB = new address[](3);
        pathB[0] = _from;
        pathB[1] = WETH;
        pathB[2] = _to;

        // is one of these WETH
        if (FACTORIES[_i].getPair(_from, _to) == address(0x0)) {
            // does a direct liquidity pair not exist?
            amountIn = safeGetAmountsIn(_amountOut, pathB, _i)[0];
            path = pathB;
        } else {
            // if a direct pair exists, we want to know whether pathA or path B is better
            (path, amountIn) = comparePathsFixedOutput(path, pathB, _amountOut, _i);
        }
    }

    // Rather than let the getAmountsOut call fail due to low liquidity, we
    // catch the error and return 0 in place of the reversion
    // this is useful when we want to proceed with logic
    function safeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) public view override returns (uint256[] memory result) {
        try ROUTERS[_i].getAmountsOut(_amountIn, _path) returns (uint256[] memory amounts) {
            result = amounts;
        } catch {
            result = new uint256[](_path.length);
            result[0] = _amountIn;
        }
    }

    // Just a wrapper for the uniswap call
    // This can fail (revert) in two scenarios
    // 1. (path.length == 2 && insufficient reserves)
    // 2. (path.length > 2 and an intermediate pair has an output amount of 0)
    function unsafeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) public view override returns (uint256[] memory result) {
        result = ROUTERS[_i].getAmountsOut(_amountIn, _path);
    }

    // Rather than let the getAmountsIn call fail due to low liquidity, we
    // catch the error and return 0 in place of the reversion
    // this is useful when we want to proceed with logic (occurs when amountOut is
    // greater than avaiable reserve (ds-math-sub-underflow)
    function safeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) public view override returns (uint256[] memory result) {
        try ROUTERS[_i].getAmountsIn(_amountOut, _path) returns (uint256[] memory amounts) {
            result = amounts;
        } catch {
            result = new uint256[](_path.length);
            result[_path.length - 1] = _amountOut;
        }
    }

    // Just a wrapper for the uniswap call
    // This can fail (revert) in one scenario
    // 1. amountOut provided is greater than reserve for out currency
    function unsafeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) public view override returns (uint256[] memory result) {
        result = ROUTERS[_i].getAmountsIn(_amountOut, _path);
    }

    function comparePathsFixedInput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountIn,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountOut) {
        path = pathA;
        amountOut = safeGetAmountsOut(_amountIn, pathA, _i)[pathA.length - 1];
        uint256 bAmountOut = safeGetAmountsOut(_amountIn, pathB, _i)[pathB.length - 1];
        if (bAmountOut > amountOut) {
            path = pathB;
            amountOut = bAmountOut;
        }
    }

    function comparePathsFixedOutput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountOut,
        uint256 _i
    ) public view override returns (address[] memory path, uint256 amountIn) {
        path = pathA;
        amountIn = safeGetAmountsIn(_amountOut, pathA, _i)[0];
        uint256 bAmountIn = safeGetAmountsIn(_amountOut, pathB, _i)[0];
        if (bAmountIn < amountIn) {
            path = pathB;
            amountIn = bAmountIn;
        }
    }

    // TWAP Oracle Factory
    address[] private _oracles;
    mapping(address => bool) private _isOurs;
    // Pair -> period -> oracle
    mapping(address => mapping(uint256 => address)) private _oraclesByPair;

    function ours(address a) external view override returns (bool) {
        return _isOurs[a];
    }

    function oracleCount() external view override returns (uint256) {
        return _oracles.length;
    }

    function oracleAt(uint256 idx) external view override returns (address) {
        require(idx < _oracles.length, "Index exceeds list length");
        return _oracles[idx];
    }

    function getOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external view override returns (address) {
        return _oraclesByPair[FACTORIES[_i].getPair(_tokenA, _tokenB)][_period];
    }

    function createOrUpdateOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external override returns (address oracleAddr) {
        address pair = FACTORIES[_i].getPair(_tokenA, _tokenB);
        require(pair != address(0), "Nonexistant-pair");

        // If the oracle exists, try to update it
        if (_oraclesByPair[pair][_period] != address(0)) {
            OracleSimple(_oraclesByPair[pair][_period]).update();
            oracleAddr = _oraclesByPair[pair][_period];
            return oracleAddr;
        }

        // create new oracle contract
        oracleAddr = address(new OracleSimple(pair, _period));

        // remember oracle
        _oracles.push(oracleAddr);
        _isOurs[oracleAddr] = true;
        _oraclesByPair[pair][_period] = oracleAddr;

        // log creation
        emit OracleCreated(msg.sender, oracleAddr, _period);
    }

    function consultForFree(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    ) public view override returns (uint256 amountOut, uint256 lastUpdatedAt) {
        OracleSimple oracle =
            OracleSimple(_oraclesByPair[FACTORIES[_i].getPair(_from, _to)][_period]);
        lastUpdatedAt = oracle.blockTimestampLast();
        amountOut = oracle.consult(_from, _amountIn);
    }

    /// get the data we want and pay the gas to update
    function consult(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    )
        public
        override
        returns (
            uint256 amountOut,
            uint256 lastUpdatedAt,
            bool updated
        )
    {
        OracleSimple oracle =
            OracleSimple(_oraclesByPair[FACTORIES[_i].getPair(_from, _to)][_period]);
        lastUpdatedAt = oracle.blockTimestampLast();
        amountOut = oracle.consult(_from, _amountIn);
        try oracle.update() {
            updated = true;
        } catch {
            updated = false;
        }
    }

    function updateOracles() external override returns (uint256 updated, uint256 expected) {
        expected = _oracles.length;
        for (uint256 i = 0; i < expected; i++) {
            if (OracleSimple(_oracles[i]).update()) updated++;
        }
    }

    function updateOracles(address[] memory _oracleAddrs)
        external
        override
        returns (uint256 updated, uint256 expected)
    {
        expected = _oracleAddrs.length;
        for (uint256 i = 0; i < expected; i++) {
            if (OracleSimple(_oracleAddrs[i]).update()) updated++;
        }
    }
}
