// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./IMintableBurnableERC721.sol";

interface IGenesisNFT is IMintableBurnableERC721 {
    function MAX_MINT_NUM() external returns(uint);
    function MAX_RESERVE_NUM() external returns(uint);
    function ticketNFT() external returns(IMintableBurnableERC721);
    function mintedNum() external returns(uint);
    function reservedNum() external returns(uint);
    function userReserved(address user) external returns(uint);
    function draw(uint _luckyNftId, uint _totalNum, uint8 _v, bytes32 _r, bytes32 _s) external;
    function reserve(address _to, uint _num, uint8 _v, bytes32 _r, bytes32 _s) external;
}

