// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IMomocoToken.sol";


contract MomocoStaking is Ownable, Pausable, ReentrancyGuard, Initializable {
    struct StakingRule {
        uint128 duration;
        uint128 amount;
    }

    address public nft;
    address public token;
    uint public maxRule; // start 1
    mapping(uint => StakingRule) public stakingRules;
    mapping(uint => uint) public stakingTime;
    mapping(uint => uint) public stakingRuleId;
    mapping(address =>uint[]) public staked;

    event Claimed(address indexed _user, uint indexed _tokenId, uint indexed _amount);
    event StakeAdded(address indexed _user, uint indexed _tokenId);
    event StakedRemoved(address indexed _user, uint indexed _tokenId);
 
    function initialize(address _nft, address _token, uint32 _maxRule) external initializer {
        nft = _nft;
        token = _token;
        maxRule = _maxRule;
        owner = msg.sender;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
            
    function setMaxRule(uint32 _maxRule) external onlyOwner {
        require(maxRule != _maxRule, 'NO_CHANGE');
        maxRule = _maxRule;
    }

    function setStakingRule(uint _id, StakingRule memory _rule) public onlyOwner {
        require(_id > 0, 'INVALID_ID');
        stakingRules[_id] = _rule;
    }

    function setStakingRules(uint[] calldata _ids, StakingRule[] memory _rules) external onlyOwner {
        require(_ids.length == _rules.length, 'INVALID_PARAM');
        for(uint i; i<_ids.length; i++) {
            setStakingRule(_ids[i], _rules[i]);
        }
    }

    function _claim(uint  _tokenId) internal returns (uint) {
        uint amount = queryClaim(_tokenId);
        if(amount == 0) {
            return 0;
        }
        
        uint ruleId;
        for(uint i=stakingRuleId[_tokenId]+1; i<=maxRule; i++) {
            if(stakingTime[_tokenId] > 0 && block.timestamp - stakingTime[_tokenId] > uint(stakingRules[i].duration)) {
                ruleId = i;
            }
        }

        if(ruleId > stakingRuleId[_tokenId]) stakingRuleId[_tokenId] = ruleId;

        IMomocoToken(token).mint(msg.sender, amount);
        emit Claimed(msg.sender, _tokenId, amount);
        return amount;
    }

    function claim(uint  _tokenId) external whenNotPaused {
        require(isStaked(msg.sender, _tokenId), 'NON-STAKED');
        uint amount = _claim(_tokenId);
        require(amount > 0, 'ZERO');
    }

    function onERC721Received(
        address /*_operator*/,
        address _from,
        uint256 _tokenId,
        bytes calldata /* data */
    ) external returns (bytes4) {
        require(msg.sender == nft, 'ERC721_RECEIVED_INVAILD_SENDER');
        require(_from != address(this), 'ERC721_RECEIVED_INVAILD_FROM');
        _addStake(_from, _tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _addStake(address _user, uint _tokenId) internal returns (bool) {
        require(_user != address(0), 'ZERO_ADDR');
        require(!isStaked(_user, _tokenId), 'STAKED');
        stakingTime[_tokenId] = block.timestamp;
        staked[_user].push(_tokenId);
        emit StakeAdded(_user, _tokenId);
        return true;
    }

    function addStake(uint _tokenId) public returns (bool) {
        IERC721(nft).safeTransferFrom(msg.sender, address(this), _tokenId);
        return true;
    }

    function removeStake(uint _tokenId) public returns (bool) {
        uint index = indexStake(msg.sender, _tokenId);
        require(index != staked[msg.sender].length, 'NOT_FOUND_STAKED');
        require(isStaked(msg.sender, _tokenId), 'NON-STAKED');

        _claim(_tokenId);

        if(index < staked[msg.sender].length-1) {
            staked[msg.sender][index] = staked[msg.sender][staked[msg.sender].length-1];
        }
        staked[msg.sender].pop();
        stakingTime[_tokenId] = 0;

        IERC721(nft).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit StakedRemoved(msg.sender, _tokenId);
        return true;
    }

    function addStakes(uint[] calldata _tokenIds) external returns (bool) {
        for(uint i; i< _tokenIds.length; i++) {
            addStake(_tokenIds[i]);
        }
        return true;
    }

    function removeStakes(uint[] calldata _tokenIds) external returns (bool) {
        for(uint i; i< _tokenIds.length; i++) {
            removeStake(_tokenIds[i]);
        }
        return true;
    }

    function indexStake(address _user, uint _tokenId) public view returns (uint) {
        for(uint i; i < staked[_user].length; i++) {
            if(_tokenId == staked[_user][i]) {
                return i;
            }
        }
        return staked[_user].length;
    }

    function isStaked(address _user, uint _tokenId) public view returns (bool) {
        for(uint i; i < staked[_user].length; i++) {
            if(_tokenId == staked[_user][i]) {
                return true;
            }
        }
        return false;
    }

    function countStake(address _user) public view returns (uint) {
        return staked[_user].length;
    }

    function canStake(uint _tokenId) public view returns (bool) {
        return stakingRuleId[_tokenId] < maxRule && stakingTime[_tokenId] == 0;
    }

    function queryClaim(uint _tokenId) public view returns (uint) {
        if(stakingRuleId[_tokenId] >= maxRule) {
            return 0;
        }
        
        uint amount;
        for(uint i=stakingRuleId[_tokenId]+1; i<=maxRule; i++) {
            if(stakingTime[_tokenId] > 0 && block.timestamp - stakingTime[_tokenId] > uint(stakingRules[i].duration)) {
                amount += uint(stakingRules[i].amount);
            }
        }

        if(IMomocoToken(token).take() < amount) {
            return 0;
        }
        return amount;
    }

    function getStaked(address _user) external view returns (uint[] memory) {
        return staked[_user];
    }
}