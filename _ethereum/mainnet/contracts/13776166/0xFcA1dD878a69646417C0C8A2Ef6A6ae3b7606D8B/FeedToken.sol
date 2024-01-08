// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

interface Feed {
    function balanceMetamal(address owner) external view returns(uint256);
}

contract FeedToken is Initializable, OwnableUpgradeable, ERC20Upgradeable  {

    Feed public feed;

    string constant private _name = "$F33D";
    string constant private _symbol = "$F33D";

    uint256 constant public BASE_RATE = 5 ether;
    uint256 constant COOLDOWN = 1 days;
    uint256 constant SPINCOOLDOWN = 7 days;
    uint256 public START;
    bool private rewardPaused;

    mapping(address => uint256) public rewards;
    mapping(address => string) public coupons;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    function initialize(address _address) public initializer {
        __ERC20_init_unchained(_name, _symbol);
        __Ownable_init_unchained();
        feed = Feed(_address);
        START = block.timestamp;
        rewardPaused = false;
    }

    // Updates rewards list for minting
    function updateReward(address from, address to) external {
        require(msg.sender == address(feed));
        if(from != address(0)){
            rewards[from] += getPendingReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            rewards[to] += getPendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    // Claims all tokens from the rewards list
    function claimReward() external {
        require(!rewardPaused, "Reward claiming has been paused!"); 
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    // Burn tokens
    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(feed), "Address cannot burn tokens!");
        _burn(user, amount);
    }

    // Returns the total amount of rewards claimable from last update
    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    // Return claimable amount of tokens from last update
    function getPendingReward(address user) internal view returns(uint256) {
        return feed.balanceMetamal(user) * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / COOLDOWN;
    }

    // Adding accounts to the administration list
    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }
}