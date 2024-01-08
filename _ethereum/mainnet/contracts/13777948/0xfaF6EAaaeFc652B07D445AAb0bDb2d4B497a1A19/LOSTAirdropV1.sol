// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./LOSTToken.sol";
import "./TheLostGlitches.sol";

contract LOSTAirdropV1 is Ownable, Pausable {
    LOSTToken public lost;
    TheLostGlitches public tlg;
    uint256 public airdropPerGlitch = 10e18;
    mapping(uint256 => bool) public hasClaimed;

    constructor(address _lost, address _tlg) {
        lost = LOSTToken(_lost);
        tlg = TheLostGlitches(_tlg);
    }

    function claimable(address _beneficiary) public view returns (uint256 amount) {
        uint256 ownedGlitches = tlg.balanceOf(_beneficiary);
        if (ownedGlitches == 0) {
            return 0;
        }

        uint256 claimableAmount = 0;
        for (uint256 i = 0; i < ownedGlitches; i++) {
            uint256 glitch = tlg.tokenOfOwnerByIndex(_beneficiary, i);
            if (hasClaimed[glitch] == false) {
                claimableAmount += airdropPerGlitch;
            }
        }
        return claimableAmount;
    }

    function claim(address _beneficiary, uint256 _glitch) public {
        require(tlg.ownerOf(_glitch) == _beneficiary, "LOSTAirdrop: Beneficiary is not owner of Glitch");
        require(hasClaimed[_glitch] == false, "LOSTAirdrop: Reward already claimed for Glitch");
        require(lost.balanceOf(address(this)) >= airdropPerGlitch, "LOSTAirdrop: Not enough rewards left.");

        hasClaimed[_glitch] = true;
        lost.transfer(_beneficiary, airdropPerGlitch);
    }

    function claimAll(address _beneficiary) public {
        uint256 ownedGlitches = tlg.balanceOf(_beneficiary);
        require(ownedGlitches > 0, "LOSTAirdrop: Beneficiary is does not own any Glitches");

        uint256 totalAirdrop = 0;
        for (uint256 i = 0; i < ownedGlitches; i++) {
            uint256 glitch = tlg.tokenOfOwnerByIndex(_beneficiary, i);
            if (hasClaimed[glitch] == false) {
                hasClaimed[glitch] = true;
                totalAirdrop += airdropPerGlitch;
            }
        }
        require(lost.balanceOf(address(this)) >= totalAirdrop, "LOSTAirdrop: Not enough rewards left.");
        lost.transfer(_beneficiary, totalAirdrop);
    }

    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "Cannot withdraw to the 0 address");
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function withdrawTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(receiver != address(0), "Cannot withdraw tokens to the 0 address");
        token.transfer(receiver, amount);
    }
}
