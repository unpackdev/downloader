// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IUniOption {
    //custom functions in use
    function burnUniOption(uint _id) external;
    function mintUniOption(address _to) external returns (uint256);
    //IERC721 functions in use
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
