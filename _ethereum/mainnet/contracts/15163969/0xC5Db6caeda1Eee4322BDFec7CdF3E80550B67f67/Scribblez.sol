// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Scribblez is ERC721A, ReentrancyGuard, Ownable {
    uint256 public MAX_SUPPLY = 10000;
    uint256 public MAX_PER_WALLET = 10;
    uint256 public mintPrice = 0.005 ether;
    string baseURI = "";
    string notRevealedURI = "ipfs://QmQh1a7nH7gVtpuSHCLZD6AeWdG95yga29VFYuJCuqpLre";
    bool isRevealed = false;

    constructor() ERC721A("Scribblez", "SCRIBBLEZ") {}

    function mint(uint256 quantity) external payable {
        require(quantity + totalSupply() <= MAX_SUPPLY);
        require(quantity + balanceOf(msg.sender) <= MAX_PER_WALLET, "Maximum number");
        if (totalSupply() < 1500) {
            _mint(msg.sender, quantity);
        } else {
            require(msg.value >= mintPrice * quantity, "Not enough eth sent");
            _mint(msg.sender, quantity);
        }
    }

    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function setMaxPerWallet(uint256 _max) public onlyOwner {
        MAX_PER_WALLET = _max;
    }

    function setBaseURI(string calldata _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        if (!isRevealed) {
            return notRevealedURI;
        }

        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}
