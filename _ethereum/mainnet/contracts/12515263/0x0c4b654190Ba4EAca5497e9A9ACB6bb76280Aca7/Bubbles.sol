// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.3;

import "./NFT.sol";

contract Bubbles is NFT {
    uint256 private constant MAX_SUPPLY = 5555;
    uint256 private constant MAX_AMOUNT = 20;
    uint256 private constant PRICE = 0.1 ether;
    bytes32 private _finalBaseTokenURIHash;

    string private constant NAME = "CryptoBubblesArt";
    string private constant SYMBOL = "BUBBLES";
    string private constant BASE_URI = "ipfs://QmQnH3gvFVRC6CvGGJKVJEeuqWVZuJrtauFihREXR7tuFA/";

    address private constant ROOT = 0x0E8d04d9042d6376357994541ADC25159b7E1C23;

    bytes32 private constant PROVENANCE = 0x5456c71895f4e84d2ff2b8cc453f501acc05c27ca66c082f8f44eb635777a660;

    constructor() NFT(NAME, SYMBOL, BASE_URI) {
        _finalBaseTokenURIHash = PROVENANCE;
        transferOwnership(ROOT);
        _pause();
    }

    function purchase(uint256 amount)
        external
        payable
        virtual
        whenNotPaused
        whenSelling
    {
        require(amount > 0, "not enough");
        require(amount < 21, "too much");

        require(msg.value == amount * PRICE, "not exact amount");
        require(totalSupply() + amount < MAX_SUPPLY, "not enough supply");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function reserve(uint256 amount) external onlyOwner {
        require(amount > 0, "not enough");
        require(amount < 21, "too much");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /**
     * @dev update token uri on sale end
     * we only set base token uri if it passes provenance
     * eg. keccak256(abi.encodePacked("ipfs://cid1/"))
     * should match originally prepared
     */

    function setBaseTokenURI(string memory baseTokenURI)
        public
        virtual
        override
        onlyOwner
    {
        require(
            keccak256(abi.encodePacked(baseTokenURI)) == _finalBaseTokenURIHash,
            ".."
        );
        super.setBaseTokenURI(baseTokenURI);
    }
}
