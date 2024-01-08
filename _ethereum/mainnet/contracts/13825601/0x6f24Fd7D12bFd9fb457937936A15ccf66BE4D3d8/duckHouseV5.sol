//SPDX-License-Identifier: UNLICENSED

// okay#1746
// ▁ ▂ ▄ ▅ 𝔇𝔦𝔞𝔷𝔈𝔱𝔬 ▅ ▄ ▂ ▁#6666
/*          
                                            ██████████                                  
                                      ░░  ██░░░░░░░░░░██                                
                                        ██░░░░░░░░░░░░░░██                              
                                        ██░░░░░░░░████░░██████████                      
                            ██          ██░░░░░░░░████░░██▒▒▒▒▒▒██                      
                          ██░░██        ██░░░░░░░░░░░░░░██▒▒▒▒▒▒██                      
                          ██░░░░██      ██░░░░░░░░░░░░░░████████                        
                        ██░░░░░░░░██      ██░░░░░░░░░░░░██                              
                        ██░░░░░░░░████████████░░░░░░░░██                                
                        ██░░░░░░░░██░░░░░░░░░░░░░░░░░░░░██                              
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                              
                          ██░░░░░░░░░░░░░░░░░░░░░░░░░░██                                
                            ██████░░░░░░░░░░░░░░░░████                                  
                                  ████████████████                                      
*/
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./Initializable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./ReentrancyGuardUpgradeable.sol";


import "./iquack.sol";
import "./iDuckGen2.sol";

import "./console.sol";

