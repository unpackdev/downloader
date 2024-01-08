// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC20Mintable.sol";
import "./base64.sol";
import "./Ships.sol";
import "./SettlementsV2.sol";
import "./Islands.sol";
import "./console.sol";

contract ShipsHelper is Ownable {
    uint256 constant ONE = 10**18;

    Ships public shipsContract;

    uint256[] public nameToMaxRouteLength = [2, 3, 4, 5, 5];
    uint256[] public expeditionMultipliers = [3, 2, 2, 1, 1];

    uint256[] public setlNameMultipliers = [1, 2, 2, 4, 4];
    uint256[] public setlExpeditionMultipliers = [1, 3, 1, 2, 2];

    Ships.TokenHarvest[][] public nameToCost;

    SettlementsV2 public settlementsContract;
    Islands public islandsContract;

    ERC20Mintable public setlTokenAddress;

    enum Status {
        Resting,
        Sailing,
        Harvesting
    }

    constructor(ERC20Mintable setlTokenAddress_) {
        setlTokenAddress = setlTokenAddress_;
    }

    /** Setters */
    function setShipsContract(Ships shipsContract_) public onlyOwner {
        shipsContract = shipsContract_;
    }

    function setSettlementsContract(SettlementsV2 settlementsContract_) public onlyOwner {
        settlementsContract = settlementsContract_;
    }

    function setIslandsContract(Islands islandsContract_) public onlyOwner {
        islandsContract = islandsContract_;
    }

    function setCosts(Ships.TokenHarvest[][] memory costs) public onlyOwner {
        delete nameToCost;

        for (uint256 i = 0; i < costs.length; i++) {
            nameToCost.push();
            for (uint256 s = 0; s < costs[i].length; s++) {
                nameToCost[i].push();
                nameToCost[i][s].resourceTokenContract = costs[i][s].resourceTokenContract;
                nameToCost[i][s].amount = costs[i][s].amount;
            }
        }
    }

    /** Getters */
    // breh the level of modulo math in the next few functions is insane nocap
    function getStatus(uint256 tokenId) public view returns (Status) {
        Ships.Ship memory shipInfo = shipsContract.getShipInfo(tokenId);

        uint256 lastRouteUpdate = shipsContract.tokenIdToLastRouteUpdate(tokenId);
        uint256 blockDelta = block.number - lastRouteUpdate;

        uint256 sailingDuration = getSailingDuration(shipInfo);
        uint256 harvestDuration = 120;

        uint256 progressIntoCurrentPath = blockDelta % (sailingDuration + harvestDuration);
        uint256 currentTargetIndex = getCurrentTargetIndex(tokenId);
        Status status = progressIntoCurrentPath >= sailingDuration
            ? currentTargetIndex == 0 ? Status.Resting : Status.Harvesting
            : Status.Sailing;

        return status;
    }

    function getCurrentTargetIndex(uint256 tokenId) public view returns (uint256) {
        Ships.Ship memory shipInfo = shipsContract.getShipInfo(tokenId);

        uint256 lastRouteUpdate = shipsContract.tokenIdToLastRouteUpdate(tokenId);
        uint256 blockDelta = block.number - lastRouteUpdate;

        uint256 sailingDuration = getSailingDuration(shipInfo);
        uint256 harvestDuration = 120;

        uint256 singlePathDuration = sailingDuration + harvestDuration;

        uint256 index = (blockDelta % (singlePathDuration * shipInfo.route.length)) /
            singlePathDuration;
        uint256 currentTargetIndex = (index + 1) % shipInfo.route.length;

        return currentTargetIndex;
    }

    function getCurrentTarget(uint256 tokenId) public view returns (Ships.Path memory) {
        uint256 currentTargetIndex = getCurrentTargetIndex(tokenId);
        Ships.Ship memory shipInfo = shipsContract.getShipInfo(tokenId);
        return shipInfo.route[currentTargetIndex];
    }

    function getSailingDuration(Ships.Ship memory shipInfo) public pure returns (uint256) {
        return (15 * 200) / shipInfo.speed;
    }

    function getBlocksUntilNextPhase(uint256 tokenId) public view returns (uint256) {
        Ships.Ship memory shipInfo = shipsContract.getShipInfo(tokenId);
        uint256 lastRouteUpdate = shipsContract.tokenIdToLastRouteUpdate(tokenId);
        uint256 blockDelta = block.number - lastRouteUpdate;

        uint256 sailingDuration = getSailingDuration(shipInfo);
        uint256 harvestDuration = 120;

        uint256 singlePathDuration = sailingDuration + harvestDuration;
        uint256 progressIntoCurrentPath = blockDelta % singlePathDuration;

        uint256 blocksUntilNextPhase = progressIntoCurrentPath < sailingDuration
            ? sailingDuration - progressIntoCurrentPath
            : singlePathDuration - progressIntoCurrentPath;

        return blocksUntilNextPhase;
    }

    function getUnharvestedTokens(uint256 tokenId)
        public
        view
        returns (Ships.TokenHarvest[] memory)
    {
        Ships.Ship memory shipInfo = shipsContract.getShipInfo(tokenId);
        Ships.Attributes memory shipAttr = shipsContract.getTokenIdToAttributes(tokenId);

        uint256 lastRouteUpdate = shipsContract.tokenIdToLastRouteUpdate(tokenId);
        uint256 blockDelta = block.number - lastRouteUpdate;

        uint256 sailingDuration = getSailingDuration(shipInfo);
        uint256 harvestDuration = 120;
        uint256 singlePathDuration = sailingDuration + harvestDuration;
        uint256 totalPathDuration = singlePathDuration * shipInfo.route.length;

        Ships.TokenHarvest[] memory listOfTokensToHarvest = new Ships.TokenHarvest[](
            shipInfo.route.length - 1
        );
        uint256 tokensSeen = 0;

        // why hasn't any of the eth big brains figured out how to do a hashmap in memory
        for (uint256 i = 1; i < shipInfo.route.length; i++) {
            // offset = totalPathDuration - singlePathDuration * i
            // amountOfTimesHarvestedTarget = (blockDelta + offset) / totalPathDuration
            uint256 tokensToHarvest = (((blockDelta +
                (totalPathDuration - singlePathDuration * i)) / totalPathDuration) *
                ONE *
                expeditionMultipliers[shipAttr.expedition]);

            (ERC20Mintable resourceTokenContract, uint256 __) = islandsContract.getTaxIncome(
                shipInfo.route[i].tokenId
            );

            uint256 index = shipInfo.route.length;
            for (uint256 s = 0; s < listOfTokensToHarvest.length; s++) {
                if (
                    listOfTokensToHarvest[s].resourceTokenContract == address(resourceTokenContract)
                ) {
                    index = s;
                }
            }

            if (tokensToHarvest > 0) {
                if (index != shipInfo.route.length) {
                    listOfTokensToHarvest[index].amount += tokensToHarvest;
                } else {
                    listOfTokensToHarvest[tokensSeen].amount += tokensToHarvest;
                    listOfTokensToHarvest[tokensSeen].resourceTokenContract = address(
                        resourceTokenContract
                    );
                    tokensSeen += 1;
                }
            }
        }

        Ships.TokenHarvest[] memory filteredListOfTokensToHarvest = new Ships.TokenHarvest[](
            tokensSeen + 1
        );
        for (uint256 i = 0; i < tokensSeen; i++) {
            filteredListOfTokensToHarvest[i] = listOfTokensToHarvest[i];
        }

        filteredListOfTokensToHarvest[tokensSeen] = Ships.TokenHarvest({
            resourceTokenContract: address(setlTokenAddress),
            amount: getUnharvestedSettlementTokens(tokenId)
        });

        return filteredListOfTokensToHarvest;
    }

    function getUnharvestedSettlementTokens(uint256 tokenId) public view returns (uint256) {
        Ships.Attributes memory shipAttr = shipsContract.getTokenIdToAttributes(tokenId);
        uint256 lastSetlHarvest = shipsContract.tokenIdToLastRouteUpdate(tokenId);
        uint256 blockDelta = block.number - lastSetlHarvest;

        // timeSinceLastSettleHarvest * expeditionMultiplier * shipMultiplier
        uint256 unharvestedSetlTokens = (setlExpeditionMultipliers[shipAttr.expedition] *
            setlNameMultipliers[shipAttr.name] *
            blockDelta *
            ONE) / 1000;

        return unharvestedSetlTokens;
    }

    function getTaxDestination(uint256 tokenId) public view returns (address) {
        Ships.Ship memory shipInfo = shipsContract.getShipInfo(tokenId);
        return settlementsContract.ownerOf(shipInfo.route[0].tokenId);
    }

    function getInitialRoute(uint256 tokenId, uint8 name)
        public
        view
        returns (Ships.Path[] memory)
    {
        uint256 routeLength = nameToMaxRouteLength[name];
        Ships.Path[] memory routes = new Ships.Path[](routeLength);

        uint256 settlementId = getRandomNumber(abi.encodePacked("s", tokenId), 9_900);
        routes[0] = Ships.Path({
            tokenId: settlementId,
            tokenContract: address(settlementsContract)
        });

        for (uint256 i = 1; i < routes.length; i++) {
            uint256 islandId = getRandomNumber(abi.encodePacked(i, tokenId), 10_000);
            routes[i] = Ships.Path({tokenId: islandId, tokenContract: address(islandsContract)});
        }

        return routes;
    }

    function getRandomNumber(bytes memory seed, uint256 maxValue) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(seed))) % maxValue;
    }

    function getCost(uint8 name) public view returns (Ships.TokenHarvest[] memory) {
        return nameToCost[name];
    }

    // We'll disable trading route updates for now until the mechanics are clearer
    // It's only valid on initialisation
    function isValidRoute(
        Ships.Path[] memory route,
        uint256 tokenId,
        address sender,
        bool init
    ) public view returns (bool) {
        return init;
    }

    function getImageOutput(Ships.Ship memory shipInfo) public view returns (string memory) {
        string memory imageOutput = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.txt { fill: black; font-family: monospace; font-size: 12px;}</style><rect width="100%" height="100%" fill="white" /><text x="10" y="20" class="txt">',
                shipInfo.name,
                '</text><text x="10" y="40" class="txt">',
                shipInfo.expedition,
                '</text><text x="10" y="60" class="txt">',
                string(abi.encodePacked(Strings.toString(uint256(shipInfo.length)), " ft")),
                '</text><text x="10" y="80" class="txt">',
                string(abi.encodePacked(Strings.toString(uint256(shipInfo.speed)), " km/h")),
                '</text><text x="10" y="100" class="txt">'
            )
        );

        string memory routeStr = "";
        uint256 svgY = 160;
        for (uint256 i = 0; i < shipInfo.route.length; i++) {
            string memory symbol = shipInfo.route[i].tokenContract == address(settlementsContract)
                ? "S"
                : "I";

            string memory suffix = i == shipInfo.route.length - 1 ? "" : ",";

            routeStr = string(
                abi.encodePacked(
                    routeStr,
                    " ",
                    symbol,
                    Strings.toString(shipInfo.route[i].tokenId),
                    suffix
                )
            );

            if ((i + 1) % 4 == 0 && i + 1 != shipInfo.route.length) {
                svgY += 20;
                routeStr = string(
                    abi.encodePacked(
                        routeStr,
                        '</text><text x="10" y="',
                        Strings.toString(svgY),
                        '" class="txt">'
                    )
                );
            }
        }

        Status shipStatus = getStatus(shipInfo.tokenId);
        Ships.Path memory currentTarget = getCurrentTarget(shipInfo.tokenId);
        imageOutput = string(
            abi.encodePacked(
                imageOutput,
                "------------",
                '</text><text x="10" y="120" class="txt">',
                "Status: ",
                shipStatus == Status.Harvesting ? "Harvesting " : shipStatus == Status.Resting
                    ? "Resting at "
                    : "Sailing to ",
                currentTarget.tokenContract == address(settlementsContract) ? "S" : "I",
                Strings.toString(currentTarget.tokenId),
                '</text><text x="10" y="140" class="txt">',
                abi.encodePacked(
                    "ETA: ",
                    Strings.toString(getBlocksUntilNextPhase(shipInfo.tokenId)),
                    " blocks"
                ),
                '</text><text x="10" y="160" class="txt">',
                "Route: ",
                routeStr,
                abi.encodePacked(
                    '</text><text x="10" y="',
                    Strings.toString(svgY + 20),
                    '" class="txt">'
                ),
                "------------",
                abi.encodePacked(
                    '</text><text x="10" y="',
                    Strings.toString(svgY + 40),
                    '" class="txt">'
                )
            )
        );

        svgY += 40;
        Ships.TokenHarvest[] memory unharvestedTokens = getUnharvestedTokens(shipInfo.tokenId);
        string memory unharvestedTokenStr = "";
        for (uint256 i = 0; i < unharvestedTokens.length; i++) {
            string memory suffix = i == unharvestedTokens.length - 1 ? "" : ", ";
            unharvestedTokenStr = string(
                abi.encodePacked(
                    unharvestedTokenStr,
                    Strings.toString(unharvestedTokens[i].amount / ONE),
                    " $",
                    ERC20Mintable(unharvestedTokens[i].resourceTokenContract).symbol(),
                    suffix
                )
            );

            if ((i + 1) % 3 == 0) {
                svgY += 20;
                unharvestedTokenStr = string(
                    abi.encodePacked(
                        unharvestedTokenStr,
                        '</text><text x="10" y="',
                        Strings.toString(svgY),
                        '" class="txt">'
                    )
                );
            }
        }

        imageOutput = string(abi.encodePacked(imageOutput, unharvestedTokenStr, "</text></svg>"));

        return imageOutput;
    }

    function getAttrOutput(Ships.Ship memory shipInfo) public view returns (string memory) {
        string memory routeStr = "";
        for (uint256 i = 0; i < shipInfo.route.length; i++) {
            string memory symbol = shipInfo.route[i].tokenContract == address(settlementsContract)
                ? "S"
                : "I";

            string memory suffix = i == shipInfo.route.length - 1 ? "" : ",";

            routeStr = string(
                abi.encodePacked(
                    routeStr,
                    '"',
                    symbol,
                    Strings.toString(shipInfo.route[i].tokenId),
                    '"',
                    suffix
                )
            );
        }

        string memory attrOutput = string(
            abi.encodePacked(
                '[{ "trait_type": "Name", "value": "',
                shipInfo.name,
                '" }, { "trait_type": "Expedition", "value": "',
                shipInfo.expedition,
                '" }, { "trait_type": "Length (ft)", "display_type": "number", "value": ',
                Strings.toString(uint256(shipInfo.length)),
                ' }, { "trait_type": "Speed (km/h)", "display_type": "number", "value": ',
                Strings.toString(uint256(shipInfo.speed)),
                ' }, { "trait_type": "Trade Route", "value": [',
                routeStr,
                "]"
            )
        );

        attrOutput = string(abi.encodePacked(attrOutput, " }]"));

        return attrOutput;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        Ships.Ship memory shipInfo = shipsContract.getShipInfo(tokenId);

        string memory imageOutput = getImageOutput(shipInfo);
        string memory attrOutput = getAttrOutput(shipInfo);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Ship #',
                        Strings.toString(tokenId),
                        '", "description": "Ships can sail around the Settlements world to trade, discover and attack. All data is onchain.", "image": "data:image/svg+xml;base64,',
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
