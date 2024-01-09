// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./LOSTToken.sol";
import "./TheLostGlitchesComic.sol";

contract LOSTAirdropV2 is Ownable, Pausable {
    LOSTToken public lost;
    TheLostGlitchesComic public tlgcmc;
    uint256 public airdropPerComic = 500e18;
    mapping(uint256 => bool) public hasClaimed;

    constructor(address _lost, address _tlgcmc) {
        lost = LOSTToken(_lost);
        tlgcmc = TheLostGlitchesComic(_tlgcmc);
    }

    function claimable(address _beneficiary) public view returns (uint256 amount) {
        uint256 ownedComics = tlgcmc.balanceOf(_beneficiary);
        if (ownedComics == 0) {
            return 0;
        }

        uint256 claimableAmount = 0;
        for (uint256 i = 0; i < ownedComics; i++) {
            uint256 comic = tlgcmc.tokenOfOwnerByIndex(_beneficiary, i);
            if (hasClaimed[comic] == false) {
                claimableAmount += airdropPerComic;
            }
        }
        return claimableAmount;
    }

    function claim(address _beneficiary, uint256 _comic) public {
        require(tlgcmc.ownerOf(_comic) == _beneficiary, "LOSTAirdropV2: Beneficiary is not owner of Comic.");
        require(hasClaimed[_comic] == false, "LOSTAirdropV2: Reward already claimed for Comic.");
        require(lost.balanceOf(address(this)) >= airdropPerComic, "LOSTAirdropV2: Not enough rewards left. Try again later.");

        hasClaimed[_comic] = true;
        lost.transfer(_beneficiary, airdropPerComic);
    }

    function claimAll(address _beneficiary) public {
        uint256 ownedComics = tlgcmc.balanceOf(_beneficiary);
        uint256 claimableAmount = claimable(msg.sender);
        require(ownedComics > 0, "LOSTAirdropV2: Beneficiary is does not own any Comics.");
        require(claimableAmount > 0, "LOSTAirdropV2: No rewards can be claimed.");
        require(lost.balanceOf(address(this)) >= claimableAmount, "LOSTAirdropV2: Not enough rewards left. Try again later.");

        uint256 totalAirdrop = 0;
        for (uint256 i = 0; i < ownedComics; i++) {
            uint256 comic = tlgcmc.tokenOfOwnerByIndex(_beneficiary, i);
            if (hasClaimed[comic] == false) {
                hasClaimed[comic] = true;
                totalAirdrop += airdropPerComic;
            }
        }

        lost.transfer(_beneficiary, totalAirdrop);
    }

    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "Cannot withdraw to the 0 address.");
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function withdrawTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(receiver != address(0), "Cannot withdraw tokens to the 0 address.");
        token.transfer(receiver, amount);
    }
}
