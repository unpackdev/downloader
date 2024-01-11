//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ABCBears is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant TOTAL_SUPPLY = 6666;
    uint256 public constant STAGE1_SUPPLY = 2222;
    uint256 public constant STAGE2_SUPPLY = 4444;
    uint256 public constant MAX_PER_TX = 10;

    uint256 public STAGE2_PRICE = 0.0009 ether;
    uint256 public STAGE3_PRICE = 0.003 ether;

    string private baseURI;
    string private constant BASE_EXTENSION = ".json";
    bool public isSaleActive = false;

    constructor(string memory _baseURI) ERC721A("ABCBears", "ABCBEARS") {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURI, _tokenId.toString(), BASE_EXTENSION)
            );
    }

    function mint(uint256 quantity) external payable {
        require(isSaleActive, "Sale is not active");
        require(quantity <= MAX_PER_TX, "Exceed max mint per tx");

        uint256 minted = totalSupply();
        require(minted + quantity <= TOTAL_SUPPLY, "Exceed total supply");

        if (minted > STAGE1_SUPPLY && minted <= STAGE2_SUPPLY) {
            uint256 cost = quantity * STAGE2_PRICE;
            require(msg.value >= cost, "Wrong payment amount");
        } else if (minted > STAGE2_SUPPLY) {
            uint256 cost = quantity * STAGE3_PRICE;
            require(msg.value >= cost, "Wrong payment amount");
        }

        _safeMint(msg.sender, quantity);
    }

    function airdrop(address[] calldata addresses, uint256 quantity)
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

    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdrawAll(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    function setStage2Price(uint256 price) external onlyOwner {
        STAGE2_PRICE = price;
    }

    function setStage3Price(uint256 price) external onlyOwner {
        STAGE3_PRICE = price;
    }
}
