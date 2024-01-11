//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract NoMoreGoblins is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_FREE_SUPPLY = 2000;
    uint256 public constant MAX_MINT_PER_TX = 10;
    uint256 public constant RICH_MINT_PRICE = 0.003 ether;

    string private _baseTokenURI;

    constructor() ERC721A("NoMoreGoblins", "NMG") {}

    // free mint
    function freeMint() external {
        require(
            totalSupply() + 2 <= MAX_FREE_SUPPLY,
            "No More Free NoMoreGoblins"
        );
        _safeMint(msg.sender, 2);
    }

    function richMint(uint256 amount) external payable {
        require(totalSupply() + amount <= MAX_SUPPLY, "No More NoMoreGoblins");
        require(amount <= MAX_MINT_PER_TX, "Too many mints per transaction");
        require(msg.value >= RICH_MINT_PRICE * amount, "Insufficient funds");
        _safeMint(msg.sender, amount);
    }

    function lfg(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(_baseTokenURI).length != 0
                ? string(
                    abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json")
                )
                : "";
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(msg.sender, balance);
    }
}
