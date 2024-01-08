pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Vesting.sol";

contract VestingRouter is Ownable, ReentrancyGuard {
    event VestingCreated(address indexed beneficiary, address indexed vestingAddress, uint256 tokenAmount);
    event VestingReleased(address indexed vestingAddress, uint256 amount);
    event VestingRevoked(address indexed vestingAddress);

    struct UserInfo {
        address activeVesting;
        address[] vestingHistory;
    }
   
    IERC20 immutable mxsToken;

    mapping(address => UserInfo) userVesting;
   
    constructor(address _token) {
        mxsToken = IERC20(_token);
    }
   
    function createVesting(address _beneficiary, uint256 _tokenAmount, uint256 _duration, uint256 _cliff, bool _revokable) external onlyOwner nonReentrant {
        require(userVesting[_beneficiary].activeVesting == address(0), "Address already has an active vesting contract");
        Vesting vestingContract = new Vesting(_beneficiary, block.timestamp, _cliff, _duration, _revokable, _tokenAmount, address(mxsToken));
        bool transferred = mxsToken.transfer(address(vestingContract), _tokenAmount);
        require(transferred, "Token transfer failed");
        userVesting[_beneficiary].activeVesting = address(vestingContract);
        userVesting[_beneficiary].vestingHistory.push(address(vestingContract));

        emit VestingCreated(_beneficiary, address(vestingContract), _tokenAmount);
    }
   
    function userInfo(address account) external view returns(address activeVesting, address[] memory vestingHistory) {
        UserInfo memory _userInfo = userVesting[account];
        return(_userInfo.activeVesting, _userInfo.vestingHistory);
    }
   
    function userVestingInfo(address _account) external view returns(
        address vestingAddress,
        uint256 releasedAmount,
        uint256 releasableAmount,
        uint256 vestedAmount,
        uint256 allocation,
        uint256 reflectionsReceived,
        uint256 timeRemaining,
        bool complete
    ) {
        return vestingInfo(userVesting[_account].activeVesting);
    }
   
    function vestingInfo(address _vestingAddress) public view returns (
        address vestingAddress,
        uint256 releasedAmount,
        uint256 releasableAmount,
        uint256 vestedAmount,
        uint256 allocation,
        uint256 reflectionsReceived,
        uint256 timeRemaining,
        bool complete
    ) {
        Vesting vestingContract = Vesting(_vestingAddress);
        vestingAddress = _vestingAddress;
        releasedAmount = vestingContract.released();
        releasableAmount = vestingContract.releasableAmount();
        vestedAmount = vestingContract.vestedAmount();
        allocation = vestingContract.initialAllocation();
        reflectionsReceived = vestingContract.reflections();
        timeRemaining = vestingContract.timeRemaining();
        complete = vestingContract.complete();
    }
   
    function revoke(address _vestingAddress) external onlyOwner {
        Vesting vestingContract = Vesting(_vestingAddress);
        require(address(vestingContract) != address(0), "Cannot release an invalid address");
        require(!vestingContract.complete(), "Vesting is already complete");
       
        vestingContract.revoke();
        userVesting[vestingContract.beneficiary()].activeVesting = address(0);
        emit VestingRevoked(_vestingAddress);
    }
   
    function release(address _vestingAddress) external {
        Vesting vestingContract = Vesting(_vestingAddress);
        require(address(vestingContract) != address(0), "Cannot release an invalid address");
        require(!vestingContract.complete(), "Vesting is already complete");
        require(vestingContract.beneficiary() == msg.sender, "Sender must be beneficiary");

        uint256 tokenAmount = vestingContract.release();
       
        if (vestingContract.complete()) {
            userVesting[vestingContract.beneficiary()].activeVesting = address(0);
        }
        emit VestingReleased(_vestingAddress, tokenAmount);
    }
}
