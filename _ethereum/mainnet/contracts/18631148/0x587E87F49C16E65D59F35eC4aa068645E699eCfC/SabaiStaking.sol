// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";

contract SabaiStaking is Ownable {
    using SafeMath for uint256;
    
    IERC20 immutable private _token;
    uint256 immutable private percentageOfEarnings;
    uint256 immutable private penaltyPercentage;
    uint256 immutable private minDeposit;
    uint256 immutable private depositDuration;
    uint256 private planExpired;

    struct Deposit {        
        uint256 startTS;
        uint256 endTS;        
        uint256 amount; 
        uint256 claimed;
        bool get;     
    }
    
    mapping(bytes32 => Deposit) deposits;
    mapping(uint256 => bytes32) depositsCounter;

    mapping(address => bool) users;
    address[] usersArray;
    mapping (address => bytes32[]) usersDeposits;
    mapping (bytes32 => address) depositsUsers;

    address public SabaiRewarderAddress;
    address public SabaiManager;

    uint totalDepositsCount;

    event DepositCreated(address _user, uint256 _amount, bytes32 _depositId);
    event DepositCreatedTo(address _user, uint256 _amount, bytes32 _depositId);
    event DepositClosed(address _user, uint256 _amount, bytes32 _depositId, bool _status);

    constructor(address _tokenAddress, uint256 _planExpired, uint256 _percentageOfEarnings, uint256 _penaltyPercentage, uint256 _minDeposit, uint256 _depositDuration, address _SabaiRewarderAddress, address _SabaiManager) {
        require(_tokenAddress != address(0x0));
        require(_SabaiRewarderAddress != address(0x0));
        require(_SabaiManager != address(0x0));

        _token = IERC20(_tokenAddress);

        planExpired = block.timestamp + _planExpired;
        
        percentageOfEarnings = _percentageOfEarnings;
        penaltyPercentage = _penaltyPercentage;
        minDeposit = _minDeposit;
        depositDuration = _depositDuration;
        SabaiRewarderAddress = _SabaiRewarderAddress;
        SabaiManager = _SabaiManager;
    }

    function ChangeSabaiRewarderAddress(address _newSabaiRewarderAddress) public onlyOwner {
        require(_newSabaiRewarderAddress != address(0x0));
        SabaiRewarderAddress = _newSabaiRewarderAddress;
    }

    function ChangeSabaiManager(address _newSabaiManager) public onlyOwner {
        require(_newSabaiManager != address(0x0));
        SabaiManager = _newSabaiManager;
    }

    function _checkUserDeposit(address _address, bytes32 _deposit_id) internal view returns(bool) {
        return depositsUsers[_deposit_id] == _address;
    }

    function getCurrentTime() private view returns(uint){
        return block.timestamp;
    }

    // Create a new deposit for an address
    function createDeposit(uint256 _amount) public {
        uint256 timestamp = getCurrentTime();

        require(timestamp < planExpired, "Offer has expired");
        require(_amount >= minDeposit, "Deposit amount is too small");
        require(_token.allowance(msg.sender, address(this)) >= _amount, "No permission to transfer tokens");
        require(_token.transferFrom(_msgSender(), address(this), _amount), "Problem with tokens transfer");

        bytes32 depositId = generateDepositId(msg.sender);
        deposits[depositId] = Deposit(timestamp, timestamp+depositDuration, _amount, 0, false);

        depositsCounter[totalDepositsCount] = depositId;
        totalDepositsCount = totalDepositsCount + 1;
        
        usersDeposits[msg.sender].push(depositId);

        depositsUsers[depositId] = msg.sender;

        if (!users[msg.sender]) {
            users[msg.sender] = true;
            usersArray.push(msg.sender);
        }

        emit DepositCreated(msg.sender, _amount, depositId);
    }

    // Create a new deposit by moderator
    function createDepositTo(address _to, uint256 _amount) public {
        uint256 timestamp = getCurrentTime();
        require(msg.sender == SabaiManager, "You are not a contract manager");
        require(timestamp < planExpired, "Offer has expired");
        require(_amount >= minDeposit, "Deposit amount is too small");
        require(_token.allowance(msg.sender, address(this)) >= _amount, "No permission to transfer tokens");
        require(_token.transferFrom(_msgSender(), address(this), _amount), "Problem with tokens transfer");

        bytes32 depositId = generateDepositId(_to);
        deposits[depositId] = Deposit(timestamp, timestamp+depositDuration, _amount, 0, false);

        depositsCounter[totalDepositsCount] = depositId;
        totalDepositsCount = totalDepositsCount + 1;
        
        usersDeposits[_to].push(depositId);

        depositsUsers[depositId] = _to;

        if (!users[_to]) {
            users[_to] = true;
            usersArray.push(_to);
        }

        emit DepositCreatedTo(_to, _amount, depositId);
    }

    function getReward(bytes32 _depositId) public {
        require(_checkUserDeposit(msg.sender, _depositId), "You are not the owner of the deposit"); 
        require(deposits[_depositId].get == false, "You have already taken a deposit");

        // If the deposit time is over - address receives a reward, otherwise a penalty
        if (getCurrentTime() > deposits[_depositId].endTS) {
            uint256 _claimedAmount = deposits[_depositId].amount.sub(deposits[_depositId].claimed); // Checking if the user has already tried to collect the reward, but did not receive it in full or not receive a rewards

            if (_claimedAmount > 0) {
                require(_token.transfer(msg.sender, _claimedAmount), "Problem with tokens transfer");
                deposits[_depositId].claimed.add(_claimedAmount);
            }

            uint256 _rewardAmount = deposits[_depositId].amount.mul(percentageOfEarnings).div(100);
            if (_token.allowance(SabaiRewarderAddress, address(this)) >= _rewardAmount) {
                require(_token.transferFrom(SabaiRewarderAddress, msg.sender, _rewardAmount), "Problem with tokens transfer");
            
                deposits[_depositId].get = true;

                emit DepositClosed(msg.sender, deposits[_depositId].amount, _depositId, true);
            }

        } else { // If the deposit is closed ahead of schedule (penalty)
            uint256 _claimedAmount = deposits[_depositId].amount.sub(deposits[_depositId].amount.mul(penaltyPercentage).div(100));
            require(_token.transfer(msg.sender, _claimedAmount), "Problem with tokens transfer");

            deposits[_depositId].claimed = _claimedAmount;
            deposits[_depositId].get = true;

            uint256 _penaltyAmount = deposits[_depositId].amount.sub(_claimedAmount);
            require(_token.transfer(SabaiRewarderAddress, _penaltyAmount), "Problem with tokens transfer");

            emit DepositClosed(msg.sender, deposits[_depositId].amount, _depositId, false);
        }
    }

    function generateDepositId(address _address) private view returns (bytes32) {
        return bytes32(keccak256(abi.encodePacked(_address, block.timestamp)));
    }

    // Get deposit ids by address
    function getDepositIdsByAddress(address _address) public view returns (bytes32[] memory) { 
        return usersDeposits[_address];
    }

    // Get information about the deposit by deposit id
    function getDepositDataById(bytes32 _depositId) public view returns (Deposit memory) {
        return deposits[_depositId];
    }

    function getUsersArray() public view returns (address[] memory) {
        return usersArray;
    }

    // The amount of tokens on the contract without deposits
    function getContractBalance() public view returns(uint256) {
        return _token.balanceOf(address(this));
    }

    // It is necessary for the correct calculation of future rewards and right approval
    function getRestOfDeposits() public view returns (uint256) {
        uint256 totalActualRewardsAmount = 0;
        for (uint i = 0; i < totalDepositsCount; i++) {
            if (deposits[depositsCounter[i]].get == false) {
                totalActualRewardsAmount = totalActualRewardsAmount.add(deposits[depositsCounter[i]].amount.mul(percentageOfEarnings).div(100));
            }
        }

        return totalActualRewardsAmount;
    }

    // Stop offers now (emergency)
    function stop() external onlyOwner {
        planExpired = getCurrentTime();
    }
}