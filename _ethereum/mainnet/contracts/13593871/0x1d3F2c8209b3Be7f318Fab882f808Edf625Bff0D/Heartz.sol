// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import statements
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

// contract class
contract Heartz is ERC721Enumerable, Ownable {
    // utilities
    using Strings for uint256;
    using SafeMath for uint256;

    // uint256
    uint256 public constant nftPrice = 50000000000000000;
    uint256 public constant maxNftPurchase = 20;
    uint256 public maxSupply = 7499;
    uint256 public nftPerAddressLimit = 5;

    // booleans
    bool public saleIsActive = false; // false
    bool public publicMintingStatus = false; // false
    bool public onlyWhitelisted = true; // true
    bool public revealed = false;

    // addresses
    address[] public whitelistAddresses;

    // strings
    string public baseURI;

    // mappings
    mapping(uint256 => string) _tokenURIs;

    // contract constructor
    constructor() ERC721("Heartz", "HRTZ") {}

    // get functions
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return whitelistAddresses;
    }

    function getBaseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    // set functions
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipPublicMintingStatus() public onlyOwner {
        publicMintingStatus = !publicMintingStatus;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipOnlyWhitelisted() public onlyOwner {
        onlyWhitelisted = !onlyWhitelisted;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), "Token does not exist");
        _tokenURIs[tokenId] = _tokenURI;
    }

    // unnecessarily long mint function
    function mint(uint256 numberOfTokens) public payable {
        require(
            numberOfTokens > 0,
            "The number of tokens can not be less than or equal to 0"
        );
        require(
            totalSupply().add(numberOfTokens) <= maxSupply,
            "The purchase would exceed the max supply of Heartz"
        );

        if (msg.sender != owner()) {
            require(
                numberOfTokens <= maxNftPurchase,
                "The contract can only mint up to 20 tokens at a time"
            );
            require(
                nftPrice.mul(numberOfTokens) <= msg.value,
                "The contract did not receive enough Ethereum"
            );
            require(saleIsActive, "The contract sale is not active");

            if (publicMintingStatus) {
                for (uint256 i = 0; i < numberOfTokens; i++) {
                    uint256 newId = totalSupply();
                    if (totalSupply() < maxSupply) {
                        _safeMint(msg.sender, newId);
                        _setTokenURI(newId, tokenURI(newId));
                    }
                }
            } else if (onlyWhitelisted) {
                require(
                    isWhitelisted(msg.sender),
                    "The user is not currently whitelisted"
                );
                require(
                    (balanceOf(msg.sender) < nftPerAddressLimit) &&
                        (numberOfTokens <=
                            (nftPerAddressLimit.sub(balanceOf(msg.sender)))),
                    "The contract can only mint up to 5 tokens at a time"
                );

                for (uint256 i = 0; i < numberOfTokens; i++) {
                    uint256 newId = totalSupply();
                    if (totalSupply() < maxSupply) {
                        _safeMint(msg.sender, newId);
                        _setTokenURI(newId, tokenURI(newId));
                    }
                }
            }
        } else {
            for (uint256 i = 0; i < numberOfTokens; i++) {
                uint256 newId = totalSupply();
                if (totalSupply() < maxSupply) {
                    _safeMint(msg.sender, newId);
                    _setTokenURI(newId, tokenURI(newId));
                }
            }
        }
    }

    // token URI retriever
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        if (revealed == false) {
            return
                "https://ipfs.io/ipfs/QmdmY6GJqqUzRKgEbnD3Q7E2GYykVMWg4gGhrKWaJBaPf2";
        }

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // classic withdraw function
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    // check if specified user is whitelisted
    function isWhitelisted(address user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            if (whitelistAddresses[i] == user) {
                return true;
            }
        }
        return false;
    }

    // generate list of whitelist users
    function whitelistUsers(address[] calldata users) public onlyOwner {
        delete whitelistAddresses;
        whitelistAddresses = users;
    }
}
