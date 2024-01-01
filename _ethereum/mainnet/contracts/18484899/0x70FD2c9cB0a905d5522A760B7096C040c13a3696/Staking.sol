// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.5 <0.9.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";
import "./NftCommon.sol";
import "./IERC721Receiver.sol";

/**
 * @title Staking
 * Staking is a contract that can be used to stake tokens and receive profit for it.
 * Profit can be received only after withdrawing staked token.
 * The balance to distribute can be replenished by OpenSea if the contract will be marked as royalty receiver or manually
 */

contract Staking is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {

    /// @dev this value will be initialised by the block.number in the constructor 
    uint256 private _deploymentBlockNum;

    /// @dev after stake the token it will be transwered to this smartcontract so we need to store original token owner
    /// stakeCreationBlock keep a block number minus _deploymentBlockNum when the token is staked. will be used to calculate stake proffit
    struct StakeInfo { 
        address stakeOwner;
        uint256 stakeCreationBlock;
        uint16 index;
    }

    /// @dev minimal staking period in blocks. User can't withdrow the token before the end of the period
    uint256 public minimalStakingPeriod;
    /// @dev stakers will be splited to 4 maps depending to the token type
    /// key is a token id
    mapping (uint256 => StakeInfo) private _stakers;
    /// @dev it is required for receiving all NFTs that are staked by defined staker
    mapping (address => uint256[]) private _stakedNfts;

    uint256 public regStakersCount;
    uint256 public expStakersCount;
    uint256 public incrStakersCount;
    uint256 public metaStakersCount;

    /// @dev to keep profit received by each staker
    mapping (address => uint256) private _totalProfit;

    /// @dev when a staker stake the token block number 
    /// when it have been staked minus _deploymentBlockNum should be added to apropriate variable
    uint256 private _regCollectedBaseBlocks = 0;
    uint256 private _expCollectedBaseBlocks = 0;
    uint256 private _incrCollectedBaseBlocks = 0;
    uint256 private _metaCollectedBaseBlocks = 0;

    ERC721 private _nftContract;

    using NftCommon for uint256;
    /**
     * @dev contract constructor. 
     * @param nftContract nft contract address
     * @param minStakingPeriod minimal staking period in blocks. User can't withdrow the token before the end of the period. 
     *   It can be 0 that means that token owner can withdraw his token any time
     * Requirements:
     * - nftContract should not be 0
    */
    constructor(address nftContract, uint256 minStakingPeriod) {
        require(nftContract != address(0), "nft contract address can not be 0");
        _deploymentBlockNum = block.number;
        _nftContract = ERC721(nftContract);
        minimalStakingPeriod = minStakingPeriod;
    }

    /**
     * @notice Function used to stake ERC721 Tokens.
     * @param tokenId - The token id to stake.
     * @dev Each Token id must be approved for transfer by the user before calling this function.
     * Emits a {Stake} event.
    */
    event Stake(uint256 tokenId, address tokenOwner);
    function stake(uint256 id) external whenNotPaused {
        require(_nftContract.ownerOf(id) == msg.sender, "Can be called only by owner");
        _nftContract.safeTransferFrom(msg.sender, address(this), id);

        TokenType tokenType = id.getTokenType();
        uint256 stakeCreationBlock = _blockNumberSinceDeployment();
        if(tokenType == TokenType.REGULAR) {
            _regCollectedBaseBlocks += stakeCreationBlock;
            regStakersCount += 1;
        }
        else if(tokenType == TokenType.EXPIRIENCED) {
            _expCollectedBaseBlocks += stakeCreationBlock;
            expStakersCount += 1;
        }
        else if(tokenType == TokenType.INCORRIGIBLE) {
            _incrCollectedBaseBlocks += stakeCreationBlock;
            incrStakersCount += 1;
        }
        else {
            _metaCollectedBaseBlocks += stakeCreationBlock;
            metaStakersCount += 1;
        }
        uint16 curIndex = uint16(_stakedNfts[msg.sender].length); // 16 bit is enough because we have only 10000 nfts
        _stakers[id] = StakeInfo(msg.sender, stakeCreationBlock, curIndex);
        _stakedNfts[msg.sender].push(id);
        emit Stake(id, msg.sender);
    }

    function getTotalBlocksToPayoutForReg() public view returns(uint256)  {
        return (regStakersCount * _blockNumberSinceDeployment() - _regCollectedBaseBlocks);
    }

    function getTotalBlocksToPayoutForExp() public view returns(uint256)  {
        return (expStakersCount * _blockNumberSinceDeployment() - _expCollectedBaseBlocks);
    }

    function getTotalBlocksToPayoutForIncr() public view returns(uint256)  {
        return (incrStakersCount * _blockNumberSinceDeployment() - _incrCollectedBaseBlocks);
    }

    function getTotalBlocksToPayoutForMeta() public view returns(uint256)  {
        return (metaStakersCount * _blockNumberSinceDeployment() - _metaCollectedBaseBlocks);
    }
    /// @dev to avoid floating points the result of the function is multiplied to factor.  
    function _getBlockBasePrice() private view returns(uint256) {
        uint256 regBlocsCount = getTotalBlocksToPayoutForReg(); // 4888
        uint256 expBlocsCount = getTotalBlocksToPayoutForExp(); // 0
        uint256 incrBlocsCount = getTotalBlocksToPayoutForIncr(); // 0
        uint256 metaBlocsCount = getTotalBlocksToPayoutForMeta(); // 0
        if(regBlocsCount == 0 && expBlocsCount == 0 && incrBlocsCount == 0 && metaBlocsCount == 0) {
            return 0;
        }
        
        uint256 div = regBlocsCount * regWeight + expBlocsCount * expWeight + incrBlocsCount * incrWeight + metaBlocsCount * metaWeight;
        //div = 4888 * 20 = 97760
        return address(this).balance * factor * regWeight / div;
        //return = 100000000000000000 * 10**10 * 20 / 97760 = 204947368421052.63157894 wei = 0.000204947 eth
    }

    function calculateTokeProfit(uint256 id) public view returns (uint256) {
        TokenType tokenType = id.getTokenType();
        StakeInfo memory stakeInfo = _stakers[id];

        require(stakeInfo.stakeCreationBlock !=0, "Token is not staked");

        uint256 profit = (_blockNumberSinceDeployment() - stakeInfo.stakeCreationBlock) * _getBlockBasePrice();
        //profit = (5004 - 16) * 204947368421052.63157894 = 1.02219923578947e+15 wei
        // for not regular tokens profit should be corrected
        // to avoid floating points it should be multiplied to the factor. 
        if(tokenType == TokenType.EXPIRIENCED) {
            profit *= expWeight;
            profit /= regWeight;
        }
        else if(tokenType == TokenType.INCORRIGIBLE) {
            profit *= incrWeight;
            profit /= regWeight;
        }
        else if(tokenType == TokenType.META){
            profit *= metaWeight;
            profit /= regWeight;
        }

        return profit / factor;
        //return = 1.02219923578947e+15 / 10**10 = 102219.923578947 wei
    }

    event Unstake(uint256 tokenId, address tokenReceiver, address stakeReceiver);
    /**
     * @notice Function used to unstake staked token.
     * @param id token id which shoukd be withdrawn.
     * @param to payable address that receive stake proffit. 
     * Requirements:
     * - to should not be 0
     * - id should not be 0
    */
    function unstake(uint256 id, address payable to) external nonReentrant whenNotPaused {
        require(id > 0, "Token id should be larger then 0");
        require(to != address(0), "Stake receiver address should not be 0");
        StakeInfo memory stakeInfo = _stakers[id];
        require(stakeInfo.stakeOwner == msg.sender, "Can be called only by token owner");
        require(_blockNumberSinceDeployment() - stakeInfo.stakeCreationBlock >= minimalStakingPeriod, "Cannot unstake before minimal staking period expiration");

        uint256 profit = calculateTokeProfit(id);
        TokenType tokenType = id.getTokenType();

        if(tokenType == TokenType.EXPIRIENCED) {
            _expCollectedBaseBlocks -= stakeInfo.stakeCreationBlock;
            expStakersCount -= 1;
        }
        else if(tokenType == TokenType.INCORRIGIBLE) {
            _incrCollectedBaseBlocks -= stakeInfo.stakeCreationBlock;
            incrStakersCount -= 1;
        }
        else if(tokenType == TokenType.META){
            _metaCollectedBaseBlocks -= stakeInfo.stakeCreationBlock;
            metaStakersCount -= 1;
        }
        else {
            _regCollectedBaseBlocks -= stakeInfo.stakeCreationBlock;
            regStakersCount -= 1;
        }
        // send profit
        if(profit > 0) {
            bool sent = to.send(profit);
            require(sent, "Failed to send Ether");
        }

        uint16 index = _stakers[id].index;
        // remove stakedNft info
        uint256 arrayLen = _stakedNfts[msg.sender].length;
        if(index != (arrayLen - 1)) {
            // swap last element and element that should be removed. we can remove only last element
            uint256 lastElId = _stakedNfts[msg.sender][arrayLen - 1];
            _stakedNfts[msg.sender][index] = _stakedNfts[msg.sender][arrayLen - 1];
            _stakers[lastElId].index = index;
        }
        _stakedNfts[msg.sender].pop();
        // remove staker from the list of stakers
        delete _stakers[id];

        // send token to the token owner
        _nftContract.safeTransferFrom(address(this), msg.sender, id);
        // save user profit
        _totalProfit[msg.sender] += profit;

        emit Unstake(id, msg.sender, to);
    }

    /// @dev inharited from IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    /**
    * @notice returns total staking profit payed aout to the specific address
    */
    function getPayedOutProfit(address receiver) external view returns(uint256) {
        return _totalProfit[receiver];
    }

    /**
    * @notice returns count of blocks passed after the contract have been deployed
    */
    function getBlockNumSinceDeployment() external view returns(uint256) {
        return _blockNumberSinceDeployment();
    }

    /// @dev for testing purposes
    function _blockNumberSinceDeployment() internal virtual view returns (uint256) {
        return block.number - _deploymentBlockNum;
    }
    /**
     * @dev set minimal staking period in blocks. User can't withdrow the token before the end of the period.
     *
     * stakingPeriod can be 0 that means that token owner can withdraw his token any time
     */
    function setMinimalStakingPeriod(uint256 stakingPeriod) external onlyOwner {
        minimalStakingPeriod = stakingPeriod;
    }

    /// @dev to receive ETH by the contract
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev pause stake and withdraw operations. 
     *
     * Requirements:
     * - can be called only by owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause stake and withdraw operations.
     *
     * Requirements:
     * - can be called only by owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice withdraw ETH from the smartcontract.
     *
     * Requirements:
     * - can be called only by owner
     * - smart contract balance should be greater or equal to the 'amount'
     * @param   amount  - amount ETH to withdraw
     * @param   receiver - address receiver of ETH
    */
    function withdraw(uint256 amount, address payable receiver) external onlyOwner {
        bool sent = receiver.send(amount);
        require(sent, "Failed to send Ether");
    }

    /** 
    * @notice getStakedNfts function returns all staked NFTs by the staker
    * @return ids - array that contains all staked NFT ids
    * @return blocks - array each record of it sutes appropriate record from ids. The records conain left blocks until the the stake can be returned back  
    */ 
    function getStakedNfts(address staker) public view returns(uint256[] memory, uint256[] memory) {
        uint256 len = _stakedNfts[staker].length;
        if(len > 0) {
            uint256[] memory ids = new uint256[](len);
            uint256[] memory blocks = new uint256[](len);
            uint256 blockNumberSinceDeployment = _blockNumberSinceDeployment();
            for(uint256 i = 0; i < len; i++) {
                uint256 id = _stakedNfts[staker][i]; 
                ids[i] = id;
                uint256 stakeDuration = blockNumberSinceDeployment - _stakers[id].stakeCreationBlock;
                uint256 blocksLeft = 0;
                if(stakeDuration < minimalStakingPeriod) {
                    blocksLeft = minimalStakingPeriod - stakeDuration;
                }
                blocks[i] = blocksLeft;
            }
            return (ids, blocks);
        }
        revert('Not found');
    }
}
