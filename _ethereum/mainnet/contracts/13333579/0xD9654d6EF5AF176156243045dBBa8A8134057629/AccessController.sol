// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IAccessController.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";

contract AccessController is IAccessController, Ownable {
    address public constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address public AQUA_PRIMARY;
    address public lpFeeTaker;

    struct Pool {
        uint256 aquaPremium;
        bool status;
        bytes data;
    }

    mapping(address => Pool) public override whitelistedPools;

    modifier onlyPrimaryContract() {
        require(msg.sender == AQUA_PRIMARY, "Sushiswap Handler :: NOT AQUA PRIMARY");
        _;
    }

    event OwnerUpdated(address oldOwner, address newOwner);
    event PoolAdded(address pool, uint256 aquaPremium, bool status);
    event PoolPremiumUpdated(address pool, uint256 oldAquaPremium, uint256 newAquaPremium);
    event AquaPrimaryUpdated(address oldAddress, address newAddress);
    event PoolStatusUpdated(address pool, bool oldStatus, bool newStatus);

    constructor(address primary) {
        AQUA_PRIMARY = primary;
    }

    function addPools(
        address[] memory tokenA,
        address[] memory tokenB,
        uint256[] memory aquaPremium
    ) external override onlyOwner {
        require(
            (tokenA.length == tokenB.length) && (tokenB.length == aquaPremium.length),
            "Sushiswap Handler :: Invalid Args."
        );
        for (uint8 i = 0; i < tokenA.length; i++) {
            address pool = IUniswapV2Factory(SUSHI_FACTORY).getPair(tokenA[i], tokenB[i]);
            require(pool != address(0), "Sushiswap Handler :: Pool does not exist");
            whitelistedPools[pool] = Pool(aquaPremium[i], true, abi.encode(0));
            emit PoolAdded(pool, aquaPremium[i], true);
        }
    }

    function updateIndexFundAddress(address newAddr) external onlyOwner {
        lpFeeTaker = newAddr;
    }

    function updatePremiumOfPool(address pool, uint256 newAquaPremium) external override onlyOwner {
        emit PoolPremiumUpdated(pool, whitelistedPools[pool].aquaPremium, newAquaPremium);
        whitelistedPools[pool].aquaPremium = newAquaPremium;
    }

    function updatePoolStatus(address pool) external override onlyOwner {
        bool status = whitelistedPools[pool].status;
        emit PoolStatusUpdated(pool, status, !status);
        whitelistedPools[pool].status = !status;
    }

    function updatePrimary(address newAddress) external override onlyOwner {
        emit AquaPrimaryUpdated(AQUA_PRIMARY, newAddress);
        AQUA_PRIMARY = newAddress;
    }
}
