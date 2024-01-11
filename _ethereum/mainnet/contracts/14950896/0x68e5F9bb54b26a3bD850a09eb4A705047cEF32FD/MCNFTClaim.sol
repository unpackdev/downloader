//SPDX-License-Identifier: MIT
//contracts/MCNFTClaim.sol
pragma solidity 0.8.12;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./EIP712Whitelisting.sol";

contract MCNFTClaim is Ownable, ReentrancyGuard, EIP712Whitelisting, IERC721Receiver {
    uint public maxMintPerAddress = 1;
    uint256 public tokenId = 0;
    address public nft;
    mapping(address => uint256) private addressMintCount;

    constructor(address _nft)
    {
        nft = _nft;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setMaxMintPerAddress(uint amount) external onlyOwner {
        maxMintPerAddress = amount;
    }

    function claim(bytes calldata signature) 
        external
        nonReentrant
        returns (bool)
    {
        require(addressMintCount[_msgSender()] < maxMintPerAddress, "You cannot mint more");
        // require(isEIP712WhiteListed(signature), "Not whitelisted.");

        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        tokenId = tokenId + 1;
        addressMintCount[_msgSender()] = addressMintCount[_msgSender()] + 1;

        return true;
    }
}