// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC2981.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract GambitChessClub is ERC721Enumerable, Ownable, IERC2981 {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.025 ether;
    uint256 public constant maxSupply = 10032; //10000
    uint8 private constant maxMintAmount = 5; // 5 - max number of items that can be minted
    string public _contractURI;
    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _cURI,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        _contractURI = _cURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        _safeMint(msg.sender, 1);
    }

    function mintNFT(uint8 numberOfTokens) external payable {
        uint256 supply = totalSupply();
        require(numberOfTokens > 0, "At least 1 NFT");
        require(numberOfTokens <= maxMintAmount, "Exceeded max token purchase");
        require(
            supply + numberOfTokens <= maxSupply,
            "Purchase would exceed max tokens"
        );
        require(
            msg.value >= cost * numberOfTokens,
            "Amount of ether sent not correct."
        );
        for (uint8 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function cntURI(string calldata _URI) external onlyOwner {
        _contractURI = _URI;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    // internal
    // reduce gas fee if followed
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    function setCost(uint8 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (address(this), (salePrice * 75) / 1000);
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
