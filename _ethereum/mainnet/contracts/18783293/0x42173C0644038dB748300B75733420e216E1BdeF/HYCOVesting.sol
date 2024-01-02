// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";

contract HYCOVesting is Ownable {
    event SetVesting(address indexed account, uint256 amount, uint256 startTime, uint256 releaseMonths);
    event UpdateVesting(address indexed account, uint256 valueIndex, uint256 value);
    event Released(address indexed account, uint256 amount);

    struct VestingInfo {
        uint256 amount;    
        uint256 startTime;
        uint256 releaseMonths;
        uint256 released;
    }
    mapping(address => VestingInfo) private _vestingInfos;

    address private _fromAddress = 0xcB8E27169eC43e75751CEa7033e1E39aeD5595f3;

    IERC20 private immutable _erc20;
    
    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address erc20Address
    ) {
        _erc20 = IERC20(erc20Address);
    }  

    /**
     * @dev Setter for the VestingInfo.
     */
    function setVestingInfo (address beneficiaryAddress, uint256 amount, uint256 startTime, uint256 releaseMonths) external onlyOwner {
        require(_vestingInfos[beneficiaryAddress].amount < 1, "Aleady exist vestig info.");
        require(beneficiaryAddress != address(0), "Beneficiary cannot be address zero.");
        require(block.timestamp < startTime, "Current time is greater than start time");
        require(releaseMonths > 0, "ReleaseMonths is smaller than 0");
        require(amount > 0, "Amount is smaller than 0");
        
        _vestingInfos[beneficiaryAddress] = VestingInfo(amount, startTime, releaseMonths, 0);

        emit SetVesting( beneficiaryAddress, amount, startTime, releaseMonths );
    }
    function setVestingAmount (address beneficiaryAddress, uint256 value) external onlyOwner {
        require(_vestingInfos[beneficiaryAddress].amount > 0, "Not exist vesting info.");
        _vestingInfos[beneficiaryAddress].amount = value;

        emit UpdateVesting( beneficiaryAddress, 1, value );
    }
    function setVestingStartTime (address beneficiaryAddress, uint256 value) external onlyOwner {
        require(_vestingInfos[beneficiaryAddress].amount > 0, "Not exist vesting info.");
        _vestingInfos[beneficiaryAddress].startTime = value;

        emit UpdateVesting( beneficiaryAddress, 2, value );
    }
    function setVestingDuration(address beneficiaryAddress, uint256 value) external onlyOwner {
        require(_vestingInfos[beneficiaryAddress].amount > 0, "Not exist vesting info.");
        require(value > 0, "ReleaseMonths is smaller than 0");
        _vestingInfos[beneficiaryAddress].releaseMonths = value;

        emit UpdateVesting( beneficiaryAddress, 3, value );
    }
    function setFromAddress(address fromAddress) external onlyOwner
    {
        _fromAddress = fromAddress;
    }

    /**
     * @dev Getter for the VestingInfo.
     */
    function getVestingInfo(address beneficiaryAddress) public view virtual returns (uint256 amount, uint256 startTime, uint256 releaseMonths, uint256 released) {
        return (_vestingInfos[beneficiaryAddress].amount, _vestingInfos[beneficiaryAddress].startTime, _vestingInfos[beneficiaryAddress].releaseMonths, _vestingInfos[beneficiaryAddress].released);
    }
    function getVestingTotalAmount() public view returns(uint256 amount) {
        return _erc20.allowance(_fromAddress, address(this));
    }
    function getFromAddress() public view onlyOwner returns(address)
    {
        return _fromAddress;
    }
    /**
     * @dev Release the tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function release(address beneficiaryAddress) public virtual {
        require(_vestingInfos[beneficiaryAddress].amount > 0, "Not exist vesting info.");

        uint256 calculationAmount = _vestingSchedule(beneficiaryAddress, uint256(block.timestamp));
        
        require(calculationAmount > 0, "Insufficient release amount.");
        require(calculationAmount >= _vestingInfos[beneficiaryAddress].released, "Insufficient release amount.");

        uint256 releasable = calculationAmount - _vestingInfos[beneficiaryAddress].released;

        SafeERC20.safeTransferFrom(_erc20, _fromAddress, beneficiaryAddress, releasable);

        _vestingInfos[beneficiaryAddress].released += releasable;

        emit Released(beneficiaryAddress, releasable);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address beneficiaryAddress, uint256 timestamp) public view virtual returns (uint256) {
        if (timestamp < 1) timestamp = uint256(block.timestamp);
        return _vestingSchedule(beneficiaryAddress, timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(address beneficiaryAddress, uint256 timestamp) internal view virtual returns (uint256) {

        uint256 vestingAmount = _vestingInfos[beneficiaryAddress].amount;
        uint256 vestingStartTime = _vestingInfos[beneficiaryAddress].startTime;
        uint256 releaseMonths = _vestingInfos[beneficiaryAddress].releaseMonths;

        if (timestamp < vestingStartTime) return 0;

        uint256 checkReleasedSecond = timestamp - vestingStartTime;
        uint256 checkReleasedMonth = checkReleasedSecond / (86400 * 30) + 1;  //per 30day

        if (releaseMonths <= checkReleasedMonth) {
            return vestingAmount;
        } else if (checkReleasedMonth < 1) {
            return 0;
        } else {
            return vestingAmount * checkReleasedMonth / releaseMonths;
        }        
    }

    function withdraw(address walletAddress) external onlyOwner { 
        SafeERC20.safeTransfer(_erc20, walletAddress, IERC20(_erc20).balanceOf(address(this)));
    }

}
