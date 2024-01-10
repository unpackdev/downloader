// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

interface TKONFT{
    function ownerOf(uint256 tokenId) external returns (address);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;
}

interface UtilityToken{
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract StakingPool is IERC721Receiver, Ownable{
    using EnumerableSet for EnumerableSet.UintSet;

    event StakeStarted(address indexed user, uint256 indexed tokenId);
    event StakeStopped(address indexed user, uint256 indexed tokenId);
    event UtilityAddrSet(address from, address addr);
    event StartStakingTimeChanged(uint256 newTime, uint256 currentTime);
    event EndStakingTimeChanged(uint256 newTime, uint256 currentTime);
    event GetReward(address indexed user, uint256 amount);

    UtilityToken private _utilityToken;
    TKONFT private _tentacle;
    struct StakedInfo {
        uint256 lastUpdate;
    }

    mapping(uint256 => StakedInfo) private tokenInfo;
    mapping(address => EnumerableSet.UintSet) private stakedTko;
    address private _tkoContract;
    uint256 public rewardUnit = 333;
    uint256 private _tTotal = 26000000;
    uint256 private _nowTotal = 0;
    uint256 public startTimeOfStaking;
    uint256 public endTimeOfStaking;

    modifier masterContract() {
        require(
            msg.sender == _tkoContract,
            "Master Contract can only call Staking Contract"
        );
        _;
    }

    modifier enableStaking() {
        require(startTimeOfStaking!=0 && endTimeOfStaking!=0, 'Start and end time of staking not set');
        require(
            endTimeOfStaking >= startTimeOfStaking,
            "Staking Mechanism is not started yet"
        );
        _;
    }

    constructor(address _tkoAddr) {
        _tkoContract = _tkoAddr;
        startTimeOfStaking=0;
        endTimeOfStaking=0;
        _tentacle = TKONFT(_tkoAddr);
    }

    function setUtilitytoken(address payable _addr) external onlyOwner {
        _utilityToken = UtilityToken(_addr);
        emit UtilityAddrSet(address(this), _addr);
    }
    
    function changeRewardUnit(uint256 _rewardUnit) external onlyOwner {
        rewardUnit = _rewardUnit;
    }

    

    function setStartStakingTime(uint256 _timeStamp) external onlyOwner {
        startTimeOfStaking = _timeStamp;
        emit StartStakingTimeChanged(startTimeOfStaking, block.timestamp);
    }

    function setEndStakingTime(uint256 _timeStamp) external onlyOwner {
        endTimeOfStaking = _timeStamp;
        emit EndStakingTimeChanged(endTimeOfStaking, block.timestamp);
    }

    function startStakings(address _user, uint256[] memory _tokenIds)
        external
    {
        require(_tokenIds.length>=4, "4 NFTs min to stake");
        
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(!stakedTko[_user].contains(_tokenIds[i]), "Already staked");
            require(_tentacle.ownerOf(_tokenIds[i]) == msg.sender, "Staking: owner not matched");
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenInfo[_tokenIds[i]].lastUpdate = block.timestamp;
            stakedTko[_user].add(_tokenIds[i]);
            _tentacle.safeTransferFrom(_user, address(this), _tokenIds[i], "");
            emit StakeStarted(_user, _tokenIds[i]);
        }
    }

    function stopStaking(address _user, uint256 _tokenId)
        external
        enableStaking
        masterContract
    {
        require(stakedTko[_user].contains(_tokenId), "You're not the owner");
        require(block.timestamp >= startTimeOfStaking, "Didn't start staking");
        uint256 interval;
        if(block.timestamp<endTimeOfStaking){
            interval = block.timestamp - tokenInfo[_tokenId].lastUpdate;
        }else{
            interval = endTimeOfStaking - tokenInfo[_tokenId].lastUpdate -1;
        }
        uint256 day=interval / 86400;
        uint256 reward = rewardUnit * day * 10**9;
        if(reward>0){
            _utilityToken.transfer(_user, reward);
        }
        delete tokenInfo[_tokenId];
        stakedTko[_user].remove(_tokenId);

        emit StakeStopped(_user, _tokenId);
    }

    function stakedTokensOf(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](stakedTko[_user].length());
        for (uint256 i = 0; i < stakedTko[_user].length(); i++) {
            tokens[i] = stakedTko[_user].at(i);
        }
        return tokens;
    }

    function getClaimableToken(address _user) public view enableStaking returns (uint256) {
        uint256[] memory tokens = stakedTokensOf(_user);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 interval;
            if(block.timestamp<endTimeOfStaking){
                interval = block.timestamp - tokenInfo[tokens[i]].lastUpdate;
            }else{
                interval = endTimeOfStaking - tokenInfo[tokens[i]].lastUpdate -1;
            }
            uint256 day=interval / 86400;
            uint256 reward = rewardUnit * day * 10**9;

            totalAmount += reward;
        }

        return totalAmount;
    }

    function getReward() external enableStaking {
        uint256 reward = getClaimableToken(msg.sender);
        require(reward>0, "reward must be greater than zero");
        _utilityToken.transfer(msg.sender, reward);
        emit GetReward(msg.sender, reward);
        for (uint256 i = 0; i < stakedTko[msg.sender].length(); i++) {
            uint256 tokenId = stakedTko[msg.sender].at(i);
            tokenInfo[tokenId].lastUpdate = block.timestamp;
        }
    }

    /**
     * ERC721Receiver hook for single transfer.
     * @dev Reverts if the caller is not the whitelisted NFT contract.
     */
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /* tokenId */
        bytes calldata /*data*/
    ) external view override returns (bytes4) {
        require(
            _tkoContract == msg.sender,
            "You can stake only Tko"
        );
        return this.onERC721Received.selector;
    }
}
