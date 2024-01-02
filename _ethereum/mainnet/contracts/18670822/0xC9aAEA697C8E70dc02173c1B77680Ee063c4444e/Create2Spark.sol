// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./IAaveIncentivesController.sol";
import { IPool }                     from 'aave-v3-core-private/contracts/interfaces/IPool.sol';
import { IPoolAddressesProvider }    from 'aave-v3-core-private/contracts/interfaces/IPoolAddressesProvider.sol';
import { IInitializableAToken }      from 'aave-v3-core-private/contracts/interfaces/IInitializableAToken.sol';
import { IInitializableDebtToken }   from 'aave-v3-core-private/contracts/interfaces/IInitializableDebtToken.sol';

// Function doesn't exist in interfaces and it doesn't make sense to import the Pool/PoolConfigurator contracts
interface IInitializableAddressesProvider {
    function initialize(IPoolAddressesProvider provider) external;
}

contract Create2Spark {

    IPoolAddressesProvider public immutable poolAddressesProvider;
    IPool                  public immutable pool;

    constructor(address _poolAddressesProvider) {
        poolAddressesProvider = IPoolAddressesProvider(_poolAddressesProvider);
        pool                  = IPool(poolAddressesProvider.getPool());
    }

    function deploy(bytes32 salt, bytes memory creationCode) public payable returns (address addr) {
        require(creationCode.length != 0, "empty code");

        assembly {
            addr := create2(callvalue(), add(creationCode, 0x20), mload(creationCode), salt)
        }

        require(addr != address(0), "failed deployment");
    }

    function deployPool(bytes32 salt, bytes memory creationCode) external payable returns (address addr) {
        addr = deploy(salt, creationCode);
        IInitializableAddressesProvider(addr).initialize(poolAddressesProvider);
    }

    function deployPoolConfigurator(bytes32 salt, bytes memory creationCode) external payable returns (address addr) {
        addr = deploy(salt, creationCode);
        IInitializableAddressesProvider(addr).initialize(poolAddressesProvider);
    }

    function deployAToken(bytes32 salt, bytes memory creationCode) external payable returns (address addr) {
        addr = deploy(salt, creationCode);
        IInitializableAToken(addr).initialize(pool, address(0), address(0), IAaveIncentivesController(address(0)), 0, "SPTOKEN_IMPL", "SPTOKEN_IMPL", "");
    }

    function deployStableDebtToken(bytes32 salt, bytes memory creationCode) external payable returns (address addr) {
        addr = deploy(salt, creationCode);
        IInitializableDebtToken(addr).initialize(pool, address(0), IAaveIncentivesController(address(0)), 0, "STABLE_DEBT_TOKEN_IMPL", "STABLE_DEBT_TOKEN_IMPL", "");
    }

    function deployVariableDebtToken(bytes32 salt, bytes memory creationCode) external payable returns (address addr) {
        addr = deploy(salt, creationCode);
        IInitializableDebtToken(addr).initialize(pool, address(0), IAaveIncentivesController(address(0)), 0, "VARIABLE_DEBT_TOKEN_IMPL", "VARIABLE_DEBT_TOKEN_IMPL", "");
    }

    function computeAddress(bytes32 salt, bytes32 creationCodeHash) external view returns (address addr) {
        address contractAddress = address(this);
        
        assembly {
            let ptr := mload(0x40)

            mstore(add(ptr, 0x40), creationCodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, contractAddress)
            let start := add(ptr, 0x0b)
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }

}