// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./AddressArrayLib.sol";
import "./TimelockCallable.sol";
import "./IAdapterBase.sol";
import "./IControllerLink.sol";

contract AdapterManager is TimelockCallable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressArrayLib for address[];

    bool public _paused;
    address public immutable userDatabase;
    uint256 public constant maxReservedBits = 16; //0 ~ 15 are reserved bits
    uint256 public maxIndex = maxReservedBits;
    EnumerableSet.AddressSet private registeredAdapters;
    mapping(address => bool) public suspendPermissions;
    mapping(address => uint256) public adaptersIndex;

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    event AdapterRegistered(address indexed adapter, string indexed identifier);
    event AdapterUnregistered(
        address indexed adapter,
        string indexed identifier
    );

    event CallOnAdapterExecuted(
        address vaultProxy,
        address indexed adapter,
        bytes4 indexed selector,
        bytes adpaterData
    );

    event SetPauseWhiteList(address partner, bool val);

    constructor(address _userDatabase, address _timelock)
        TimelockCallable(_timelock)
    {
        userDatabase = _userDatabase;
    }

    modifier onlyUser() {
        require(
            IControllerLink(userDatabase).existing(msg.sender),
            "!Cian user."
        );
        _;
    }

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    function _whenNotPaused() internal view {
        require(!_paused, "System is paused");
    }

    function execute(bytes calldata callArgs)
        external
        payable
        onlyUser
        whenNotPaused
        returns (bytes memory)
    {
        (address adapter, , bytes4 selector, bytes memory callData) = abi
            .decode(callArgs, (address, uint256, bytes4, bytes));
        require(adapterIsRegistered(adapter), "Adapter is not registered");
        return __callOnAdapter(msg.sender, adapter, selector, callData);
    }

    function __callOnAdapter(
        address account,
        address adapter,
        bytes4 selector,
        bytes memory callArgs
    ) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = adapter.call{
            value: msg.value
        }(abi.encodeWithSelector(selector, account, callArgs));

        emit CallOnAdapterExecuted(account, adapter, selector, callArgs);
        require(success, string(returnData));
        return returnData;
    }

    function registerAdapters(address[] calldata _adapters)
        external
        onlyTimelock
    {
        require(_adapters.length > 0, "Adapter cannot be empty");
        for (uint256 i; i < _adapters.length; i++) {
            require(_adapters[i] != address(0), "Adapter cannot be empty");
            require(
                !adapterIsRegistered(_adapters[i]),
                "Adapter already registered"
            );
            require(maxIndex < 256, "Out of length!");
            registeredAdapters.add(_adapters[i]);
            adaptersIndex[_adapters[i]] = maxIndex++;
            emit AdapterRegistered(
                _adapters[i],
                IAdapterBase(_adapters[i]).ADAPTER_NAME()
            );
        }
    }

    function unregisterAdapters(address[] calldata _adapters)
        external
        onlyTimelock
    {
        require(_adapters.length > 0, "Adapter cannot be empty");

        for (uint256 i; i < _adapters.length; i++) {
            require(_adapters[i] != address(0), "Adapter cannot be empty");

            require(
                adapterIsRegistered(_adapters[i]),
                "Adapter does not exist"
            );

            registeredAdapters.remove(_adapters[i]);
            adaptersIndex[_adapters[i]] = 0;
            emit AdapterUnregistered(
                _adapters[i],
                IAdapterBase(_adapters[i]).ADAPTER_NAME()
            );
        }
    }

    function adapterIsRegistered(address _adapter) public view returns (bool) {
        return registeredAdapters.contains(_adapter);
    }

    function adapterIsAvailable(address _adapter)
        external
        view
        whenNotPaused
        returns (bool)
    {
        return adapterIsRegistered(_adapter);
    }

    function getAdaptersLength() external view returns (uint256) {
        return registeredAdapters.length();
    }

    function getRegisteredAdapter(uint256 i)
        external
        view
        returns (address adapter)
    {
        return registeredAdapters.at(i);
    }

    function setPauseWhiteList(address partner, bool val)
        external
        onlyTimelock
    {
        require(suspendPermissions[partner] != val, "No change.");
        suspendPermissions[partner] = val;
        emit SetPauseWhiteList(partner, val);
    }

    function setPause(bool val) external {
        if (val == true) {
            require(
                suspendPermissions[msg.sender] || msg.sender == owner(),
                "verification failed."
            );
        } else {
            require(msg.sender == TIMELOCK_ADDRESS, "verification failed.");
        }
        _paused = val;
        if (_paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }
}
