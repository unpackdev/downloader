// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./Ownable.sol";

import "./IMetroBlockInfo.sol";
import "./MetroMiniBlock.sol";
import "./MetToken.sol";

contract MetroMiniBlockClaim is Ownable {

    address immutable public tokenAddress;
    address immutable public miniBlockAddress;
    address public blockInfoAddress;

    bool claimDisabled;

    event Claimed(address indexed owner, uint256 amount);

    constructor(address _tokenAddress, address _miniBlockAddress) {
        tokenAddress = _tokenAddress;
        miniBlockAddress = _miniBlockAddress;
    }

    function setBlockInfoAddress(address _blockInfoAddress) public onlyOwner {
        blockInfoAddress = _blockInfoAddress; 
    }

    function enableClaim() external onlyOwner {
        claimDisabled = false;
    }

    function disableClaim() external onlyOwner {
      claimDisabled = true;
    }
    
    function claim(uint256[] calldata tokenIds) external {
        require(!claimDisabled, 'Claim is disabled');
        _claim(_msgSender(), tokenIds);
    }
    
    function claimForAddress(address account, uint256[] calldata tokenIds) external {
        require(!claimDisabled, 'Claim is disabled');
        _claim(account, tokenIds);
    }

    function _claim(address account, uint256[] calldata tokenIds) internal {
        uint256 earned = 0;

        if (blockInfoAddress == address(0x0)) {
            return;
        }

        MetroMiniBlock miniBlock = MetroMiniBlock(miniBlockAddress);
        IMetroBlockInfo blockInfoContract = IMetroBlockInfo(blockInfoAddress);

        uint64[] memory previousTimestamps = miniBlock.setTimestampsOf(account, tokenIds, uint64(block.timestamp));

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 score = blockInfoContract.getBlockScore(tokenIds[i]);
            earned += 1 ether * score * (block.timestamp - previousTimestamps[i]) / 1 days;
        }

        if (earned > 0) {
            uint256 boost = blockInfoContract.getHoodBoost(tokenIds);
            earned = boost * earned / 10000;
            MetToken(tokenAddress).mint(account, earned);
        }

        emit Claimed(account, earned);
    }

    function earningInfo(uint256[] calldata tokenIds) external view returns (EarningInfo memory) {
        uint256 totalScore;
        uint256 earned;
        uint256 prevTokenId;

        MetroMiniBlock miniBlock = MetroMiniBlock(miniBlockAddress);
        IMetroBlockInfo blockInfoContract = IMetroBlockInfo(blockInfoAddress);

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            require(prevTokenId < tokenId, 'no duplicates allowed');
            prevTokenId = tokenId;

            uint256 score = blockInfoContract.getBlockScore(tokenId);
            totalScore += score;
            
            uint256 timestamp = miniBlock.timestampOf(tokenId);
            earned += 1 ether * score * (block.timestamp - timestamp) / 1 days;
        }

        uint256 boost = blockInfoContract.getHoodBoost(tokenIds);
        earned = boost * earned / 10000;

        uint256 earnRatePerSecond = totalScore * 1 ether / 1 days;
        earnRatePerSecond = boost * earnRatePerSecond / 10000;

        return EarningInfo(earned, earnRatePerSecond);
    }

    function tokensOfOwner(address account) public view returns (uint256[] memory) {
      return MetroMiniBlock(miniBlockAddress).tokensOfOwner(account);
    }

    function tokensOfOwnerIn(address account, uint256 start, uint256 stop) public view returns (uint256[] memory) {
      return MetroMiniBlock(miniBlockAddress).tokensOfOwnerIn(account, start, stop);
    }
}
