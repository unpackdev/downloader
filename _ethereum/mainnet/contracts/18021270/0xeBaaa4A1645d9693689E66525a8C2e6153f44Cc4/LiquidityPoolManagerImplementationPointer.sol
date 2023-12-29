// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Address.sol";

import "./ILiquidityPoolManager.sol";

abstract contract LiquidityPoolManagerImplementationPointer is Ownable {
    ILiquidityPoolManager internal liquidityPoolManager;

    event UpdateLiquidityPoolManager(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyLiquidityPoolManager() {
        require(
            address(liquidityPoolManager) != address(0),
            "Implementations: LiquidityPoolManager is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(liquidityPoolManager),
            "Implementations: Not LiquidityPoolManager"
        );
        _;
    }

    function getLiquidityPoolManagerImplementation() public view returns (address) {
        return address(liquidityPoolManager);
    }

    function changeLiquidityPoolManagerImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(liquidityPoolManager);
        require(
            Address.isContract(newImplementation) ||
                newImplementation == address(0),
            "LiquidityPoolManager: You can only set 0x0 or a contract address as a new implementation"
        );
        liquidityPoolManager = ILiquidityPoolManager(newImplementation);
        emit UpdateLiquidityPoolManager(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}