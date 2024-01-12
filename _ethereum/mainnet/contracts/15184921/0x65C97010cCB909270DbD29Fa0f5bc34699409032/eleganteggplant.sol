// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./PullPayment.sol";
import "./Strings.sol";

contract ElegantEggplant is Ownable, ERC721URIStorage, PullPayment {
    using Counters for Counters.Counter;

    uint256 public maxSupply = 6969;
    uint256 private _maxLegendary = 21;
    uint256 private _maxEpic = 20;
    uint256 private _maxRare = 40;
    uint256 private _bodyLength = 8;
    uint256 private _rareLength = 18;
    uint256 private _headLength = 12;
    uint256 private _clotheLength = 8;
    uint256 private _eyeLength = 12;
    uint256 private _mouthLength = 12;

    mapping(uint256 => uint256) public tokenIds;
    mapping(uint256 => uint256) private _amountEpicMinted;
    mapping(uint256 => uint256) private _amountRareMinted;

    Counters.Counter public tokenRank;

    constructor() ERC721("ElegantEggplant", "EGGPLANT") {}

    function _getTokenIdFromAttributes(
        uint256 legendaryIndex,
        uint256 bodyIndex,
        uint256 rareIndex,
        uint256 headIndex,
        uint256 clotheIndex,
        uint256 eyeIndex,
        uint256 mouthIndex
    ) private pure returns (uint256) {
        uint256 tokenId = legendaryIndex *
            1_00_00_00_00_00_00 +
            bodyIndex *
            1_00_00_00_00_00 +
            rareIndex *
            1_00_00_00_00 +
            headIndex *
            1_00_00_00 +
            clotheIndex *
            1_00_00 +
            eyeIndex *
            1_00 +
            mouthIndex;

        return tokenId;
    }

    function getTokenValidation(
        uint256 legendaryIndex,
        uint256 bodyIndex,
        uint256 rareIndex,
        uint256 headIndex,
        uint256 clotheIndex,
        uint256 eyeIndex,
        uint256 mouthIndex
    ) public view returns (bool) {
        require(tokenRank.current() < maxSupply, "Max token minted reached.");

        require(!_exists(_getTokenIdFromAttributes(
            legendaryIndex,
            bodyIndex,
            rareIndex,
            headIndex,
            clotheIndex,
            eyeIndex,
            mouthIndex
        )), "This token already exists.");

        if (legendaryIndex > 0) {
            require(
                legendaryIndex <= _maxLegendary,
                "Incorrect 'legendary' token index exceed max index."
            );
            require(
                bodyIndex == 0 &&
                    rareIndex == 0 &&
                    headIndex == 0 &&
                    clotheIndex == 0 &&
                    eyeIndex == 0 &&
                    mouthIndex == 0,
                "A 'legendary' token must have all attributes index (except 'legendary') to null (0)."
            );
        } else {
            require(
                bodyIndex >= 1,
                "Any type of token except 'legendary', must have a not null (> 0) 'body' attribute index."
            );
            require(
                rareIndex <= _rareLength,
                "Incorrect 'rare' attribute index exceed max index."
            );
            require(
                headIndex <= _headLength,
                "Incorrect 'head' attribute index exceed max index."
            );
            require(
                clotheIndex <= _clotheLength,
                "Incorrect 'clothe' attribute index exceed max index."
            );
            require(
                eyeIndex <= _eyeLength,
                "Incorrect 'eye' attribute index exceed max index."
            );
            require(
                mouthIndex <= _mouthLength,
                "Incorrect 'mouth' attribute index exceed max index."
            );

            if (rareIndex == 0) {
                require(
                    eyeIndex >= 1,
                    "An 'eye' attribute index can be null (0) only if the token has a 'legendary' or 'rare - eye' attribute."
                );
                require(
                    mouthIndex >= 1,
                    "A 'mouth' attribute index can be null (0) only if the token has a 'legendary' or 'rare - mouth' attribute."
                );
            }

            if (bodyIndex > 1) {
                require(
                    bodyIndex <= _bodyLength,
                    "A 'body - epic' attribute index must be between 2 and 8 inclusive."
                );

                require(
                    rareIndex == 0 && headIndex == 0 && clotheIndex == 0,
                    "A token with an 'epic' attribute must have null (0) attribute index for this attributes: 'legendary', 'rare', 'head' and 'clothe'."
                );

                require(
                    _amountEpicMinted[bodyIndex] <= _maxEpic,
                    "Max token minted reached for this 'body - epic' attribute index."
                );
            } else if (rareIndex > 0) {
                require(
                    bodyIndex == 1,
                    "A token with a 'rare' attribute must have 1 for 'body' attribute index."
                );

                if (rareIndex <= 6) {
                    require(
                        headIndex == 0,
                        "A token with a 'rare - head' attribute ([1, 6]) must have a null (0) 'head' attribute index."
                    );
                } else if (rareIndex >= 7 && rareIndex <= 12) {
                    require(
                        clotheIndex == 0,
                        "A token with a 'rare - clothe' attribute ([7, 12]) must have a null (0) 'clothe' attribute index."
                    );
                } else if (rareIndex >= 13 && rareIndex <= 15) {
                    require(
                        eyeIndex == 0,
                        "A token with a 'rare - eye' attribute ([13, 15]) must have a null (0) 'eye' attribute index."
                    );
                } else if (rareIndex >= 16) {
                    require(
                        mouthIndex == 0,
                        "A token with a 'rare - mouth' attribute ([16, 18]) must have a null (0) 'mouth' attribute index."
                    );
                }

                require(
                    _amountRareMinted[rareIndex] <= _maxRare,
                    "Max token minted reached for this 'rare' attribute index."
                );
            }
        }

        return true;
    }

    function _getTokenPrice(
        uint256 legendaryIndex,
        uint256 bodyIndex,
        uint256 rareIndex,
        uint256 rank
    ) private pure returns (uint256 price) {
        if (legendaryIndex > 0) return 4 ether;
        else if (bodyIndex > 1) return 1.5 ether;
        else if (rareIndex > 0) return 0.2 ether;
        else if (rank < 50) return 0.001 ether;
        else if (rank < 150) return 0.002 ether;
        else if (rank < 300) return 0.003 ether;
        else return 0.05 ether;
    }

    function _getTokenCID(uint256 tokenId) private pure returns (string memory) {
        if (tokenId <= 10004050812)
            return "bafybeidg2ugmhtttntcj3khqiro5upbmhztksilt3s4c4r7tprhmsgmq4q";
        else if (tokenId >= 10004050901 && tokenId <= 10009020412)
            return "bafybeigz3fzmztrhznhti2qp5u6yyobmznykhkozeglkheym7h2l4f365q";
        else if (tokenId >= 10009020501 && tokenId <= 10100071212)
            return "bafybeig4rijihdwez5ukb6dev5rfoz3ev262vz4wvx7jyhjix3xjlcyr5q";
        else if (tokenId >= 10100080101 && tokenId <= 10600040812)
            return "bafybeifa3bcbaixljbrzg4zj4ju2kaspluwftdnoyy3fp2fwhtbjws42oq";
        else if (tokenId >= 10600040901 && tokenId <= 10911000412)
            return "bafybeidz7mpqzlw3dceidduycazmddoonhh4x7wpovamyaxq33jfaxzpyy";
        else if (tokenId >= 10911000501 && tokenId <= 11301020012)
            return "bafybeia7js5q4pyumwje652456cnzi7x6xfyj7mili5o7dmajy2kzm2l3i";
        else if (tokenId >= 11301030001 && tokenId <= 11704071200)
            return "bafybeic4nqup32ojomwmcyicawuvzalukswsadsqs7w5w42vfjsmnpepga";
        else
            return "bafybeifoyywgquwhrxvqioesnndmwuip3ljncokyikwvrn7peon4qpqzsu";

    }

    function _getTokenURI(string memory tokenCID, string memory tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked("https://", tokenCID, ".ipfs.nftstorage.link/metadata/", tokenId, ".json"));
    }

    function mint(
        address recipient,
        uint256 legendaryIndex,
        uint256 bodyIndex,
        uint256 rareIndex,
        uint256 headIndex,
        uint256 clotheIndex,
        uint256 eyeIndex,
        uint256 mouthIndex
    ) public payable {
        getTokenValidation(
            legendaryIndex,
            bodyIndex,
            rareIndex,
            headIndex,
            clotheIndex,
            eyeIndex,
            mouthIndex
        );

        uint256 price = _getTokenPrice(legendaryIndex, bodyIndex, rareIndex, tokenRank.current());

        uint256 tokenId = _getTokenIdFromAttributes(
            legendaryIndex,
            bodyIndex,
            rareIndex,
            headIndex,
            clotheIndex,
            eyeIndex,
            mouthIndex
        );

        require(
            msg.value == price,
            "Transaction amount value is different to the mint price."
        );

        tokenRank.increment();

        if (bodyIndex > 1) _amountEpicMinted[bodyIndex] += 1;
        if (rareIndex > 0) _amountRareMinted[rareIndex] += 1;

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, _getTokenURI(_getTokenCID(tokenId), Strings.toString(tokenId)));

        tokenIds[tokenRank.current()] = tokenId;
    }

    function withdrawPayments(address payable payee) public override onlyOwner virtual {
      super.withdrawPayments(payee);
    }
}
