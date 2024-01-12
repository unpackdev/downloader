//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

abstract contract ERC721AI is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    function balanceOf(address account) external view virtual override returns (uint256);
}
