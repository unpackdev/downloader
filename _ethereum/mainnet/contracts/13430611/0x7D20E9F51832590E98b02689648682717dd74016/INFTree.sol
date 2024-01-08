// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./IERC721.sol";

interface INFTree is IERC721{

    /**
        @dev see {NFTree-mintNFTree}
     */
    function mintNFTree(address _recipient, string memory _tokenURI, uint256 _carbonOffset, string memory _collection) external;
}