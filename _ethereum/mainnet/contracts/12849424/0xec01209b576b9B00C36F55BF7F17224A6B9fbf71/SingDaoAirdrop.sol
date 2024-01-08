pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SingDaoAirdrop is Ownable {

    using SafeMath for uint256;

    ERC20 public sdaoToken; // Address of token contract
    
    mapping (address => uint256) public airdropUsers; 

    // Events
    event WithdrawToken(address indexed owner, uint256 amount);

    constructor(address _token)
    public
    {
        sdaoToken = ERC20(_token);
    }
    
    function withdrawToken(uint256 value) public onlyOwner
    {

        // Check if contract is having required balance 
        require(sdaoToken.balanceOf(address(this)) >= value, "Not enough balance in the contract");
        require(sdaoToken.transfer(msg.sender, value), "Unable to transfer token to the operator account");

        emit WithdrawToken(msg.sender, value);
        
    }


    function addAddresses(address[] calldata _addresses, uint256[] calldata _rewards)
    external
    onlyOwner
    {
        require(_addresses.length == _rewards.length, "Number of addresses should match number of rewards");

        for(uint256 i = 0; i < _addresses.length; i++) {
            airdropUsers[_addresses[i]] = _rewards[i];
        }
    }

    function removeAddresses(address[] calldata _addresses)
    external
    onlyOwner
    {
        require(_addresses.length > 0, "Need atleast one address to remove");

        for(uint256 i = 0; i < _addresses.length; i++) {
            airdropUsers[_addresses[i]] = 0;
        }
    }

    function claim() 
    public 
    {
    
        uint256 reward = airdropUsers[msg.sender];
        require(reward > 0,'Claim not allowed, address not whitelisted');
        require(sdaoToken.balanceOf(address(this)) >= reward, "Not enough tokens left to distribute reward");
    
        // Update the rewards to zero
        airdropUsers[msg.sender] = 0;

        // Do the transfer
        sdaoToken.transfer(msg.sender, reward);

        // Dont need explicit event for the claim instead use sdao token transfer with from addrees as contract address
  }

}