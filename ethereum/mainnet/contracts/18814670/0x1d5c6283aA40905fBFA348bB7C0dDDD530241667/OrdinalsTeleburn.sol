// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721 {
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract OrdinalsTeleburn {

    event NftTeleburn(address indexed contractAddress, string indexed taprootReceiptAddress, uint256 tokenId);

    function batchTeleburnNfts(uint256[] calldata tokenIds, address[] calldata recipients, address contractAddress, string calldata taprootReceiptAddress) public {
        require(tokenIds.length == recipients.length, "Param arrays must be same length");
        require(_startsWith(taprootReceiptAddress, "bc1p"), "Invalid Taproot address");

        // Initialise NFT Contract
        IERC721 nftContract = IERC721(contractAddress);

        // Check if this contract is approved to transfer all NFTs of the sender
        require(nftContract.isApprovedForAll(msg.sender, address(this)), "Ordinals Teleburn contract not approved to transfer NFTs");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            address owner = nftContract.ownerOf(tokenId);
            require(owner == msg.sender, "Sender does not own the NFT");

            nftContract.transferFrom(owner, recipients[i], tokenId);

            emit NftTeleburn(contractAddress, taprootReceiptAddress, tokenId);
        }
    }

    function _startsWith(string memory _string, string memory _prefix) internal pure returns (bool) {
        bytes memory stringBytes = bytes(_string);
        bytes memory prefixBytes = bytes(_prefix);

        if (stringBytes.length < prefixBytes.length) {
            return false;
        }

        for (uint i = 0; i < prefixBytes.length; i++) {
            if (stringBytes[i] != prefixBytes[i]) {
                return false;
            }
        }

        return true;
    }
}