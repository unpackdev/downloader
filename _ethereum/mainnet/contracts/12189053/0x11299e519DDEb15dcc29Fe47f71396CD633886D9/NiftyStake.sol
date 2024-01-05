// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./INifty.sol";

// Contract designed to hold and stake Nifty Token
contract NiftyStake is ReentrancyGuard {

    using SafeMath for uint256;

    // Maps stakeholders to their staking amount
    mapping(address => UserInfo) public userInfo;
    address public NFTY;

    // Holds a list of all stakers
    address[] private _stakeHolders;
    uint256 private _totalStakes;
    
    constructor(address niftyAddress) {
        NFTY = niftyAddress;
    }

    struct UserInfo {
        uint256 amountStaked;
        string waxWalletAddress;
        bool exists;
    }

    function getTotalStakes() external view returns (uint256) {
        return _totalStakes;
    }

    // Returns an array of all the stakeholders
    function getStakerInfo() external view returns(uint256, address[] memory, uint256[] memory) {
        address[] memory wallets = new address[](_stakeHolders.length);
        uint256[] memory allStakes = new uint256[](_stakeHolders.length);
        for (uint256 i = 0; i < _stakeHolders.length; i++) {
            wallets[i] =  _stakeHolders[i];
            allStakes[i] = userInfo[_stakeHolders[i]].amountStaked;
        }
        return (_totalStakes, wallets, allStakes);
    }

    // Creates a stake, adds the user to list of stakeholders, and transfers staked amount to contract
    function deposit(uint256 amount, string calldata waxAddress) external nonReentrant returns(uint256, uint256){
        require(INifty(NFTY).balanceOf(msg.sender) > 0, 'cannot stake without coin');
        require(INifty(NFTY).balanceOf(msg.sender) >= amount, 'cannot stake more than you have');
        require(bytes(waxAddress).length <= 24, "invalid WAX address");
        require(INifty(NFTY).transferFrom(address(msg.sender), address(this), amount), 'transfer into contract');

        UserInfo storage user = userInfo[msg.sender];

        if(!user.exists && user.amountStaked == 0) {

            _addStakeHolder(msg.sender, waxAddress);
        }
        else {
            user.waxWalletAddress = waxAddress;
        }

        user.amountStaked = user.amountStaked.add(amount);
        _totalStakes = INifty(NFTY).balanceOf(address(this));

        emit Deposit(msg.sender, amount);

        return (user.amountStaked, _totalStakes);
    }

    // Removes a user's stake and transfers the balance back to them
    function withdraw(uint256 amount) external nonReentrant returns (uint256, uint256){
        require(amount > 0, 'cannot unstake negative amounts');

        UserInfo storage user = userInfo[msg.sender];

        require(amount <= user.amountStaked, 'cannot unstake more than staked');

        user.amountStaked = user.amountStaked.sub(amount);

        require(INifty(NFTY).transfer(msg.sender, amount), 'transfer out of contract');

        if (user.exists && user.amountStaked == 0) {
            _removeStakeHolder(msg.sender);
        }

        _totalStakes = INifty(NFTY).balanceOf(address(this));

        emit Withdraw(msg.sender, amount);

        return (user.amountStaked, _totalStakes);
    }

    // Change the wax address associated with a stake
    function changeWaxAddress(string calldata waxAddress) external nonReentrant {
        require(bytes(waxAddress).length <= 24, "invalid WAX address");

        UserInfo storage user = userInfo[msg.sender];

        require (user.exists && user.amountStaked > 0, "stakeholder does not exist");

        user.waxWalletAddress = waxAddress;
    }

    // Adds a stakeholder
    function _addStakeHolder(address stakeholderAddress, string calldata waxAddress) private {
        _stakeHolders.push(stakeholderAddress);
        userInfo[stakeholderAddress].exists = true;
    }

    // Removes a stakeholder
    function _removeStakeHolder(address stakeholderAddress) private {
        (bool isStakeholder, uint256 index) = _isStakeHolder(stakeholderAddress);
        if (isStakeholder) {
            delete(userInfo[stakeholderAddress]);
            _stakeHolders[index] = _stakeHolders[_stakeHolders.length - 1];
            _stakeHolders.pop();
        }
    }

    // Checks if someone is a stakeholder, return the index if they exist
    function _isStakeHolder(address stakeholderAddress) private view returns (bool exists, uint256 index) {
        exists = false;
        index = 0;
        for (uint256 i = 0; i < _stakeHolders.length; i++) {
            if (stakeholderAddress == _stakeHolders[i]) {
                exists = true;
                index = i;
                break;
            }
        }
    }


    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

}
