//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract IOStaking is Initializable, ReentrancyGuardUpgradeable {
    // Contract state v1 (do not change) ----

    // General state
    address public owner;
    bool public paused;

    // NFT connected to this staking contract
    mapping(address => bool) public stakableContractAddresses;
    mapping(address => bool) public disallowNewStaking;

    // Ranking timing
    mapping(address => uint256[]) public rankTime;

    // Staking records
    mapping(address => mapping(uint256 => uint256)) public stakedTokenTime;
    mapping(address => mapping(uint256 => address)) public stakedOwner;

    // End of contract state v1 (append new state after this) ----

    struct TokenOwner {
        uint256 id;
        address owner;
    }

    // Events
    event Staked(address indexed holderAddress, uint256[] tokenIDs);
    event Unstaked(address indexed holderAddress, uint256[] tokenIDs);

    // Errors
    error GlobalStakingPaused();
    error DirectStakingNotAllowed();
    error NotStakableContractAddress(address nftAddress);
    error StakingPaused(address nftAddress);
    error TokenAlreadyStaked();
    error CallerNotNFTOwner();
    error NFTNotStaked();
    error ContractIsNot721();
    error RankNotMonotonic();
    error CallerIsNotContractOwner();

    // Modifiers
    modifier contractNotPaused() {
        if (paused) revert GlobalStakingPaused();
        _;
    }

    modifier isStakable(address nftAddr) {
        if (!stakableContractAddresses[nftAddr])
            revert NotStakableContractAddress({nftAddress: nftAddr});
        _;
    }

    // Functions
    // Upgradable contract initializer
    function initialize(address ownerData) public initializer {
        owner = ownerData;
        paused = true;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId;
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        if (operator != address(this)) revert DirectStakingNotAllowed();
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    // Staking - Requires approve or SetApprovalForAll first
    function stake(address nftContract, uint256[] calldata tokenIds)
        public
        contractNotPaused
        isStakable(nftContract)
        nonReentrant
    {
        if (disallowNewStaking[nftContract])
            revert StakingPaused(nftContract);

        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];

            if (stakedOwner[nftContract][tokenId] != address(0))
                revert TokenAlreadyStaked();

            stakedTokenTime[nftContract][tokenId] = block.timestamp;
            stakedOwner[nftContract][tokenId] = msg.sender;

            IERC721(nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );

            unchecked {
                ++i;
            }
        }

        emit Staked(msg.sender, tokenIds);
    }

    // Unstake
    function unstake(address nftContract, uint256[] calldata tokenIds)
        public
        contractNotPaused
        isStakable(nftContract)
        nonReentrant
    {
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];

            if (stakedOwner[nftContract][tokenId] != msg.sender)
                revert CallerNotNFTOwner();

            _unstake(nftContract, tokenId, msg.sender);

            unchecked {
                ++i;
            }
        }

        emit Unstaked(msg.sender, tokenIds);
    }

    function _unstake(
        address nftContract,
        uint256 tokenId,
        address ownerAddress
    ) private {
        // Reset staking time
        delete stakedTokenTime[nftContract][tokenId];
        delete stakedOwner[nftContract][tokenId];

        // Return staked tokens
        IERC721(nftContract).safeTransferFrom(
            address(this),
            ownerAddress,
            tokenId
        );
    }

    function getStakedOwner(address nftContract, uint256 tokenId)
        public
        view
        isStakable(nftContract)
        returns (address)
    {
        if (stakedOwner[nftContract][tokenId] == address(0))
            revert NFTNotStaked();

        return stakedOwner[nftContract][tokenId];
    }

    function totalBalanceOf(
        address nftContract,
        address holder,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (uint256) {
        uint256 count;
        unchecked {
            for (uint256 i = startIndex; i <= endIndex; ++i) {
                if (stakedOwner[nftContract][i] == holder) {
                    ++count;
                }
            }
        }

        return count;
    }

    function getStakedTokenIds(
        address nftContract,
        address holder,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (uint256[] memory) {
        uint256 count = totalBalanceOf(
            nftContract,
            holder,
            startIndex,
            endIndex
        );
        uint256 idx = 0;
        uint256[] memory ownedIds = new uint256[](count);
        unchecked {
            for (uint256 i = startIndex; i <= endIndex; ++i) {
                if (stakedOwner[nftContract][i] == holder) ownedIds[idx++] = i;

            }
        }

        return ownedIds;
    }

    function tokenOwnersCount(
        address nftContract,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (uint256) {
        uint256 count;
        unchecked {
            for (uint256 i = startIndex; i <= endIndex; ++i) {
                if (stakedOwner[nftContract][i] != address(0)) {
                    ++count;
                }
            }
        }

        return count;
    }

    function getTokenOwners(
        address nftContract,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (TokenOwner[] memory) {
        TokenOwner[] memory tokenOwners = new TokenOwner[](
            tokenOwnersCount(nftContract, startIndex, endIndex)
        );

        uint256 counter;
        unchecked {
            for (uint256 i = startIndex; i <= endIndex; ++i) {
                if (stakedOwner[nftContract][i] != address(0)) {
                    tokenOwners[counter] = TokenOwner(
                        i,
                        stakedOwner[nftContract][i]
                    );
                    ++counter;
                }
            }
        }

        return tokenOwners;
    }

    // Admin functions
    modifier ownerOnly() {
        if (msg.sender != owner) revert CallerIsNotContractOwner();
        _;
    }

    function changeOwnership(address newOwner) public ownerOnly {
        owner = newOwner;
    }

    function setPaused(bool pause) public ownerOnly {
        paused = pause;
    }

    function addStakableNFT(address nftContract) private {
        if (!ERC165(nftContract).supportsInterface(type(IERC721).interfaceId))
            revert ContractIsNot721();

        stakableContractAddresses[nftContract] = true;
    }

    function setDisallowNewStake(address nftContract, bool state)
        public
        isStakable(nftContract)
        ownerOnly
    {
        disallowNewStaking[nftContract] = state;
    }

    function setRanking(address nftContract, uint256[] calldata rankTimeData)
        public
        ownerOnly
    {
        if (!stakableContractAddresses[nftContract]) {
            addStakableNFT(nftContract);
        }

        // Check rankTimeData is monotonic increasing
        unchecked {
            for (uint256 i = 1; i < rankTimeData.length; ++i) {
                if (rankTimeData[i] <= rankTimeData[i - 1]) revert RankNotMonotonic();
            }
        }

        rankTime[nftContract] = rankTimeData;
    }

    // Emergency release particular staked token/s of a particular contract address to original wallet
    function emergencyReleaseToken(
        address nftContract,
        uint256[] calldata tokenIds
    ) public isStakable(nftContract) ownerOnly {
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            // Get the owner of token
            address ownerAddress = stakedOwner[nftContract][tokenId];
            if (ownerAddress != address(0))
                _unstake(nftContract, tokenId, ownerAddress);

            unchecked {
                ++i;
            }
        }
    }
}
