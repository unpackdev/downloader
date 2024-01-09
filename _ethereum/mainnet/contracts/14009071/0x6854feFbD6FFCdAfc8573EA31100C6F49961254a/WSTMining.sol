// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./InternalWhitelistControl.sol";
import "./WallStreetArt.sol";
import "./WST.sol";

contract WSTMining is Ownable, InternalWhitelistControl
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    WallStreetArt public wsa;
    WST public wst;

    uint256 private _totalSupply = 0;

    uint256 constant public OneDay = 1 days;
    uint256 constant public Percent = 100;
    uint256 constant public Thousand = 1000;


    uint256 public starttime;
    uint256 public periodFinish = 0;
    //note that, you should combine the bonus rate to get the final production rate
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(uint256 => uint256) public tokenIdRewardPerTokenPaid;
    mapping(uint256 => uint256) public rewards;
    mapping(uint256 => bool) public stakedTokens;

    event Staked(uint256 [] tokenIds);
    event TransferBack(address token, address to, uint256 amount);

    constructor(
        address _wsa, //wsa
        address _wst, //wst
        uint256 _starttime
    ) {
        require(_wsa != address(0), "_wsa is zero address");
        require(_wst != address(0), "_wst is zero address");

        wsa = WallStreetArt(_wsa);
        wst = WST(_wst);
        starttime = _starttime;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, 'Pool: not start');
        _;
    }

    modifier updateReward(uint256 [] memory tokenIds, bool firstStake) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();


        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (firstStake) {
                //remove all reward between the very start and current moment
                tokenIdRewardPerTokenPaid[tokenId] = rewardPerTokenStored;
            }

            rewards[tokenId] = earned(tokenId);

            tokenIdRewardPerTokenPaid[tokenId] = rewardPerTokenStored;
        }

        _;
    }


    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
        );
    }

    function earned(uint256 tokenId) public view returns (uint256) {

        return rewardPerToken().sub(tokenIdRewardPerTokenPaid[tokenId]).add(rewards[tokenId]);

    }

    function earnedAll(uint256 [] memory tokenIds) public view returns (uint256){
        uint256 _reward = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {

            _reward = _reward.add(
                earned(tokenIds[i])
            );
        }

        return _reward;
    }


    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    //7acb7757
    function stake(uint256 [] memory tokenIds)
    public
    updateReward(tokenIds,true)
    checkStart
    internalWhitelisted(msg.sender)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {

            uint256 tokenId = tokenIds[i];

            require(wsa.ownerOf(tokenId) != address(0), 'tokenId not exist');

            require(!stakedTokens[tokenId], 'tokenId already in mining');
            stakedTokens[tokenId] = true;

            rewards[tokenId] = rewards[tokenId].add(1000 ether);

            _totalSupply = _totalSupply.add(1);
        }
        emit Staked(tokenIds);
    }

    //hook the bonus when user getReward
    function getReward(uint256[] memory tokenIds) public payable updateReward(tokenIds,false) checkStart {
        uint256 reward = earnedAll(tokenIds);
        if (reward > 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(wsa.ownerOf(tokenIds[i]) == msg.sender, 'invalid owner');
                rewards[tokenIds[i]] = 0;
            }
            WST(wst).mint(msg.sender, reward);
        }
    }

    function transferBack(IERC20 erc20Token, address to, uint256 amount) external onlyOwner {
        if (address(erc20Token) == address(0)) {
            payable(to).transfer(amount);
        } else {
            erc20Token.safeTransfer(to, amount);
        }
        emit TransferBack(address(erc20Token), to, amount);
    }

    //you can call this function many time as long as block.number does not reach starttime and _starttime
    function initSet(
        uint256 _starttime,
        uint256 rewardPerDay,
        uint256 _periodFinish
    )
    external
    onlyOwner
    updateReward(new uint256[](0),true)
    {

        require(block.timestamp < starttime, "block.timestamp < starttime");

        require(block.timestamp < _starttime, "block.timestamp < _starttime");
        require(_starttime < _periodFinish, "_starttime < _periodFinish");

        starttime = _starttime;
        rewardRate = rewardPerDay.div(OneDay);
        periodFinish = _periodFinish;
        lastUpdateTime = starttime;
    }

    function updateRewardRate(uint256 rewardPerDay, uint256 _periodFinish)
    external
    onlyOwner
    updateReward(new uint256[](0),true)
    {
        if (_periodFinish == 0) {
            _periodFinish = block.timestamp;
        }

        require(starttime < block.timestamp, "starttime < block.timestamp");
        require(block.timestamp <= _periodFinish, "block.timestamp <= _periodFinish");

        rewardRate = rewardPerDay.div(OneDay);
        periodFinish = _periodFinish;
        lastUpdateTime = block.timestamp;
    }

    //=======================

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

}
