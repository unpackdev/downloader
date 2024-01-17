// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract ArtDriverEvent {
    event Mint(uint256 tokenId, address player, string verb, string adj, string noun, uint8 types);
    event RefreshWords(uint256 tokenId, string verb, string adj, string noun);
    event Locked(uint256 tokenId);
    event AddWord(uint256 tokenId, uint256 weight, string word);
    event NewDefAllowedMintAmount(uint256 _old, uint256 _new);
    event NewPrice(uint256 _old, uint256 _new);
    event TransferEth(address _recipient, uint256 _amount);
    event ClaimMintAmount(address _recipient, uint256 _amount);
}
