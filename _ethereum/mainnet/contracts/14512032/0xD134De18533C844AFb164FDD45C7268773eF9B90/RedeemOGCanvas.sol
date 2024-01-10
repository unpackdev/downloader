//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// @title:  CRYPTOPUPPETS
// @desc:   LAPO FATAI ICONIC CHARACTER
// @artist: https://www.instagram.com/lapofatai
// @team:   https://cryptopuppets.io
// @author: https://medusa.dev
// @url:    https://cryptopuppets.io

import "./Ownable.sol";
import "./IERC721.sol";

contract RedeemOGCanvas is Ownable {
    IERC721 private immutable _ogContract;
    mapping(uint256 => address) private _redeem;

    constructor(address ogContractAddress) {
        _ogContract = IERC721(ogContractAddress);
    }

    function isRedeemed(uint256 tokenId) public view returns (bool) {
        return _redeem[tokenId] != address(0);
    }

    function getRedeemer(uint256 tokenId) public view returns (address) {
        return _redeem[tokenId];
    }

    function redeem(uint256 tokenId) external {
        require(_redeem[tokenId] == address(0), "already redeemed");
        require(
            msg.sender == _ogContract.ownerOf(tokenId),
            "only owner can redeem"
        );
        _redeem[tokenId] = msg.sender;
    }

    function redeem(uint256 tokenId, address redeemer) external onlyOwner {
        require(_redeem[tokenId] == address(0), "already redeemed");
        require(
            redeemer == _ogContract.ownerOf(tokenId),
            "redeemer is not owner of token"
        );
        _redeem[tokenId] = redeemer;
    }

    function deredeem(uint256 tokenId) external onlyOwner {
        require(_redeem[tokenId] != address(0), "already not redeemed");
        _redeem[tokenId] = address(0);
    }
}
