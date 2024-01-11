// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

interface IUgokiCOA is IERC721 {
    function mint(address _owner, string memory tokenURI) external returns (uint256);
}
