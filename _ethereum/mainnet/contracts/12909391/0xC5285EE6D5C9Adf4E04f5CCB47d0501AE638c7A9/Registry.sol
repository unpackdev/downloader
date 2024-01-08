/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;

import "./Ownable.sol";
import "./Address.sol";
import "./Interfaces.sol";

/**
 * @title Registry
 * @notice Single source of truth for the addresses of all contracts int he protocol
 * @dev Should be governance-owned to allow contracts addresses to change by vote
 */
contract Registry is IRegistry, Ownable {

    /**
     * @notice Emitted when address for `key` contract is changed to `newValue`
     */
    event Registration(string indexed key, address newValue);

    /**
     * @notice USDC token contract
     */
    address public usdc;

    /**
     * @notice Compound protocol cUSDC pool
     */
    address public cUsdc;

    /**
     * @notice ESD stablecoin contract
     */
    address public dollar;

    /**
     * @notice ESDS governance token contract
     */
    address public stake;

    /**
     * @notice ESD reserve contract
     */
    address public reserve;

    /**
     * @notice ESD governor contract
     */
    address public governor;

    /**
     * @notice ESD timelock contract, owner for the protocol
     */
    address public timelock;

    /**
     * @notice Migration contract to bridge v1 assets with current system
     */
    address public migrator;

    // ADMIN

    /**
     * @notice Registers a new address for USDC
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setUsdc(address newValue) external validate(newValue) onlyOwner {
        usdc = newValue;
        emit Registration("USDC", newValue);
    }

    /**
     * @notice Registers a new address for cUSDC
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setCUsdc(address newValue) external validate(newValue) onlyOwner {
        cUsdc = newValue;
        emit Registration("CUSDC", newValue);
    }

    /**
     * @notice Registers a new address for ESD
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setDollar(address newValue) external validate(newValue) onlyOwner {
        dollar = newValue;
        emit Registration("DOLLAR", newValue);
    }

    /**
     * @notice Registers a new address for ESDS
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setStake(address newValue) external validate(newValue) onlyOwner {
        stake = newValue;
        emit Registration("STAKE", newValue);
    }

    /**
     * @notice Registers a new address for the reserve
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setReserve(address newValue) external validate(newValue) onlyOwner {
        reserve = newValue;
        emit Registration("RESERVE", newValue);
    }

    /**
     * @notice Registers a new address for the governor
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setGovernor(address newValue) external validate(newValue) onlyOwner {
        governor = newValue;
        emit Registration("GOVERNOR", newValue);
    }

    /**
     * @notice Registers a new address for the timelock
     * @dev Owner only - governance hook
     *      Does not automatically update the owner of all owned protocol contracts
     * @param newValue New address to register
     */
    function setTimelock(address newValue) external validate(newValue) onlyOwner {
        timelock = newValue;
        emit Registration("TIMELOCK", newValue);
    }

    /**
     * @notice Registers a new address for the v1 migration contract
     * @dev Owner only - governance hook
     * @param newValue New address to register
     */
    function setMigrator(address newValue) external validate(newValue) onlyOwner {
        migrator = newValue;
        emit Registration("MIGRATOR", newValue);
    }

    /**
     * @notice Ensures the newly supplied value is a deployed contract
     * @param newValue New address to validate
     */
    modifier validate(address newValue) {
        require(newValue != address(this), "Registry: this");
        require(Address.isContract(newValue), "Registry: not contract");

        _;
    }
}