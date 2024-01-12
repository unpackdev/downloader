// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/// @author Misterjuiice https://instagram.com/misterjuiice
/// @title Big Cat & Little Cat Stacking

import "./IERC721.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";

contract BigLittleCatStaking is IERC721Receiver {
    // boolean to prevent reentrancy
    bool internal locked;

    // Library usage
    using SafeMath for uint256;

    // Contract owner
    address public owner;

    // ERC20 contract address
    IERC721 public bigCatContract;
    IERC721 public littleCatContract;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
       return this.onERC721Received.selector;
    }

     /**
    @dev tokenId to staking start time (0 = not staking).
     */
    mapping(uint256 => uint256) private stakingStarted;

    mapping(uint256 => uint256) public stakingUsedPoints;

    /**
    @dev BigCat owner address.
     */
    mapping(uint256 => address) public stakedUserBigCat;

    /**
    @dev Little owner address.
     */
    mapping(uint256 => address) public stakedUserLittleCat;

    /**
    @dev associate LittleCat to BigCat.
     */
    mapping(uint256 => uint256) public littleCatLinkToBigCat;

    /**
    @dev Cumulative per-token staking, excluding the current period.
     */
    mapping(uint256 => uint256) private stakingTotal;

    // Events

    /**
    @dev Emitted when a NFT begins staking.
     */
    event Stacked(uint256 indexed tokenId);

    /**
    @dev Emitted when a NFT stops staking; either through standard means or
    by expulsion.
     */
    event Unstacked(uint256 indexed tokenId);

    /**
    @dev Emitted when a NFT is expelled from the stack.
     */
    event Expelled(uint256 indexed tokenId);

    /// @dev Deploys contract and links the ERC20 token which we are staking, also sets owner as msg.sender and sets timestampSet bool to false.
    /// @param bigCatAddress.
    /// @param littleCatAddress.
    constructor(IERC721 bigCatAddress, IERC721 littleCatAddress) {
        // Set contract owner
        owner = msg.sender;
        // Set the erc20 contract address which this timelock is deliberately paired to
        require(address(bigCatAddress) != address(0), "bigCatAddress address can not be zero");
        require(address(littleCatAddress) != address(0), "littleCatAddress address can not be zero");
        bigCatContract = bigCatAddress;
        littleCatContract = littleCatAddress;

        // Initialize the reentrancy variable to not locked
        locked = false;
    }

    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Message sender must be the contract's owner.");
        _;
    }

    /// @dev Stake NFT 
    /// @param bigCatTokenId, BigCat token
    /// @param littleCatTokenId, LittleCat token
    function stakeTokens(uint256 bigCatTokenId, uint256 littleCatTokenId) external noReentrant {
        uint256 start = stakingStarted[bigCatTokenId];
        if (start == 0) {
            require(msg.sender == bigCatContract.ownerOf(bigCatTokenId), "Message sender must be the BigCat owner.");
            require(msg.sender == littleCatContract.ownerOf(littleCatTokenId), "Message sender must be the LittleCat owner.");

            bigCatContract.safeTransferFrom(msg.sender, address(this), bigCatTokenId);
            littleCatContract.safeTransferFrom(msg.sender, address(this), littleCatTokenId);

            stakingStarted[bigCatTokenId] = block.timestamp;
            stakedUserBigCat[bigCatTokenId] = msg.sender;
            littleCatLinkToBigCat[bigCatTokenId] = littleCatTokenId;
            stakedUserLittleCat[littleCatTokenId] = msg.sender;

            emit Stacked(bigCatTokenId);
        } else {
            require(msg.sender == stakedUserBigCat[bigCatTokenId], "Message sender must be the BigCat owner.");
            require(msg.sender == stakedUserLittleCat[littleCatTokenId], "Message sender must be the LittleCat owner.");

            stakingTotal[bigCatTokenId] += block.timestamp - start;
            stakingStarted[bigCatTokenId] = 0;
            bigCatContract.safeTransferFrom(address(this), msg.sender, bigCatTokenId);
            littleCatContract.safeTransferFrom(address(this), msg.sender, littleCatTokenId);

            delete stakedUserBigCat[bigCatTokenId];
            delete stakedUserLittleCat[littleCatTokenId];
            delete littleCatLinkToBigCat[bigCatTokenId];

            emit Unstacked(bigCatTokenId);
        }
    }

    function expelFromStack(uint256 bigCatTokenId, uint256 littleCatTokenId) external onlyOwner {
        require(stakingStarted[bigCatTokenId] != 0, "Stacking: not stacked");
        stakingTotal[bigCatTokenId] += block.timestamp - stakingStarted[bigCatTokenId];
        stakingStarted[bigCatTokenId] = 0;

        bigCatContract.safeTransferFrom(address(this), stakedUserBigCat[bigCatTokenId], bigCatTokenId);
        littleCatContract.safeTransferFrom(address(this), stakedUserLittleCat[littleCatTokenId], littleCatTokenId);

        delete stakedUserBigCat[bigCatTokenId];
        delete stakedUserLittleCat[littleCatTokenId];
        delete littleCatLinkToBigCat[bigCatTokenId];

        emit Unstacked(bigCatTokenId);
        emit Expelled(bigCatTokenId);
    }

     /**
    @notice Returns the length of time, in seconds, that the NFT has
    nested.
    @dev Staking is tied to a specific Big Cat & Little Cat, not to the owner, so it doesn't
    reset upon sale.
    @return staking Whether the NFT is currently staking. MAY be true with
    zero current staking if in the same block as nesting began.
    @return current Zero if not currently staking, otherwise the length of time
    since the most recent staking began.
    @return total Total period of time for which the NFT has staked across
    its life, including the current period.
     */
    function stakingPeriod(uint256 bigCatTokenId)
        external
        view
        returns (
            bool staking,
            uint256 current,
            uint256 total,
            address ownerAddress,
            uint256 littleCatTokenId
        )
    {
        uint256 start = stakingStarted[bigCatTokenId];
        if (start != 0) {
            staking = true;
            current = block.timestamp - start;
            ownerAddress = stakedUserBigCat[bigCatTokenId];
            littleCatTokenId = littleCatLinkToBigCat[bigCatTokenId];
        }
        total = current + stakingTotal[bigCatTokenId] - stakingUsedPoints[bigCatTokenId];
        ownerAddress = stakedUserBigCat[bigCatTokenId];
        littleCatTokenId = littleCatLinkToBigCat[bigCatTokenId];
    }

    function usePoint(uint256 bigCatTokenId, uint256 littleCatTokenId, uint256 points) external noReentrant {
        require(msg.sender == stakedUserBigCat[bigCatTokenId], "Message sender must be the BigCat owner.");
        require(msg.sender == stakedUserLittleCat[littleCatTokenId], "Message sender must be the LittleCat owner.");
        require(stakingStarted[bigCatTokenId] != 0, "Not actually staking");
        uint256 start = stakingStarted[bigCatTokenId];
        uint256 current = block.timestamp - start;
        uint256 total = current + stakingTotal[bigCatTokenId];
        require(total > points, "Not enought points");
        
        stakingUsedPoints[bigCatTokenId] += points;
        stakingTotal[bigCatTokenId] += block.timestamp - stakingStarted[bigCatTokenId];
        stakingStarted[bigCatTokenId] = block.timestamp;
    }

    function changeOwner(address newAddress) external onlyOwner {
        owner = newAddress;
    }
}