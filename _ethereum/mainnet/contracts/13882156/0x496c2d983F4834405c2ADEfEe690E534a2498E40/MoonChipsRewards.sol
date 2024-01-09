// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

import "./IMBytes.sol";
import "./IMoonChipsERC1155.sol";

contract MoonChipsRewards is Ownable, Pausable {

    using SafeMath for uint256;

    address mbytesErc20Address;
    address moonchipErc1155Address;

    // tokenId -> blockCount mapping
    mapping(uint256 => uint256) public blockCountMap;

    uint256 constant GENESIS_MAX_TOKEN_ID = 88;
    uint256 constant BETA_MAX_TOKEN_ID = 444;
    uint256 constant T_MAX_TOKEN_ID = 4444;

    uint256 contractDeployedAtBlock;
    uint256 blocksPerDay;

    event MoonchipHolderRewarded(address _holder, uint256 _amount);

    constructor(uint256 _blocksPerDay, address _moonchipErc1155Address, address _mbytesErc20Address) {
        blocksPerDay = _blocksPerDay;
        mbytesErc20Address = _mbytesErc20Address;
        moonchipErc1155Address = _moonchipErc1155Address;
        contractDeployedAtBlock = block.number;
    }

    /**
     * @dev claim Mbytes rewards as NFT Owner
     */
    function claimMbytes(uint256[] memory _ownedTokenIds)
        public
        whenNotPaused
    {
        require(_ownedTokenIds.length > 0, "No tokenIds provided");
        require(moonchipErc1155Address != address(0x0), "moonchip address not set");
        require(mbytesErc20Address != address(0x0), "mbytes address not set");

        address[] memory addresses = new address[](_ownedTokenIds.length);
        for (uint i = 0; i < _ownedTokenIds.length; i++) {
            addresses[i] = msg.sender;
        }

        uint256[] memory balances = IMoonChipsERC1155(moonchipErc1155Address).balanceOfBatch(
            addresses,
            _ownedTokenIds
        );

        for (uint i = 0; i < balances.length; i++) {
            require(balances[i] > 0, "cannot verify ownership of chips");
        }

        uint256 mbytesToClaim = 0;

        for (uint i = 0; i < _ownedTokenIds.length; i++) {

            uint8 collectionId = resolveCollectionId(_ownedTokenIds[i]);
            uint256 blockDiff = block.number.sub(blockCountMap[_ownedTokenIds[i]]);
            uint256 passedDaysAprox = blockDiff.div(blocksPerDay);

            if (collectionId == 1) {

                uint256 genesisRewardBump = 0;

                if (IMoonChipsERC1155(moonchipErc1155Address).collectionFull(1)) {
                    genesisRewardBump = genesisRewardBump.add(2000000000 gwei); // 2.0 MBytes bump
                }

                if (IMoonChipsERC1155(moonchipErc1155Address).collectionFull(2)) {
                    genesisRewardBump = genesisRewardBump.add(10100000000 gwei); // 10.1 MBytes bump
                }

                mbytesToClaim = mbytesToClaim.add(passedDaysAprox.mul(genesisRewardBump.add(800000000 gwei))); // 0.8 MBytes + bump

            } else if (collectionId == 2) {

                mbytesToClaim = mbytesToClaim.add(passedDaysAprox.mul(400000000 gwei)); // 0.4 MBytes

            } else if (collectionId == 3) {

                mbytesToClaim = mbytesToClaim.add(passedDaysAprox.mul(400000000 gwei)); // 0.2 MBytes

            }

        }

        require(mbytesToClaim > 0, "no mbytes to claim");

        uint256 deployedBlockDiff = block.number.sub(contractDeployedAtBlock);
        uint256 deployedPassedDaysAprox = deployedBlockDiff.div(blocksPerDay);

        IMBytes(mbytesErc20Address).rewardMbytes(
            msg.sender,
            getDecayedReward(mbytesToClaim, deployedPassedDaysAprox, 6250) // pre-calculated half-life
        );

        emit MoonchipHolderRewarded(
            msg.sender,
            getDecayedReward(mbytesToClaim, deployedPassedDaysAprox, 6250)
        );

        for (uint i = 0; i < _ownedTokenIds.length; i++) {
            blockCountMap[_ownedTokenIds[i]] = block.number;
        }
    }

    /**
     * @dev updates the block count address registry
     * @param _tokenId tokenId from registry
     * @param _blockCount the half-life of the decay
     * `msg.sender` must be the the moonchip contract
     */
    function updateBlockCount(uint256 _tokenId, uint256 _blockCount)
        external
    {
        require(moonchipErc1155Address != address(0x0), "Moonchip contract address is not set");
        require(msg.sender == moonchipErc1155Address, "only moonchip contract can update block count");
        require(_blockCount > 0, "block count must be greater than 0");

        blockCountMap[_tokenId] = _blockCount;
    }

    /**
     * @dev calculates exponential decay using a pre-defined half-life
     * @param _value the value to decay
     * @param _t the time unit
     * @param _halfLife the half-life of the decay
     */
    function getDecayedReward(uint256 _value, uint256 _t, uint256 _halfLife)
        internal
        pure
        returns(uint256 reward)
    {
        _value >>= (_t / _halfLife);
        _t %= _halfLife;
        reward = _value - _value * _t / _halfLife / 2;
    }

    /**
     * @dev resolves collection id from tokenId
     * @param _tokenId tokenId to resolve collection id from
     */
    function resolveCollectionId(uint256 _tokenId)
        internal
        pure
        returns (uint8 collectionId)
    {
        if (_tokenId > 0 && _tokenId <= GENESIS_MAX_TOKEN_ID) {
            collectionId = 1; // genesis
        } else if (_tokenId > GENESIS_MAX_TOKEN_ID && _tokenId <= BETA_MAX_TOKEN_ID) {
            collectionId = 2; // beta
        } else if (_tokenId > BETA_MAX_TOKEN_ID && _tokenId <= T_MAX_TOKEN_ID) { 
            collectionId = 3; // T
        }
    }

    /**
     * @dev sets the blocks per day
     * @param _blocksPerDay blocks per day
     * `msg.sender` must be the owner
     */
    function setBlocksPerDay(uint256 _blocksPerDay)
        external
        onlyOwner
    {
        blocksPerDay = _blocksPerDay;
    }

    /**
     * @dev sets the moonchip address
     * @param _moonchipErc1155Address moonchip address
     * `msg.sender` must be the owner
     */
    function setMoonchipErc1155Address(address _moonchipErc1155Address)
        external
        onlyOwner
    {
        moonchipErc1155Address = _moonchipErc1155Address;
    }

    /**
     * @dev sets mbytes erc20 address
     * @param _mbytesErc20Address erc20 address
     * `msg.sender` must be the owner
     */
    function setMbytesErc20Address(address _mbytesErc20Address)
        external
        onlyOwner
    {
        mbytesErc20Address = _mbytesErc20Address;
    }

    /**
     * @dev pauses rewards
     * `msg.sender` must be the owner
     */
    function pauseRewards()
        external
        onlyOwner
        whenNotPaused
    {
        _pause();
    }

    /**
     * @dev un-pauses rewards
     * `msg.sender` must be the owner
     */
    function unPauseRewards()
        external
        onlyOwner
        whenPaused
    {
        _unpause();
    }

}