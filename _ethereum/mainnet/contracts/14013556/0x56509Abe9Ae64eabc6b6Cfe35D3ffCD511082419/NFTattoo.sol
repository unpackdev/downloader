// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract nftattoo is ERC721, Ownable {
    bool public isActive = true;
    uint16 private totalSupply_ = 0;
    uint16 private nbFreeMint = 0;
    address payable public immutable shareholderAddress;
    uint16[] private forbiddenPixels;

    mapping(uint16 => uint16) idToPixel;
    mapping(address => uint16[]) ownerToPixel;
    uint16[] lstSold;

    constructor(address payable shareholderAddress_)
        ERC721("nftattoo", "PIXEL")
    {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;

        totalSupply_ = 1;
        _safeMint(shareholderAddress_, 0);

        forbiddenPixels.push(271);
        forbiddenPixels.push(272);
        forbiddenPixels.push(273);
        forbiddenPixels.push(331);
        forbiddenPixels.push(332);
        forbiddenPixels.push(333);
        forbiddenPixels.push(391);
        forbiddenPixels.push(392);
        forbiddenPixels.push(393);
        forbiddenPixels.push(106);
        forbiddenPixels.push(107);
        forbiddenPixels.push(740);
        forbiddenPixels.push(741);
        forbiddenPixels.push(800);
        forbiddenPixels.push(801);
        forbiddenPixels.push(1542);
        forbiddenPixels.push(1602);
        forbiddenPixels.push(1945);
        forbiddenPixels.push(1946);
        forbiddenPixels.push(1947);
        forbiddenPixels.push(2005);
        forbiddenPixels.push(2006);
        forbiddenPixels.push(2007);
        forbiddenPixels.push(2881);
        forbiddenPixels.push(2882);
        forbiddenPixels.push(2941);
        forbiddenPixels.push(2942);
    }

    function totalSupply() public view returns (uint16) {
        return totalSupply_;
    }

    function setNbFree(uint16 nbFree) external onlyOwner {
        nbFreeMint = nbFree;
    }

    function setSaleState(bool newState) public onlyOwner {
        isActive = newState;
    }

    function mint(uint16[] memory pixels) public payable {
        require(isActive, "Sale must be active to mint pixels");
        require(
            totalSupply_ + pixels.length <= 4774,
            "Purchase would exceed max supply of tokens"
        );
        require(
            0.069 ether * pixels.length <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint16 i = 0; i < pixels.length; i++) {
            for (uint8 j = 0; j < forbiddenPixels.length; j++) {
                require(pixels[i] != forbiddenPixels[j], "This pixel is not for sale!");
            }
            uint16 mintIndex = totalSupply_ + 1;
            if (totalSupply_ < 4774) {
                idToPixel[mintIndex] = pixels[i];
                ownerToPixel[msg.sender].push(pixels[i]);
                lstSold.push(pixels[i]);
                totalSupply_ = totalSupply_ + 1;
                _safeMint(msg.sender, pixels[i]);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }

    function soldPixels() public view returns (uint16[] memory) {
        return lstSold;
    }

    function owned(address ownerAddress) public view returns (uint16[] memory) {
        return ownerToPixel[ownerAddress];
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (tokenId > 0) {
            uint16 coord = idToPixel[uint16(tokenId)];
            uint16 coordY = uint16((coord - 1) / 60) + 1;
            uint16 coordX = coord - ((coordY - 1) * 60);
            // const y = Math.floor((pixel-1) / 60) + 1
            // const x = pixel - ((y - 1) * 60)
            string memory metadata = string(
                abi.encodePacked(
                    '{"name": "Pixel (',
                    Strings.toString(coordX),
                    ", ",
                    Strings.toString(coordY),
                    ')", "description": "Your Pixel of History", "image": "ipfs://QmUkCyTiN4pVwJuMMtEdLkH3SKuNcnQfbu7HFq86sesFjV", "attributes": []}'
                )
            );
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        base64(bytes(metadata))
                    )
                );
        } else {
            string memory metadata = string(
                abi.encodePacked(
                    '{"name": "Pixel 0 - The invisible one", "description": "Your Pixel of History", "image": "ipfs://QmUkCyTiN4pVwJuMMtEdLkH3SKuNcnQfbu7HFq86sesFjV", "attributes": []}'
                )
            );
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        base64(bytes(metadata))
                    )
                );
        }
    }

    /* BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
