// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import "./StringsUpgradeable.sol";
import "./Base64.sol";

/// @title NFTDescriptor library
/// @author UNIFARM
/// @notice create token metadata & onchain SVG

library NFTDescriptor {
    /// @notice for converting uint256 to string
    using StringsUpgradeable for uint256;

    /// @notice NFT Description Parameters
    struct DescriptionParam {
        // farm id
        uint32 fid;
        // cohort version
        string cohortName;
        // stake token ticker
        string stakeTokenTicker;
        // cohort address
        string cohortAddress;
        // owner staked  block
        uint256 stakedBlock;
        // nft token id
        uint256 tokenId;
        // owner stakedAmount
        uint256 stakedAmount;
        // owner confirmed epochs
        uint256 confirmedEpochs;
        // denotes booster availablity
        bool isBoosterAvailable;
    }

    /**
     * @dev construct the NFT name
     * @param cohortName cohort name
     * @param farmTicker farm token ticker
     * @return NFT name
     */

    function generateName(string memory cohortName, string memory farmTicker) internal pure returns (string memory) {
        return string(abi.encodePacked(farmTicker, ' ', '(', cohortName, ')'));
    }

    /**
     * @dev construct the first segment of description
     * @param tokenId farm token address
     * @param cohortName cohort name
     * @param stakeTokenTicker farm token ticker
     * @param cohortId cohort contract address
     * @return long description
     */

    function generateDescriptionSegment1(
        uint256 tokenId,
        string memory cohortName,
        string memory stakeTokenTicker,
        string memory cohortId
    ) internal pure returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    'This NFT denotes your staking on Unifarm. Owner of this nft can Burn or sell on any NFT marketplace. please check staking details below. \\n',
                    'Token Id :',
                    tokenId.toString(),
                    '\\n',
                    'Cohort Name :',
                    cohortName,
                    '\\n',
                    'Cohort Address :',
                    cohortId,
                    '\\n',
                    'Staked Token Ticker :',
                    stakeTokenTicker,
                    '\\n'
                )
            )
        );
    }

    /**
     * @dev construct second part of description
     * @param stakedAmount user staked amount
     * @param confirmedEpochs number of confirmed epochs
     * @param stakedBlock block on which user staked
     * @param isBoosterAvailable true, if user bought booster pack
     * @return long description
     */

    function generateDescriptionSegment2(
        uint256 stakedAmount,
        uint256 confirmedEpochs,
        uint256 stakedBlock,
        bool isBoosterAvailable
    ) internal pure returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    'Staked Amount :',
                    stakedAmount.toString(),
                    '\\n',
                    'Confirmed Epochs :',
                    confirmedEpochs.toString(),
                    '\\n',
                    'Staked Block :',
                    stakedBlock.toString(),
                    '\\n',
                    'Booster: ',
                    isBoosterAvailable ? 'Yes' : 'No'
                )
            )
        );
    }

    /**
     * @dev construct SVG with available information
     * @param svgParams it includes all the information of user staking
     * @return svg
     */

    function generateSVG(DescriptionParam memory svgParams) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg width="350" height="350" viewBox="0 0 350 350" fill="none" xmlns="http://www.w3.org/2000/svg">',
                    generateBoosterIndicator(svgParams.isBoosterAvailable),
                    generateRectanglesSVG(),
                    generateSVGTypography(svgParams),
                    generateSVGTypographyForRectangles(svgParams.tokenId, svgParams.stakedBlock, svgParams.confirmedEpochs),
                    '<text x="45" y="313" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    svgParams.stakedAmount.toString(),
                    '</text>',
                    generateSVGDefs()
                )
            );
    }

    /**
     * @dev generate svg rectangles
     * @return svg rectangles
     */

    function generateRectanglesSVG() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path d="M38 162a5 5 0 0 1 5-5h78a5 5 0 0 1 5 5v22a5 5 0 0 1-5 5H43a5 5 0 0 1-5-5v-22Zm0 38a5 5 0 0 1 5-5h147a5 5 0 0 1 5 5v22a5 5 0 0 1-5 5H43a5 5 0 0 1-5-5v-22Zm0 38a5 5 0 0 1 5-5h180a5 5 0 0 1 5 5v22a5 5 0 0 1-5 5H43a5 5 0 0 1-5-5v-22Zm0 42.969c0-4.401 2.239-7.969 5-7.969h210c2.761 0 5 3.568 5 7.969v35.062c0 4.401-2.239 7.969-5 7.969H43c-2.761 0-5-3.568-5-7.969v-35.062Z" fill="#293922" fill-opacity=".51"/>'
                )
            );
    }

    /**
     * @dev generate booster indicator
     * @param isBoosted true, if user bought the booster pack
     * @return booster indicator
     */

    function generateBoosterIndicator(bool isBoosted) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g clip-path="url(#a)">',
                    '<rect width="350" height="350" rx="37" fill="url(#b)"/>',
                    '<rect x="15.35" y="14.35" width="315.3" height="318.3" rx="29.65" stroke="#D6D6D6" stroke-opacity=".74" stroke-width=".7"/>',
                    generateRocketIcon(isBoosted),
                    '</g>'
                )
            );
    }

    /**
     * @dev generate rocket icon
     * @param isBoosted true, if user bought the booster pack
     * @return rocket icon
     */
    function generateRocketIcon(bool isBoosted) internal pure returns (string memory) {
        return
            isBoosted
                ? string(
                    abi.encodePacked(
                        '<path d="M49 75h62a5 5 0 0 1 5 5v12a5 5 0 0 1-5 5H49V75Z" fill="#C4C4C4"/>',
                        '<circle cx="49" cy="86" r="10.5" fill="#C4C4C4" stroke="#fff"/>',
                        '<path d="m43.832 90.407 4.284-4.284.758.757-4.285 4.284-.757-.757Z" fill="#fff"/>',
                        '<path d="M49.036 94a.536.536 0 0 1-.53-.46l-.536-3.75 1.072-.15.401 2.823 1.736-1.399v-4.028a.534.534 0 0 1 .155-.38l2.18-2.181a4.788 4.788 0 0 0 1.415-3.407v-.996h-.997a4.788 4.788 0 0 0-3.407 1.414l-2.18 2.18a.536.536 0 0 1-.38.156h-4.029l-1.398 1.746 2.823.402-.15 1.071-3.75-.536a.537.537 0 0 1-.342-.867l2.142-2.679a.536.536 0 0 1 .418-.209h4.066l2.02-2.025A5.85 5.85 0 0 1 53.932 79h.997A1.071 1.071 0 0 1 56 80.072v.996a5.853 5.853 0 0 1-1.725 4.168l-2.025 2.02v4.065a.537.537 0 0 1-.203.418l-2.679 2.143a.535.535 0 0 1-.332.118Z" fill="#fff"/>'
                    )
                )
                : '';
    }

    /**
     * @dev generate typography for NFTSVG with rectangle fields
     * @param tokenId NFT tokenId
     * @param stakedBlock user staked block
     * @param confirmedEpochs staking confirmed epochs
     * @return typography for NFTSVG
     */

    function generateSVGTypographyForRectangles(
        uint256 tokenId,
        uint256 stakedBlock,
        uint256 confirmedEpochs
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text x="45" y="177" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">'
                    'ID: ',
                    tokenId.toString(),
                    '</text>',
                    '<text x="45" y="216" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    'Staked block: ',
                    stakedBlock.toString(),
                    '</text>',
                    '<text x="45" y="254" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    'Confirmed epochs: ',
                    confirmedEpochs.toString(),
                    '</text>'
                    '<text x="45" y="292" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    'Staked Amount: ',
                    '</text>'
                )
            );
    }

    /**
     * @dev create typography for SVG header
     * @param params it includes all the information of user staking
     * @return typography for SVG header
     */

    function generateSVGTypography(DescriptionParam memory params) internal pure returns (string memory) {
        DescriptionParam memory svgParam = params;
        return
            string(
                abi.encodePacked(
                    '<text x="36" y="65" fill="#fff" font-size="1em" font-family="Arial, Helvetica, sans-serif">',
                    generateName(svgParam.cohortName, svgParam.stakeTokenTicker),
                    '</text>',
                    generateBoostedLabelText(svgParam.isBoosterAvailable),
                    '<text x="40" y="127" fill="#FFF" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                    '<tspan x="40" dy="0">Cohort Address:</tspan>',
                    '<tspan x="40" dy="1.2em">',
                    svgParam.cohortAddress,
                    '</tspan>',
                    '</text>'
                )
            );
    }

    /**
     * @dev create boosted label text for NFT SVG
     * @param isBoosted true, if user bought the booster pack
     * @return boosted label text
     */

    function generateBoostedLabelText(bool isBoosted) internal pure returns (string memory) {
        return
            isBoosted
                ? string(
                    abi.encodePacked(
                        '<text x="64" y="90" fill="#fff" font-size=".75em" font-family="Arial, Helvetica, sans-serif">',
                        'Boosted',
                        '</text>'
                    )
                )
                : '';
    }

    /**
     * @dev create defs for NFT SVG
     * @return defs
     */
    function generateSVGDefs() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<defs>',
                    '<linearGradient id="b" x1="44.977" y1="326.188" x2="113.79" y2="-21.919" gradientUnits="userSpaceOnUse">',
                    '<stop stop-color="#730AAC"/>',
                    '<stop offset=".739" stop-color="#A2164A"/>',
                    '</linearGradient>',
                    '<clipPath id="a">',
                    '<rect width="350" height="350" rx="37" fill="#fff"/>',
                    '</clipPath>',
                    '</defs>',
                    '</svg>'
                )
            );
    }

    /**
     * @dev create NFT Token URI
     * @param descriptionParam it includes all the information of user staking
     * @return NFT Token URI
     */

    function createNftTokenURI(DescriptionParam memory descriptionParam) internal pure returns (string memory) {
        string memory name = generateName(descriptionParam.cohortName, descriptionParam.stakeTokenTicker);
        string memory description = string(
            abi.encodePacked(
                generateDescriptionSegment1(
                    descriptionParam.tokenId,
                    descriptionParam.cohortName,
                    descriptionParam.stakeTokenTicker,
                    descriptionParam.cohortAddress
                ),
                generateDescriptionSegment2(
                    descriptionParam.stakedAmount,
                    descriptionParam.confirmedEpochs,
                    descriptionParam.stakedBlock,
                    descriptionParam.isBoosterAvailable
                )
            )
        );
        string memory svg = Base64.encode(bytes(generateSVG(descriptionParam)));
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    string(
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{',
                                    '"name":',
                                    '"',
                                    name,
                                    '"',
                                    ',',
                                    '"description":',
                                    '"',
                                    description,
                                    '"',
                                    ',',
                                    '"image":',
                                    '"data:image/svg+xml;base64,',
                                    svg,
                                    '"',
                                    '}'
                                )
                            )
                        )
                    )
                )
            );
    }
}
