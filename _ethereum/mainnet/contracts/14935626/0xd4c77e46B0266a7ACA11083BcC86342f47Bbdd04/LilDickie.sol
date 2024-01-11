//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract LilDickie is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant TOTAL_SUPPLY = 6677;
    uint256 public constant FREE_SUPPLY = 3000;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant PUBLIC_PRICE = 0.0009 ether;

    string private baseURI;
    bool public mintActive = false;

    constructor(string memory _baseURI) ERC721A("LilDickie", "LILDICKIE") {
        baseURI = _baseURI;
    }

    function toggleMint() external onlyOwner {
        mintActive = !mintActive;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdrawAll(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function mint(uint256 quantity) external payable {
        require(mintActive, "Mint is not active");
        require(quantity <= MAX_PER_TX, "More than max per tx");

        uint256 currentSupply = totalSupply();
        require(
            currentSupply + quantity <= TOTAL_SUPPLY,
            "Mint amount is wrong"
        );

        if (currentSupply > FREE_SUPPLY) {
            require(
                msg.value >= (quantity * PUBLIC_PRICE),
                "Wrong payment amount"
            );
        }

        _safeMint(msg.sender, quantity);
    }

    function mintForAddresses(address[] calldata addresses, uint256 quantity)
        external
        onlyOwner
    {
        uint256 total = 0;
        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], quantity);
            total += quantity;
        }

        require(totalSupply() + total <= TOTAL_SUPPLY, "Exceed total supply");
    }
}
