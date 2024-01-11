pragma solidity ^0.8.0;

import "./ERC721WContract.sol";

contract ParamiLink {

    function setWNFTLink(address wContractAddress, uint256 tokenId, string calldata value) external {
        ERC721WContract wContract = (ERC721WContract)(wContractAddress);
        require(wContract.isAddressAuthroized(tokenId, address(this)), "not authorized");
        require(wContract.ownerOf(tokenId) == msg.sender, "not token owner");
        wContract.setValue(tokenId, value);
    }
}
