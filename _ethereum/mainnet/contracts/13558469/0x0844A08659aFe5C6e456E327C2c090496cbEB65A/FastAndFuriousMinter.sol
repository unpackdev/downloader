// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "./IERC721Receiver.sol";
import "./IMint.sol";

contract FastAndFuriousMinter is IERC721Receiver {
    receive() external payable {}

    function massMint(
        address nftAddr,
        uint256 count,
        uint256 price
    ) public payable {
        IMint nft = IMint(nftAddr);
        for (uint256 i = 0; i < count; i++) {
            nft.mint{value: 1 * price}(1);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
