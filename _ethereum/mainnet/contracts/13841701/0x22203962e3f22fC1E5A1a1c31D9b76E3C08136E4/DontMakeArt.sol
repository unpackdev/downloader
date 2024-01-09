// contracts/DontMakeArt.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";

contract DontMakeArt is ERC721 {
    string public baseURI =
        "ipfs://QmP1xEH5CMbUi2rM1XSAYWECYdZnMkU74HevfrfT79PZmj/";
    address public constant deployer =
        address(0x9954154fb679105b06F16AcAd24C2Fc159C4248e);

    uint256 public totalMinted = 0;

    constructor() ERC721("DontMakeArt", "DMA") {}

    function mintQuantity(uint256 _q) external {
        require(msg.sender == deployer, "DontMakeArt: Only deployer");
        require(_q + totalMinted <= 500, "DontMakeArt: Max 500");

        for (uint256 i = 0; i < _q; i++) _mint(msg.sender, i + totalMinted);

        totalMinted += _q;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "DontMakeArt: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId + 1),
                    ".json"
                )
            );
    }

    function setBaseURI(string calldata _to) external {
        require(msg.sender == deployer, "DontMakeArt: Only deployer");
        baseURI = _to;
    }
}
