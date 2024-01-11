pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721AQueryable.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./IERC721Receiver.sol";


contract StakePool is Ownable,Pausable,IERC721Receiver{
    ERC721AQueryable public cryptoWarrior;
    IERC20 public cryptoWarriorGold;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public reward_per_day;
    uint256 public unstaked_gap_time;
    uint256 public reward_gap_time;
    
    event Stake(address indexed user,uint256[] tokenIds);
    event GetReward(address indexed user,uint256 reward,uint256[] tokenIds);
    event UnStake(address indexed user,uint256[] tokenIds);

    modifier callerIsNotContract() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }

    struct StakeStatus{
        uint256 tokenId;
        address owner;
        uint256 startTime;
    }

    //tokenid => StakeStatus
    mapping(uint256=>StakeStatus) private stakeStatusMap;

    //user address => staked tokenId array
    // mapping (address=>EnumerableSet.UintSet) private userStakedMap;

    constructor(address cryptoWarrior_,address cryptoWarriorGold_){
        cryptoWarrior=ERC721AQueryable(cryptoWarrior_);
        cryptoWarriorGold=IERC20(cryptoWarriorGold_);

        reward_per_day = 1000 * 10**18;
        unstaked_gap_time = 3600 * 24 * 3;
        reward_gap_time = 3600 * 24;
    }

    function setReward(uint256 reward) public onlyOwner{
        reward_per_day = reward;
    }

    function stake(uint256[] memory warriors) public callerIsNotContract whenNotPaused{
        for(uint256 i =0;i<warriors.length;i++){
            if(stakeStatusMap[warriors[i]].startTime!=0){
                continue;
            }
            stakeStatusMap[warriors[i]] =StakeStatus(warriors[i],msg.sender,block.timestamp); 
            cryptoWarrior.safeTransferFrom(msg.sender, address(this), warriors[i]);
        }
        emit Stake(msg.sender, warriors);
    }

    function getStakeStatus(uint256 tokenId) public view returns(uint256,address,uint256){
        StakeStatus memory status = stakeStatusMap[tokenId];
        return (status.tokenId,status.owner,status.startTime);
    }

    //use this to save gas
    function getUserStaked(address user) public view returns(uint256[] memory){
        uint256 size = 0;
        for(uint256 i=0;i<cryptoWarrior.totalSupply();i++){
            if(stakeStatusMap[i].owner == user){
                size++;
            }
        }
        uint[] memory ids = new uint[](size);
        size = 0;
        for(uint256 i=0;i<cryptoWarrior.totalSupply();i++){
            if(stakeStatusMap[i].owner == user){
                ids[size] = i;
                size++;
            }
        }
        return ids;
    }

    function getRewards(uint256[] memory warriors) public callerIsNotContract whenNotPaused{
        uint256 reward = 0;
        for(uint256 i =0;i<warriors.length;i++){
            StakeStatus storage status = stakeStatusMap[warriors[i]];
            require(status.owner==msg.sender,"You are not owner.");
            if(block.timestamp - status.startTime > reward_gap_time){
                uint256 day = (block.timestamp - status.startTime )/reward_gap_time;
                if(day >= 1){
                    reward += day * reward_per_day;
                }
                status.startTime = status.startTime + day * reward_gap_time;
            }
        }
        require(reward!=0,"No reward.");

        cryptoWarriorGold.transfer(msg.sender, reward);
        emit GetReward(msg.sender, reward,warriors);
    }

    function unstake(uint256[] memory warriors) public callerIsNotContract whenNotPaused{
        bool unstakeFlag = false;
        for(uint256 i =0;i<warriors.length;i++){
            uint256 id = warriors[i];
            StakeStatus storage status = stakeStatusMap[id];
            if(status.owner==msg.sender && block.timestamp - status.startTime > unstaked_gap_time){
                status.startTime = 0;
                status.owner = address(0);
                status.tokenId = 0;
                cryptoWarrior.safeTransferFrom(address(this), msg.sender, id);
                unstakeFlag = true;
            }
        }
        require(unstakeFlag,"No warrior can be unstaked.");
        emit UnStake(msg.sender, warriors);
    }

    function withdrawEmergency(address to,uint256 amount) public onlyOwner{
        cryptoWarriorGold.transferFrom(address(this), to, amount);
    }

    function withdrawWarriorEmergency(address to,uint256 tokenId) public onlyOwner{
        StakeStatus storage status = stakeStatusMap[tokenId];
        status.startTime = 0;
        status.owner = address(0);
        status.tokenId = 0;
        cryptoWarrior.safeTransferFrom(address(this), to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )external override pure returns (bytes4){
        return this.onERC721Received.selector;
    }
}