// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Islands.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC20Mintable.sol";
import "./base64.sol";

contract IslandsHelper is Ownable {
    uint256 constant ONE = 10**18;

    Islands public islandContract;

    uint8[] public climateMultipliers;
    uint8[] public terrainMultipliers;

    function setIslandsContract(Islands islandContract_) public onlyOwner {
        islandContract = islandContract_;
    }

    function setMultipliers(uint8[] memory climateMultipliers_, uint8[] memory terrainMultipliers_)
        public
        onlyOwner
    {
        climateMultipliers = climateMultipliers_;
        terrainMultipliers = terrainMultipliers_;
    }

    function getImageOutput(Islands.Island memory islandInfo) public view returns (string memory) {
        string memory imageOutput = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.txt { fill: black; font-family: monospace; font-size: 12px;}</style><rect width="100%" height="100%" fill="white" /><text x="10" y="20" class="txt">',
                islandInfo.climate,
                '</text><text x="10" y="40" class="txt">',
                islandInfo.terrain,
                '</text><text x="10" y="60" class="txt">',
                islandInfo.resource,
                '</text><text x="10" y="80" class="txt">',
                string(abi.encodePacked(Strings.toString(islandInfo.area), " sq mi")),
                '</text><text x="10" y="100" class="txt">'
            )
        );

        (ERC20Mintable resourceTokenContract, uint256 taxIncome) = getTaxIncome(islandInfo.tokenId);

        imageOutput = string(
            abi.encodePacked(
                imageOutput,
                string(
                    abi.encodePacked(
                        "Pop. ",
                        Strings.toString(islandInfo.population),
                        "/",
                        Strings.toString(islandInfo.maxPopulation)
                    )
                ),
                '</text><text x="10" y="120" class="txt">',
                "------------",
                '</text><text x="10" y="140" class="txt">',
                string(abi.encodePacked("Tax Rate: ", Strings.toString(islandInfo.taxRate), "%")),
                '</text><text x="10" y="160" class="txt">',
                string(
                    abi.encodePacked(
                        "Tax Income: ",
                        Strings.toString(taxIncome / 10**18),
                        " $",
                        resourceTokenContract.symbol()
                    )
                ),
                '</text><text x="10" y="180" class="txt">',
                "</text></svg>"
            )
        );

        return imageOutput;
    }

    function getAttrOutput(Islands.Island memory islandInfo) public view returns (string memory) {
        (ERC20Mintable __, uint256 taxIncome) = getTaxIncome(islandInfo.tokenId);

        string memory attrOutput = string(
            abi.encodePacked(
                '[{ "trait_type": "Climate", "value": "',
                islandInfo.climate,
                '" }, { "trait_type": "Terain", "value": "',
                islandInfo.terrain,
                '" }, { "trait_type": "Resource", "value": "',
                islandInfo.resource,
                '" }, { "trait_type": "Area (sq mi)", "display_type": "number", "value": ',
                Strings.toString(islandInfo.area),
                ' }, { "trait_type": "Population", "display_type": "number", "value": ',
                Strings.toString(islandInfo.population),
                ' }, { "trait_type": "Tax Rate", "display_type": "boost_percentage", "value": ',
                Strings.toString(islandInfo.taxRate)
            )
        );

        attrOutput = string(
            abi.encodePacked(
                attrOutput,
                ' }, { "trait_type": "Max Population", "display_type": "number", "value": ',
                Strings.toString(islandInfo.maxPopulation),
                ' }, { "trait_type": "Tax Income", "display_type": "number", "value": ',
                Strings.toString(taxIncome / 10**18),
                " }]"
            )
        );

        return attrOutput;
    }

    function getTaxIncome(uint256 tokenId) public view returns (ERC20Mintable, uint256) {
        Islands.Attributes memory islandInfo = islandContract.getTokenIdToAttributes(tokenId);
        ERC20Mintable resourceTokenContract = islandContract.resourcesToTokenContracts(
            islandInfo.resource
        );

        uint256 lastHarvest = islandContract.tokenIdToLastHarvest(tokenId);
        uint256 blockDelta = block.number - lastHarvest;

        uint256 tokenAmount = (blockDelta *
            climateMultipliers[islandInfo.climate] *
            terrainMultipliers[islandInfo.terrain] *
            islandInfo.taxRate *
            islandInfo.population *
            ONE) / 1_000_000_000;

        return (resourceTokenContract, tokenAmount);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        Islands.Island memory islandInfo = islandContract.getIslandInfo(tokenId);

        string memory imageOutput = getImageOutput(islandInfo);
        string memory attrOutput = getAttrOutput(islandInfo);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Island #',
                        Strings.toString(tokenId),
                        '", "description": "Islands can be discovered and harvested for their resources. All data is onchain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(imageOutput)),
                        '", "attributes": ',
                        attrOutput,
                        "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
