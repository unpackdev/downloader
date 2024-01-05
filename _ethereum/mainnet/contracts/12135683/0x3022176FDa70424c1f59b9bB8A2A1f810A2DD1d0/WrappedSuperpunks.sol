// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

interface ISPunk {
    function mintNFT(uint256) payable external;
}

contract WrappedSuperpunks is ERC721, IERC721Receiver, Ownable {

    // Public variables
    address public constant oldToken = 0x39ED051A1A3A1703b5E0557B122eC18365dBC184;

    // Used for naming etc
    address public customDataSource;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory _uri) ERC721("Wrapped Superpunks", "wSP") {
        _setBaseURI(_uri);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _setBaseURI(uri);
    }

    function setCustomDataSource(address newCustomDataSource) external onlyOwner {
        customDataSource = newCustomDataSource;
    }

    function mintWrapped(uint256 numberOfNfts) external payable {
        ISPunk(oldToken).mintNFT{value: msg.value}(numberOfNfts);
        uint256 balance = IERC721(oldToken).balanceOf(address(this));
        for (uint256 i = 0; i < balance; i ++) {
            _mint(msg.sender, IERC721Enumerable(oldToken).tokenOfOwnerByIndex(address(this), i));
        }
    }

    function wrap(uint256[] memory ids) external {
        for (uint256 i = 0; i < ids.length; i ++) {
            IERC721(oldToken).transferFrom(msg.sender, address(this), ids[i]);
            _mint(msg.sender, ids[i]);
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {

    }
}
