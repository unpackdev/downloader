// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

import "./SafeMath.sol";
import "./Address.sol";
contract UpgradeabilityProxy {

    using SafeMath for uint;

    bytes32 private constant proxyOwnerPosition = keccak256("proxy.owner");
    bytes32 private constant newProxyOwnerPosition = keccak256("proxy.newOwner");
    bytes32 private constant implementationPosition = keccak256("proxy.implementation");
    bytes32 private constant newImplementationPosition = keccak256("proxy.newImplementation");
    bytes32 private constant timelockPosition = keccak256("proxy.timelock");
    uint public constant timelockPeriod = 21600; // 6 hours

    constructor (address _proxyOwner, address implementation_, bytes memory initializationData, bool forceCall) {
        _setProxyOwner(_proxyOwner);
        _setImplementation(implementation_);
        if (initializationData.length > 0 || forceCall) {
            Address.functionDelegateCall(_implementation(), initializationData);
        }
    }


    modifier ifProxyOwner() {
        if (msg.sender == _proxyOwner()) {
            _;
        } else {
            _delegate(_implementation());
        }
    }

    function _proxyOwner() internal view returns (address proxyOwner_) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            proxyOwner_ := sload(position)
        }
    }

    function proxyOwner() public ifProxyOwner returns (address proxyOwner_) {
        return _proxyOwner();
    }

    function newProxyOwner() public ifProxyOwner returns (address _newProxyOwner) {
        bytes32 position = newProxyOwnerPosition;
        assembly {
            _newProxyOwner := sload(position)
        }
    }

    function _setProxyOwner(address _newProxyOwner) private {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    function setNewProxyOwner(address _newProxyOwner) public ifProxyOwner {
        /* require(msg.sender == proxyOwner(), "UpgradeabilityProxy: only current proxy owner can set new proxy owner."); */
        bytes32 position = newProxyOwnerPosition; 
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    function transferProxyOwnership() public {
        address _newProxyOwner = newProxyOwner();
        if (msg.sender == _newProxyOwner) {
            _setProxyOwner(_newProxyOwner);
        } else {
            _delegate(_implementation());
        }
    }

    function _implementation() private view returns (address implementation_) {
        bytes32 position = implementationPosition;
        assembly {
            implementation_ := sload(position)
        }
    }
    

    function implementation() public ifProxyOwner returns (address implementation_) {
        return _implementation();
    }

    function newImplementation() public ifProxyOwner returns (address _newImplementation) {
        bytes32 position = newImplementationPosition;
        assembly {
            _newImplementation := sload(position)
        }
    } 

    function timelock() public ifProxyOwner returns (uint _timelock) {
        bytes32 position = timelockPosition;
        assembly {
            _timelock := sload(position)
        }
    }

    function _setTimelock(uint newTimelock) private {
        bytes32 position = timelockPosition;
        assembly {
            sstore(position, newTimelock)
        }
    }

    function _setImplementation(address _newImplementation) private {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }


    function setNewImplementation(address _newImplementation) public ifProxyOwner {
        /* require(msg.sender == proxyOwner(), "UpgradeabilityProxy: only current proxy owner can set new implementation."); */
        bytes32 position = newImplementationPosition; 
        assembly {
            sstore(position, _newImplementation)
        }
        uint newTimelock = block.timestamp.add(timelockPeriod);
        _setTimelock(newTimelock);
    }

    function transferImplementation() public ifProxyOwner {
        /* require(msg.sender == proxyOwner(), "UpgradeabilityProxy: only proxy owner can transfer implementation."); */
        require(block.timestamp >= timelock(), "UpgradeabilityProxy: cannot transfer implementation yet.");
        _setImplementation(newImplementation());
    }

    function _delegate(address _implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())


            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }


    fallback () external payable virtual {
        _delegate(implementation());
    }


    receive () external payable virtual {
        _delegate(implementation());
    }
}