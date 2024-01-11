// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./TheModernAcreNFTPassBase.sol";

contract TheModernAcreNFTPass is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    TheModernAcreNFTPassBase
{
    using StringsUpgradeable for uint256;

    function initialize(
        uint256 _tps,
        uint256 _trs,
        uint256 _tms,
        uint256 _price,
        string memory _bu,
        string[] memory _images
    ) public initializer {
        __ERC721_init("TheModernAcreNFTPass", "TMAP");
        __Ownable_init();
        __Pausable_init();
        TOTAL_PUBLIC_SUPPLY = _tps;
        TOTAL_RESERVED_SUPPLY = _trs;
        TOTAL_MENTOR_SUPPLY = _tms;
        TOTAL_MENTEE_SUPPLY = _tms;
        BASE_URI = _bu;
        PRICE = _price;
        images = _images;
    }

    function mint(uint256 amount) external payable {
        require(!paused(), "NFT is paused.");
        require(!presale, "NFT presale mint is over.");
        require(
            msg.value >= amount * PRICE,
            "TheModernAcreNFTPass: Insufficient funds"
        );
        require(amountMintedPublic < TOTAL_PUBLIC_SUPPLY, "No more NFTs");
        // require(balanceOf(_msgSender()) == 0, "You already own one TheModernAcreNFT");

        funds += msg.value;

        uint256 actualAmount;
        if (amount + amountMintedPublic > TOTAL_PUBLIC_SUPPLY)
            actualAmount = TOTAL_PUBLIC_SUPPLY - amountMintedPublic;
        else actualAmount = amount;

        for (uint256 i = 0; i < actualAmount; i++) {
            _safeMint(_msgSender(), amountMintedTotal);
            tokenIdToImage[amountMintedTotal] = amountMintedTotal % 6;
            amountMintedTotal++;
        }
        amountMintedPublic += actualAmount;
    }

    function reserveMint(uint256 image, uint256 amount) external onlyOwner {
        require(!paused(), "TheModernAcreNFTPass: NFT is paused.");
        require(
            amountMintedReserved + amount <= TOTAL_RESERVED_SUPPLY ||
                amountMintedPublic + amount <= TOTAL_PUBLIC_SUPPLY,
            "TheModernAcreNFTPass: No more NFTs"
        );

        if (amountMintedReserved + amount <= TOTAL_RESERVED_SUPPLY) {
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(owner(), amountMintedTotal);
                tokenIdToImage[amountMintedTotal] = image;
                amountMintedTotal++;
            }
            amountMintedReserved += amount;
        } else if (amountMintedPublic + amount <= TOTAL_PUBLIC_SUPPLY) {
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(owner(), amountMintedTotal);
                tokenIdToImage[amountMintedTotal] = image;
                amountMintedTotal++;
            }
            amountMintedPublic += amount;
        }
    }

    function airdropMentorPass(address airdropee) external onlyOwner {
        require(!paused(), "TheModernAcreNFTPass: NFT is paused.");
        require(
            amountMintedMentor < TOTAL_MENTOR_SUPPLY,
            "TheModernAcreNFTPass: No more NFTs"
        );

        _safeMint(airdropee, amountMintedTotal);
        tokenIdToImage[amountMintedTotal] = 6;
        amountMintedTotal++;
        amountMintedMentor++;
    }

    function airdropMenteePass(address airdropee, uint256 image)
        external
        onlyOwner
    {
        require(!paused(), "TheModernAcreNFTPass: NFT is paused.");
        require(
            amountMintedMentee < TOTAL_MENTEE_SUPPLY,
            "TheModernAcreNFTPass: No more NFTs"
        );

        _safeMint(airdropee, amountMintedTotal);
        tokenIdToImage[amountMintedTotal] = image;
        amountMintedTotal++;
        amountMintedMentee++;
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

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenIdToImage[tokenId].toString(),
                        ".json"
                    )
                )
                : "";
    }

    function setBaseURI(string memory _URI) external {
        BASE_URI = _URI;
    }

    function setImage(uint256 tokenId, uint256 image) external onlyOwner {
        tokenIdToImage[tokenId] = image;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function pauseNFT() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Cannot be free");
        PRICE = newPrice;
    }

    function setPresale() external onlyOwner {
        presale = !presale;
    }

    function withdrawBalance() external payable onlyOwner {
        payable(owner()).transfer(funds);
        funds = 0;
    }
}
