// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract Bubble is Ownable, ERC721A, ReentrancyGuard {
    constructor(
        //PROD 5
    ) ERC721A("The Bubbles", "BUBBLE", 5, 10000) {}

    //public sale
    bool public publicSaleStatus = true;
    uint256 public publicPrice = 0.0000 ether;
    uint256 public amountForPublicSale = 10000;
    //PROD 5
    uint256 public immutable publicSalePerMint = 5;
    //PROD 5
    uint256 public immutable publicSaleWalletLimit = 5;

    function publicSaleMint(uint256 quantity) external payable {
        require(
        publicSaleStatus,
        "public sale has not started yet"
        );
        require(
        totalSupply() + quantity <= collectionSize,
        "SOLD OUT"
        );
        require(
        amountForPublicSale >= quantity,
        "SOLD OUT"
        );

        require(
        quantity <= publicSalePerMint,
        "reached batch limit"
        );

        require(
        quantity + balanceOf(msg.sender) <= publicSaleWalletLimit,
        "reached wallet limit"
        );

        _safeMint(msg.sender, quantity);

        amountForPublicSale -= quantity;
        refundIfOver(uint256(publicPrice) * quantity);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }

    function getPublicSaleStatus() external view returns(bool) {
        return publicSaleStatus;
    }

    function reserveMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= collectionSize,
            "reached limit"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        if (quantity % maxBatchSize != 0){
            _safeMint(msg.sender, quantity % maxBatchSize);
        }
    }

    // metadata URI
    string private _baseTokenURI;

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
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string[7] memory parts;
        parts[0] = _baseTokenURI;
        parts[1] = '?';
        parts[2] = Strings.toString(sizeOf(tokenId));
        parts[3] = '_';
        parts[4] = Strings.toString(colorOf(tokenId));
        parts[5] = "bubble-asset/bubble";
        parts[6] = ".svg";

        string memory animUrl = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
        string memory imgUrl = string(abi.encodePacked(parts[0], parts[5], parts[2], parts[3], parts[4], parts[6]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Bubble #',
            Strings.toString(tokenId),
            '","description": "The bubble shrinks over time. Each transfer will make it bigger.","image":"',
            imgUrl,
            '","animation_url":"',
            animUrl,
            '"}'
            ))));
        
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}