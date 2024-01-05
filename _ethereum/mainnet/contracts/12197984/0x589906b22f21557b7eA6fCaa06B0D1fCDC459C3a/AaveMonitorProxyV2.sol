pragma solidity ^0.6.0;

import "./DSProxyInterface.sol";
import "./SafeERC20.sol";
import "./AdminAuth.sol";

/// @title Contract with the actuall DSProxy permission calls the automation operations
contract AaveMonitorProxyV2 is AdminAuth {

    using SafeERC20 for ERC20;

    string public constant NAME = "AaveMonitorProxyV2";

    uint public CHANGE_PERIOD;
    address public monitor;
    address public newMonitor;
    address public lastMonitor;
    uint public changeRequestedTimestamp;

    event MonitorChangeInitiated(address oldMonitor, address newMonitor);
    event MonitorChangeCanceled();
    event MonitorChangeFinished(address monitor);
    event MonitorChangeReverted(address monitor);


    modifier onlyMonitor() {
        require (msg.sender == monitor);
        _;
    }

    constructor(uint _changePeriod) public {
        CHANGE_PERIOD = _changePeriod * 1 hours;
    }

    /// @notice Only monitor contract is able to call execute on users proxy
    /// @param _owner Address of cdp owner (users DSProxy address)
    /// @param _aaveSaverProxy Address of AaveSaverProxy
    /// @param _data Data to send to AaveSaverProxy
    function callExecute(address _owner, address _aaveSaverProxy, bytes memory _data) public payable onlyMonitor {
        // execute reverts if calling specific method fails
        DSProxyInterface(_owner).execute{value: msg.value}(_aaveSaverProxy, _data);

        // return if anything left
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    /// @notice Owner is able to set Monitor contract without any waiting period first time
    /// @param _monitor Address of Monitor contract
    function setMonitor(address _monitor) public onlyOwner {
        require(monitor == address(0));
        monitor = _monitor;
    }

    /// @notice Owner is able to start procedure for changing monitor
    /// @dev after CHANGE_PERIOD needs to call confirmNewMonitor to actually make a change
    /// @param _newMonitor address of new monitor
    function changeMonitor(address _newMonitor) public onlyOwner {
        require(changeRequestedTimestamp == 0);

        changeRequestedTimestamp = now;
        lastMonitor = monitor;
        newMonitor = _newMonitor;

        emit MonitorChangeInitiated(lastMonitor, newMonitor);
    }

    /// @notice At any point owner is able to cancel monitor change
    function cancelMonitorChange() public onlyOwner {
        require(changeRequestedTimestamp > 0);

        changeRequestedTimestamp = 0;
        newMonitor = address(0);

        emit MonitorChangeCanceled();
    }

    /// @notice Anyone is able to confirm new monitor after CHANGE_PERIOD if process is started
    function confirmNewMonitor() public onlyOwner {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);
        require(newMonitor != address(0));

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;

        emit MonitorChangeFinished(monitor);
    }

    /// @notice Its possible to revert monitor to last used monitor
    function revertMonitor() public onlyOwner {
        require(lastMonitor != address(0));

        monitor = lastMonitor;

        emit MonitorChangeReverted(monitor);
    }

    function setChangePeriod(uint _periodInHours) public onlyOwner {
        require(_periodInHours * 1 hours > CHANGE_PERIOD);

        CHANGE_PERIOD = _periodInHours * 1 hours;
    }
}
