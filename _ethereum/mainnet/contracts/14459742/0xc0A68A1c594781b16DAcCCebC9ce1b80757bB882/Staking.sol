//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./cIERC20.sol";

contract Staking is ERC721Holder, AccessControl, Pausable, ReentrancyGuard {
    IERC721 private nft;
    cIERC20 private token;

    struct Stake {
        uint256 lastClaimedAt;
        uint128 balance;
        uint256 pendingRewards;
    }

    mapping(address => Stake) public stakes;
    mapping(uint256 => address) private ownership;
    // uint rate = 10 ether / 1 days;

    // Metadata

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setNFTAddress(address nftAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nft = IERC721(nftAddress);
    }

    function setTokenAddress(address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token = cIERC20(tokenAddress);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function stake(uint[] calldata tokenIds) 
        external 
        whenNotPaused nonReentrant {
            for(uint i=0;i<tokenIds.length;i++) {
                require(nft.ownerOf(tokenIds[i]) == msg.sender, "not authorized");
                ownership[tokenIds[i]] = msg.sender;
                nft.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            }
            Stake memory s = stakes[msg.sender];
            s.balance += uint128(tokenIds.length);
            s.lastClaimedAt = block.timestamp;
            s.pendingRewards = rewards(msg.sender);
            stakes[msg.sender] = s;
    }
    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function unstake(uint[] calldata tokenIds) 
        external 
        whenNotPaused nonReentrant {
            for(uint i=0;i<tokenIds.length;i++) {
                require(ownership[tokenIds[i]] == msg.sender, "not authorized");
                ownership[tokenIds[i]] = address(0);
                nft.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            }
            Stake memory s = stakes[msg.sender];
            s.balance -= uint128(tokenIds.length);
            s.lastClaimedAt = block.timestamp;
            s.pendingRewards = rewards(msg.sender);
            stakes[msg.sender] = s;
    }
    
    function rewards(address owner) public view returns (uint256){
        uint256 single = (((block.timestamp - stakes[owner].lastClaimedAt) * 10 ether) / (1 days));
        return single * stakes[owner].balance;
    }

    function claim() external {
        Stake memory s = stakes[msg.sender];
        uint256 receipt = s.pendingRewards + rewards(msg.sender);
        s.lastClaimedAt = block.timestamp;
        s.pendingRewards = 0;
        stakes[msg.sender] = s;
        token.mint(msg.sender, receipt);
    }

    function owned(address owner) external view returns (uint256[] memory){
        uint256[] memory result = new uint256[](stakes[owner].balance);
        uint c = 0;
        uint i = 1;
        while (c < stakes[owner].balance) {
            if(ownership[i] == owner) {
                result[c] = i;
                c++;
            }
            i++;
        }
        return result;
    }
}
