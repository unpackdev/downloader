//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./TokenUri.sol";

contract WildSteves is ERC721, Ownable {
    uint256 public constant CUSTOM_MINT_PRICE = 0.042 ether;
    uint256 public constant MULTI_MINT_PRCE = 0.029 ether;

    uint8 public constant BACKGROUND_COUNT = 14;
    uint8 public constant HEAD_COUNT = 32;
    uint8 public constant EYES_COUNT = 21;
    uint8 public constant MOUTH_COUNT = 12;
    uint8 public constant BODIES_COUNT = 24;
    uint8 public constant LEGS_COUNT = 20;
    uint8 public constant FEET_COUNT = 13;
    uint8 public constant ITEM_COUNT = 14;

    TokenUri public tokenUriContract;
    uint256 public totalSupply;
    mapping(uint256 => Attributes) public tokenIdToAttributes;
    mapping(bytes32 => bool) public isHashAttributesUsed;

    event Mint(uint256 tokenId);

    struct Attributes {
        uint8 background;
        uint8 head;
        uint8 eyes;
        uint8 mouth;
        uint8 body;
        uint8 legs;
        uint8 feet;
        uint8 item;
    }

    constructor(TokenUri tokenUriContract_) ERC721("Wild Steves", "STEVE") {
        tokenUriContract = tokenUriContract_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return tokenUriContract.tokenURI(tokenId);
    }

    function withdraw() external onlyOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }

    function randomNumber(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(totalSupply, seed)));
    }

    function customMint(Attributes memory attr) external payable {
        require(
            msg.value >= CUSTOM_MINT_PRICE,
            "Custom mint costs 0.042 ether"
        );

        mint(attr);
    }

    function multiMint(uint256 count) external payable {
        require(
            msg.value >= count * MULTI_MINT_PRCE,
            "Multi mint costs 0.029 ether per Steve"
        );
        require(count <= 20, "Can't mint more than 20");
        require(tx.origin == msg.sender, "Only EOA");

        uint256 i = 0;
        uint256 seed = 0;
        while (i < count) {
            Attributes memory attr = Attributes({
                background: uint8(randomNumber(seed + 1)) % BACKGROUND_COUNT,
                head: uint8(randomNumber(seed + 2)) % HEAD_COUNT,
                eyes: uint8(randomNumber(seed + 3)) % EYES_COUNT,
                mouth: uint8(randomNumber(seed + 4)) % MOUTH_COUNT,
                body: uint8(randomNumber(seed + 5)) % BODIES_COUNT,
                legs: uint8(randomNumber(seed + 6)) % LEGS_COUNT,
                feet: uint8(randomNumber(seed + 7)) % FEET_COUNT,
                item: 0
            });

            (bool isValid, string memory reason) = isValidMint(attr);
            if (isValid) {
                mint(attr);
                i += 1;
            }

            seed += 1;
        }
    }

    function hashAttributes(Attributes memory attr)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encode(attr.head, attr.body, attr.legs, attr.feet));
    }

    function mint(Attributes memory attr) internal {
        totalSupply += 1;

        attr.item = 8; // set to none
        if (randomNumber(8) % 10 == 0) {
            attr.item = uint8(randomNumber(9)) % ITEM_COUNT;

            // Don't let ripped have boxing gloves
            if (attr.item == 1 && attr.body == 19) {
                attr.item = 5;
            }

            // Don't let puffer have boxing gloves
            if (attr.item == 1 && attr.body == 16) {
                attr.item = 11;
            }
        }

        (bool isValid, string memory reason) = isValidMint(attr);
        require(isValid, reason);

        _mint(msg.sender, totalSupply);

        tokenIdToAttributes[totalSupply] = attr;
        isHashAttributesUsed[hashAttributes(attr)] = true;

        emit Mint(totalSupply);
    }

    function isValidMint(Attributes memory attr)
        public
        view
        returns (bool, string memory)
    {
        // less than max supply
        if (totalSupply > 9_999) {
            return (false, "Over max supply");
        }

        // Hash hasn't been used before
        if (isHashAttributesUsed[hashAttributes(attr)]) {
            return (false, "Attributes already used");
        }

        // Check all attributes are within range
        if (
            attr.background >= BACKGROUND_COUNT ||
            attr.head >= HEAD_COUNT ||
            attr.eyes >= EYES_COUNT ||
            attr.mouth >= MOUTH_COUNT ||
            attr.body >= BODIES_COUNT ||
            attr.legs >= LEGS_COUNT ||
            attr.feet >= FEET_COUNT ||
            attr.item >= ITEM_COUNT
        ) {
            return (false, "Invalid attributes");
        }

        // correct combination of attributes
        if (attr.head == 28) {
            if (attr.eyes == 15 || attr.eyes == 7 || attr.eyes == 20) {
                return (
                    false,
                    "Can't have warpaint and sunglasses/glasses/worried eyes"
                );
            }
        }

        return (true, "");
    }

    function setTokenUriContract(TokenUri tokenUriContract_)
        external
        onlyOwner
    {
        tokenUriContract = tokenUriContract_;
    }
}
