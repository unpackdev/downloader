//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CommonNft.sol";

contract RMF is CommonNft {
    uint256 public mintPerBundle;
    uint256 public maxBundleSizePerTx;

    constructor()
        CommonNft("RMF", CommonNft.Config(9, 3, 0, 0.0069 ether, 9, ""))
    {
        mintPerBundle = 3;
        maxBundleSizePerTx = 3;
    }

    function setBundleProps(uint256 mintPerBundle_, uint256 maxBundleSizePerTx_)
        external
        onlyOwner
    {
        mintPerBundle = mintPerBundle_;
        maxBundleSizePerTx = maxBundleSizePerTx_;
    }

    function mint(uint256 size) external payable override nonReentrant {
        require(isMintStarted, "Not started");
        require(tx.origin == msg.sender, "Contracts not allowed");
        require(size <= maxBundleSizePerTx, "Bundle size need to be smaller");
        uint256 quantity = size * mintPerBundle;
        uint256 pubMintSupply = config.maxSupply - config.reserved;
        require(
            totalSupply() + quantity <= pubMintSupply,
            "Exceed sales max limit"
        );
        require(
            numberMinted(msg.sender) + quantity <= config.maxTokenPerAddress,
            "can not mint this many"
        );
        if (totalSupply() >= config.firstFreeMint) {
            uint256 cost;
            unchecked {
                cost = size * config.mintPrice;
            }
            require(msg.value == cost, "wrong payment");
        }
        _safeMint(msg.sender, quantity);
    }
}
