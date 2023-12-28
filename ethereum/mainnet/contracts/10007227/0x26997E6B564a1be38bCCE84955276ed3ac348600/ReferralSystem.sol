pragma solidity ^0.5.0;

/// this contract is working with myetherstore deployed at 0xB4D69A7cb01Ef545C7bdf3c98dCa0ce4cE19402f (main net)
/// requires that referral system contract is always fully funded by the owners to pay the referrers

contract ReferralSystem{
    mapping(address => bytes32) users;
    mapping(bytes32 => address payable) hashedIds;
    event rewardPaid(address _wallet, uint256 amount);
    
    function() external payable{
        // receives ethers from any account
    }
    function myReferralLink(address _wallet) public view returns(bytes32) {
        return users[_wallet];
    }
    
    function referralExist(address _wallet) public view returns(bool){
        if(users[_wallet] != bytes32(0))
            return true;
        else
            return false;
    }
    
    function generateReferral(address payable _wallet) public{
        // generate new referral
        // calculates the hash of the address and now time
        bytes32 id = keccak256(abi.encode(_wallet, now));
        users[_wallet] = id;
        hashedIds[id] = _wallet;
    }
    
    // send reward in wei to your referrer
    function payReferralReward(bytes32 _code, uint256 reward) public payable{
        if(msg.value >= reward){ // checks if there is sufficient balance
            hashedIds[_code].transfer(reward); // send reward
            emit rewardPaid(hashedIds[_code], reward);
        }
    }
}