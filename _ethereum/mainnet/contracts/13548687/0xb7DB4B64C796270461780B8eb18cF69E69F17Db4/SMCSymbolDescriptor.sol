// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./Address.sol";
import "./Strings.sol";
import "./base64.sol";
import "./ISMCSymbol.sol";

contract SMCSymbolDescriptor is ISMCSymbolDescriptor {
    using Address for address;
    using Strings for uint256;

    string public imageURIPrefix = "";

    constructor(string memory uri) {
        imageURIPrefix = uri;
    }

    function toPaddedString(uint256 n) private pure returns (string memory) {
        if (n >= 10) {
            return n.toString();
        }
        return string(abi.encodePacked("0", n.toString()));
    }

    function imagePath(ISMCManager manager, uint256 tokenId)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    manager.getRespectColorCode().toString(),
                    manager.getRarityDigit(tokenId).toString(),
                    manager.getColorLCode(tokenId).toString(),
                    toPaddedString(manager.getPatternLCode(tokenId)),
                    manager.getColorRCode(tokenId).toString(),
                    toPaddedString(manager.getPatternRCode(tokenId)),
                    manager.getActivatedKatana(tokenId)
                )
            );
    }

    function quotePair(string memory k, string memory v)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', k, '":', '"', v, '"'));
    }

    function quotePairNum(string memory k, uint256 v)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', k, '":', v.toString()));
    }

    function tokenURI(ISMCManager manager, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory name = string(
            abi.encodePacked(
                "SAMURAI cryptos SymbolNFT - ",
                manager.getRarity(tokenId),
                " #",
                tokenId.toString()
            )
        );

        string memory descriptionEn = string(
            abi.encodePacked(
                "[item]\\n\\n",
                name,
                "\\n\\n",
                "[NFT Terms]\\n\\n",
                "- The NFT is for image data only.\\n\\n",
                "- The purchaser of the NFT is granted rights to exploit and/or dispose the NFT that contains information of the image data, including, but not limited to, the URL, provided, however that the purchaser is not granted any intellectual property rights, including copyright, trademarks, or the like, in and to the image data.\\n\\n",
                "- The NFT is for private use only. It shall not be offered to any third person beyond the scope of the private use or exploited for commercial purposes.\\n\\n",
                "- The author of the image data is not liable for any damage or loss the purchaser, the transferee or any other third person or party suffer in connection with the purchase or the sale of the NFT, regardless of reasons."
            )
        );

        string memory image = string(
            abi.encodePacked(imageURIPrefix, imagePath(manager, tokenId))
        );

        string memory p1 = string(
            abi.encodePacked(
                quotePair("respect", manager.getRespect()),
                ",",
                quotePair("codes of arts", manager.getCodesOfArt(tokenId)),
                ",",
                quotePair("rarity", manager.getRarity(tokenId)),
                ",",
                quotePairNum("samu-rights", manager.getSamurights(tokenId)),
                ",",
                quotePair("name", manager.getName(tokenId)),
                ",",
                quotePair("native place", manager.getNativePlace(tokenId)),
                ",",
                quotePair(
                    "japanese zodiac",
                    manager.getJapaneseZodiac(tokenId)
                ),
                ","
            )
        );

        string memory attributes = string(
            abi.encodePacked(
                p1,
                quotePair("color left", manager.getColorL(tokenId)),
                ",",
                quotePair("color right", manager.getColorR(tokenId)),
                ",",
                quotePair("pattern left", manager.getPatternL(tokenId)),
                ",",
                quotePair("pattern right", manager.getPatternR(tokenId)),
                ",",
                quotePair("katana pattern", manager.getActivatedKatana(tokenId))
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                quotePair("name", name),
                                ",",
                                quotePair("description", descriptionEn),
                                ",",
                                quotePair("image", image),
                                ",",
                                '"attributes":{',
                                attributes,
                                "}",
                                "}"
                            )
                        )
                    )
                )
            );
    }
}
