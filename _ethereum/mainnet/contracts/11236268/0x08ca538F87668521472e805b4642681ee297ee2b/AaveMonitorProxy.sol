pragma solidity ^0.6.0;

import "./DSProxyInterface.sol";
import "./SafeERC20.sol";
import "./AdminAuth.sol";

/// @title Contract with the actuall DSProxy permission calls the automation operations
contract AaveMonitorProxy is AdminAuth {

    using SafeERC20 for ERC20;

    uint public CHANGE_PERIOD;
    address public monitor;
    address public newMonitor;
    address public lastMonitor;
    uint public changeRequestedTimestamp;

    mapping(address => bool) public allowed;

    event MonitorChangeInitiated(address oldMonitor, address newMonitor);
    event MonitorChangeCanceled();
    event MonitorChangeFinished(address monitor);
    event MonitorChangeReverted(address monitor);

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
        CHANGE_PERIOD = _changePeriod * 1 days;
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

    /// @notice Allowed users are able to set Monitor contract without any waiting period first time
    /// @param _monitor Address of Monitor contract
    function setMonitor(address _monitor) public onlyAllowed {
        require(monitor == address(0));
        monitor = _monitor;
    }

    /// @notice Allowed users are able to start procedure for changing monitor
    /// @dev after CHANGE_PERIOD needs to call confirmNewMonitor to actually make a change
    /// @param _newMonitor address of new monitor
    function changeMonitor(address _newMonitor) public onlyAllowed {
        require(changeRequestedTimestamp == 0);

        changeRequestedTimestamp = now;
        lastMonitor = monitor;
        newMonitor = _newMonitor;

        emit MonitorChangeInitiated(lastMonitor, newMonitor);
    }

    /// @notice At any point allowed users are able to cancel monitor change
    function cancelMonitorChange() public onlyAllowed {
        require(changeRequestedTimestamp > 0);

        changeRequestedTimestamp = 0;
        newMonitor = address(0);

        emit MonitorChangeCanceled();
    }

    /// @notice Anyone is able to confirm new monitor after CHANGE_PERIOD if process is started
    function confirmNewMonitor() public onlyAllowed {
        require((changeRequestedTimestamp + CHANGE_PERIOD) < now);
        require(changeRequestedTimestamp != 0);
        require(newMonitor != address(0));

        monitor = newMonitor;
        newMonitor = address(0);
        changeRequestedTimestamp = 0;

        emit MonitorChangeFinished(monitor);
    }

    /// @notice Its possible to revert monitor to last used monitor
    function revertMonitor() public onlyAllowed {
        require(lastMonitor != address(0));

        monitor = lastMonitor;

        emit MonitorChangeReverted(monitor);
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

    function setChangePeriod(uint _periodInDays) public onlyAllowed {
        require(_periodInDays * 1 days > CHANGE_PERIOD);

        CHANGE_PERIOD = _periodInDays * 1 days;
    }

    /// @notice In case something is left in contract, owner is able to withdraw it
    /// @param _token address of token to withdraw balance
    function withdrawToken(address _token) public onlyOwner {
        uint balance = ERC20(_token).balanceOf(address(this));
        ERC20(_token).safeTransfer(msg.sender, balance);
    }

    /// @notice In case something is left in contract, owner is able to withdraw it
    function withdrawEth() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}
