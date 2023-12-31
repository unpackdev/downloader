// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./console.sol";

import "./OwnerTwoStep.sol";
import "./IDittoPool.sol";

import "./MetadataInfo.sol";
import "./Base64.sol";
import "./Utf8.sol";
import "./IMetadataGenerator.sol";
import "./Strings.sol";
import "./IERC20Metadata.sol";
import {IERC721Metadata} from
    "../../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./MetadataGeneratorError.sol";

/**
 * @title MetadataGenerator
 * @notice Provides the function for generating an SVG associated with an liquidity position NFT of a Ditto protocol.
 * @dev Address supplied as a parameter to the constructor of the liquidity position NFT contract.
 */
contract MetadataGenerator is OwnerTwoStep, IMetadataGenerator {
    ///@notice Longest character length for an NFT/ERC20 symbol.
    uint256 private constant MAX_SYMBOL_LENGTH = 8;
    uint256 private constant MAX_TEXT_LENGTH = 16;
    uint256 private constant BOOLEAN_LENGTH = 2;

    ///@notice Base64 encoded SVG element to be used as the profile image for the NFT collection.
    string public _assetProfile;

    ///@notice Array containing base64 encoded SVG elements to be selected at (pseudo)random for each NFT.
    ///@notice These assets represent "nighttime" scenes.
    string[] public _assetVariant00;

    ///@notice Alternative coloring schema for an NFT's base64 encoded animated compoents.
    ///@notice These assets represent "daytime" scenes.
    string[] public _assetVariant01;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************
    event MetadataGeneratorAdminSetAsset(bool colorvariant);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************
    error MetadataGeneratorTokenDecimalsTooLarge(uint8 decimals);
    error MetadataGeneratorTokenSymbolInvalidUtf8(string symbolToken);
    error MetadataGeneratorNftSymbolInvalidUtf8(string symbolNft);
    error MetadataGeneratorBondingCurveInvalidUtf8(string bondingCurve);
    error MetadataGeneratorPoolFeeGreaterThan100Percent(uint256 poolFee);

    /**
     * @notice Initializes the contract by setting an owner for adding/removing assets and the description for the NFT collection.
     */
    constructor(string memory assetProfile_) {
        _assetProfile = assetProfile_;
    }

    // ***************************************************************
    // * =============== ADMINISTRATIVE FUNCTIONS ================== *
    // ***************************************************************

    /**
     * @notice Assigns the base64 encoded SVG animation elements by variant ("daytime"/"nighttime").
     * @dev Only the owner can call this function.
     * @param asset A baset64 encoded SVG animation element
     * @param colorVariant Allocate to array associagted with "daytime" or "nighttime" assets
     */
    function setAsset(string calldata asset, bool colorVariant) external onlyOwner {
        _setAsset(asset, colorVariant);
    }

    function setAssetBulk00(string[] calldata asset) external onlyOwner {
        uint256 count = asset.length;
        for (uint256 i = 0; i < count;) {
            _setAsset(asset[i], false);
            unchecked {
                ++i;
            }
        }
    }

    function setAssetBulk01(string[] calldata asset) external onlyOwner {
        uint256 count = asset.length;
        for (uint256 i = 0; i < count;) {
            _setAsset(asset[i], true);
            unchecked {
                ++i;
            }
        }
    }

    function _setAsset(string calldata asset, bool colorVariant) private {
        if (colorVariant) {
            _assetVariant01.push(asset);
        } else {
            _assetVariant00.push(asset);
        }

        emit MetadataGeneratorAdminSetAsset(colorVariant);
    }

    // ***************************************************************
    // * ======= EXTERNALLY CALLABLE READ-ONLY VIEW FUNCTIONS ====== *
    // ***************************************************************

    /**
     * @notice Returns the baset64 encoded SVG animation element for a given index.
     * @param index A counter less than the length of _assetVariant00 or _assetVariant01
     * @param colorVariant Select value from array associagted with "daytime" or "nighttime" assets
     * @return asset Baset64 encoded SVG animation element
     */
    function getAsset(uint256 index, bool colorVariant) external view returns (string memory asset) {
        if (colorVariant) {
            asset = _assetVariant01[index];
        } else {
            asset = _assetVariant00[index];
        }
    }

    ///@inheritdoc IMetadataGenerator
    function payloadContractUri() external view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"Ditto V1 LP Positions",'
                            '"description":"A next-gen NFT AMM & liquidity protocol optimized for DeFi. Effortlessly swap between NFTs and ERC-20 tokens.",'
                            '"image": "',
                            "data:image/svg+xml;base64,",
                            _assetProfile,
                            '",' '"external_link": "https://dittohq.xyz/",' '"seller_fee_basis_points": 0,'
                            '"fee_recipient": "0x0000000000000000000000000000000000000000"}'
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice Generates a string containing the metadata for a given fee.
     * @param fee The raw fee value
     */
    function _generateFeeString(uint256 fee) public pure returns (string memory feeString_) {
        uint256 left = fee / (1e16);
        uint256 right = fee % (1e16);
        string memory value;
        if (right == 0 && left == 0) {
            return "Fee: 0%";
        }
        if (right == 0) {
            value = "0";
        } else {
            value = _removeTrailingZeros(_truncateString(Strings.toString(right), 6, false));
        }
        if (left == 0) {
            return string(abi.encodePacked(abi.encodePacked("Fee: ", _formatNumberSmall(fee, MAX_TEXT_LENGTH), "%")));
        }
        feeString_ = string(abi.encodePacked("Fee: ", Strings.toString(left), ".", value, "%"));
    }

    ///@inheritdoc IMetadataGenerator
    function payloadTokenUri(uint256 tokenId, IDittoPool pool, uint256 countToken, uint256 countNFT)
        external
        view
        override
        returns (string memory)
    {
        // make all external calls for data to show in the SVG payload
        ExternalCallData memory eData = _makeExternalCalls(pool);

        // make any checks necessary for the data to be valid
        _validateExternalData(eData);

        // process the data for display
        eData.bondingCurve = _svgCharacterEscape(_truncateString(eData.bondingCurve, MAX_TEXT_LENGTH, false));
        string memory tokenCountString =
            _svgCharacterEscape(_generateTokenCountString(countToken, eData.decimals, eData.symbolToken));
        string memory feeString = _generateFeeString(eData.poolFee);

        MetadataInfo memory info = MetadataInfo(
            eData.bondingCurve,
            address(pool),
            eData.addressAdmin,
            tokenCountString,
            feeString,
            countNFT,
            eData.symbolNft,
            eData.addressNft,
            tokenId
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            string(abi.encodePacked("Ditto V1 LP Position #", Strings.toString(tokenId))),
                            '", "description":"',
                            MetadataGeneratorError.DESCRIPTION,
                            '", "image": "',
                            "data:image/svg+xml;base64,",
                            Base64.encode(bytes(_generateImage(info))),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    // ***************************************************************
    // * ============= PRIVATE HELPER FUNCTIONS =================== *
    // ***************************************************************

    /**
     * @notice makes all the necessary external calls to contracts we do not control
     * in order to show the SVG. Also returns it in a struct to avoid stack too deep
     */
    function _makeExternalCalls(IDittoPool pool) internal view returns (ExternalCallData memory data) {
        IERC20Metadata token = IERC20Metadata(pool.token());
        data = ExternalCallData({
            addressAdmin: pool.owner(),
            addressNft: address(pool.nft()),
            decimals: uint256(token.decimals()),
            poolFee: pool.fee(),
            bondingCurve: pool.bondingCurve(),
            symbolToken: token.symbol(),
            symbolNft: IERC721Metadata(address(pool.nft())).symbol()
        });
    }

    /**
     * @notice escapes SVG necessary characters in a string
     * @param raw the raw string to escape
     * @return processed the string with characters replaced with their HTML escape codes
     */
    function _svgCharacterEscape(string memory raw) public pure returns (string memory processed) {
        // there's probably a CPU + gas efficient way to process the string in-place O(n),
        // rather than processing the whole string twice 2*O(n), but this is mentally easier
        // and since the MetadataGenerator is only called for tokenURI calls (which occur in CALL not TXs)
        // gas cost doesn't actually matter.
        bytes memory rawBytes = bytes(raw);
        uint256 length = rawBytes.length;
        uint256 addedEscapeLength = 0;
        uint256 i;
        for (i = 0; i < length; i++) {
            (bool needsEscape, string memory escapeString) = _escapeCharacterCode(rawBytes[i]);
            if (needsEscape) {
                addedEscapeLength += bytes(escapeString).length - 1;
            }
        }
        bytes memory processedBytes = new bytes(length + addedEscapeLength);
        uint256 j = 0;
        for (i = 0; i < length; i++) {
            (bool needsEscape, string memory escapeString) = _escapeCharacterCode(rawBytes[i]);
            if (needsEscape) {
                for (uint256 k = 0; k < bytes(escapeString).length; k++) {
                    processedBytes[j] = bytes(escapeString)[k];
                    j++;
                }
            } else {
                processedBytes[j] = rawBytes[i];
                j++;
            }
        }
        return string(processedBytes);
    }

    /**
     * @notice escape characters in SVG that need to be HTML escaped
     * & becomes &amp;
     * ' becomes &apos;
     * " becomes &quot;
     * < becomes &lt;
     * > becomes &gt;
     * @param charCode the character code to escape
     * @return needsEscape whether the character needs to be escaped
     * @return escapeString the string to replace the character with
     */
    function _escapeCharacterCode(bytes1 charCode)
        private
        pure
        returns (bool needsEscape, string memory escapeString)
    {
        if (charCode == 0x26) {
            return (true, "&amp;");
        } else if (charCode == 0x27) {
            return (true, "&apos;");
        } else if (charCode == 0x22) {
            return (true, "&quot;");
        } else if (charCode == 0x3C) {
            return (true, "&lt;");
        } else if (charCode == 0x3E) {
            return (true, "&gt;");
        } else {
            return (false, "");
        }
    }

    /**
     * @notice performs validation operations of external data to make sure that it is
     * viewable in SVG form.
     */
    function _validateExternalData(ExternalCallData memory data) internal pure {
        if (data.decimals > 77) {
            revert MetadataGeneratorTokenDecimalsTooLarge(uint8(data.decimals));
        }
        if (!Utf8.isValid(data.symbolToken)) {
            revert MetadataGeneratorTokenSymbolInvalidUtf8(data.symbolToken);
        }
        if (!Utf8.isValid(data.symbolNft)) {
            revert MetadataGeneratorNftSymbolInvalidUtf8(data.symbolNft);
        }
        if (!Utf8.isValid(data.bondingCurve)) {
            revert MetadataGeneratorBondingCurveInvalidUtf8(data.bondingCurve);
        }
        if (data.poolFee > 1e18) {
            revert MetadataGeneratorPoolFeeGreaterThan100Percent(data.poolFee);
        }
    }

    /**
     * @notice Removes trailing zeros from a string.
     */
    function _removeTrailingZeros(string memory value) public pure returns (string memory) {
        uint256 length = bytes(value).length;

        while (length > 0 && bytes(value)[length - 1] == bytes("0")[0]) {
            length--;
        }

        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length;) {
            result[i] = bytes(value)[i];
            unchecked {
                ++i;
            }
        }

        return string(result);
    }

    /**
     * @notice Generates the SVG image string
     * @param info aggregate struct of input parameters for svg creation
     * @return svg completed Baset64 encoded SVG animation element
     */
    function _generateImage(MetadataInfo memory info) private view returns (string memory svg) {
        bool colorVariant =
            _getPseudoRandomNumber(BOOLEAN_LENGTH, info.tokenId, info.addressPool, info.addressNft, 0) == 0;
        console.log("generateImage colorVariant: %s", colorVariant);
        svg = string(
            abi.encodePacked(
                _getComponent00(colorVariant, info.addressPool),
                _getComponent01(info.addressAdmin, info.curve),
                _getComponent02(info, colorVariant)
            )
        );
    }

    /**
     * @notice Truncate NFT/ERC20 symbols that are too long.
     * @param symbolRaw The raw symbol to be truncated
     * @param maxSymbolLength The maximum length of the symbol
     * @return symbolFormatted The truncated symbol
     */
    function _truncateString(string memory symbolRaw, uint256 maxSymbolLength, bool text)
        public
        pure
        returns (string memory symbolFormatted)
    {
        if (bytes(symbolRaw).length > maxSymbolLength) {
            bytes memory strBytes = bytes(symbolRaw);
            bytes memory result = new bytes(maxSymbolLength);
            for (uint256 i = 0; i < maxSymbolLength;) {
                result[i] = strBytes[i];
                unchecked {
                    ++i;
                }
            }
            if (text) {
                return string(abi.encodePacked(result, "."));
            }
            symbolFormatted = string(result);
        } else {
            symbolFormatted = symbolRaw;
        }
    }

    /**
     * @notice Prevent value from exceeding a maximum value, for display purposes.
     * @param number The value to be capped, e.g. 1,100
     * @return formatted The formatted value, e.g. 1.1k
     */
    function _formatNumberLarge(uint256 number) public pure returns (string memory formatted) {
        uint256 zero = 0;
        uint256 oneK = 1000;
        uint256 oneM = 1_000_000;
        if (number < oneK) {
            return Strings.toString(number);
        }
        if (number < oneM) {
            uint256 thousands = number / oneK;
            uint256 hundreds = number % oneK / 100;
            if (hundreds > zero) {
                return string(abi.encodePacked(Strings.toString(thousands), ".", Strings.toString(hundreds), "k"));
            } else {
                return string(abi.encodePacked(Strings.toString(thousands), "k"));
            }
        }
        if (number < 1_000_000_000) {
            uint256 millions = number / oneM;
            uint256 thousands = number % oneM / 100_000;
            if (thousands == zero) {
                return string(abi.encodePacked(Strings.toString(millions), "M"));
            } else {
                return string(abi.encodePacked(Strings.toString(millions), ".", Strings.toString(thousands), "M"));
            }
        }
        return "1B+";
    }

    function _formatNumberSmall(uint256 countToken, uint256 decimals) public pure returns (string memory) {
        // Get the fractional part of the Ether value as an integer with two decimal places
        uint256 fractional = countToken * 1000 / (10 ** decimals);

        // Check if the tenths place is non-zero
        bool hasNonZeroTenths = (fractional / 100) % 10 != 0;
        if (hasNonZeroTenths) {
            return string(abi.encodePacked("0.", Strings.toString((fractional / 100) % 10)));
        }

        // Check if the hundredths place is non-zero
        bool hasNonZeroHundredths = (fractional / 10) % 10 != 0;
        if (hasNonZeroHundredths) {
            return string(abi.encodePacked("0.0", Strings.toString((fractional / 10) % 10)));
        }

        // Check if the thousandths place is non-zero
        bool hasNonZeroThousandths = fractional % 10 != 0;
        if (hasNonZeroThousandths) {
            return string(abi.encodePacked("0.00", Strings.toString(fractional % 10)));
        }

        return "&lt;0.001";
    }

    /**
     * @notice Perform common address encoding operation.
     * @param addressRaw The address to be encoded.
     * @return addressString The encoded address.
     */
    function _formatAddressAsString(address addressRaw) private pure returns (string memory addressString) {
        addressString = Strings.toHexString(uint256(uint160(addressRaw)), 20);
    }

    /**
     * @notice Generates the first of three components of the SVG for a given NFT.
     * @param colorVariant which variant of the SVG to use
     * @param addressPool Address of the DittoPool associated with the liquidity position NFT.
     * @return svg00 For use in assignment of SVG animation elements.\
     */
    function _getComponent00(bool colorVariant, address addressPool) private view returns (string memory svg00) {
        string memory colorBackground;
        string memory colorAccent;
        // daytime is 1, nighttime is 0
        if (colorVariant) {
            // daytime
            colorBackground = "#00A0FF";
            colorAccent = "#FFC600";
        } else {
            // nighttime
            colorBackground = "#20F";
            colorAccent = "#FF583E";
        }
        console.log("component00 colorBackground %s", colorBackground);
        console.log("component00 colorAccent %s", colorAccent);
        svg00 = string(
            abi.encodePacked(
                '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 768 768"><defs><style>.gray{fill:#e5e5e5;}.strokes{stroke:#000;stroke-miterlimit:10;stroke-width:1.5px;}.bg{fill:',
                colorBackground,
                ";}.alt{fill:",
                colorAccent,
                ';}</style></defs><rect width="768" height="768" class="gray"/><g class="strokes"><rect class="bg" x="19.22" y="19.73" width="355.16" height="355.16" rx="40" ry="40"/><rect class="bg" x="19.22" y="394.11" width="355.16" height="355.16" rx="40" ry="40"/><path class="alt" d="m337.92,218.48c19.07-42.5,2.47-92.89-44.59-63.49-39.9,24.92-61.99-11.56-73.34-31.1-16.84-28.99-33.68-6.94-56.68,5.48-28.19,15.22-36.69-17.26-75.39-17.17-28.21.07-33.61,20.35-19.59,38.52,21.95,28.45,3.57,60.1-9.15,87.67-12.54,27.19-14.6,39.87-6.04,50.22,10.63,12.84,34.6,8.03,54.48-5.43,32.2-21.8,38.94-32.11,58.45-39.68,64.49-25.02,50.41,31.79,76.03,41.7,42.55,16.47,81.58-34.99,95.82-66.72Z"/><path class="gray" d="m116.47,221.75c1.36-2.28,2.35-5.13,2.97-8.57.62-3.44.93-7.58.93-12.43,0-4.31-.37-7.95-1.11-10.95-.74-2.99-1.79-5.44-3.16-7.35s-3.09-3.4-5.19-4.49c-2.1-1.09-4.6-1.84-7.5-2.26-2.9-.42-6.17-.63-9.83-.63h-15.31c1.83,17.69-6.13,35.8-14.14,52.79-.03.97-.06,1.94-.1,2.88h29.17c4.06,0,7.57-.28,10.54-.85,2.97-.57,5.49-1.5,7.57-2.78,2.08-1.29,3.8-3.07,5.16-5.34Zm-19.26-14.51c-.15,1.41-.38,2.57-.71,3.49-.32.92-.75,1.65-1.3,2.19s-1.2.9-1.97,1.08c-.77.17-1.6.26-2.49.26-.64,0-1.25-.01-1.82-.04-.57-.02-1.15-.06-1.74-.11-.09,0-.17-.02-.26-.03-.02-1.46-.04-3.12-.04-4.98v-11.69c0-1.73.01-3.5.04-5.31,0-.76.02-1.49.04-2.21.06,0,.12-.01.18-.01,1.16-.07,2.34-.11,3.53-.11,1.04,0,1.93.09,2.67.26.74.17,1.37.49,1.89.97.52.47.93,1.14,1.23,2,.3.87.53,2.03.71,3.49.17,1.46.26,3.25.26,5.38s-.07,3.97-.22,5.38Z"/><path class="gray" d="m151.15,218.14c-.05-2.3-.07-4.69-.07-7.16v-16.4c0-2.52.02-4.9.07-7.12.05-2.23.09-4.35.11-6.38.02-2.03.04-4.03.04-6.01h-23.68c.15,1.98.23,3.98.26,6.01.02,2.03.04,4.17.04,6.42v30.73c0,2.25-.01,4.4-.04,6.46s-.11,4.07-.26,6.05h23.68c.05-1.98.05-4,0-6.05-.05-2.05-.1-4.23-.15-6.53Z"/><path class="gray" d="m139.7,146.86c-3.76,0-6.53.88-8.31,2.63-1.78,1.76-2.67,4.24-2.67,7.46,0,3.27.89,5.76,2.67,7.5,1.78,1.73,4.55,2.6,8.31,2.6,3.56,0,6.21-.88,7.94-2.64,1.73-1.76,2.6-4.24,2.6-7.46,0-3.37-.87-5.89-2.6-7.57-1.73-1.68-4.38-2.52-7.94-2.52Z"/><path class="gray" d="m192.35,230.8c-.05-.79-.07-2-.07-3.64s-.04-3.59-.11-5.86c-.07-2.28-.11-4.81-.11-7.61s-.01-5.76-.04-8.91c-.02-2.85-.03-5.75-.04-8.7.68,0,1.34.01,2.04.02,2.65.02,5.33.09,8.05.19-.05-1.58-.09-3.36-.11-5.34-.02-1.98-.04-3.81-.04-5.49,0-1.83.01-3.7.04-5.6.02-1.9.06-3.5.11-4.79h-44.53c.1,1.29.15,2.88.15,4.79v11.17c0,1.98-.05,3.74-.15,5.27,3.49-.13,6.87-.2,10.16-.23,0,2.99-.03,5.91-.07,8.73-.05,3.14-.1,6.12-.15,8.94-.05,2.82-.07,5.36-.07,7.61s-.03,4.21-.07,5.86c-.05,1.66-.07,2.86-.07,3.6,1.19-.1,2.49-.17,3.9-.22,1.41-.05,2.89-.06,4.45-.04,1.56.02,2.96.04,4.19.04s2.68-.01,4.19-.04,3.01-.01,4.49.04c1.48.05,2.77.12,3.86.22Z"/><path class="gray" d="m243.38,230.8c-.05-.79-.07-2-.07-3.64s-.04-3.59-.11-5.86c-.07-2.28-.11-4.81-.11-7.61s-.01-5.76-.04-8.91c-.02-2.85-.03-5.75-.04-8.7.68,0,1.34.01,2.04.02,2.65.02,5.33.09,8.05.19-.05-1.58-.09-3.36-.11-5.34-.02-1.98-.04-3.81-.04-5.49,0-1.83.01-3.7.04-5.6.02-1.9.06-3.5.11-4.79h-44.53c.1,1.29.15,2.88.15,4.79v11.17c0,1.98-.05,3.74-.15,5.27,3.49-.13,6.87-.2,10.16-.23,0,2.99-.03,5.91-.07,8.73-.05,3.14-.1,6.12-.15,8.94-.05,2.82-.07,5.36-.07,7.61s-.03,4.21-.07,5.86c-.05,1.66-.07,2.86-.07,3.6,1.19-.1,2.49-.17,3.9-.22,1.41-.05,2.89-.06,4.45-.04,1.56.02,2.96.04,4.19.04s2.68-.01,4.19-.04,3.01-.01,4.49.04c1.48.05,2.77.12,3.86.22Z"/><path class="gray" d="m262.88,182.85c-1.58,2.13-2.75,4.74-3.49,7.83-.74,3.09-1.11,6.69-1.11,10.8,0,4.45.33,8.3,1,11.54.67,3.24,1.74,6.05,3.23,8.42s3.38,4.33,5.68,5.86c2.3,1.53,5.06,2.65,8.28,3.34,3.22.69,6.95,1.04,11.21,1.04s8.05-.35,11.25-1.04c3.19-.69,5.97-1.81,8.35-3.34,2.37-1.53,4.33-3.49,5.86-5.86,1.53-2.38,2.67-5.18,3.42-8.42.74-3.24,1.11-7.09,1.11-11.54,0-5.24-.62-9.61-1.86-13.1-1.24-3.49-3.12-6.3-5.64-8.42-2.52-2.13-5.67-3.64-9.43-4.53-3.76-.89-8.09-1.34-12.99-1.34-4.06,0-7.65.27-10.76.82-3.12.54-5.85,1.47-8.2,2.78-2.35,1.31-4.32,3.03-5.9,5.16Zm27.54,7.5c.79.3,1.45.9,1.97,1.82.52.92.9,2.15,1.15,3.71.25,1.56.37,3.45.37,5.68,0,2.43-.12,4.47-.37,6.12-.25,1.66-.63,2.98-1.15,3.97-.52.99-1.16,1.7-1.93,2.12-.77.42-1.67.63-2.71.63-1.09,0-2.03-.21-2.82-.63-.79-.42-1.44-1.11-1.93-2.08-.49-.97-.87-2.28-1.11-3.93-.25-1.66-.37-3.72-.37-6.2,0-2.27.14-4.18.41-5.71.27-1.53.64-2.76,1.11-3.67.47-.92,1.1-1.52,1.89-1.82.79-.3,1.73-.45,2.82-.45.99,0,1.88.15,2.67.45Z"/><path class="gray" d="m326.28,212.54c-1.68,1.73-2.52,4.38-2.52,7.94,0,3.76.88,6.53,2.63,8.31,1.28,1.3,2.94,2.11,4.99,2.47,2.54-4.46,4.74-8.78,6.54-12.78.98-2.18,1.86-4.38,2.65-6.58-1.69-1.3-3.93-1.95-6.71-1.95-3.37,0-5.89.87-7.57,2.6Z"/></g><path fill="transparent" id="rect-path-0" d="m39.39,166.08v-101.2c0-13.81,11.19-25,25-25h264.84c13.81,0,25,11.19,25,25v101.2"/><text font-family="monospace" font-size="1em" class="gray"><textPath xlink:href="#rect-path-0" dominant-baseline="text-after-edge" startOffset="50%" text-anchor="middle">',
                string.concat("Pool: ", _formatAddressAsString(addressPool))
            )
        );
    }

    /**
     * @notice Generates the second of three components of the SVG for a given NFT.
     * @param addressAdmin Address of the DittoPool admin associated with the liquidity position NFT.
     * @param formatEncodedCurve The curve type, preformatted for inclusion in SVG.
     * @return svg01 For use in assignment of SVG animation elements.
     */
    function _getComponent01(address addressAdmin, string memory formatEncodedCurve)
        private
        pure
        returns (string memory svg01)
    {
        svg01 = string(
            abi.encodePacked(
                '</textPath></text><path fill="transparent" id="rect-path" d="m39.39,226.05v101.2c0,13.81,11.19,25,25,25h264.84c13.81,0,25-11.19,25-25v-101.2"/><text font-family="monospace" font-size="1em" class="gray"><textPath xlink:href="#rect-path" dominant-baseline="hanging" startOffset="50%" text-anchor="middle">',
                string.concat("Admin: ", _formatAddressAsString(addressAdmin)),
                '</textPath></text><g transform="translate(-60,0)"><path d="m114.98,507.47h-26.84v-26.91h26.84v26.91Zm-25.55-1.3h24.25v-24.31h-24.25v24.31Z" class="gray"/><path d="m114.27,481.15c0,5.71,0,18.74-13.36,23.6-1.75.65-3.7,1.1-5.97,1.43-1.88.26-3.96.39-6.22.39v.13h25.61l-.06-25.55h0Z" class="gray"/><text transform="translate(126.2 500.58)" font-family="monospace" class="gray" font-size="1.75em">',
                formatEncodedCurve
            )
        );
    }

    /**
     * @notice Generates the token count and symbol element metadata output for display.
     * @param countToken The token count
     * @param decimals The number of decimals of the token
     * @param symbolTokenRaw The raw symbol of the token
     * @return tokenCountString_ The formatted token count and symbol string
     */
    function _generateTokenCountString(uint256 countToken, uint256 decimals, string memory symbolTokenRaw)
        public
        pure
        returns (string memory tokenCountString_)
    {
        uint256 left = countToken / (10 ** decimals);
        uint256 right = countToken % (10 ** decimals);
        if (left >= 1000) {
            return string(
                abi.encodePacked(
                    _truncateString(symbolTokenRaw, MAX_SYMBOL_LENGTH, true), ": ", _formatNumberLarge(left)
                )
            );
        }
        if (left == 0) {
            return string(
                abi.encodePacked(
                    _truncateString(symbolTokenRaw, MAX_SYMBOL_LENGTH, true),
                    ": ",
                    _formatNumberSmall(countToken, decimals)
                )
            );
        }
        string memory value;
        if (right == 0) {
            value = "0";
        } else {
            value = _removeTrailingZeros(_truncateString(Strings.toString(right), 2, false));
        }
        return string(
            abi.encodePacked(
                _truncateString(symbolTokenRaw, MAX_SYMBOL_LENGTH, true), ": ", Strings.toString(left), ".", value
            )
        );
    }

    /**
     * @notice Generates the third of three components of the SVG for a given NFT.
     * @param info aggregate struct of input parameters for svg creation
     * @param colorVariant The pseudo-random number used to determine background color of the SVG.
     * @return svg02 For use in assignment of SVG animation elements.
     */
    function _getComponent02(MetadataInfo memory info, bool colorVariant) private view returns (string memory svg02) {
        string memory symbolValueNft = _svgCharacterEscape(
            string.concat(
                _truncateString(info.symbolNft, MAX_SYMBOL_LENGTH, true), ": ", _formatNumberLarge(info.nftCount)
            )
        );
        // nightime is 0, daytime is 1
        uint256 assetVariant00Random =
            _getPseudoRandomNumber(_assetVariant00.length, info.tokenId, info.addressPool, info.addressNft, 0);
        uint256 assetVariant01Random =
            _getPseudoRandomNumber(_assetVariant01.length, info.tokenId, info.addressPool, info.addressNft, 1);

        colorVariant ? console.log("getComponent02 using asset variant 1") : console.log("getComponent02 using asset variant 0");

        svg02 = string(
            abi.encodePacked(
                '</text><ellipse class="gray" cx="101.56" cy="549.7" rx="13.42" ry="3.81"/><path class="gray" d="m88.14,553.1v15.83c0,2.1,6.01,3.81,13.42,3.81s13.42-1.71,13.42-3.81v-15.83c-2.78,2.14-9.21,2.78-13.42,2.78s-10.64-.64-13.42-2.78Z"/><text transform="translate(126.88 563.83)" font-family="monospace" class="gray" font-size="1.75em">',
                info.feeString,
                '</text><rect x="88.79" y="603.76" width="25.61" height="25.61" class="gray"/><text transform="translate(126.18 623.14)" font-family="monospace" class="gray" font-size="1.75em">',
                symbolValueNft,
                '</text><path d="m101.56,637.28h0c7.07,0,12.77,5.71,12.77,12.77h0c0,7.07-5.71,12.77-12.77,12.77h0c-7.07,0-12.77-5.71-12.77-12.77h0c0-7.07,5.71-12.77,12.77-12.77Z" transform="translate(0 25.75)" class="gray"/><text transform="translate(126.18 685)" font-family="monospace" class="gray" font-size="1.75em">',
                info.tokenString,
                '</text></g><image width="100%" height="100%" xlink:href="data:image/svg+xml;base64,',
                colorVariant ? _assetVariant01[assetVariant01Random] : _assetVariant00[assetVariant00Random],
                '"/></svg>'
            )
        );
    }

    /**
     * @notice Generates a number between zero and `max` for use in assignment of SVG animation elements.
     * @param max Upper bound of pseudo-random number.
     * @param tokenId The identifier for an liquidity position NFT
     * @param addressDittoPool Address of the DittoPool associated with the liquidity position NFT.
     * @param addressToken Address of the ERC20 token used for liquidity provision in the DittoPool.
     * @param seed Additional data to get multiple random values for a repeated tokenId
     * @return pseudoRandomNumber For use in assignment of SVG animation elements.
     * @dev The inputs to this function are unchanging, to ensure that the same SVG animation element assigned to the NFT is persistent.
     */
    function _getPseudoRandomNumber(
        uint256 max,
        uint256 tokenId,
        address addressDittoPool,
        address addressToken,
        uint8 seed
    ) private pure returns (uint256 pseudoRandomNumber) {
        pseudoRandomNumber = uint256(keccak256(abi.encodePacked(tokenId, addressDittoPool, addressToken, seed))) % max;
    }
}
