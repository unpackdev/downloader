//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC721X.sol";

contract NeuralBeasts is ERC721X, Ownable {
    using Strings for uint256;

    event PublicSaleStateUpdate(bool publicSaleActive);

    string public baseURI =
        "ipfs://QmTBFgcYpFdR31JDJPhWdy9BuD4dVJpExfttRRhcJ9S9zL/";

    bool public publicSaleActive;

    uint256 public price = 0.1 ether;

    uint256 private constant MAX_TRAIT1 = 17;
    uint256 private constant MAX_TRAIT2 = 12;
    uint256 private constant MAX_TRAIT3 = 21;

    constructor() ERC721X("Neural Beasts", "NEURAL") {}

    // ------------- External -------------

    function mint(uint256 tokenId)
        external
        payable
        whenPublicSaleActive
        onlyHuman
    {
        require(msg.value == price, "INCORRECT_VALUE");

        uint256 trait1 = tokenId / 10000;
        uint256 trait2 = (tokenId / 100) % 100;
        uint256 trait3 = tokenId % 100;

        require(trait1 < MAX_TRAIT1, "INCORRECT_TRAIT1");
        require(trait2 < MAX_TRAIT2, "INCORRECT_TRAIT2");
        require(trait3 < MAX_TRAIT3, "INCORRECT_TRAIT3");

        _mint(msg.sender, tokenId);
    }

    // ------------- View -------------

    function getTraits(uint256 tokenId)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 trait1 = tokenId / 10000;
        uint256 trait2 = (tokenId / 100) % 100;
        uint256 trait3 = tokenId % 100;

        uint256[] memory res = new uint256[](3);
        res[0] = trait1;
        res[1] = trait2;
        res[2] = trait3;
        return res;
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function mintable(uint256 tokenId) public view returns (bool) {
        return !_exists(tokenId);
    }

    // ------------- ERC721 -------------

    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        uint256 count;
        for (uint256 i; i < MAX_TRAIT1; ++i) {
            for (uint256 j; j < MAX_TRAIT2; ++j) {
                for (uint256 k; k < MAX_TRAIT3; ++k) {
                    uint256 tokenId = i * 10000 + j * 100 + k;
                    if (owner == _owners[tokenId]) count++;
                }
            }
        }
        return count;
    }

    // ------------- Admin -------------

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
        emit PublicSaleStateUpdate(active);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        bool _success = _token.transfer(owner(), balance);
        require(_success, "TOKEN_TRANSFER_FAILED");
    }

    // ------------- Modifier -------------

    modifier whenPublicSaleActive() {
        require(publicSaleActive, "PUBLIC_SALE_NOT_ACTIVE");
        _;
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender, "CONTRACT_CALL");
        _;
    }
}
