//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

interface ILaunchpad {
    struct ClaimInfo {
        uint256 amount;
        uint256 count;
        uint256 amountWithdrawn;
    }

    function claimInfo(address user, bytes32 campaignId) external view returns (ClaimInfo memory);
}

contract LaunchpadVesting is Initializable, OwnableUpgradeable {

    struct UserInfo {
        uint256 count;
        uint256 amountWithdrawn;
        uint256 airdropClaimedAmount;
    }

    struct OwnerWithdrawInfo {
        address admin;
        bool canWithdraw;
    }

    enum VestingType {
        FIXED,
        LINEAR
    }

    struct ProjectInfo {
        IERC20Upgradeable token;
        uint256 startTime;
        uint256 endTime;
        uint256 cliff; //no of days in seconds (not the actual timestamp)
        uint256 amountAllocated;
        uint256 amountRemaining;
        uint256 vestedPerc; //2 decimals //70_00 = 70%
        address IDOContract;
        address signer;
        VestingType vestingType;
    }

    struct VestingSchedule {
        uint256 timestamp;
        uint256 percentage;
    }

    mapping(bytes32 => mapping(address => UserInfo)) public userInfo;
    mapping(bytes32 => ProjectInfo) public projectInfo;
    mapping(bytes32 => mapping(bytes32 => bool)) public usedNonce;
    mapping(bytes32 => OwnerWithdrawInfo) public ownerWithdrawInfo;
    mapping(bytes32 => VestingSchedule[]) public vestingSchedule;

    error INVALID_TIMESTAMP();
    error INVALID_SIGNATURE();
    error SIGNATURE_EXPIRED();
    error ONLY_PROJECT_OWNER();
    error WITHDRAW_NOT_ENABLED();
    error METHOD_NOT_ENABLED();

    //validation errors
    error INVALID_AMOUNT();
    error INVALID_SIGNER();
    error INVALID_VESTING_TIMESTAMP();

    event Claim(address user, bytes32 campaignId, uint256 amount);
    event CreateVesting(bytes32 campaignId, ProjectInfo info);

    function initialize(address admin) external initializer {
        __Ownable_init();
        transferOwnership(admin);
    }

    function withdraw(bytes32 campaignId) external {
        ProjectInfo storage _projectInfo = projectInfo[campaignId];
        UserInfo storage _userInfo = userInfo[campaignId][msg.sender];

        if(_projectInfo.IDOContract == address(0)) revert METHOD_NOT_ENABLED();
        if(block.timestamp < _projectInfo.startTime + _projectInfo.cliff) revert INVALID_TIMESTAMP();

        ILaunchpad.ClaimInfo memory _claimInfo = ILaunchpad(_projectInfo.IDOContract).claimInfo(msg.sender, campaignId);
        uint256 vestedAmount = _claimInfo.amount * _projectInfo.vestedPerc / 100_00;

        uint256 _claimableAmount;
        if(_projectInfo.vestingType == VestingType.FIXED) {
            _claimableAmount = _calculateFixedVesting(campaignId, vestedAmount, _userInfo.amountWithdrawn);
        } else {
            _claimableAmount = _calculateLinearVesting(
                vestedAmount, 
                _userInfo.amountWithdrawn, 
                _projectInfo.startTime, 
                _projectInfo.endTime,
                _projectInfo.cliff
            );
        }

        if(_claimableAmount > 0) {
            _userInfo.count++;
            _userInfo.amountWithdrawn += _claimableAmount;
            _projectInfo.amountRemaining -= _claimableAmount;

            SafeERC20Upgradeable.safeTransfer(_projectInfo.token, msg.sender, _claimableAmount);

            emit Claim(msg.sender, campaignId, _claimableAmount);
        }

    }

    ///@param userTotalAmount total amount of tokens the user has bought in IDO (doesn't including airdrop).
    ///@param airdropAmount Amount allocated for airdrop. No need to reduce in backend. Claims whole airdropAmount the first time
    function withdraw(bytes32 campaignId, bytes32 nonce, uint256 expiry, uint256 userTotalAmount, uint256 airdropAmount, bytes calldata signature) external {
        if(block.timestamp < projectInfo[campaignId].startTime + projectInfo[campaignId].cliff) revert INVALID_TIMESTAMP();
        if(usedNonce[campaignId][nonce]) revert INVALID_SIGNATURE();
        if(block.timestamp > expiry) revert SIGNATURE_EXPIRED();
        if(projectInfo[campaignId].signer == address(0) || projectInfo[campaignId].IDOContract != address(0)) revert METHOD_NOT_ENABLED();
        usedNonce[campaignId][nonce] = true;


        bytes32 message = keccak256(abi.encodePacked(msg.sender, nonce, block.chainid, expiry, campaignId, userTotalAmount, airdropAmount));
        bytes32 messageHash = ECDSAUpgradeable.toEthSignedMessageHash(message);
        address signer = ECDSAUpgradeable.recover(messageHash, signature);

        if(signer != projectInfo[campaignId].signer) revert INVALID_SIGNATURE();

        UserInfo storage _userInfo = userInfo[campaignId][msg.sender];
        ProjectInfo storage _projectInfo = projectInfo[campaignId];

        uint256 vestedAmount = userTotalAmount * _projectInfo.vestedPerc / 100_00;
        uint256 airdropAmountRemaining = airdropAmount - _userInfo.airdropClaimedAmount;
        uint256 _claimableAmount;
        bytes32 _campaignId = campaignId;

        if(_projectInfo.vestingType == VestingType.FIXED) {
            _claimableAmount = _calculateFixedVesting(_campaignId, vestedAmount, _userInfo.amountWithdrawn);
        } else {
            _claimableAmount = _calculateLinearVesting(
                vestedAmount, 
                _userInfo.amountWithdrawn, 
                _projectInfo.startTime, 
                _projectInfo.endTime,
                _projectInfo.cliff
            );
        }

        _userInfo.count++;
        _userInfo.amountWithdrawn += _claimableAmount;
        _userInfo.airdropClaimedAmount += airdropAmountRemaining;
        _projectInfo.amountRemaining = _projectInfo.amountRemaining - (_claimableAmount + airdropAmountRemaining);


        SafeERC20Upgradeable.safeTransfer(_projectInfo.token, msg.sender, _claimableAmount + airdropAmountRemaining);

        emit Claim(msg.sender, _campaignId, _claimableAmount);
    }


    function createVesting(bytes32 campaignId, ProjectInfo calldata info, VestingSchedule[] calldata schedule) external onlyOwner {
        if(info.startTime > info.endTime) revert INVALID_TIMESTAMP();

        projectInfo[campaignId] = info;
        projectInfo[campaignId].amountRemaining = info.amountAllocated;

        uint256 previousTimestamp;
        for(uint256 i = 0; i < schedule.length; i++) {
            if(schedule[i].timestamp < previousTimestamp) revert INVALID_VESTING_TIMESTAMP();
            previousTimestamp = schedule[i].timestamp;

            vestingSchedule[campaignId].push(schedule[i]);
        } 

        //cliff not applicable for fixed vesting
        if (projectInfo[campaignId].vestingType == VestingType.FIXED) projectInfo[campaignId].cliff = 0;

        emit CreateVesting(campaignId, info);
    }

    function adminWithdraw(bytes32 campaignId) external {
        OwnerWithdrawInfo memory _ownerWithdrawInfo = ownerWithdrawInfo[campaignId];
        ProjectInfo memory _projectInfo = projectInfo[campaignId];

        if(!_ownerWithdrawInfo.canWithdraw) revert WITHDRAW_NOT_ENABLED();
        if(msg.sender != _ownerWithdrawInfo.admin) revert ONLY_PROJECT_OWNER();

        SafeERC20Upgradeable.safeTransfer(_projectInfo.token, msg.sender, _projectInfo.amountRemaining);
    }

    function setAdminWithdraw(bytes32 campaignId, address admin, bool canWithdraw) external onlyOwner {
        ownerWithdrawInfo[campaignId] = OwnerWithdrawInfo(admin, canWithdraw);
    }

    function setProjectInfo(bytes32 campaignId, ProjectInfo calldata info, VestingSchedule[] calldata schedule) external onlyOwner {
        ProjectInfo memory _projectInfo = projectInfo[campaignId];

        uint256 amountSpent = _projectInfo.amountAllocated - _projectInfo.amountRemaining;
        uint256 amountRemaining = info.amountAllocated - amountSpent;

        projectInfo[campaignId] = info;
        projectInfo[campaignId].amountRemaining = amountRemaining;

        delete vestingSchedule[campaignId];

        uint256 previousTimestamp;
        for(uint256 i = 0; i < schedule.length; i++) {
            if(schedule[i].timestamp < previousTimestamp) revert INVALID_VESTING_TIMESTAMP();
            previousTimestamp = schedule[i].timestamp;

            vestingSchedule[campaignId].push(schedule[i]);
        } 
    }

    //returns vestedAmount and airdrop amount
    function claimableAmount(bytes32 campaignId, address user, uint256 userTotalAmount, uint256 airdropAmount) external view returns (uint256, uint256) {
        ProjectInfo memory _projectInfo = projectInfo[campaignId];

        uint256 startTime = _projectInfo.startTime;
        uint256 endTime = _projectInfo.endTime;

        uint256 userVestedAmount = userTotalAmount * _projectInfo.vestedPerc / 100_00;
        uint256 airdropAmountRemaining = airdropAmount - userInfo[campaignId][user].airdropClaimedAmount;

        if(_projectInfo.vestingType == VestingType.FIXED) 
            return (_calculateFixedVesting(campaignId, userVestedAmount, userInfo[campaignId][user].amountWithdrawn), airdropAmountRemaining);
        
        return (_calculateLinearVesting(
            userVestedAmount, 
            userInfo[campaignId][user].amountWithdrawn, 
            startTime, 
            endTime,
            _projectInfo.cliff)
            , 
            airdropAmountRemaining
        );
    }


    function _calculateLinearVesting(uint256 userVestedAmount, uint256 amountWithdrawn, uint256 startTime, uint256 endTime, uint256 cliff) internal view returns (uint256) {
        if(block.timestamp < startTime + cliff) return 0;
        
        uint256 totalVestingTime = endTime - startTime;
        uint256 timenow = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 timePassed = timenow - startTime;

        uint256 userUnlockedAmount = (userVestedAmount * timePassed) / totalVestingTime;

        return userUnlockedAmount - amountWithdrawn;
    }

    function _calculateFixedVesting(bytes32 campaignId, uint256 vestedAmount, uint256 withdrawnAmount) internal view returns (uint256 availableAmount){
        ProjectInfo storage _projectInfo = projectInfo[campaignId];
        VestingSchedule[] memory _vestingSchedule = vestingSchedule[campaignId];
        
        uint256 unlockedPerc;
        for(uint256 i = 0; i < _vestingSchedule.length; i++) {

            if(block.timestamp >= _projectInfo.endTime) {
                unlockedPerc = 100_00;
                break;
            }

            if( block.timestamp > _vestingSchedule[i].timestamp) {
                unlockedPerc += _vestingSchedule[i].percentage;
            }
        }

        uint256 unlockedAmount = (vestedAmount * unlockedPerc) / 100_00;
        availableAmount = unlockedAmount - withdrawnAmount;
    }
}