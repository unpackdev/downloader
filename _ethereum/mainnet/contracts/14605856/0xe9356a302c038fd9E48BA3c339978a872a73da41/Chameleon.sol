//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./IChameleon.sol";
import "./ISvgGenerator.sol";

contract Chameleon is IChameleon, ERC721A, Ownable {
    using Strings for uint256;

    ISvgGenerator public immutable svgGenerator;

    // Mapping from token ID to it's colors
    mapping(uint256 => Chameleon) private _chameleons;

    constructor(
        string memory name_,
        string memory symbol_,
        ISvgGenerator svgGenerator_
    ) ERC721A(name_, symbol_) {
        svgGenerator = svgGenerator_;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _beforeTransfer(id);
        super.transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _beforeTransfer(id);
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual override {
        _beforeTransfer(id);
        super.safeTransferFrom(from, to, id, data);
    }

    function _beforeTransfer(
        uint256 tokenId
    ) private {
        if (_chameleons[tokenId].bodyType == 1) {
            _chameleons[tokenId].body = uint16(_randomishForAttribute(tokenId, "body"));
        }
        if (_chameleons[tokenId].backgroundType == 1) {
            _chameleons[tokenId].background = uint16(
                _randomishForAttribute(tokenId, "background")
            );
        }
    }

    function _randomishForAttribute(uint256 tokenId, bytes32 salt)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(salt, generateSeed(tokenId))
                )
            ) % 360;
    }

    // Mint logic and settings
    modifier validMintCount(uint8 quantity) {
        require(_currentIndex + quantity <= 100, 'Chameleon: public mint max exceeded');
        _;
    }

    function collectFees() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }(new bytes(0));
        require(success, "Chameleon: ether transfer failed");
    }

    function generateSeed(uint256 tokenId) internal view returns (uint256) {
        return  uint256(keccak256(abi.encodePacked(tokenId, block.timestamp)));
    }

    function mint(address recipient, uint8 quantity)
        public
        payable
        validMintCount(quantity)
        returns (uint256)
    {
        uint256 startTokenId = _currentIndex;
        _safeMint(recipient, quantity);

        // Set the colors
        for (uint8 i = 0; i < quantity; i++) {
            uint tokenId = startTokenId + i;
            uint8 bodyType;
            uint8 backgroundType;
            uint16 eyeColor;
            uint16 body = uint16(_randomishForAttribute(tokenId, "body"));
            uint16 background = uint16(_randomishForAttribute(tokenId, "background"));
            uint256 seed = generateSeed(tokenId);
            if (seed % 3 == 0) {
                bodyType = 1;
                backgroundType = 0;
            } else if (seed % 3 == 1) {
                bodyType = 0;
                backgroundType = 1;
            } else if (seed % 3 == 2) {
                bodyType = 1;
                backgroundType = 1;
            }

            // 1/6 of the chameleons with dynamic color antimate to transparent
            if (bodyType == 1 && seed % 6 == 0) {
                bodyType = 2;
            }

            // 1/25 get non-black eyecolor
            if (seed % 25 == 0) {
                eyeColor = uint16(_randomishForAttribute(tokenId, "eyes"));
            }

            Chameleon memory chameleon = Chameleon({
                body: body,
                eyes: eyeColor,
                background: background,
                bodyType: bodyType,
                backgroundType: backgroundType
            });
            _chameleons[tokenId] = chameleon;
        }

        return quantity;
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

        // Fetch chameleon tags
        Chameleon memory chameleon = _chameleons[tokenId];
        return svgGenerator.generateTokenUri(tokenId, chameleon);
    }
}
