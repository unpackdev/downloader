// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Owned.sol";
import "./ERC721.sol";
import "./IERC20.sol";

contract MuseTime is ERC721, Owned {

    constructor() ERC721("MuseTime", "MT") Owned(msg.sender) {}

    /**
     *  @dev mint/render logic
     */
    address public controller;

    function setController(address controller_) external onlyOwner {
        controller = controller_;
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == controller, "UNAUTHORIZED");
        _safeMint(to, tokenId, "");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf[tokenId] != address(0), "NONEXISTENT_TOKEN");
        return IController(controller).tokenURI(tokenId);
    }

    /**
     * @dev Receive and withdraw assets
     */

    receive() external payable {}

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

}

interface IController {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
