// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

// Builds new Pools, logging their addresses and providing `isPool(address) -> (bool)`

import "./Ownable.sol";
import "./IPoolBuilder.sol";
import "./IPool.sol";
import "./Color.sol";
import "./IPausablePool.sol";
import "./IAddressRegistry.sol";

contract PoolFactory is Bronze, Ownable {
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    event LOG_BLABS(
        address indexed caller,
        address indexed blabs
    );

    address[] internal _pools;
    mapping(address=>bool) private _isPool;

    IPoolBuilder public _poolBuilder;
    address public _dynamicFee;

    IAddressRegistry public _repricerRegistry;

    constructor(
        address poolBuilder,
        address dynamicFee,
        address repricerRegistry
    ) public {
        setPoolBuilder(poolBuilder);
        setDynamicFee(dynamicFee);
        setRepricerRegistry(repricerRegistry);
    }

    function isPool(address b)
    external view returns (bool)
    {
        return _isPool[b];
    }

    function newPool(
        address derivativeVault,
        bytes32 repricerSymbol,
        uint baseFee,
        uint maxFee,
        uint feeAmp
    )
    external
    returns (IPool)
    {
        address bpool = _poolBuilder.buildPool(
            msg.sender,
            derivativeVault,
            _dynamicFee,
            _repricerRegistry.get(repricerSymbol),
            baseFee,
            maxFee,
            feeAmp
        );
        _pools.push(bpool);
        _isPool[bpool] = true;
        emit LOG_NEW_POOL(msg.sender, bpool);
        return IPool(bpool);
    }

    function setPoolBuilder(address poolBuilder) public onlyOwner {
        require(poolBuilder != address(0), "Pool builder");
        _poolBuilder = IPoolBuilder(poolBuilder);
    }

    function setDynamicFee(address dynamicFee) public onlyOwner {
        require(dynamicFee != address(0), "DynamicFee");
        _dynamicFee = dynamicFee;
    }

    function setRepricerRegistry(address repricerRegistry) public onlyOwner {
        require(repricerRegistry != address(0), "Repricer registry");
        _repricerRegistry = IAddressRegistry(repricerRegistry);
    }

    function setRepricer(address _value) external {
        _repricerRegistry.set(_value);
    }

    function pausePool(address _pool) public onlyOwner {
        IPausablePool(_pool).pause();
    }

    function unpausePool(address _pool) public onlyOwner {
        IPausablePool(_pool).unpause();
    }

    function collect(IPool pool)
        external onlyOwner
    {
        uint collected = IERC20(pool).balanceOf(address(this));
        bool xfer = pool.transfer(owner(), collected);
        require(xfer, "ERC20_FAILED");
    }

    function getPool(uint _index) external view returns(address) {
        return _pools[_index];
    }

    function getLastPoolIndex() external view returns(uint) {
        return _pools.length - 1;
    }

    function getAllPools() external view returns(address[] memory) {
        return _pools;
    }
}
