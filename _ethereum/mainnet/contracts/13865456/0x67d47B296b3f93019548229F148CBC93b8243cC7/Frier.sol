// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract Frier is Ownable {
    mapping(uint256 => uint256) public lastClaimed;

    uint256 public rate;
    uint256 public genesisBlock;
    uint256 public finalBlock;

    bool public claimEnabled;

    IERC721 public frens;
    IERC20 public fries;

    constructor(IERC20 _fries,
        IERC721 _frens,
        uint256 _rate,
        uint256 _finalBlock,
        uint256 _genesisBlock) {
            fries = _fries;
            frens = _frens;
            rate = _rate;
            finalBlock = _finalBlock;
            genesisBlock = _genesisBlock;
            claimEnabled = false;
    }    

    function claim(uint256 fren) public {
        require(claimEnabled, "Claim not enabled");
        require(frens.ownerOf(fren) == _msgSender(), "Not owner of Fren");
        uint256 amount = friedTokens(fren);
        require(amount > 0, "No fries to claim");
        require(fries.balanceOf(address(this)) > amount);
        lastClaimed[fren] = Math.min(block.number, finalBlock);

        require(fries.transfer(_msgSender(), amount));
    }

    function friedTokens(uint256 fren) public view returns(uint256) {
        uint256 blocks;
        if (lastClaimed[fren] == 0) {
            blocks = Math.min(block.number, finalBlock) - genesisBlock;
        } else {
            blocks = Math.min(block.number, finalBlock) - lastClaimed[fren];
        }

        return SafeMath.mul(blocks, rate);
    }

    function friedTokensBatch(uint256[] memory frensToClaim) public view returns(uint256[] memory){
        uint256[] memory tokensId = new uint256[](frensToClaim.length);
        for(uint256 i = 0; i < frensToClaim.length; i++){
            tokensId[i] = friedTokens(frensToClaim[i]);
        }
        return tokensId;
    }

    function claimBatch(uint256[] memory frensToClaim) public {
        for(uint256 i = 0; i < frensToClaim.length; i++){
            claim(frensToClaim[i]);
        }
    }

    function setFinalBlock(uint256 _finalBlock) external onlyOwner {
        finalBlock = _finalBlock;
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function setFries(IERC20 _fries) external onlyOwner {
        fries = _fries;
    }

    function setClaimEnable(bool _enabled) external onlyOwner {
        claimEnabled = _enabled;
    }

    function withdraw(address to) external onlyOwner {
        require(fries.transfer(to, fries.balanceOf(address(this))));
    }
}