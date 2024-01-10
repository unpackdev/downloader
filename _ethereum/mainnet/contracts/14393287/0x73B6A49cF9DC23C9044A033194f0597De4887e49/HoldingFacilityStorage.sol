// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


interface IBounty {
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
}

interface ICryptid {
    function ownerOf(uint id) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
}

interface IHoldingLogic {
    function getPendingReward(address user) external view returns(uint256);
}

contract HoldingFacilityStorage is Ownable, ReentrancyGuard {
    bool private _paused = false;

    struct Stake { //this structure identifies the total count staked, the last reward update time, and the modifier to apply.
        uint256 count;
        uint256 lastUpdateTime;
        uint256[] tokens;
    }

    IBounty public bounty;
    ICryptid public cryptid;
    IHoldingLogic public logic;

    mapping(address => Stake) public accountStake;
    mapping(uint256 => address) public ownerOfToken;
    mapping(address => uint256) public userBountyBalance;



    // emergency rescue to allow unstaking without any checks but without $GGOLD
    bool public rescueEnabled = false;

//   ==== MODIFIERS ====

        modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

//   ==== Public Write Functions ====

    function stake(uint256[] memory tokenIds) public whenNotPaused {
        updateReward(msg.sender);
        for (uint256 i; i < tokenIds.length; i++) {
            require(cryptid.ownerOf(tokenIds[i]) == msg.sender, "Not the owner");
            cryptid.transferFrom(msg.sender, address(this), tokenIds[i]);
            ownerOfToken[tokenIds[i]] = msg.sender;
            accountStake[msg.sender].tokens.push(tokenIds[i]);
        }
        accountStake[msg.sender].count = accountStake[msg.sender].count + tokenIds.length;
    }

    function unStake(uint256[] memory tokenIds) public whenNotPaused {
        updateReward(msg.sender);
        for (uint256 i; i < tokenIds.length; i++) {
            require(ownerOfToken[tokenIds[i]] == msg.sender, "Not the owner");
            delete(ownerOfToken[tokenIds[i]]);
            removeToken(msg.sender, tokenIds[i]);
            cryptid.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
        accountStake[msg.sender].count = accountStake[msg.sender].count - tokenIds.length;
    }

    function updateReward(address _staker) public {
        userBountyBalance[_staker] += logic.getPendingReward(_staker);
        updateLastTime(_staker);
    }

    function spendBounty(address _staker, uint256 _amount) external {
        require(tx.origin == _staker, "cannot spend for another user");
        updateReward(_staker);
        require(userBountyBalance[_staker] >= _amount, "You do not have have enough bounty to make this purchase");
        userBountyBalance[_staker] = userBountyBalance[_staker] - _amount;
    }

    function claimBounty(uint256 amount) public whenNotPaused nonReentrant {
        updateReward(msg.sender);
        userBountyBalance[msg.sender] = userBountyBalance[msg.sender] - amount;
        bounty.mint(msg.sender, amount);
    }

    function depositBounty(uint256 amount) public whenNotPaused nonReentrant {
        bounty.burn(msg.sender, amount);
        userBountyBalance[msg.sender] = userBountyBalance[msg.sender] + amount;
    }

//   ==== Public Read Functions ====

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function getAccountStaked(address user) external view returns (Stake memory) {
        return accountStake[user];
    }

    function getAccountStakedTokens(address user) external view returns (uint256[] memory) {
        return accountStake[user].tokens;
    }

    function getAccountStakedCount(address user) external view returns (uint256) {
        return accountStake[user].count;
    }

    function getAccountLastUpdate(address user) external view returns (uint256) {
        return accountStake[user].lastUpdateTime;
    }

    function getBountyBalance(address user) external view returns(uint256) {
        return userBountyBalance[user] + logic.getPendingReward(user);
    }

    
//   ==== Internal Functions ====


    function removeToken(address _user, uint256 id) internal {
        for (uint256 i; i < accountStake[_user].tokens.length; i++) {
            if (accountStake[_user].tokens[i] == id) {
                accountStake[_user].tokens[i] = accountStake[_user].tokens[accountStake[_user].tokens.length - 1];
                accountStake[_user].tokens.pop();
                break;
            }

        }
    }

    function updateLastTime(address _user) internal {
        accountStake[_user].lastUpdateTime = block.timestamp;
    }
    

//   ==== Admin Functions ====

    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }

    function setCryptid(address _cryptid) external onlyOwner { 
        cryptid = ICryptid(_cryptid); 
    }

    function setLogic(address _logic) external onlyOwner {
        logic = IHoldingLogic(_logic);
    }

    function setBounty(address _bounty) external onlyOwner {
        bounty = IBounty(_bounty);
    }

    function emergencyWithdraw(uint256[] memory tokenIds) public onlyOwner whenPaused{
      require(tokenIds.length <= 50, "50 is max per tx");
      for (uint256 i; i < tokenIds.length; i++) {
        address receiver = ownerOfToken[tokenIds[i]];
        if (receiver != address(0) && cryptid.ownerOf(tokenIds[i]) == address(this)) {
          cryptid.transferFrom(address(this), receiver, tokenIds[i]);
        }
      }
    }

}