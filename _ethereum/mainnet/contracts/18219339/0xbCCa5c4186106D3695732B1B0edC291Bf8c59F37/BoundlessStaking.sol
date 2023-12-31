// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./console.sol";

interface IBoundlessContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
}

contract BoundlessStaking is OwnableUpgradeable {
    error IncorrectTokenQuantity();
    error InvalidLevel();
    error StakerAlreadyExists();
    error NotTokenOwner();
    error StakerDoesNotExist();
    error StakeNotMature();
    error NotAllowed();

    event Staked(
        address indexed stakerAddress,
        uint32 stakedStartTime,
        uint32 stakedEndTime,
        uint32 stakedNFTs
    );

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    uint32 public constant DAY_IN_SECONDS = 86400;


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             STATE VARIABLES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    mapping(uint32 => StakingLevelInfo) public stakingLevelDetailsByNftCount;
    mapping(address => Staker) public stakerDetailsByAddress;
    address public boundlessContractAddress;
    address public boundlessCertificateAddress;
    // mapping(uint256 => bool) public tokenStakedByTokenId;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             STRUCTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    struct StakingLevelInfo {
        uint32 lockingPeriodInSeconds;
        uint32 requiredNFTs;
        uint16 discountPercentage;
    }

    struct StakedNFT {
        uint32 idx;
        uint32 tokenId;
        bool claimed;
    }

    struct Staker {
        uint32 tokenId1;
        bool claimed1;
        uint32 tokenId2;
        bool claimed2;
        uint32 tokenId3;
        bool claimed3;
        uint32 tokenId4;
        bool claimed4;
        uint32 tokenId5;
        bool claimed5;
        uint8 stakedCount;
        uint32 stakedEndTime;
    }


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             SETUP
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function initialize() public initializer {
        __Ownable_init();
        __initializeStakingLevels();
        setBoundlessCertificateAddress(0x19fB9CA4ecf18A8CDD5CC0d04b768a4A38774f68);
        setBoundlessContractAddress(0xA6dEC94903Fc1EeD53A13167F80993A31d312973);
    }

    function __initializeStakingLevels() internal {
        stakingLevelDetailsByNftCount[1] = StakingLevelInfo(
            DAY_IN_SECONDS * 300,
            1,
            3000
        );
        stakingLevelDetailsByNftCount[2] = StakingLevelInfo(
            DAY_IN_SECONDS * 90,
            2,
            2000
        );
        stakingLevelDetailsByNftCount[3] = StakingLevelInfo(
            DAY_IN_SECONDS * 180,
            3,
            3000
        );
        stakingLevelDetailsByNftCount[4] = StakingLevelInfo(
            DAY_IN_SECONDS * 270,
            4,
            4000
        );
        stakingLevelDetailsByNftCount[5] = StakingLevelInfo(
            DAY_IN_SECONDS * 360,
            5,
            5000
        );
    }


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             ADMIN
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function setBoundlessContractAddress(address _contractAddress) public onlyOwner {
        boundlessContractAddress = _contractAddress;
    }

    function setBoundlessCertificateAddress(address _contractAddress) public onlyOwner {
        boundlessCertificateAddress = _contractAddress;
    }

    function stakingDetailsByLevel(
        uint8 numberOfNfts
    )
        public
        view
        returns (
            uint32 lockingPeriodSeconds,
            uint32 requiredNFTs,
            uint16 discountPercentage
        )
    {

        StakingLevelInfo
            memory stakingLevelInfo = stakingLevelDetailsByNftCount[numberOfNfts];

        if (stakingLevelInfo.requiredNFTs == 0) {
            revert InvalidLevel();
        }

        lockingPeriodSeconds = stakingLevelInfo.lockingPeriodInSeconds;
        requiredNFTs = stakingLevelInfo.requiredNFTs;
        discountPercentage = stakingLevelInfo.discountPercentage;
    }

    function updateStakingDetailsByLevel(
        uint32 _lockingPeriodSeconds,
        uint32 _requiredNFTs,
        uint16 _discountPercentage
    ) public onlyOwner {
        StakingLevelInfo
            memory stakingLevelInfo = stakingLevelDetailsByNftCount[
                _requiredNFTs
            ];

        stakingLevelInfo.lockingPeriodInSeconds = _lockingPeriodSeconds;
        stakingLevelInfo.requiredNFTs = _requiredNFTs;
        stakingLevelInfo.discountPercentage = _discountPercentage;
        stakingLevelDetailsByNftCount[_requiredNFTs] = stakingLevelInfo;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            ASSEMBLY 
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function setStakedNFTByIdx (bytes32 stakerRaw, uint32 idx, uint32 tokenId) public pure returns(bytes32) {
        bytes32 tokenIdMask = bytes32(uint256(tokenId));
        assembly {
            // Get the offset for the 32bit ints padded with 8 bits bool
            let offset := mul(idx, 40)

            // Reset value to 0
            let invertedMask := not(0)
            let mask := shl(offset, 0xFFFFFF)
            mask := xor(mask, invertedMask)
            stakerRaw := and(stakerRaw, mask)

            // Create the tokenId mask
            tokenIdMask := shl(offset, tokenId)

            // Apply and store it
            stakerRaw := or(stakerRaw, tokenIdMask)
        }
        return stakerRaw;
    }

    function setStakedCount (bytes32 stakerRaw, uint8 count) public pure returns (bytes32 stakerWithCount) {
        bytes32 countMask = bytes32(uint256(count));
        assembly {
            // Reset value to 0
            let invertedMask := not(0)

            // Count is on 8bits 
            let mask := shl(200, 0xFF)
            mask := xor(mask, invertedMask)
            stakerRaw := and(stakerRaw, mask)

            // get the count 
            countMask := shl(200, count)
            stakerWithCount := or(stakerRaw, countMask)
        }
    }

    function getStakedCount(bytes32 stakerRaw) public pure returns (uint8 count) {
        assembly {
            let countMask := shl(200, 0xFF)
            count := and(stakerRaw, countMask)
            count := shr(200, count)
        }
    }

    function setEndtime ( bytes32 stakerRaw, uint32 endtime) public pure returns(bytes32) {
        bytes32 endtimeMask = bytes32(uint256(endtime));
        assembly {
            // Time is 32bits starting at bit 208 
            endtimeMask := shl(208, endtimeMask)
            stakerRaw := or(stakerRaw, endtimeMask)
 
        }
        return stakerRaw;
    }

    function _createStakedNFTs (address staker, uint32[] calldata tokenIds, uint32 stakeEndTime) internal {
        bytes32 stakedNFTRaw = setStakedCount(bytes32(0x0), uint8(tokenIds.length));
        stakedNFTRaw = setEndtime(stakedNFTRaw, stakeEndTime);
        bytes32 slot = getStakerStorageSlot(staker);
        for (uint32 idx = 0; idx < tokenIds.length; idx++) {
            uint32 boundlessTokenId = editionedTokenId(1, uint32(tokenIds[idx]));
            if (IBoundlessContract(boundlessContractAddress).ownerOf(boundlessTokenId) != msg.sender) {
                revert NotTokenOwner();
            }
            stakedNFTRaw = setStakedNFTByIdx(stakedNFTRaw, idx, uint32(tokenIds[idx]));
        }
        assembly {
            sstore(slot, stakedNFTRaw)
        }
    }

    function getStakerStorageSlot(address stakerAddress) public pure returns (bytes32 slot) {
        assembly {
            // Get free mem pointer and allocate 2 words of space
            let freeMemPointer := mload(0x40)
            mstore(0x40, add(freeMemPointer, 0x40))

            // Store address and slot number in memory for hashing
            mstore(freeMemPointer, stakerAddress)
            mstore(add(freeMemPointer, 0x20), stakerDetailsByAddress.slot)
            
            // Get the hasked key
            slot := keccak256(freeMemPointer, 0x40)
        }
    }

    function getStakerRaw(address stakerAddress) public view returns(bytes32 stakerRaw){
        bytes32 storageSlot = getStakerStorageSlot(stakerAddress);
        assembly {
            // Load the current data
            stakerRaw := sload(storageSlot)
        }
    }


    function getStakedByIdx (bytes32 stakerRaw, uint32 idx) public pure returns(StakedNFT memory ) {
        bytes32 tokenIdMask;
        bytes32 claimMask;
        uint32 stakedId;
        bool claimed;
        assembly {            
            let flagOffset := add(mul(add(1, idx), 32), mul(idx, 8))
            let tokenOffset := mul(idx, 40)
            tokenIdMask := shl(tokenOffset, 0xFFFFFF)
            claimMask := shl(flagOffset, 0xFF)

            stakedId := and(stakerRaw, tokenIdMask)
            stakedId := shr(tokenOffset, stakedId)
            claimed := and(stakerRaw, claimMask)
            claimed := shr(flagOffset, claimed)
        }
        return StakedNFT(idx, stakedId, claimed);
    }


    function getStakedNFTs (address stakerAddress) public view returns(StakedNFT[] memory, bytes32 stakerRaw) {
        stakerRaw = getStakerRaw(stakerAddress);
        uint32 stakedCount = getStakedCount(stakerRaw);
        StakedNFT[] memory stakedNFTs = new StakedNFT[](stakedCount);
        for (uint32 idx = 0; idx < stakedCount; idx++) {
            StakedNFT memory stakedNFT = getStakedByIdx(stakerRaw, idx);
            stakedNFTs[idx] = stakedNFT;
        }
        return (stakedNFTs, stakerRaw);
    }


    function claimDiscount(
        address _staker, uint256 _tokenId
    ) external {
        if (msg.sender != boundlessCertificateAddress) {
            revert NotAllowed();
        }
        (StakedNFT[] memory stakedNFTs, bytes32 stakerRaw) = getStakedNFTs(_staker); 
        bytes32 slot = getStakerStorageSlot(_staker);
        for (uint32 idx = 0; idx < stakedNFTs.length; idx++) {
            if (_tokenId == stakedNFTs[idx].tokenId) {
                if (stakedNFTs[idx].claimed) {
                    revert NotAllowed();
                }
                uint tokenIdx = stakedNFTs[idx].idx;
                assembly {
                    let offset := add(mul(add(1, tokenIdx), 32), mul(tokenIdx, 8))
                    let mask := shl(offset, 0xFF)
                    stakerRaw := or(stakerRaw, mask)
                    sstore(slot, stakerRaw)
                }
            }
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                             STAKING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /**
     * @dev stake NFTs
     * @notice User can only stake NFTs once per wallet address
     **/
    function setStake(uint32[] calldata _nfts) public {
        uint32 stakeStartTime = uint32(block.timestamp);
        uint8 totalNFTs = uint8(_nfts.length);

        // Staker memory stakerDetails = stakerDetailsByAddress[msg.sender];
        bytes32 stakerRaw = getStakerRaw(msg.sender);
        // If any bit is set, then staker is already staking
        if (uint256(stakerRaw) > 0) {
            revert StakerAlreadyExists();
        }

        StakingLevelInfo
            memory stakingLevelInfo = stakingLevelDetailsByNftCount[totalNFTs];

        if (stakingLevelInfo.requiredNFTs == 0) {
            revert InvalidLevel();
        }

        uint32 calculatedStakeEndTime = uint32(
            calculateStakeEndTime(stakeStartTime, totalNFTs)
        );

        _createStakedNFTs(msg.sender, _nfts, calculatedStakeEndTime);

        emit Staked(
            msg.sender,
            stakeStartTime,
            calculatedStakeEndTime,
            stakingLevelInfo.requiredNFTs
        );
    }


    function getStakedTokenById(uint256 _tokenId) public view returns (StakedNFT memory stakedNFT) {
        address tokenOwner = IBoundlessContract(boundlessContractAddress).ownerOf(_tokenId);
        (StakedNFT[] memory stakedNFTs,) = getStakedNFTs(tokenOwner); 

        if (_tokenId == 0 ) { 
            revert NotAllowed();
        }

        for (uint i = 0; i < stakedNFTs.length; i++) {
            stakedNFT = stakedNFTs[i];
            uint256 boundlessTokenId = editionedTokenId(1, stakedNFT.tokenId);
            if (boundlessTokenId == _tokenId) {
                return stakedNFT;
            }
        }
        return stakedNFT;
    }

    function isTokenStaked(uint256 _tokenId) public view returns (bool tokenStaked) {
        StakedNFT memory stakedNFT = getStakedTokenById(_tokenId);
        address tokenOwner = IBoundlessContract(boundlessContractAddress).ownerOf(_tokenId);
        Staker memory stakerDetails = stakerDetailsByAddress[tokenOwner];
        if (stakedNFT.tokenId == 0) { 
            return false;
        }
        if (stakerDetails.stakedEndTime <= block.timestamp) {
            return false;
        }
        return true;
    }

    function getStakerDetails(
        address _staker
    ) public view returns (Staker memory stakerDetails) {
        return stakerDetailsByAddress[_staker];
    }

    function getDiscountByTokenId(
        uint256 _tokenId
    ) public view returns (uint256 discount) {
        address tokenOwner = IBoundlessContract(boundlessContractAddress).ownerOf(_tokenId);

        bytes32 stakerRaw = getStakerRaw(tokenOwner);
        uint32 stakedCount = getStakedCount(stakerRaw);

        StakedNFT memory stakedNFT = getStakedTokenById(_tokenId);

        if (stakedCount == 0) {
            return 0;
        }

        if (stakedNFT.tokenId == 0) {
            return 0;
        }

        StakingLevelInfo
            memory stakingLevelInfo = stakingLevelDetailsByNftCount[stakedCount];

        return stakingLevelInfo.discountPercentage;
    }


    function getDiscountedByWallet(
        address _staker
    ) public view returns (StakedNFT[] memory stakedNFTs, uint256 discount) {
        Staker memory stakerDetails = stakerDetailsByAddress[_staker];
        if (stakerDetails.stakedEndTime == 0) {
            return (stakedNFTs, 0);
        }
        (stakedNFTs,) = getStakedNFTs(_staker); 

        StakingLevelInfo
            memory stakingLevelInfo = stakingLevelDetailsByNftCount[stakerDetails.stakedCount];

        uint256 unclaimedCount;


        for (uint i = 0; i < stakedNFTs.length; i++) {
            if (stakedNFTs[i].claimed == false ) {
                unclaimedCount += 1;
            }
        }
        StakedNFT[] memory stakedNFTsUnclaimed = new StakedNFT[](unclaimedCount);
        uint256 idx;
        for (uint i = 0; i < stakedNFTs.length; i++) {
            if (stakedNFTs[i].claimed == false ) {
                stakedNFTsUnclaimed[idx] = stakedNFTs[i];
                idx +=1;
            }
        }
        return (stakedNFTsUnclaimed, stakingLevelInfo.discountPercentage);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            INTERNAL FUNCTIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function calculateStakeEndTime(
        uint32 _stakedStartTime,
        uint8 _totalNFTs
    ) internal view returns (uint32 stakeEndTime) {
        uint32 lockingPeriodInSeconds = stakingLevelDetailsByNftCount[
            _totalNFTs
        ].lockingPeriodInSeconds;
        stakeEndTime = _stakedStartTime + lockingPeriodInSeconds;
    }

    function editionedTokenId(
        uint8 editionId,
        uint32 tokenNumber
    ) internal pure returns (uint32 tokenId) {
        uint32 paddedEditionID = editionId * 10e5;
        tokenId = paddedEditionID + tokenNumber;
    }
}
