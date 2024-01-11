//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Omc.sol";
import "./IOmcDistributor.sol";
import "./OMCLib.sol";

contract OmcDistributor is IOmcDistributor, ReentrancyGuard {
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public omcEpoch;
    address public omc;
    uint256 public omcEpochNum;
    mapping(uint256 => uint256) public lastEpochPerTokenId;
    mapping(uint256 => uint256) public epochReward;
    mapping(uint256 => uint256) public epochTotalSupply;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY OWNER");
        _;
    }

    modifier onlyEpoch() {
        require(msg.sender == omcEpoch, "ONLY OMC_EPOCH");
        _;
    }

    constructor(address _omc, address _omcEpoch) {
        owner = msg.sender;
        omc = _omc;
        omcEpoch = _omcEpoch;
    }

    function setOmc(address _newOmc) external override onlyOwner {
        omc = _newOmc;
    }

    function setOmcEpoch(address _newOmcEpoch) external override onlyOwner {
        omcEpoch = _newOmcEpoch;
    }

    function compound(
        uint256 _epochNum,
        uint256 _totalRewardAmount,
        uint256 _totalSupply
    ) external override onlyEpoch {
        omcEpochNum = _epochNum;
        epochReward[omcEpochNum] = _totalRewardAmount / _totalSupply;
        epochTotalSupply[omcEpochNum] = _totalSupply;

        emit Compound(
            _epochNum,
            _totalRewardAmount,
            epochReward[omcEpochNum],
            _totalSupply
        );
    }

    function _checkEpochNum(uint256 tokenId) internal view returns (bool) {
        if (lastEpochPerTokenId[tokenId] > omcEpochNum) return true;
        return false;
    }

    function pendingReward(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        if (_checkEpochNum(tokenId)) return 0;
        uint256 reward;
        for (
            uint256 index = lastEpochPerTokenId[tokenId];
            index <= omcEpochNum;
            index++
        ) {
            if (epochTotalSupply[index] <= tokenId) continue;

            reward += epochReward[index];
        }
        return reward;
    }

    function withdrawReward(uint256 tokenId) public override nonReentrant {
        if (_checkEpochNum(tokenId)) return;
        address tokenOwner = IERC721(omc).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "ONLY OWNER CAN WITHDRAW");

        uint256 reward;
        uint256 index;
        for (
            index = lastEpochPerTokenId[tokenId];
            index <= omcEpochNum;
            index++
        ) {
            if (epochTotalSupply[index] <= tokenId) continue;

            reward += epochReward[index];
            if (gasleft() < 40000) break;
        }
        lastEpochPerTokenId[tokenId] = index;
        if (reward > 0) OMCLib._safeTransfer(WETH, msg.sender, reward);
        emit RewardWithdrawal(tokenId, lastEpochPerTokenId[tokenId], reward);
    }
}
