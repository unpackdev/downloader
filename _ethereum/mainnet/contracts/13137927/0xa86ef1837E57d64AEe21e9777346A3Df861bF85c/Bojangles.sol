// SPDX-License-Identifier: MIT
// eyJuYW1lIjoiME4xIC0gTWV0YWRhdGEiLCJkZXNjcmlwdGlvbiI6IlRoaXMgc2hvdWxkIE5PVCBiZSByZXZlYWxlZCBiZWZvcmUgYWxsIGFyZSBzb2xkLiBJbWFnZXMgY29udGFpbmVkIGJlbG93IiwiaW1hZ2VzIjoiMHg1MTZENTU0ODYxMzQ0QTc3NEI1MDY3NjY0ODcxNDM1ODMxNTQ3ODMyNTc2OTRBNTg2NDYzNEM2MzY1NTM3NDZGNTEzNjY1Nzg1NTU4Mzg1NDRBNkE0NjYxNjE1MSJ9
pragma solidity ^0.8.0;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./console.sol";

interface BojanglesBase {
    function purchase(uint256 numberOfTokens) external payable;

    function gift(address[] calldata to) external;

    function setIsActive(bool isActive) external;

    function withdraw() external;
}

interface BojanglesMetadata {
    function setContractURI(string calldata URI) external;

    function setBaseURI(string calldata URI) external;

    function setRevealedBaseURI(string calldata revealedBaseURI) external;

    function contractURI() external view returns (string memory);
}

contract Bojangles is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    BojanglesBase,
    BojanglesMetadata
{
    using StringsUpgradeable for uint256;

    // Gift + Public = MAX mint. Allowed Mint is so we can sell a certain amount at a time.
    uint256 public constant BOJANGLES_GIFT = 69;
    uint256 public constant BOJANGLES_PUBLIC = 6_900;
    uint256 public constant BOJANGLES_MAX = BOJANGLES_GIFT + BOJANGLES_PUBLIC;

    uint256 public purchaseLimit;
    uint256 public price;
    uint256 public allowedMint; // For presale. We are allowing 500 to be minted this number will = 6959 once it's available after presale.
    bool public isActive;

    /// @dev We will use these to be able to calculate remaining correctly.
    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;

    string private _contractURI;
    string private _tokenBaseURI;
    string private _tokenRevealedBaseURI;

    function initialize(string memory name, string memory symbol)
        public
        initializer
    {
        _contractURI = '';
        _tokenBaseURI = '';
        _tokenRevealedBaseURI = '';
        isActive = false;
        allowedMint = 500;
        purchaseLimit = 20;
        price = 0.04 ether;

        __Ownable_init();
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
    }

    function purchase(uint256 numberOfTokens) external payable override {
        require(isActive, 'Contract is not active');
        require(totalSupply() < BOJANGLES_MAX, 'All tokens have been minted');
        require(numberOfTokens <= purchaseLimit, 'Would exceed purchaseLimit');
        /**
         * @dev The last person to purchase might pay too much.
         * This way however they can't get sniped.
         * If this happens, we'll refund the Eth for the unavailable tokens.
         */
        require(
            totalPublicSupply + numberOfTokens <= allowedMint,
            'Purchase would exceed AllowedMint'
        );
        require(
            totalPublicSupply < BOJANGLES_PUBLIC,
            'Purchase would exceed BOJANGLES_PUBLIC'
        );
        require(
            price * numberOfTokens <= msg.value,
            'ETH amount is not sufficient'
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            /**
             * @dev Since they can get here while exceeding the BOJANGLES_MAX,
             * we have to make sure to not mint any additional tokens.
             */
            if (totalPublicSupply < BOJANGLES_PUBLIC) {
                //** @dev Public token numbering starts after BOJANGLES_GIFT. And we don't want our tokens to start at 0 but at 1. */
                uint256 tokenId = BOJANGLES_GIFT + totalPublicSupply + 1;

                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(totalSupply() < BOJANGLES_MAX, 'All tokens have been minted');
        require(
            totalGiftSupply + to.length <= BOJANGLES_GIFT,
            'Not enough tokens left to gift'
        );

        for (uint256 i = 0; i < to.length; i++) {
            // @dev We don't want our tokens to start at 0 but at 1.
            uint256 tokenId = totalGiftSupply + 1;

            totalGiftSupply += 1;
            _safeMint(to[i], tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI)
        external
        override
        onlyOwner
    {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setAllowedMint(uint256 _allowedMint) external onlyOwner {
        allowedMint = _allowedMint;
    }

    function setPurchaseLimit(uint256 _limit) external onlyOwner {
        purchaseLimit = _limit;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), 'Token does not exist');

        // @dev Convert string to bytes so we can check if it's empty or not.
        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return
            bytes(revealedBaseURI).length > 0
                ? string(abi.encodePacked(revealedBaseURI, tokenId.toString()))
                : _tokenBaseURI;
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }
}
