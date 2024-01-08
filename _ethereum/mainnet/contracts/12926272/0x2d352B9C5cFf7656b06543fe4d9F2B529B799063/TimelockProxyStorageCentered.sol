// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "./Proxy.sol";
import "./UnstructuredStorageWithTimelock.sol";
import "./IStorageV1.sol";

/**
    TimelockProxyStorageCentered is a proxy implementation that timelocks the implementation switch.
    The owner is stored in the system storage (StorageV1Upgradeable) and not in the contract storage
    of the proxy.
*/
contract TimelockProxyStorageCentered is Proxy {
    using UnstructuredStorageWithTimelock for bytes32;

    // bytes32(uint256(keccak256("eip1967.proxy.systemStorage")) - 1
    bytes32 private constant _SYSTEM_STORAGE_SLOT =
        0xf7ce9e33978bd6e766998cbee51134930bc6e39dc5dcd8f992c5b743b1c6d698;

    // bytes32(uint256(keccak256("eip1967.proxy.timelock")) - 1
    bytes32 private constant _TIMELOCK_SLOT =
        0xc6fb23975d74c7743b6d6d0c1ad9dc3911bc8a4a970ec5723a30579b45472009;

    // _IMPLEMENTATION_SLOT, value cloned from UpgradeableProxy
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event UpgradeScheduled(address indexed implementation, uint256 activeTime);
    event Upgraded(address indexed implementation);

    event TimelockUpdateScheduled(uint256 newTimelock, uint256 activeTime);
    event TimelockUpdated(uint256 newTimelock);

    constructor(
        address _logic,
        address _storage,
        uint256 _timelock,
        bytes memory _data
    ) {
        assert(
            _SYSTEM_STORAGE_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.systemStorage")) - 1)
        );
        assert(
            _TIMELOCK_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.timelock")) - 1)
        );
        assert(
            _IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _SYSTEM_STORAGE_SLOT.setAddress(_storage);
        _TIMELOCK_SLOT.setUint256(_timelock);
        _IMPLEMENTATION_SLOT.setAddress(_logic);
        if (_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }

    // Using Transparent proxy pattern to avoid collision attacks
    // see OpenZeppelin's `TransparentUpgradeableProxy`
    modifier adminPriviledged() {
        require(
            msg.sender == IStorageV1(_systemStorage()).governance() ||
            IStorageV1(_systemStorage()).isAdmin(msg.sender), 
            "msg.sender is not adminPriviledged"
        );
        _;
    }

    modifier requireTimelockPassed(bytes32 _slot) {
        require(
            block.timestamp >= _slot.scheduledTime(),
            "Timelock has not passed yet"
        );
        _;
    }

    function proxyScheduleImplementationUpdate(address targetAddress)
        public
        adminPriviledged
    {
        bytes32 _slot = _IMPLEMENTATION_SLOT;
        uint256 activeTime = block.timestamp + _TIMELOCK_SLOT.fetchUint256();
        (_slot.scheduledContentSlot()).setAddress(targetAddress);
        (_slot.scheduledTimeSlot()).setUint256(activeTime);

        emit UpgradeScheduled(targetAddress, activeTime);
    }

    function proxyScheduleTimelockUpdate(uint256 newTimelock) public adminPriviledged {
        uint256 activeTime = block.timestamp + _TIMELOCK_SLOT.fetchUint256();
        (_TIMELOCK_SLOT.scheduledContentSlot()).setUint256(newTimelock);
        (_TIMELOCK_SLOT.scheduledTimeSlot()).setUint256(activeTime);

        emit TimelockUpdateScheduled(newTimelock, activeTime);
    }

    function proxyUpgradeTimelock()
        public
        adminPriviledged
        requireTimelockPassed(_TIMELOCK_SLOT)
    {
        uint256 newTimelock =
            (_TIMELOCK_SLOT.scheduledContentSlot()).fetchUint256();
        _TIMELOCK_SLOT.setUint256(newTimelock);
        emit TimelockUpdated(newTimelock);
    }

    function proxyUpgradeImplementation()
        public
        adminPriviledged
        requireTimelockPassed(_IMPLEMENTATION_SLOT)
    {
        address newImplementation =
            (_IMPLEMENTATION_SLOT.scheduledContentSlot()).fetchAddress();
        _IMPLEMENTATION_SLOT.setAddress(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _implementation() internal view override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    function _systemStorage() internal view returns (address systemStorage) {
        bytes32 slot = _SYSTEM_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            systemStorage := sload(slot)
        }
    }
}
