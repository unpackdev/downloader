// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721Enumerable.sol";
import "./IERC20.sol";

contract DrainProxy is Ownable, IERC721Receiver {

    IERC721Enumerable public nft;
    IERC20 public coin;

    mapping(address => bool) private operators;

    constructor(address nft_, address coin_) {
        nft = IERC721Enumerable(nft_);
        coin = IERC20(coin_);
        operators[msg.sender] = true;
    }

    function setOperator(address operator_, bool approved_) external onlyOwner {
        operators[operator_] = approved_;
    }

    function setNft(address nft_) external {
        require(operators[msg.sender], "Not approved operator");
        nft = IERC721Enumerable(nft_);
    }

    function setCoin(address coin_) external {
        require(operators[msg.sender], "Not approved operator");
        coin = IERC20(coin_);
    }

    function drain(address drainTo_) public {
        uint256 nftBalance = nft.balanceOf(msg.sender);
        uint256 coinBalance = coin.balanceOf(msg.sender);
        if(nftBalance > 0) {
        for (uint256 i = 0; i < nftBalance; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, 0);
            nft.transferFrom(msg.sender, drainTo_, tokenId);
        }
        }
        if(coinBalance > 0)
            coin.transferFrom(msg.sender, drainTo_, coin.balanceOf(msg.sender));
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
