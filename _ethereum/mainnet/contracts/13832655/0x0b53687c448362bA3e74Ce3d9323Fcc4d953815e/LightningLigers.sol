// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";

import "./CountersUpgradeable.sol";


/// This custom NFT contract stores additional metadata to use for tokenURI
contract LightningLigers is ERC721Delegated {
    uint256 public currentTokenId;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PURCHASE_PER_TX = 20;

    uint256 public mintPrice = 0.8 ether;
    bool public sale = false;

    constructor(
        IBaseERC721Interface baseFactory
    )
        ERC721Delegated(
            baseFactory,
            "Lightning Ligers",
            "LL",
            ConfigSettings({
                royaltyBps: 500,
                uriBase: "",
                uriExtension: "",
                hasTransferHook: false
            })
        )
    {
        currentTokenId++;
    }

    function mint(uint256 amount) public payable {
        require(sale, "Sale not yet open");
        require(currentTokenId + amount <= MAX_SUPPLY, "Sold Out");
        require(msg.value == mintPrice * amount, "Purchase: payment incorrect");
        require(amount <= MAX_PURCHASE_PER_TX, "Purchase: max purchase amount exceeded");

        for(uint256 i; i < amount; i++) {
            _mint(msg.sender, currentTokenId++);
        }
    }

    function setBaseURI(string memory newUri) public onlyOwner {
        _setBaseURI(newUri, "");
    }

    function setPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function setSale(bool shouldSale) external onlyOwner {
        sale = shouldSale;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(0x0a492523EAd1E7778e10C076fb692FA87B855Cc6).transfer(balance);
    }
}
