// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWomanSeekersNewDawn {
    function lastTokenIdTransfer() external view returns (uint);

        function totalSupplyTR1() external view returns (uint);


    function totalSupplyTR2() external view returns (uint);

    function cost() external view returns(uint256);

    function gameDiscount() external view returns(uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);

    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function mintFromGame(uint256 _mintAmount) external;

    function viewNFTCost() external view returns (uint256);

    function viewNotTransferable(uint256 _tokenId) external view returns (bool);

    function setNotTransferable(uint256 _tokendId, bool _value) external;
}
