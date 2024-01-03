// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./IAddressRegistry.sol";
import "./AddressRegistry.sol";

// AddressRegistry Owner which enforces a 48hr timelock on address changes
contract AddressRegistryManager is Ownable {
    event TimelockInitialized(address indexed user, bytes32 method);

    bytes32 private constant AVALANCHE_KEY = "AVALANCHE";
    bytes32 private constant LGE_KEY = "LGE";
    bytes32 private constant LODGE_KEY = "LODGE";
    bytes32 private constant LOYALTY_KEY = "LOYALTY";
    bytes32 private constant OWNERSHIP_KEY = "OWNERSHIP";
    bytes32 private constant PWDR_KEY = "PWDR";
    bytes32 private constant PWDR_POOL_KEY = "PWDR_POOL";
    bytes32 private constant SLOPES_KEY = "SLOPES";
    bytes32 private constant SNOW_PATROL_KEY = "SNOW_PATROL";
    bytes32 private constant TREASURY_KEY = "TREASURY";
    bytes32 private constant UNISWAP_ROUTER_KEY = "UNISWAP_ROUTER";
    bytes32 private constant WETH_KEY = "WETH";
    bytes32 private constant VAULT_KEY = "VAULT";

    uint256 private constant TIMELOCK_PERIOD = 48 hours;
    address internal addressRegistry;
    mapping(bytes32 => uint256) public accessTimestamps;

    constructor(address _addressRegistry) public {
        addressRegistry = _addressRegistry;
    }

    function setTimelock(bytes32 method) private returns (bool) {
        if (accessTimestamps[method] == 0) {
            accessTimestamps[method] = block.timestamp + getTimelockPeriod();
            emit TimelockInitialized(msg.sender, method);
            return false;
        } else if (block.timestamp < accessTimestamps[method]) {
            revert("Timelock period has not concluded");
        } else {
            accessTimestamps[method] = 0;
            return true;
        }
    }

    function returnOwnership() public onlyOwner {
        if (setTimelock(OWNERSHIP_KEY)) {
            AddressRegistry registry = AddressRegistry(addressRegistry);
            registry.transferOwnership(msg.sender);
        }
    }

    function setAvalanche(address _address) public onlyOwner {
        if (setTimelock(AVALANCHE_KEY)) {
            IAddressRegistry(addressRegistry).setAvalanche(_address);
        }
    }

    function setLGE(address _address) public onlyOwner {
        if (setTimelock(LGE_KEY)) {
            IAddressRegistry(addressRegistry).setLGE(_address);
        }
    }

    function setLodge(address _address) public onlyOwner {
        if (setTimelock(LODGE_KEY)) {
            IAddressRegistry(addressRegistry).setLodge(_address);
        }
    }

    function setLoyalty(address _address) public onlyOwner {
        if (setTimelock(LOYALTY_KEY)) {
            IAddressRegistry(addressRegistry).setLoyalty(_address);
        }
    }

    function setPwdr(address _address) public onlyOwner {
        if (setTimelock(PWDR_KEY)) {
            IAddressRegistry(addressRegistry).setPwdr(_address);
        }
    }

    function setPwdrPool(address _address) public onlyOwner {
        if (setTimelock(PWDR_POOL_KEY)) {
            IAddressRegistry(addressRegistry).setPwdrPool(_address);
        }
    }

    function setSlopes(address _address) public onlyOwner {
        if (setTimelock(SLOPES_KEY)) {
            IAddressRegistry(addressRegistry).setSlopes(_address);
        }
    }

    function setSnowPatrol(address _address) public onlyOwner {
        if (setTimelock(SNOW_PATROL_KEY)) {
            IAddressRegistry(addressRegistry).setSnowPatrol(_address);
        }
    }

    function setTreasury(address _address) public onlyOwner {
        if (setTimelock(TREASURY_KEY)) {
            IAddressRegistry(addressRegistry).setTreasury(_address);
        }
    }

    function setUniswapRouter(address _address) public onlyOwner {
        if (setTimelock(UNISWAP_ROUTER_KEY)) {
            IAddressRegistry(addressRegistry).setUniswapRouter(_address);
        }
    }

    function setVault(address _address) public onlyOwner {
        if (setTimelock(VAULT_KEY)) {
            IAddressRegistry(addressRegistry).setVault(_address);
        }
    }

    function setWeth(address _address) public onlyOwner {
        if (setTimelock(WETH_KEY)) {
            IAddressRegistry(addressRegistry).setWeth(_address);
        }
    }

    function getTimelockPeriod() public virtual pure returns (uint256) {
        return TIMELOCK_PERIOD;
    }
}