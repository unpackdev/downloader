// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./Ownable.sol";
import "./ICentaurFactory.sol";
import "./ICentaurPool.sol";
import "./ICentaurRouter.sol";
import "./ICloneFactory.sol";
import "./CentaurSettlement.sol";
import "./CentaurRouter.sol";
import "./CentaurPool.sol";

contract CentaurFactory is ICentaurFactory, Ownable {
	uint public override poolFee;

    address public override poolLogic;
	address public override cloneFactory;
    address public override settlement;
    address payable public override router;

    // Base token => Pool
    mapping(address => address) public override getPool;
    address[] public override allPools;

    event PoolCreated(address indexed baseToken, address pool, uint);

    constructor(address _poolLogic, address _cloneFactory, address _WETH) public {
        poolLogic = _poolLogic;
        cloneFactory = _cloneFactory;

        // Deploy CentaurSettlement
        CentaurSettlement settlementContract = new CentaurSettlement(address(this), 3 minutes);
        settlement = address(settlementContract);


        // Deploy CentaurRouter
        CentaurRouter routerContract = new CentaurRouter(address(this), _WETH);
        router = address(routerContract);

        // Default poolFee = 0.2%
        poolFee = 200000000000000000;
    }

    function allPoolsLength() external override view returns (uint) {
        return allPools.length;
    }

    function isValidPool(address _pool) external view override returns (bool) {
        for (uint i = 0; i < allPools.length; i++) {
            if (allPools[i] == _pool) {
                return true;
            }
        }

        return false;
    }

    function createPool(address _baseToken, address _oracle, uint _liquidityParameter) external onlyOwner override returns (address pool) {
    	require(_baseToken != address(0) && _oracle != address(0), 'CentaurSwap: ZERO_ADDRESS');
    	require(getPool[_baseToken] == address(0), 'CentaurSwap: POOL_EXISTS');

    	pool = ICloneFactory(cloneFactory).createClone(poolLogic);
    	ICentaurPool(pool).init(
            address(this),
            _baseToken,
            _oracle,
            _liquidityParameter
        );

    	getPool[_baseToken] = pool;
        allPools.push(pool);

        emit PoolCreated(_baseToken, pool, allPools.length);
    }

    function addPool(address _pool) external onlyOwner override {
        address baseToken = ICentaurPool(_pool).baseToken();
        require(baseToken != address(0), 'CentaurSwap: ZERO_ADDRESS');
        require(getPool[baseToken] == address(0), 'CentaurSwap: POOL_EXISTS');

        getPool[baseToken] = _pool;
        allPools.push(_pool);
    }

    function removePool(address _pool) external onlyOwner override {
        address baseToken = ICentaurPool(_pool).baseToken();
        require(baseToken != address(0), 'CentaurSwap: ZERO_ADDRESS');
        require(getPool[baseToken] != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        getPool[baseToken] = address(0);
        for (uint i = 0; i < allPools.length; i++) {
            if (allPools[i] == _pool) {
                allPools[i] = allPools[allPools.length - 1];
                allPools.pop();
                break;
            }
        }
    }

    // Pool Functions
    function setPoolTradeEnabled(address _pool, bool _tradeEnabled) public onlyOwner override {
        ICentaurPool(_pool).setTradeEnabled(_tradeEnabled);
    }

    function setPoolDepositEnabled(address _pool, bool _depositEnabled) public onlyOwner override {
        ICentaurPool(_pool).setDepositEnabled(_depositEnabled);
    }

    function setPoolWithdrawEnabled(address _pool, bool _withdrawEnabled) public onlyOwner override {
        ICentaurPool(_pool).setWithdrawEnabled(_withdrawEnabled);
    }

    function setPoolLiquidityParameter(address _pool, uint _liquidityParameter) public onlyOwner override {
        ICentaurPool(_pool).setLiquidityParameter(_liquidityParameter);
    }

    function setAllPoolsTradeEnabled(bool _tradeEnabled) external onlyOwner override {
        for (uint i = 0; i < allPools.length; i++) {
            setPoolTradeEnabled(allPools[i], _tradeEnabled);
        }
    }

    function setAllPoolsDepositEnabled(bool _depositEnabled) external onlyOwner override {
        for (uint i = 0; i < allPools.length; i++) {
            setPoolDepositEnabled(allPools[i], _depositEnabled);
        }
    }

    function setAllPoolsWithdrawEnabled(bool _withdrawEnabled) external onlyOwner override {
        for (uint i = 0; i < allPools.length; i++) {
            setPoolWithdrawEnabled(allPools[i], _withdrawEnabled);
        }
    }

    function emergencyWithdrawFromPool(address _pool, address _token, uint _amount, address _to) external onlyOwner override {
        ICentaurPool(_pool).emergencyWithdraw(_token, _amount, _to);
    }

    // Router Functions
    function setRouterOnlyEOAEnabled(bool _onlyEOAEnabled) external onlyOwner override {
        CentaurRouter(router).setOnlyEOAEnabled(_onlyEOAEnabled);
    }

    function setRouterContractWhitelist(address _address, bool _whitelist) external onlyOwner override {
        if (_whitelist) {
            CentaurRouter(router).addContractToWhitelist(_address);
        } else {
            CentaurRouter(router).removeContractFromWhitelist(_address);
        }
    }

    // Settlement Functions
    function setSettlementDuration(uint _duration) external onlyOwner override {
        CentaurSettlement(settlement).setSettlementDuration(_duration);
    }

    // Helper Functions
    function setPoolFee(uint _poolFee) external onlyOwner override {
        poolFee = _poolFee;
    }

    function setPoolLogic(address _poolLogic) external onlyOwner override {
        poolLogic = _poolLogic;
    }

    function setCloneFactory(address _cloneFactory) external onlyOwner override {
        cloneFactory = _cloneFactory;
    }

    function setSettlement(address _settlement) external onlyOwner override {
        settlement = _settlement;
    }

    function setRouter(address payable _router) external onlyOwner override {
        router = _router;
    }
}