//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";

abstract contract GorillaBitsI is Ownable, IERC721 {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);
}
