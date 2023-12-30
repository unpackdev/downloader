pragma solidity ^0.6.0;

import "./DSProxyInterface.sol";

/// @title Implements logic for calling MCDSaverProxy always from same contract
contract MCDMonitorProxy {

    uint public CHANGE_PERIOD;
    address public monitor;
    address public owner;
    address public newMonitor;
    uint public changeRequestedTimestamp;

    mapping(address => bool) public allowed;

    // if someone who is allowed become malicious, owner can't be changed
    modifier onlyAllowed() {
        require(allowed[msg.sender] || msg.sender == owner);
        _;
    }

    modifier onlyMonitor() {
        require (msg.sender == monitor);
        _;
    }

    constructor(uint _changePeriod) public {
        owner = msg.sender;
        CHANGE_PERIOD = _changePeriod * 1 days;
    }

    /// @notice Allowed users are able to set Monitor contract without any waiting period first time
    /// @param _monitor Address of Monitor contract
    function setMonitor(address _monitor) public onlyAllowed {
        require(monitor == address(0));
        monitor = _monitor;
    }

    /// @notice Only monitor contract is able to call execute on users proxy
    /// @param _owner Address of cdp owner (users DSProxy address)
    /// @param _saverProxy Address of MCDSaverProxy
    /// @param _data Data to send to MCDSaverProxy
    function callExecute(address _owner, address _saverProxy, bytes memory _data) public onlyMonitor {
        // execute reverts if calling specific method fails
        DSProxyInterface(_owner).execute(_saverProxy, _data);
    }

    /// @notice Allowed users are able to start procedure for changing monitor
    /// @dev after CHANGE_PERIOD needs to call confirmNewMonitor to actually make a change
    /// @param _newMonitor address of new monitor
    function changeMonitor(address _newMonitor) public onlyAllowed {
        changeRequestedTimestamp = now;
        newMonitor = _newMonitor;
    }

    /// @notice At any point allowed users are able to cancel monitor change
    function cancelMonitorChange() public onlyAllowed {
        changeRequestedTimestamp = 0;
        newMonitor = address(0);
    }

    /// @notice Anyone is able to confirm new monitor after CHANGE_PERIOD if process is started
    function confirmNewMonitor() public onlyAllowed {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);
        require(newMonitor != address(0));

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;
    }

    /// @notice Allowed users are able to add new allowed user
    /// @param _user Address of user that will be allowed
    function addAllowed(address _user) public onlyAllowed {
        allowed[_user] = true;
    }

    /// @notice Allowed users are able to remove allowed user
    /// @dev owner is always allowed even if someone tries to remove it from allowed mapping
    /// @param _user Address of allowed user
    function removeAllowed(address _user) public onlyAllowed {
        allowed[_user] = false;
    }
}
