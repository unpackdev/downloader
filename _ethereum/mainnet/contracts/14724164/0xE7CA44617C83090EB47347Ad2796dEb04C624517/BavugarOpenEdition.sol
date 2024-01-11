//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";
import "./Base64.sol";

contract BavugarOpenEdition is ERC721A, PaymentSplitter, Ownable  {
    uint256 public mintPrice = 0.05 * (10**18);
    uint16 public maxPurchase = 20;
    bool public isPaused = true;
    uint supply = 0;

    constructor(address[] memory payees, uint256[] memory shares)
        ERC721A("Bavugar - Rising", "RISING")
        PaymentSplitter(payees, shares)
    {}

    function mintNFT(uint numberOfTokens) external payable {
        require(!isPaused, "Cannot mint while the contract is paused");
        require(
            numberOfTokens <= maxPurchase,
            "Cannot mint more than 20 NFTs at a time"
        );
        require(mintPrice * numberOfTokens <= msg.value, "Not enough Ether sent");

        _safeMint(msg.sender, numberOfTokens);
        supply += numberOfTokens;
    }

    function totalSupply() public view override returns (uint) {
        return supply;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        if (!_exists(tokenId)) revert("Token does not exist");
        return string(abi.encodePacked("https://ipfs.io/ipfs/QmTQc55gzsRAeZBGrdfSsxwz8Utr3r5zDZwA59zfH9JcqK/metadata.json"));
    }

    function togglePause() public onlyOwner {
        isPaused = !isPaused;
    }
}
