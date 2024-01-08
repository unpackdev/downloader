//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Initializable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./ReentrancyGuardUpgradeable.sol";


import "./quack.sol";

contract DuckHouseV1 is Initializable, IERC721ReceiverUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // Ref dopey duck contract
    IERC721 public dd;
    // Ref quack contract
    Quack public quack;

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

    uint256 version;

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
    // End staking options ===

    constructor(){}
    function initialize(address _dd, address _quack, uint256[] calldata boostedTokens) public initializer {
        // __ERC721Holder_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        dd = IERC721(_dd);
        quack = Quack(_quack);
        quack.initialize("Quack", "QUACK");
        
        minStakeTime = 2 days;
        stakeRewardDefault = 1 ether;
        stakeRewardBoosted = 4 ether;

        for (uint256 i = 0; i < boostedTokens.length; i++) {
            tokenIsBoosted[boostedTokens[i]] = true;
        }
        version = 1;
    }

    // Staking ====
    function stake(uint256[] calldata ids) public {
        for (uint256 i=0; i < ids.length; i++) {
            _stake(ids[i]);
        }
    }

    function unstake(uint256[] calldata ids) public{
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
    }

    function quackOwed(uint256 id) view public returns (uint256) {
        StakeStatus memory stakeStatus = steak[id];
        if (!stakeStatus.staked) {
            return 0;
        }
        uint256 diff = (block.timestamp - stakeStatus.since) / 1 days;

        uint256 rate = stakeRewardDefault;
        if (tokenIsBoosted[id]) {
            rate = stakeRewardBoosted;
        }
        uint256 owed = diff * rate;
        return owed;
    }

    function _claimQuack(uint256 id) private {
        uint256 owed = quackOwed(id);
        quack.mint(msg.sender, owed);
        steak[id].since = uint88(block.timestamp);
    }

    function _unstake(uint256 id) nonReentrant private {
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
    }
    // End Staking ====

  function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) nonReentrant external override returns (bytes4) {
      return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

