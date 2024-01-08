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

contract FomoCompetitionReward is Ownable, ReentrancyGuard {

    address public constant fomoToken =
        0xF509CDCdF44a0BCD2953CE3F03F4b433Ef6E4c44;
    address public constant coolCats = 0x1A92f7381B9F03921564a437210bB9396471050C; //cool cats 9933
    address public constant dead = 0x000000000000000000000000000000000000dEaD;
    uint256 claimableAmount = 69000000000000000000;
    uint256 claimStopTime;
    bool burned;
    mapping(uint256 => bool) public claimed;
    constructor () public {
        claimStopTime = block.timestamp + 24 hours;
    }

    function burnFomo() internal {
        burned = true;
        uint256 currentBalance = ERC20(fomoToken).balanceOf(address(this));
        ERC20(fomoToken).transfer(dead, currentBalance);
    }

    function claim() external nonReentrant {
        require(!burned, "Too late. You missed it again.");
        if (block.timestamp > claimStopTime){
            burnFomo();
            return;
        }
        uint256 amountToBeClaimed;
        
        uint256 userCount = ERC721Enumerable(coolCats).balanceOf(msg.sender);
        for (uint256 i = 0; i < userCount; i++){
            uint256 tokenId = ERC721Enumerable(coolCats).tokenOfOwnerByIndex(msg.sender, i);
            if (!claimed[tokenId]){
                claimed[tokenId] = true;
                amountToBeClaimed += claimableAmount;
            }
        }
        ERC20(fomoToken).transfer(msg.sender, amountToBeClaimed);
    }
}
