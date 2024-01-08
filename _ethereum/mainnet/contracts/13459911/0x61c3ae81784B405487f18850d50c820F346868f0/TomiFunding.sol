// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./TransferHelper.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract TomiFunding is Ownable {
    address public tomi;

    mapping(address => bool) included;
    
    event ClaimableGranted(address _userAddress);
    event ClaimableRevoked(address _userAddress);
    event Claimed(address _userAddress, uint256 _amount);
    event FundingTokenSettled(address tokenAddress);
    
    constructor(address _tomi) public {
        tomi = _tomi;
    }
    
    modifier inClaimable(address _userAddress) {
        require(included[_userAddress], "TomiFunding::User not in claimable list!");
        _;
    }

    modifier notInClaimable(address _userAddress) {
        require(!included[_userAddress], "TomiFunding::User already in claimable list!");
        _;
    }
    
    function setTomi(address _tomi) public onlyOwner {
        tomi = _tomi;
        emit FundingTokenSettled(_tomi);
    }
    
    function grantClaimable(address _userAddress) public onlyOwner notInClaimable(_userAddress) {
        require(_userAddress != address(0), "TomiFunding::User address is not legit!");
        
        included[_userAddress] = true;
        emit ClaimableGranted(_userAddress);
    }
    
    function revokeClaimable(address _userAddress) public onlyOwner inClaimable(_userAddress) {
        require(_userAddress != address(0), "TomiFunding::User address is not legit!");
        
        included[_userAddress] = false;
        emit ClaimableRevoked(_userAddress);
    }
    
    function claim(uint256 _amount) public inClaimable(msg.sender) {
        uint256 remainBalance = IERC20(tomi).balanceOf(address(this));
        require(remainBalance >= _amount, "TomiFunding::Remain balance is not enough to claim!");
        
        TransferHelper.safeTransfer(address(tomi), msg.sender, _amount); 
        emit Claimed(msg.sender, _amount);
    }
}