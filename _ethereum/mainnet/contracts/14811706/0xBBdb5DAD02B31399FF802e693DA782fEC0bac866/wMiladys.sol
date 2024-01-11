//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract wMiladys is ERC721, IERC721Receiver, Ownable {

    address internal _underlyingToken;

    event Deposit(address, uint256);
    event Withdraw(address, uint256);

    constructor (address underlyingToken) ERC721("Wrapped Milady", "wMIL") {
        _underlyingToken = underlyingToken;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function deposit(uint256 tokenId) external payable {
        require(msg.value >= 0.005 ether, "insufficent payment");

        address owner = IERC721(_underlyingToken).ownerOf(tokenId);
        require(msg.sender == owner, "only owner can call");

        ERC721(_underlyingToken).safeTransferFrom(msg.sender, address(this), tokenId);
        _mint(msg.sender, tokenId);

        emit Deposit(msg.sender, tokenId);
    }

    function withdraw(uint256 tokenId) external {
        address owner = IERC721(_underlyingToken).ownerOf(tokenId);
        require(msg.sender == ownerOf(tokenId), "only owner can call");
        require(address(this) == owner, "invalid tokenId");

        _burn(tokenId);
        ERC721(_underlyingToken).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdraw(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return ERC721(_underlyingToken).tokenURI(tokenId);
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
