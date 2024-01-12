// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ISarugami.sol";

contract Sale3 is Ownable, ReentrancyGuard {
    bool public isMintActive = false;
    uint256 public maxIdPossibleToFreeMint = 0;

    mapping(uint256 => bool) public nftsClaimed;
    ISarugami public sarugami;

    constructor(
        address sarugamiAddress
    ) {
        sarugami = ISarugami(sarugamiAddress);
    }

    function mintFreeHolder(uint256[] memory ids) public nonReentrant {
        require(isMintActive == true, "Holder free mint not open");

        for (uint i = 0; i < ids.length; i++) {
            require(sarugami.ownerOf(ids[i]) == _msgSender(),"You are not the owner");
            require(ids[i] < maxIdPossibleToFreeMint, "Id not supported");
            require(nftsClaimed[ids[i]] == false, "Already claimed");
            nftsClaimed[ids[i]] = true;
        }

        sarugami.mint(msg.sender, ids.length);
    }

    function mintGiveAwayWithAddresses(address[] calldata supporters) external onlyOwner {
        // Reserved for people who helped this project and giveaways
        for (uint256 index; index < supporters.length; index++) {
            sarugami.mint(supporters[index], 1);
        }
    }

    function changeMintStatus() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function changeMaxId(uint256 maxId) external onlyOwner {
        maxIdPossibleToFreeMint = maxId;
    }

    function withdrawStuckToken(address recipient, address token) external onlyOwner() {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    function removeDustFunds(address treasury) external onlyOwner {
        (bool success,) = treasury.call{value : address(this).balance}("");
        require(success, "funds were not sent properly to treasury");
    }
}