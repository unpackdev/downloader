//SPDX-License-Identifier: MIT Licensed

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721A.sol";
import "./IERC20.sol";

pragma solidity 0.8.21;

contract pepetradesClaim is Ownable, ReentrancyGuard {
    IERC721A public nft;
    IERC20 public token;

    uint256 public totalTokenClaimed;
    bool public claimEnabled;
    mapping(uint256 => uint256) public ids;
    mapping(uint256 => uint256) public idsClaimed;

    constructor(address _nft, address _token) {
        nft = IERC721A(_nft);
        token = IERC20(_token);
    }

    function claim(uint256 id) public nonReentrant {
        require(claimEnabled == true, "Claim disabled.");
        require(msg.sender == nft.ownerOf(id), "Not your NFT.");
        require(ids[id] > 0, "Nothing to claim.");
        token.transfer(msg.sender, ids[id] * 1e18);
        totalTokenClaimed += ids[id];
        idsClaimed[id] += ids[id];
        ids[id] = 0;
    }

    function addData(uint256[] memory _ids, uint256[] memory amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            ids[_ids[i]] += amount[i];
        }
    }

    function setClaimEnabled(bool value) external onlyOwner {
        claimEnabled = value;
    }

    function setNFT(address _nft) external onlyOwner {
        nft = IERC721A(_nft);
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        uint256 amount;
        if (tkn == address(0)) {
            bool success;
            amount = address(this).balance;
            (success, ) = address(msg.sender).call{value: amount}("");
        } else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
            amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }
}