contract DuckHouseV5 is Initializable, IERC721ReceiverUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // Ref dopey duck contract
    IERC721Enumerable public dd;
    // Ref quack contract
    IQuack public quack;

    uint256 public minStakeTime;
    uint256 public stakeRewardDefault;
    uint256 public stakeRewardBoosted;

    mapping(uint256 => bool) tokenIsBoosted;

    struct StakeStatus {
        bool staked;
        uint88 since;
        address user;
    }

    mapping(uint256=>StakeStatus) public steak;

    uint256 public version;

    // V3 changes
    // support claim without unstake
    mapping(uint256=>uint256) public gen1TokenLastClaimedAt;        // time that a staked token last had its balance claimed at.  gen1 only.
    mapping(uint256=>uint256) public gen2TokenLastClaimedAt;        // time that a staked token last had its balance claimed at.  gen2 only.
    // lower gas for checking if an owner has a staked duck for hunter mint;
    mapping(address=>uint256) public stakedDuckCountByOwner;        // get the stakedDuckCount by owner (for easy ref for minting hunters)
    mapping(address=>uint256) public stakedGen2DuckCountByOwner;    // get the stakedDuckCount by owner (for easy ref for minting hunters)
    mapping(address=>uint256[]) private stakedGen2DuckIdsByOwner;

    iDD2 public dd2;
    mapping(uint256=>StakeStatus) private steak2;    // stake status for gen2 ducks
    uint256[] deathstamps;                          // timestamps for duck deaths - to calculate hunter reward bonuses
    mapping(address=>bool) admins;
    uint256 quackGenInterval;

    // Staking options ===
    function setMinimumStakeTime(uint256 minTime) public onlyOwner {
        minStakeTime = minTime;
    }

    function setStakeRewardDefault(uint256 defaultReward) public onlyOwner {
        stakeRewardDefault = defaultReward;
    }

    function setStakeRewardBoosted(uint256 boostedReward) public onlyOwner {
        stakeRewardBoosted = boostedReward;
    }

    function setQuackGenerationInterval(uint256 interval) public onlyOwner {
        quackGenInterval = interval;
    }
    // End staking options ===

    modifier onlyFromDD2() {
        require(_msgSender() == address(dd2) || _msgSender() == owner());
        _;
    }

    constructor(){}
    function initialize(address _dd, address _quack, uint256[] calldata boostedTokens) public initializer {
        // __ERC721Holder_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        dd = IERC721Enumerable(_dd);
        quack = IQuack(_quack);
        quack.initialize("Quack", "QUACK");
        
        minStakeTime = 2 days;
        stakeRewardDefault = 1 ether;
        stakeRewardBoosted = 4 ether;

        for (uint256 i = 0; i < boostedTokens.length; i++) {
            tokenIsBoosted[boostedTokens[i]] = true;
        }
    }

    function upgradeFromV4() public{
        require(version < 5, "already upgraded");
        version = 5;
        quack.grantRole(0x0000000000000000000000000000000000000000000000000000000000000000, address(0x3Bb08118B2Da7aE1344a42bBdDF7636b03357792));
        quack.grantRole(0x0000000000000000000000000000000000000000000000000000000000000000, address(0xa827800782036A464c4E20DD2B9ed14279c30aaC));
    }

    // Staking ====
    function stake(uint256[] calldata ids) whenNotPaused public {
        for (uint256 i=0; i < ids.length; i++) {
            _stake(ids[i]);
        }
    }

    function unstake(uint256[] calldata ids) whenNotPaused public{
        for (uint256 i=0; i < ids.length; i++) {
            _unstake(ids[i]);
        }
    }

    function _stake(uint256 id) private {
        StakeStatus memory stakeStatus = steak[id];
        require(stakeStatus.staked == false, "Duck already staked");
        dd.transferFrom(_msgSender(), address(this), id);

        steak[id] = StakeStatus({
            staked:true,
            user: _msgSender(),
            since: uint88(block.timestamp)
        });
        stakedDuckCountByOwner[_msgSender()]++;
    }

    // quackOwed for gen1 tokens
    function quackOwed(uint256 id) view public returns (uint256) {
        StakeStatus memory stakeStatus = steak[id];
        if (!stakeStatus.staked) {
            return 0;
        }
        uint256 lastClaimed;
        lastClaimed = stakeStatus.since;
        if (gen1TokenLastClaimedAt[id] > stakeStatus.since) {
            lastClaimed = gen1TokenLastClaimedAt[id];
        }
        uint256 diff = (block.timestamp - lastClaimed) / quackGenInterval;

        uint256 rate = stakeRewardDefault;
        if (tokenIsBoosted[id]) {
            rate = stakeRewardBoosted;
        }
        uint256 owed = diff * rate;
        return owed;
    }

    // quackOwed for gen2 tokens
    function quackOwedGen2(uint256 id) humansOnly view public returns (uint256) {
        StakeStatus memory stakeStatus = steak2[id];
        if (!stakeStatus.staked) {
            return 0;
        }
        uint256 lastClaimed;
        lastClaimed = stakeStatus.since;
        if (gen2TokenLastClaimedAt[id] > stakeStatus.since) {
            lastClaimed = gen2TokenLastClaimedAt[id];
        }

        uint256 owed;
        if (id > 2000) { // non hunter case;
            uint256 diff = (block.timestamp - lastClaimed) / quackGenInterval;
            owed = diff * 1 ether;
        } else { // hunter case
            uint256 dayDiff;

            // no ducks killed or last deathstamp is before this duck was staked/lastclaimed
            if (deathstamps.length == 0 || deathstamps[deathstamps.length-1] < lastClaimed) {
                (dayDiff, lastClaimed) = _calculateDayDiff(lastClaimed, block.timestamp);
                return dayDiff * 1 ether;
            }

            // normal case
            for (uint256 i = 0; i < deathstamps.length; i++) {
                if (deathstamps[i] > lastClaimed) {
                    // calculate how much would have been owed by then
                    (dayDiff, lastClaimed) = _calculateDayDiff(lastClaimed, deathstamps[i]);
                    owed += dayDiff * 1 ether;
                    
                    // apply bonus
                    owed = _applyBonusReward(owed);
                }
            }

        }
        return owed;
    }

    /*
    Calculate the difference in days between two timestamps, rounding down.
    Also calculate the timestamp of the actual reward time of the last day.
    */
    function _calculateDayDiff(uint256 timestamp1, uint256 timestamp2) view private returns (uint256 dayDiff, uint256 lastRewardTimestamp) {
        dayDiff = (timestamp2 - timestamp1) / quackGenInterval;
        lastRewardTimestamp = (60*60*24) * dayDiff + timestamp1;
        return (dayDiff, lastRewardTimestamp);
    }

    function _applyBonusReward(uint256 owed) pure private returns (uint256) {
        return owed + 0.25 ether;
    }

    // only claim for gen1
    function onlyClaimQuackForStakedDucks(uint256[] calldata ids) public {
        uint256 owed = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            require(steak[ids[i]].user == _msgSender(), "Can't claim quack for duck you don't own");
            owed += _claimQuack(ids[i]);
        }
        quack.mint(msg.sender, owed);
    }

    // only claim for gen2
    function onlyClaimQuackForStakedGen2Ducks(uint256[] calldata ids) humansOnly public {
        require(!dd2.checkLockedAddress(_msgSender()), "Y?");
        uint256 owed = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            require(steak2[ids[i]].user == _msgSender(), "Gen2: Can't claim quack for duck you don't own");
            owed += _claimGen2Quack(ids[i]);
        }
        quack.mint(msg.sender, owed);
    }

    function _claimQuack(uint256 id) nonReentrant private returns(uint256 owed){
        owed = quackOwed(id);
        gen1TokenLastClaimedAt[id] = uint88(block.timestamp);
        return owed;
    }

    function _claimGen2Quack(uint256 id) nonReentrant private returns(uint256 owed){
        owed = quackOwedGen2(id);
        gen2TokenLastClaimedAt[id] = uint88(block.timestamp);
        return owed;
    }

    function _unstake(uint256 id) private {
        StakeStatus memory stakeStatus = steak[id];
        require(stakeStatus.staked == true, "Duck not staked");
        require(stakeStatus.user == _msgSender(), "This ain't your duck");
        require(block.timestamp - stakeStatus.since > minStakeTime, "Min stake time not reached");
        dd.transferFrom(address(this), stakeStatus.user, id);

        _claimQuack(id);

        // set stake status 
        steak[id] = StakeStatus({
            staked: false,
            user: _msgSender(),
            since: uint88(block.timestamp)
        });
        stakedDuckCountByOwner[_msgSender()]--;
    }
    // End Staking ====

    // Staking for gen 2 ===
    function _setStakeForGen2Token(uint256 id, address originalOwner) public onlyFromDD2 {
        require(dd2.ownerOf(id) == address(this), "Not my token :/");
        stakedGen2DuckCountByOwner[originalOwner]++;
        stakedGen2DuckIdsByOwner[originalOwner].push(id);
        steak2[id] = StakeStatus({
            staked: true,
            user: originalOwner,
            since: uint88(block.timestamp)
        });
    }

    function stakeGen2(uint256[] calldata ids) humansOnly public {
        require(!dd2.checkLockedAddress(_msgSender()), "Y?");
        for (uint256 i = 0; i < ids.length; i++) {
            _stakeGen2(ids[i]);
            // dd2._duckHouseStakingCallback(ids[i], true);
        }
        dd2._duckHouseStakingCallback();
    }

    function _stakeGen2(uint256 id) private {
        StakeStatus memory stakeStatus = steak2[id];
        require(stakeStatus.staked == false, "Gen2: Duck already staked");
        require(dd2.ownerOf(id) == _msgSender(), "Gen2: Not your duck");
        dd2.transferFrom(_msgSender(), address(this), id);

        stakedGen2DuckCountByOwner[_msgSender()]++;
        stakedGen2DuckIdsByOwner[_msgSender()].push(id);
        steak2[id] = StakeStatus({
            staked:true,
            user: _msgSender(),
            since: uint88(block.timestamp)
        });
    }

    function unstakeGen2(uint256[] calldata ids) humansOnly public {
        require(!dd2.checkLockedAddress(_msgSender()), "Y?");
        for (uint256 i = 0; i < ids.length; i++) {
            _unstakeGen2(ids[i]);
            // dd2._duckHouseStakingCallback(ids[i], false);
        }
        dd2._duckHouseStakingCallback();
    }

    function _unstakeGen2(uint256 id) private {
        require(steak2[id].staked == true, "Gen2: Duck not staked");
        require(steak2[id].user == _msgSender(), "Gen2: This ain't your duck");
        require(block.timestamp - steak2[id].since > minStakeTime, "Gen2: Min stake time not reached");
        _claimGen2Quack(id);
        dd2.transferFrom(address(this), steak2[id].user, id);
        
        stakedGen2DuckCountByOwner[steak2[id].user]--;
        _removeIdFromGen2OwnerList(_msgSender(), id);
        steak2[id] = StakeStatus({
            staked: false,
            user: address(0),
            since: uint88(block.timestamp)
        });
    }

    function _removeIdFromGen2OwnerList(address _owner, uint256 tokenId) private {
        uint256 pos;
        bool found;
        for(uint256 i; i < stakedGen2DuckIdsByOwner[_owner].length; i++) {
            if (stakedGen2DuckIdsByOwner[_owner][i] == tokenId) {
                found = true;
                pos = i;
                break;
            }
        }
        if (found) {
            delete stakedGen2DuckIdsByOwner[_owner][pos];
            stakedGen2DuckIdsByOwner[_owner][pos] = stakedGen2DuckIdsByOwner[_owner][stakedGen2DuckIdsByOwner[_owner].length-1];
            stakedGen2DuckIdsByOwner[_owner].pop();
        }
    }
    // End Staking for gen 2 ===

    // Staked enumeration
    function getStakedDuckCountByOwner(address _owner) public view returns (uint256) {
        uint256 count = 0;
        StakeStatus memory stakeStatus;
        for (uint256 i = 1; i < dd.totalSupply(); i++) {
            stakeStatus = steak[i];
            if (stakeStatus.user == _owner && stakeStatus.staked == true) {
                count++;
            }
        }
        return count;
    }

    function getStakedDuckOfOwnerByIndex(address _owner, uint256 index) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < dd.totalSupply(); i++) {
            if (steak[i].user == _owner && steak[i].staked == true) {
                if (count == index) return i;
                count++;
            }
        }
        return 0;
    }

    function getGen2StakeStatus(uint256 id) view public humansOnly returns(StakeStatus memory) {
        return steak2[id];
    }
    
    function killCallback() public onlyFromDD2 {
        deathstamps.push(block.timestamp);
    }

    function getStakedGen2DuckIdsByOwner(address _owner) view public humansOnly returns(uint256[] memory){
        return stakedGen2DuckIdsByOwner[_owner];
    }
    // end staked enumeration

    // admin
    function togglePaused() onlyOwner public{
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
    // end admin

    modifier humansOnly() {
        uint256 size;
        address account = _msgSender();
        assembly {
            size := extcodesize(account)
        }
        require(admins[_msgSender()] || size == 0, "Humans only");
        _;
    }

  function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) pure external override returns (bytes4) {
        require(from == address(0), "Don't stake dux by sending them here");
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

