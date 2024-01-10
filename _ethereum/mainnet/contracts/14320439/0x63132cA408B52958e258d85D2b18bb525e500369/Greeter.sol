//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract HapppyGajRefund is Ownable, IERC721Receiver {
    IERC721 public HappyGaj = IERC721(0x346868f7E783e8206335bB14F74ba59a87c44F35);

    function refund(uint256 nftId) external {
        require(HappyGaj.ownerOf(nftId) == msg.sender, "You are not the owner");
        HappyGaj.safeTransferFrom(msg.sender, address(this), nftId);
        (bool sent, bytes memory data) = msg.sender.call{value: 0.05 ether}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawHappyGaj(uint256 nftId) external onlyOwner {
        HappyGaj.safeTransferFrom(address(this), msg.sender, nftId);
    }

    function depositEth() external payable onlyOwner  {

    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
