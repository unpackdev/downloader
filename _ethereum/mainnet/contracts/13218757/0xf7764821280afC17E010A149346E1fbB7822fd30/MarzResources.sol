// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./StringsUpgradeable.sol";

contract MarzResources is ERC1155Upgradeable {
    using StringsUpgradeable for uint256;

    uint256 private constant SECONDS_PER_MINING_PERIOD = 86400;
    uint256 private constant CLAIMS_PER_PLOT = 30;

    // COMMON
    uint256 public constant DIRT = 0;
    uint256 public constant TIN = 1;
    uint256 public constant COPPER = 2;
    uint256 public constant IRON = 3;
    uint256 public constant NICKEL = 4;
    uint256 public constant ZINC = 5;
    uint256[6] private COMMON;

    // UNCOMMON
    uint256 public constant ICE = 6;
    uint256 public constant LEAD = 7;
    uint256 public constant BISMUTH = 8;
    uint256 public constant ANTIMONY = 9;
    uint256 public constant LITHIUM = 10;
    uint256 public constant COBALT = 11;
    uint256[6] private UNCOMMON;

    // RARE
    uint256 public constant SILVER = 12;
    uint256 public constant GOLD = 13;
    uint256 public constant CHROMIUM = 14;
    uint256 public constant MERCURY = 15;
    uint256 public constant TUNGSTEN = 16;
    uint256[5] private RARE;

    // INSANE :o
    uint256 public constant BACTERIA = 17;
    uint256 public constant DIAMOND = 18;
    uint256[2] private INSANE;

    mapping(uint256 => uint256) public startTimes;
    mapping(uint256 => uint256) public claimed;

    address public marz;

    string public constant baseURI = "https://api.marzmining.xyz/token/";
    string public constant name = "Marz Resources";
    string public constant symbol = "rMARZ";

    //--------------------------------------------------------------------------
    // Public functions
    function initialize(address _marz) external initializer {
        __ERC1155_init("https://api.marzmining.xyz/token/{id}");
        marz = _marz;

        // upgradeable contracts need variables to be set in the initializer
        COMMON = [DIRT, TIN, COPPER, IRON, NICKEL, ZINC];
        UNCOMMON = [ICE, LEAD, BISMUTH, ANTIMONY, LITHIUM, COBALT];
        RARE = [SILVER, GOLD, CHROMIUM, MERCURY, TUNGSTEN];
        INSANE = [BACTERIA, DIAMOND];
    }

    /**
     * Return array of resources found at a given plot number
     * There will be between 1 and 4 resources of varying rarities at each plot
     */
    function getResources(uint256 plotId) public view returns (uint256[] memory resources) {
        uint256 countRand = random(string(abi.encodePacked("COUNT", plotId.toString())));
        uint256 countScore = countRand % 21;
        uint256 resourceCount = countScore < 12 ? 1 : countScore < 18 ? 2 : countScore < 20 ? 3 : 4;

        resources = new uint256[](resourceCount);
        for (uint256 i = 0; i < resourceCount; i++) {
            uint256 rarityRand = random(string(abi.encodePacked("RARITY", i, plotId.toString())));
            uint256 rarity = rarityRand % 101;

            // ~1% chance you have this
            if (rarity == 100) {
                resources[i] = INSANE[rarityRand % INSANE.length];
            }
            //  ~5% chance you have this
            else if (rarity > 95) {
                resources[i] = RARE[rarityRand % RARE.length];
            }
            // ~15% chance you have this
            else if (rarity > 80) {
                resources[i] = UNCOMMON[rarityRand % UNCOMMON.length];
            }
            // ~80% chance  you have this
            else {
                resources[i] = COMMON[rarityRand % COMMON.length];
            }
        }
    }

    /**
     * Starts mining a given plot
     * Outputs one of each resource found on that plot per period
     * with maximum of CLAIMS_PER_PLOT
     */
    function mine(uint256 plotId) external {
        // throws if not yet minted
        address owner = IERC721Upgradeable(marz).ownerOf(plotId);

        if (startTimes[plotId] == 0) {
            startTimes[plotId] = block.timestamp;
            claimed[plotId] = 1;

            // output one at the start for fun
            uint256[] memory resources = getResources(plotId);
            uint256[] memory amounts = new uint256[](resources.length);
            for (uint256 i = 0; i < resources.length; i++) {
                amounts[i] = 1;
            }
            _mintBatch(owner, resources, amounts, "");
        } else {
            uint256 numClaimed = claimed[plotId];
            require(numClaimed < CLAIMS_PER_PLOT, "Already claimed all resources");

            // add one because of the free initial mint
            uint256 totalMined = ((block.timestamp - startTimes[plotId]) /
                SECONDS_PER_MINING_PERIOD) + 1;
            if (totalMined > CLAIMS_PER_PLOT) {
                totalMined = CLAIMS_PER_PLOT;
            }

            uint256 numToClaim = totalMined - numClaimed;
            require(numToClaim > 0, "No resources to claim");

            claimed[plotId] = totalMined;

            uint256[] memory resources = getResources(plotId);
            uint256[] memory amounts = new uint256[](resources.length);
            for (uint256 i = 0; i < resources.length; i++) {
                amounts[i] = numToClaim;
            }
            _mintBatch(owner, resources, amounts, "");
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}
