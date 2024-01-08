// SPDX-License-Identifier: MIT
// Written by @devpaf
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface ERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external returns (uint256);
}

contract FomoCompetition is Ownable, ReentrancyGuard {
    address public constant fomoToken = 0xF509CDCdF44a0BCD2953CE3F03F4b433Ef6E4c44;
    uint256 public constant claimableAmount = 69000000000000000000;
    uint256 public claimStopTime;
    bool isActive;
    address[5] nftCollections = [
        0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6, // Cryptoads 6969
        0x57a204AA1042f6E66DD7730813f4024114d74f37, //cyberkongs 3938
        0x9A534628B4062E123cE7Ee2222ec20B86e16Ca8F, //mekaverse 8593
        0x1A92f7381B9F03921564a437210bB9396471050C, // cool cats 9933
        0xBd3531dA5CF5857e7CfAA92426877b022e612cf8 // pudge penguins 8888
    ];
    mapping(address => mapping(uint256 => bool)) public hasClaimed;
    mapping(address => uint256) public claimedCount;
    function activate() external onlyOwner {
        isActive = true;
        claimStopTime = block.timestamp + 24 hours;
    }
    function burnFomo() internal {
        uint256 currentBalance = ERC20(fomoToken).balanceOf(address(this));
        ERC20(fomoToken).transfer(address(0), currentBalance);
    }
    // Hello Mariano, are you feeling the FOMO?
    function claim() external nonReentrant {
        uint256 currentFomoBalance = ERC20(fomoToken).balanceOf(address(this));
        require(currentFomoBalance >= claimableAmount, "Too late. You missed it again. What can I say?");
        require(isActive, "contract is not active");
        if (block.timestamp > claimStopTime){
            burnFomo();
            return;
        }
        uint256 amountToBeClaimed;
        for (uint256 collectionIndex=0; collectionIndex<nftCollections.length; collectionIndex++){
            address nftCollectionAddress = nftCollections[collectionIndex];
            uint256 userCount = ERC721Enumerable(nftCollectionAddress).balanceOf(msg.sender);
            for (uint256 i = 0; i < userCount; i++){
                uint256 tokenId = ERC721Enumerable(nftCollectionAddress).tokenOfOwnerByIndex(msg.sender, i);
                if (!hasClaimed[nftCollectionAddress][tokenId]){
                    claimedCount[nftCollectionAddress] += 1;
                    hasClaimed[nftCollectionAddress][tokenId] = true;
                    amountToBeClaimed += claimableAmount;
                }
            }
        }
        if (amountToBeClaimed > currentFomoBalance){
            amountToBeClaimed = currentFomoBalance;
        }
        ERC20(fomoToken).transfer(msg.sender, amountToBeClaimed);
    }
}
