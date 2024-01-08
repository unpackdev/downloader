// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";

abstract contract LpTokensStorage {
    using SafeMath for uint256;

    // Address of the ERC20 Token contract.
    IERC20 _pact;
    constructor(IERC20 pact_) public {
        require(address(pact_) != address(0), "LpTokensStorage::constructor: pact_ - is empty");
        _pact = pact_;
    }

    function pact() public view returns (address) {
        return address(_pact);
    }

    struct PoolInfo {
        uint256 id;
        IUniswapV2Pair lpToken;    // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. ERC20s to distribute per block.
    }
    // poolId => PoolInfo
    PoolInfo[] _poolInfo;
    uint256 _poolInfoCount = 0;
    mapping (address => bool) _lpTokensList;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 _totalAllocPoint = 0;


    function poolInfoCount() public view returns (uint256) {
        return _poolInfoCount;
    }
    function poolInfo(uint256 poolId) public view returns (PoolInfo memory) {
        return _poolInfo[poolId];
    }
    function totalAllocPoint() public view returns (uint256) {
        return _totalAllocPoint;
    }

    function _addLpToken(uint256 allocPoint, IUniswapV2Pair lpToken) internal {
        require(_lpTokensList[address(lpToken)] == false, "_addLpToken: LP Token exists");

        _totalAllocPoint = _totalAllocPoint.add(allocPoint);

        _poolInfo.push(PoolInfo({
            id: _poolInfoCount,
            lpToken: lpToken,
            allocPoint: allocPoint
        }));
        ++_poolInfoCount;
        _lpTokensList[address(lpToken)] = true;
    }

    function _updateLpToken(uint256 poolId, uint256 allocPoint) internal {
        require(poolId < _poolInfoCount, "_updateLpToken: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];

        _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(allocPoint);
        pool.allocPoint = allocPoint;
    }
}