// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

import "./Multicall.sol";

// import "./console.sol";

interface IHOURAI {

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

}

contract HOURAIStable is Multicall, ReentrancyGuard, ERC721Enumerable, IERC721Receiver, Ownable {

    address public hourAi;
    address public recipient;
    uint256 public nftNum;

    string public baseURI;
    
    mapping(uint256=>uint256) public hourAiIds;
   
    constructor(address _hourAi, address _recipient) ERC721("HOURAI Stable", "HOURAI-STABLE") {
        hourAi = _hourAi;
        recipient = _recipient;
        nftNum = 0;
    }

    /// @notice Used for ERC721 safeTransferFrom
    function onERC721Received(address, address, uint256, bytes memory) 
        public 
        pure
        virtual 
        override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    function stake(uint256 hourAiId) external nonReentrant returns(uint256 nftId) {
        IHOURAI(hourAi).safeTransferFrom(msg.sender, address(this), hourAiId);
        nftNum ++;
        nftId = nftNum;
        hourAiIds[nftId] = hourAiId;
        _mint(msg.sender, nftId);
    }

    function modifyRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function transferTokens(uint256[] calldata hourAiId) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < hourAiId.length; i ++) {
            IHOURAI(hourAi).safeTransferFrom(address(this), recipient, hourAiId[i]);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

}