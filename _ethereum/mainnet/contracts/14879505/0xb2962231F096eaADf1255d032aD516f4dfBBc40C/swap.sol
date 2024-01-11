//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./IERC721.sol";

contract Swapping is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _swapId;

    mapping (uint256 => uint256) swapEther;
    mapping (uint256 => address) swapTokenAddr;
    mapping (uint256 => uint256) swapTokenId;
    mapping (uint256 => address) swapTargetAddr;
    mapping (uint256 => uint256) swapTargetId;

    constructor() {
        _swapId = 0;
    }

    // swap by ETHER
    function registerSwap(address targetAddr, uint256 targetTokenId) public payable returns (uint256) {
        require(msg.value > 0, "Ether amount must be greater than 0");
        
        uint256 id = _swapId;
        _swapId++;
        swapEther[id] = msg.value;
        swapTargetAddr[id] = targetAddr;
        swapTargetId[id] = targetTokenId;

        IERC721 tarNFT = IERC721(targetAddr);
        address tarOwner = tarNFT.ownerOf(targetTokenId);
        tarNFT.transferFrom(tarOwner, address(this), targetTokenId);
        return id;
    }

    // swap token and token
    function registerSwap(address sourceAddr, uint256 sourceId, address targetAddr, uint256 targetTokenId) public returns (uint256) {
        uint256 id = _swapId;
        _swapId++;
        swapEther[id] = 0;
        swapTokenAddr[id] = sourceAddr;
        swapTokenId[id] = sourceId;
        swapTargetAddr[id] = targetAddr;
        swapTargetId[id] = targetTokenId;

        IERC721 srcNFT = IERC721(sourceAddr);
        address srcOwner = srcNFT.ownerOf(sourceId);
        srcNFT.transferFrom(srcOwner, address(this), sourceId);
        return id;
    }

    function registerSwapNFT(address sourceAddr, uint256 sourceId, uint256 ethValue) public returns (uint256) {
        require(ethValue > 0, "Ether amount must be greater than 0");
        
        uint256 id = _swapId;
        _swapId++;
        swapEther[id] = 0;
        swapTokenAddr[id] = sourceAddr;
        swapTokenId[id] = sourceId;

        IERC721 srcNFT = IERC721(sourceAddr);
        address srcOwner = srcNFT.ownerOf(sourceId);
        srcNFT.transferFrom(srcOwner, address(this), sourceId);
        return id;
    }

    function applySwap(uint256 swapId) public payable {
        address srcAddr = swapTokenAddr[swapId];
        // uint256 srcId = swapTargetId[swapId];

        // address tarAddr = swapTargetAddr[swapId];
        uint256 tarId = swapTargetId[swapId];

        // IERC721 srcNFT = IERC721(srcAddr);
        IERC721 tarNFT = IERC721(srcAddr);

        // address srcOwner = srcNFT.ownerOf(srcId);
        address tarOwner = tarNFT.ownerOf(tarId);

        // srcNFT.transfer(tarOwner, srcId);

        tarNFT.transferFrom(tarOwner, address(this), tarId);
    }

    function withdraw() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

}
