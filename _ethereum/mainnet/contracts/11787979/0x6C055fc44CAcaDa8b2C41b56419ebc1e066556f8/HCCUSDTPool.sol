pragma solidity ^0.6.0;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: HAYEKCASHRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// File: @openzeppelin/contracts/math/Math.sol

import "./Math.sol";

// File: @openzeppelin/contracts/math/SafeMath.sol

import "./SafeMath.sol";

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

import "./IERC20.sol";

// File: @openzeppelin/contracts/utils/Address.sol

import "./Address.sol";

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

import "./SafeERC20.sol";

// File: contracts/IRewardDistributionRecipient.sol

import "./IRewardDistributionRecipient.sol";

contract USDTWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public usdt;

    uint256 private _totalSupply;
    uint256 private _totalInternalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _internalBalances;

    function totalInternalSupply() public view returns (uint256) {
        return _totalInternalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function internalBalanceOf(address account) public view returns (uint256) {
        return _internalBalances[account];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount, uint256 userBoostPower) internal {
        _totalSupply = _totalSupply.add(amount);
        _totalInternalSupply = _totalInternalSupply.add(amount.mul(userBoostPower.add(1e18)).div(1e18));
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _internalBalances[msg.sender] = _internalBalances[msg.sender].add((amount.mul(userBoostPower.add(1e18)).div(1e18)));
        usdt.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, uint256 userBoostPower) internal {
        _totalSupply = _totalSupply.sub(amount);
        _totalInternalSupply = _totalInternalSupply.sub(amount.mul(userBoostPower.add(1e18)).div(1e18));
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _internalBalances[msg.sender] = _internalBalances[msg.sender].sub((amount.mul(userBoostPower.add(1e18)).div(1e18)));
        usdt.safeTransfer(msg.sender, amount);
    }

    function _update(uint256 _userBoostPower) internal {
        uint256 oldInternalBalance = _internalBalances[msg.sender];
        uint256 newInternalBalance = _balances[msg.sender].mul(_userBoostPower.add(1e18)).div(1e18);
        _internalBalances[msg.sender] = newInternalBalance;
        _totalInternalSupply = _totalInternalSupply.sub(oldInternalBalance).add(newInternalBalance);
    }
}

interface IHayekPlate {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transfer(address _to, uint256 _tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getFeatureAddr() external returns(address);
}

interface IHayekPlateCustomData {
    function getTokenIdBoostPower(uint256 tokenId) external view returns(uint256);
}

contract HayekPlateWrapper {
    using SafeMath for uint256;
    IHayekPlate public hayekPlate; 
    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(address => uint256) private _ownedBoostPower;
    mapping (uint256 => address) private _tokenOwner;
    
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function totalNFTSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function stakePlate(uint256 tokenId) public virtual {
        require(msg.sender == hayekPlate.ownerOf(tokenId), 'This account is not owner');
        _tokenOwner[tokenId] = msg.sender;
        _addTokenToOwnerEnumeration(msg.sender, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
        uint256 _plateBoostPower = getTokenIdBoostPower(tokenId);
        _ownedBoostPower[msg.sender] += _plateBoostPower;
        hayekPlate.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function withdrawPlate(uint256 tokenId) public virtual {
        require(msg.sender == _tokenOwner[tokenId], 'This account is not owner');
        _removeTokenFromOwnerEnumeration(msg.sender, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);
        uint256 _plateBoostPower = getTokenIdBoostPower(tokenId);
        _ownedBoostPower[msg.sender] -= _plateBoostPower;
        hayekPlate.transfer(msg.sender, tokenId);
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        _ownedTokens[from].pop();
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }

    function getAccountBoostPower(address account) public view returns(uint256){
        return _ownedBoostPower[account];
    }

    function getStakedTokenIds(address account) public view returns(uint256[] memory){
        return _ownedTokens[account];
    }

    function getTokenIdBoostPower(uint256 tokenId) internal returns(uint256){
        address customDataAddr = hayekPlate.getFeatureAddr();
        IHayekPlateCustomData hayekPlateCustomData = IHayekPlateCustomData(customDataAddr);
        return hayekPlateCustomData.getTokenIdBoostPower(tokenId);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external 
        returns (bytes4) 
    {
        // Shh
        return _ERC721_RECEIVED;
    }
}

contract HCCUSDTPool is HayekPlateWrapper, USDTWrapper, IRewardDistributionRecipient {
    IERC20 public hayekCash;
    uint256 public DURATION = 10 days;
    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public deposits;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event PlateStaked(address indexed user, uint256 tokenId);
    event PlateWithdrawn(address indexed user, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address hayekCash_,
        address usdt_,
        address hayekPlate_,
        uint256 starttime_
    ) public {
        hayekCash = IERC20(hayekCash_);
        usdt = IERC20(usdt_);
        hayekPlate = IHayekPlate(hayekPlate_);
        starttime = starttime_;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, 'HCCUSDTPool: not start');
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalInternalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalInternalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            internalBalanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stakePlate(uint256 tokenId) 
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(tokenId > 0, 'HCCUSDTPool: Invalid tokenId');
        super.stakePlate(tokenId);
        uint256 userBoostPower = getAccountBoostPower(msg.sender);
        _update(userBoostPower);
        emit PlateStaked(msg.sender, tokenId);
    }

    function withdrawPlate(uint256 tokenId) 
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(tokenId > 0, 'HCCUSDTPool: Invalid tokenId');
        super.withdrawPlate(tokenId);
        uint256 userBoostPower = getAccountBoostPower(msg.sender);
        _update(userBoostPower);
        emit PlateWithdrawn(msg.sender, tokenId);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'HCCUSDTPool: Cannot stake 0');
        uint256 newDeposit = deposits[msg.sender].add(amount);
        require(
            newDeposit <= 20000e6,
            'HCCUSDTPool: deposit amount exceeds maximum 20000'
        );
        deposits[msg.sender] = newDeposit;
        uint256 userBoostPower = getAccountBoostPower(msg.sender);
        super.stake(amount, userBoostPower);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, 'HCCUSDTPool: Cannot withdraw 0');
        deposits[msg.sender] = deposits[msg.sender].sub(amount);
        uint256 userBoostPower = getAccountBoostPower(msg.sender);
        super.withdraw(amount, userBoostPower);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            hayekCash.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }
    }
}
