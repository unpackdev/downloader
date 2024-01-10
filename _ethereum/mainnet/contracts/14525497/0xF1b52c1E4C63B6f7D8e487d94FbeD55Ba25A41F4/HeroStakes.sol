// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.11;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Math.sol";
import "./LEGENDZ.sol";
import "./NullHeroes.sol";

error CannotSendDirectly();
error ZeroAddress();
error NotOwnedToken();
error TooEarlyToClaim();

abstract contract HeroStakes is Ownable, IERC721Receiver, Pausable {

    // Stake struct
    struct Stake {
        address owner;
        uint256 lastClaim;
    }

    // max per transaction
    uint8 public immutable maxTokensPerTx;

    // stakes
    Stake[40000] public stakes;

    // $LEGENDZ contract
    LEGENDZ internal legendz;

    // NullHeroes contract
    NullHeroes internal nullHeroes;

    // lock-up period
    uint256 public minDaysToClaim;

    constructor(address _legendz, address _nullHeroes, uint8 _maxTokensPerTx) {
        legendz = LEGENDZ(_legendz);
        nullHeroes = NullHeroes(_nullHeroes);
        maxTokensPerTx = _maxTokensPerTx + 1;
    }

    /**
     * stakes some heroes
     * @param _tokenIds an array of tokenIds to stake
     */
    function stakeHeroes(uint256[] calldata _tokenIds) external virtual whenNotPaused {
        if (_tokenIds.length > maxTokensPerTx) revert TooMuchTokensPerTx();

        nullHeroes.batchTransferFrom(_msgSender(), address(this), _tokenIds);

        for (uint i; i < _tokenIds.length; i++) {
            Stake storage stake = stakes[_tokenIds[i]];
            stake.owner = _msgSender();
            stake.lastClaim = block.timestamp;
        }
    }

    /**
     * claims the reward of some heroes
     * @param _tokenIds an array of tokenIds to claim reward from
     */
    function claimReward(uint256[] calldata _tokenIds) external virtual whenNotPaused {
        if (_tokenIds.length > maxTokensPerTx) revert TooMuchTokensPerTx();

        uint256 reward;
        for (uint i; i < _tokenIds.length; i++) {
            Stake storage stake = stakes[_tokenIds[i]];

            if (stake.owner != _msgSender()) revert NotOwnedToken();
            if ((block.timestamp - stake.lastClaim) < minDaysToClaim) revert TooEarlyToClaim();

            // resolves reward
            reward += _resolveReward(_tokenIds[i]);

            // reset last claim
            stake.lastClaim = block.timestamp;
        }

        if (reward > 0)
            legendz.mint(_msgSender(), reward);
    }

    /**
     * claims some heroes reward and unstake
     * @param _tokenIds an array of tokenIds to claim reward from
     */
    function unstakeHeroes(uint256[] calldata _tokenIds) external virtual {
        if (_tokenIds.length > maxTokensPerTx) revert TooMuchTokensPerTx();

        uint256 reward;
        for (uint i; i < _tokenIds.length; i++) {
            Stake storage stake = stakes[_tokenIds[i]];

            if (stake.owner != _msgSender()) revert NotOwnedToken();
            if ((block.timestamp - stake.lastClaim) < minDaysToClaim) revert TooEarlyToClaim();

            // resolves reward if not paused
            if (!paused())
                reward += _resolveReward(_tokenIds[i]);

            delete stakes[_tokenIds[i]];
        }

        if (reward > 0)
            legendz.mint(_msgSender(), reward);

        nullHeroes.batchTransferFrom(address(this), _msgSender(), _tokenIds);
    }

    /**
     * resolves a staked hero's total reward
     * @param _tokenId the hero's tokenId
     * return the total reward in $LEGENDZ
     */
    function _resolveReward(uint256 _tokenId) internal virtual returns (uint256);

    /**
     * estimates a staked hero's total reward
     * @param _tokenId the hero's tokenId
     * return the estimated total reward in $LEGENDZ
     */
    function estimateReward(uint256 _tokenId) public view virtual returns (uint256);

    /**
     * estimates an unknown hero's approximative daily reward
     * @return the estimated reward
     */
    function estimateDailyReward() public view virtual returns (uint256);

    /**
     * estimates a hero's daily reward
     * @return the reward
     */
    function estimateDailyReward(uint256 _tokenId) public view virtual returns (uint256);

    /**
     * calculates a base reward out of the last claim timestamp and a daily rate
     * @param _dailyReward the legendz rate per day
     * @param _lastClaim the amount of days of farming
     * @return the total reward in $LEGENDZ
     */
    function _calculateBaseReward(uint256 _lastClaim, uint256 _dailyReward) internal view returns (uint256) {
        return (block.timestamp - _lastClaim) * _dailyReward / 1 days;
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = _balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index;
        for (uint i; i < stakes.length; i++) {
            if (stakes[i].owner == _owner){
                tokenIds[index++] = i;
                if (index == tokenCount)
                    return tokenIds;
            }
        }
        revert("HeroStakes: missing tokens");
    }

    /**
     * counts the number of tokens staked by an owner
     * @param _owner the owner
     * return the token count
     */
    function _balanceOf(address _owner) internal view returns (uint)
    {
        if(_owner == address(0)) revert ZeroAddress();
        uint count;
        for (uint i; i < stakes.length; ++i) {
            if( _owner == stakes[i].owner )
                ++count;
        }
        return count;
    }

    /**
     * enables owner to pause / unpause staking
     * @param _paused the new contract paused state
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        if(from != address(0x0)) revert CannotSendDirectly();
        return IERC721Receiver.onERC721Received.selector;
    }
}
