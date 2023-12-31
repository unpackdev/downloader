// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import "./LiquidityPool.sol";
import "./Tranche.sol";
import "./RestrictionManager.sol";
import "./Auth.sol";

interface RootLike {
    function escrow() external view returns (address);
}

interface LiquidityPoolFactoryLike {
    function newLiquidityPool(
        uint64 poolId,
        bytes16 trancheId,
        address currency,
        address trancheToken,
        address escrow,
        address investmentManager,
        address[] calldata wards_
    ) external returns (address);
}

/// @title  Liquidity Pool Factory
/// @dev    Utility for deploying new liquidity pool contracts
contract LiquidityPoolFactory is Auth {
    address public immutable root;

    constructor(address _root) {
        root = _root;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function newLiquidityPool(
        uint64 poolId,
        bytes16 trancheId,
        address currency,
        address trancheToken,
        address escrow,
        address investmentManager,
        address[] calldata wards_
    ) public auth returns (address) {
        LiquidityPool liquidityPool =
            new LiquidityPool(poolId, trancheId, currency, trancheToken, escrow, investmentManager);

        liquidityPool.rely(root);
        for (uint256 i = 0; i < wards_.length; i++) {
            liquidityPool.rely(wards_[i]);
        }
        liquidityPool.deny(address(this));
        return address(liquidityPool);
    }
}

interface TrancheTokenFactoryLike {
    function newTrancheToken(
        uint64 poolId,
        bytes16 trancheId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address[] calldata restrictionManagerWards
    ) external returns (address);
}

/// @title  Tranche Token Factory
/// @dev    Utility for deploying new tranche token contracts
///         Ensures the addresses are deployed at a deterministic address
///         based on the pool id and tranche id.
contract TrancheTokenFactory is Auth {
    address public immutable root;

    constructor(address _root, address deployer) {
        root = _root;
        wards[deployer] = 1;
        emit Rely(deployer);
    }

    function newTrancheToken(
        uint64 poolId,
        bytes16 trancheId,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address[] calldata trancheTokenWards
    ) public auth returns (address) {
        // Salt is hash(poolId + trancheId)
        // same tranche token address on every evm chain
        bytes32 salt = keccak256(abi.encodePacked(poolId, trancheId));

        TrancheToken token = new TrancheToken{salt: salt}(decimals);

        token.file("name", name);
        token.file("symbol", symbol);

        token.rely(root);
        for (uint256 i = 0; i < trancheTokenWards.length; i++) {
            token.rely(trancheTokenWards[i]);
        }
        token.deny(address(this));

        return address(token);
    }
}

interface RestrictionManagerFactoryLike {
    function newRestrictionManager(uint8 restrictionSet, address token, address[] calldata restrictionManagerWards)
        external
        returns (address);
}

/// @title  Restriction Manager Factory
/// @dev    Utility for deploying new restriction manager contracts
contract RestrictionManagerFactory is Auth {
    address immutable root;

    constructor(address _root) {
        root = _root;

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function newRestrictionManager(uint8, address token, address[] calldata restrictionManagerWards)
        public
        auth
        returns (address)
    {
        RestrictionManager restrictionManager = new RestrictionManager(token);

        restrictionManager.updateMember(RootLike(root).escrow(), type(uint256).max);

        restrictionManager.rely(root);
        restrictionManager.rely(token);
        for (uint256 i = 0; i < restrictionManagerWards.length; i++) {
            restrictionManager.rely(restrictionManagerWards[i]);
        }
        restrictionManager.deny(address(this));

        return (address(restrictionManager));
    }
}
