// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./console.sol";

interface IMetaPunk2018 {
    function makeToken(uint256, uint256) external;

    // function makeToken(uint256 _tokenId, uint256 _punkId) public onlyOwner {
    //     require(indexToAddress(_punkId) == address(this), "Punk not owned by this Contract");
    //     require(_tokenId == _punkId);
    //     require(!(punkIsHere(_punkId)));
    //     _mint(msg.sender, _tokenId);
    //     punkToTokenId[_punkId] = _tokenId;
    //     tokenIdToPunk[_tokenId] = _punkId;
    //     punkExists[_punkId] = true;
    //     totalPunksInContract++;
    // }

    function seturi(uint256, string memory) external;

    // function seturi(uint256 tokenId, string uri) public onlyOwner {
    //     _setTokenURI(tokenId, uri);
    // }

    function Existing(address) external;

    // function Existing(address _t) public onlyOwner {
    //     punk = CryptoPunksMarket(_t);
    // }

    function transfer(address, uint256) external;

    // function transfer(address _to, uint256 _punk) public onlyOwner {
    //     punk.transferPunk(_to, _punk);
    // }

    function transferOwnership(address) external;

    function exists(uint256) external returns (bool);

    function owner() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function tokenURI(uint256) external view returns (string memory);

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;
}
