// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./IERC721Enumerable.sol";

interface IFearlessShrimps is IERC721Enumerable{
    function walletOfOwner() external view returns (uint256[] memory);

    function burn(uint256 _tokenId) external;
}
