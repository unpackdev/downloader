//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./MerkleProof.sol";

contract NFTClaim is Ownable, ReentrancyGuard, ERC1155Holder{
    using MerkleProof for bytes32[];


    struct CampaignInfo{
        IERC1155 nftContract;
        uint256 nftId;
        uint256 totalQuantity;
        uint256 currentQuantity;
        bytes32 whitelistRoot;
    }

    mapping(uint256 => mapping(address => uint256)) claimedQty;

    CampaignInfo[] public campaignInfo;

    event AddCampaign(uint256 indexed campaignId, address nftAddress, uint256 nftId, uint256 quantity);
    event Claim(address indexed user, uint256 indexed campaignId, uint256 quantity);
    event EmergencyWithdraw(address indexed nftAddress, uint256 indexed nftId, uint256 quantity);

    function addCampaign(address nftAddress, uint256 nftId, uint256 quantity, bytes32 whitelistRoot) external onlyOwner{
        IERC1155 nftContract = IERC1155(nftAddress);
        campaignInfo.push(CampaignInfo({
            nftContract : nftContract,
            nftId: nftId,
            totalQuantity: quantity,
            currentQuantity: quantity,
            whitelistRoot: whitelistRoot
        }));
        require(nftContract.isApprovedForAll(msg.sender, address(this)), "Need to approve contract");
        require(nftContract.balanceOf(msg.sender, nftId) >= quantity, "Don't have enough qty");
        nftContract.safeTransferFrom(msg.sender, address(this), nftId, quantity, "");
        emit AddCampaign(campaignInfo.length - 1, nftAddress, nftId, quantity);
    }

    function setWhitelistRoot(uint256 campaignId, bytes32 whitelistRoot) external onlyOwner{
        campaignInfo[campaignId].whitelistRoot = whitelistRoot;
    }

    function claim(uint256 campaignId, address user, uint256 quantity, bytes32[] calldata whitelistProof) external nonReentrant {
        require(verifyWhitelist(campaignId, user, quantity, whitelistProof), "Invalid whitelist proof");
        require(claimedQty[campaignId][user] == 0, "Already claimed");
        IERC1155 nftContract = campaignInfo[campaignId].nftContract;
        
        campaignInfo[campaignId].currentQuantity -= quantity;
        claimedQty[campaignId][user] = quantity;

        nftContract.safeTransferFrom(address(this), user, campaignInfo[campaignId].nftId , quantity, "");

        emit Claim(user, campaignId, quantity);
    }


    function verifyWhitelist(uint256 campaignId, address user, uint256 quantity, bytes32[] calldata whitelistProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(user,quantity));
        return whitelistProof.verify(campaignInfo[campaignId].whitelistRoot, leaf);    
    }

    function hasClaimed(uint256 campaignId, address user) public view returns (bool){
        return claimedQty[campaignId][user] != 0;
    }

    function emergencyWithdraw(address to, address nftAddress, uint256 nftId, uint256 quantity) external onlyOwner {
        IERC1155(nftAddress).safeTransferFrom(address(this), to, nftId, quantity, "");
        emit EmergencyWithdraw(nftAddress, nftId, quantity);
    }


}