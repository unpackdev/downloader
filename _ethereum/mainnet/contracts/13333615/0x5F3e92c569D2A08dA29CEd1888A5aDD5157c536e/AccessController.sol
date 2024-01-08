// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IAccessController.sol";
import "./Ownable.sol";
import "./IUniswapV3Factory.sol";

contract AccessController is IAccessController, Ownable {
    address public constant POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address public AQUA_PRIMARY;
    address public INDEX_FUND;

    mapping(address => Pool) public override whitelistedPools;

    struct Pool {
        uint256 aquaPremium;
        bool status;
        bytes data;
    }

    modifier onlyAquaPrimary() {
        require(msg.sender == AQUA_PRIMARY, "UniswapHandler :: Not Aqua Primary.");
        _;
    }

    event PoolAdded(address pool, uint256 aquaPremium, bool status);
    event PoolPremiumUpdated(address pool, uint256 oldAquaPremium, uint256 newAquaPremium);
    event PoolStatusUpdated(address pool, bool oldStatus, bool newStatus);

    constructor(address index) {
        INDEX_FUND = index;
    }

    function addPools(
        address[] calldata tokenA,
        address[] calldata tokenB,
        uint256[] calldata aquaPremium,
        uint24[] calldata fee
    ) external override onlyOwner {
        require(tokenA.length == tokenB.length && aquaPremium.length == fee.length, "Uniswap Handler :: Invalid Args.");
        for (uint8 i = 0; i < tokenA.length; i++) {
            address pool = IUniswapV3Factory(UNISWAP_V3_FACTORY).getPool(tokenA[i], tokenB[i], fee[i]);
            require(pool != address(0), "Uniswap handler :: Pool does not exist");
            whitelistedPools[pool] = Pool(aquaPremium[i], true, abi.encode(fee[i]));
            emit PoolAdded(pool, aquaPremium[i], true);
        }
    }

    function updateIndexFundAddress(address newAddr) external onlyOwner {
        INDEX_FUND = newAddr;
    }

    function updatePremiumOfPool(address pool, uint256 newAquaPremium) external override onlyOwner {
        emit PoolPremiumUpdated(pool, whitelistedPools[pool].aquaPremium, newAquaPremium);
        whitelistedPools[pool].aquaPremium = newAquaPremium;
    }

    function updatePrimary(address newAddress) external override onlyOwner {
        AQUA_PRIMARY = newAddress;
    }

    function updatePoolStatus(address pool) external override onlyOwner {
        bool status = whitelistedPools[pool].status;
        emit PoolStatusUpdated(pool, status, !status);
        whitelistedPools[pool].status = !status;
    }
}
