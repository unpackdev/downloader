//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainScoutsExtension.sol";
import "./IUtilityERC20.sol";
import "./Rarities.sol";
import "./Rng.sol";

contract Reroller is ChainScoutsExtension {
    using RngLibrary for Rng;

    Rng internal staticRng;
    IUtilityERC20 public token;
    uint256 public accessoryCost = 80 ether;
    uint256 public backAccessoryCost = type(uint256).max;
    uint256 public backgroundCost = 80 ether;
    uint256 public clothingCost = 80 ether;

    constructor(IUtilityERC20 _token) {
        token = _token;
        enabled = false;
    }

    function extensionKey() public pure override returns (string memory) {
        return "reroller";
    }

    function adminSetAccessoryCostWei(uint256 _wei) external onlyAdmin {
        accessoryCost = _wei;
    }

    function adminSetBackAccessoryCostWei(uint256 _wei) external onlyAdmin {
        backAccessoryCost = _wei;
    }

    function adminSetBackgroundCostWei(uint256 _wei) external onlyAdmin {
        backgroundCost = _wei;
    }

    function adminSetClothingCostWei(uint256 _wei) external onlyAdmin {
        clothingCost = _wei;
    }

    function getRandom(
        Rng memory rng,
        uint256 raritySum,
        uint16[] memory rarities
    ) internal view returns (uint256) {
        uint256 rn = rng.generate(0, raritySum - 1);

        for (uint256 i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return i;
            }
            rn -= rarities[i];
        }
        revert("rn not selected");
    }

    function rerollAccessory(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, accessoryCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.accessory();
        uint256 total = 10000;

        total -= rarities[uint256(md.accessory)];
        rarities[uint256(md.accessory)] = 0;

        if (md.backaccessory == BackAccessory.MINER) {
            total -= rarities[uint256(Accessory.CUBAN_LINK_GOLD_CHAIN)];
            rarities[uint256(Accessory.CUBAN_LINK_GOLD_CHAIN)] = 0;
        }

        if (
            md.clothing == Clothing.FLEET_UNIFORM__BLUE ||
            md.clothing == Clothing.FLEET_UNIFORM__RED
        ) {
            Accessory[4] memory xs = [
                Accessory.AMULET,
                Accessory.CUBAN_LINK_GOLD_CHAIN,
                Accessory.FANNY_PACK,
                Accessory.GOLDEN_CHAIN
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        } else if (
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Accessory.GOLD_EARRINGS)];
            rarities[uint256(Accessory.GOLD_EARRINGS)] = 0;
        }

        md.accessory = Accessory(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollBackAccessory(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, backAccessoryCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.backaccessory();
        uint256 total = 10000;

        total -= rarities[uint256(md.backaccessory)];
        rarities[uint256(md.backaccessory)] = 0;

        if (md.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN) {
            total -= rarities[uint256(BackAccessory.MINER)];
            rarities[uint256(BackAccessory.MINER)] = 0;
        }

        if (md.head == Head.ENERGY_FIELD) {
            total -= rarities[uint256(BackAccessory.PATHFINDER)];
            rarities[uint256(BackAccessory.PATHFINDER)] = 0;
        }

        md.backaccessory = BackAccessory(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollBackground(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, backgroundCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.background();
        uint256 total = 10000;

        total -= rarities[uint256(md.background)];
        rarities[uint256(md.background)] = 0;

        if (
            md.clothing == Clothing.FLEET_UNIFORM__BLUE ||
            md.clothing == Clothing.MARTIAL_SUIT ||
            md.clothing == Clothing.THUNDERDOME_ARMOR ||
            md.head == Head.ENERGY_FIELD
        ) {
            total -= rarities[uint256(Background.CITY__PURPLE)];
            rarities[uint256(Background.CITY__PURPLE)] = 0;
        }

        if (md.head == Head.ENERGY_FIELD) {
            total -= rarities[uint256(Background.CITY__RED)];
            rarities[uint256(Background.CITY__RED)] = 0;
        }

        md.background = Background(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollClothing(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, clothingCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.clothing();
        uint256 total = 10000;

        total -= rarities[uint256(md.clothing)];
        rarities[uint256(md.clothing)] = 0;

        if (
            md.accessory == Accessory.AMULET ||
            md.accessory == Accessory.CUBAN_LINK_GOLD_CHAIN ||
            md.accessory == Accessory.FANNY_PACK ||
            md.accessory == Accessory.GOLDEN_CHAIN ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            Clothing[2] memory c = [
                Clothing.FLEET_UNIFORM__BLUE,
                Clothing.FLEET_UNIFORM__RED
            ];

            for (uint256 i = 0; i < c.length; ++i) {
                uint256 cdx = uint256(c[i]);
                total -= rarities[cdx];
                rarities[cdx] = 0;
            }
        }

        if (md.background == Background.CITY__PURPLE) {
            Clothing[3] memory c = [
                Clothing.FLEET_UNIFORM__BLUE,
                Clothing.MARTIAL_SUIT,
                Clothing.THUNDERDOME_ARMOR
            ];

            for (uint256 i = 0; i < c.length; ++i) {
                uint256 cdx = uint256(c[i]);
                total -= rarities[cdx];
                rarities[cdx] = 0;
            }
        }

        if (uint256(md.background) == 10 || uint256(md.background) == 19) {
            total -= rarities[uint256(Clothing.MARTIAL_SUIT)];
            rarities[uint256(Clothing.MARTIAL_SUIT)] = 0;
        }

        if (uint256(md.background) == 10) {
            total -= rarities[uint256(Clothing.THUNDERDOME_ARMOR)];
            rarities[uint256(Clothing.THUNDERDOME_ARMOR)] = 0;
        }

        md.clothing = Clothing(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }
}

contract Reroller2 is ChainScoutsExtension {
    using RngLibrary for Rng;

    Rng internal staticRng;
    IUtilityERC20 public token;
    uint256 public eyesCost = 80 ether;
    uint256 public furCost = 80 ether;
    uint256 public headCost = 80 ether;
    uint256 public mouthCost = 80 ether;

    constructor(IUtilityERC20 _token) {
        token = _token;
        enabled = false;
    }

    function extensionKey() public pure override returns (string memory) {
        return "reroller2";
    }

    function adminSetEyesCostWei(uint256 _wei) external onlyAdmin {
        eyesCost = _wei;
    }

    function adminSetFurCostWei(uint256 _wei) external onlyAdmin {
        furCost = _wei;
    }

    function adminSetHeadCostWei(uint256 _wei) external onlyAdmin {
        headCost = _wei;
    }

    function adminSetMouthCostWei(uint256 _wei) external onlyAdmin {
        mouthCost = _wei;
    }

    function getRandom(
        Rng memory rng,
        uint256 raritySum,
        uint16[] memory rarities
    ) internal view returns (uint256) {
        uint256 rn = rng.generate(0, raritySum - 1);

        for (uint256 i = 0; i < rarities.length; ++i) {
            if (rarities[i] > rn) {
                return i;
            }
            rn -= rarities[i];
        }
        revert("rn not selected");
    }

    function rerollEyes(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, eyesCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.eyes();
        uint256 total = 10000;

        total -= rarities[uint256(md.eyes)];
        rarities[uint256(md.eyes)] = 0;

        if (
            md.head == Head.BANDANA ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.DORAG ||
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.BANANA ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.PILOT_OXYGEN_MASK ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            Eyes[2] memory xs = [Eyes.BLUE_LASER, Eyes.RED_LASER];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            Eyes[3] memory xs = [
                Eyes.BLUE_SHADES,
                Eyes.DARK_SUNGLASSES,
                Eyes.GOLDEN_SHADES
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.DORAG ||
            md.head == Head.HEADBAND ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            Eyes[3] memory xs = [
                Eyes.HUD_GLASSES,
                Eyes.HIVE_GOGGLES,
                Eyes.WHITE_SUNGLASSES
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.CAP ||
            md.head == Head.LEATHER_COWBOY_HAT ||
            md.head == Head.PURPLE_COWBOY_HAT
        ) {
            total -= rarities[uint256(Eyes.HAPPY)];
            rarities[uint256(Eyes.HAPPY)] = 0;
        }

        if (
            md.head == Head.BANDANA ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.DORAG ||
            md.head == Head.HEADBAND ||
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Eyes.HIPSTER_GLASSES)];
            rarities[uint256(Eyes.HIPSTER_GLASSES)] = 0;
        }

        if (md.head == Head.SPACESUIT_HELMET) {
            Eyes[2] memory xs = [
                Eyes.MATRIX_GLASSES,
                Eyes.NIGHT_VISION_GOGGLES
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.BANDANA ||
            md.head == Head.DORAG ||
            md.head == Head.HEADBAND ||
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.PILOT_OXYGEN_MASK ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Eyes.NOUNS_GLASSES)];
            rarities[uint256(Eyes.NOUNS_GLASSES)] = 0;
        }

        if (
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO
        ) {
            total -= rarities[uint256(Eyes.PINCENEZ)];
            rarities[uint256(Eyes.PINCENEZ)] = 0;
        }

        if (
            md.head == Head.DORAG ||
            md.head == Head.HEADBAND ||
            md.head == Head.SPACESUIT_HELMET ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Eyes.SPACE_VISOR)];
            rarities[uint256(Eyes.SPACE_VISOR)] = 0;
        }

        if (md.head == Head.SPACESUIT_HELMET || md.mouth == Mouth.MASK) {
            total -= rarities[uint256(Eyes.SUNGLASSES)];
            rarities[uint256(Eyes.SUNGLASSES)] = 0;
        }

        md.eyes = Eyes(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollFur(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, furCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.fur();
        uint256 total = 10000;

        md.fur = Fur(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollHead(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, headCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.head();
        uint256 total = 10000;

        total -= rarities[uint256(md.head)];
        rarities[uint256(md.head)] = 0;

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Head.BANDANA)];
            rarities[uint256(Head.BANDANA)] = 0;
        }

        if (md.eyes == Eyes.HAPPY) {
            total -= rarities[uint256(Head.CAP)];
            rarities[uint256(Head.CAP)] = 0;
        }

        if (
            md.accessory == Accessory.GOLD_EARRINGS ||
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.CIGAR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.PILOT_OXYGEN_MASK ||
            md.mouth == Mouth.PIPE ||
            md.mouth == Mouth.RED_RESPIRATOR ||
            md.mouth == Mouth.VAPE
        ) {
            Head[2] memory xs = [
                Head.CYBER_HELMET__BLUE,
                Head.CYBER_HELMET__RED
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.HUD_GLASSES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.HIVE_GOGGLES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.eyes == Eyes.WHITE_SUNGLASSES ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.RED_RESPIRATOR
        ) {
            total -= rarities[uint256(Head.DORAG)];
            rarities[uint256(Head.DORAG)] = 0;
        }

        if (
            md.backaccessory == BackAccessory.PATHFINDER ||
            md.background == Background.CITY__PURPLE ||
            md.background == Background.CITY__RED
        ) {
            total -= rarities[uint256(Head.ENERGY_FIELD)];
            rarities[uint256(Head.ENERGY_FIELD)] = 0;
        }

        if (
            md.eyes == Eyes.HUD_GLASSES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.HIVE_GOGGLES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.eyes == Eyes.WHITE_SUNGLASSES
        ) {
            total -= rarities[uint256(Head.HEADBAND)];
            rarities[uint256(Head.HEADBAND)] = 0;
        }

        if (md.eyes == Eyes.HAPPY) {
            Head[2] memory xs = [
                Head.LEATHER_COWBOY_HAT,
                Head.PURPLE_COWBOY_HAT
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.accessory == Accessory.GOLD_EARRINGS ||
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.BLUE_SHADES ||
            md.eyes == Eyes.DARK_SUNGLASSES ||
            md.eyes == Eyes.GOLDEN_SHADES ||
            md.eyes == Eyes.HUD_GLASSES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.HIVE_GOGGLES ||
            md.eyes == Eyes.MATRIX_GLASSES ||
            md.eyes == Eyes.NIGHT_VISION_GOGGLES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.PINCENEZ ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.eyes == Eyes.SUNGLASSES ||
            md.eyes == Eyes.WHITE_SUNGLASSES ||
            md.mouth == Mouth.BANANA ||
            md.mouth == Mouth.CHROME_RESPIRATOR ||
            md.mouth == Mouth.CIGAR ||
            md.mouth == Mouth.GREEN_RESPIRATOR ||
            md.mouth == Mouth.MAGENTA_RESPIRATOR ||
            md.mouth == Mouth.MASK ||
            md.mouth == Mouth.MEMPO ||
            md.mouth == Mouth.NAVY_RESPIRATOR ||
            md.mouth == Mouth.PILOT_OXYGEN_MASK ||
            md.mouth == Mouth.PIPE ||
            md.mouth == Mouth.RED_RESPIRATOR ||
            md.mouth == Mouth.VAPE
        ) {
            total -= rarities[uint256(Head.SPACESUIT_HELMET)];
            rarities[uint256(Head.SPACESUIT_HELMET)] = 0;
        }

        md.head = Head(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }

    function rerollMouth(uint256 tokenId)
        external
        canAccessToken(tokenId)
        whenEnabled
    {
        token.burn(msg.sender, mouthCost);

        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
            tokenId
        );
        Rng memory rng = staticRng;

        uint16[] memory rarities = Rarities.mouth();
        uint256 total = 10000;

        total -= rarities[uint256(md.mouth)];
        rarities[uint256(md.mouth)] = 0;

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.RED_LASER ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Mouth.BANANA)];
            rarities[uint256(Mouth.BANANA)] = 0;
        }

        if (
            md.clothing == Clothing.FLEET_UNIFORM__BLUE ||
            md.clothing == Clothing.FLEET_UNIFORM__RED ||
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.BLUE_SHADES ||
            md.eyes == Eyes.DARK_SUNGLASSES ||
            md.eyes == Eyes.GOLDEN_SHADES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.head == Head.BANDANA ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.DORAG ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            Mouth[5] memory xs = [
                Mouth.CHROME_RESPIRATOR,
                Mouth.GREEN_RESPIRATOR,
                Mouth.MAGENTA_RESPIRATOR,
                Mouth.NAVY_RESPIRATOR,
                Mouth.RED_RESPIRATOR
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            Mouth[3] memory xs = [Mouth.CIGAR, Mouth.PIPE, Mouth.VAPE];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            uint256(md.eyes) == 0 ||
            uint256(md.eyes) == 13 ||
            uint256(md.eyes) == 25 ||
            uint256(md.eyes) == 26 ||
            uint256(md.eyes) == 27 ||
            uint256(md.eyes) == 28 ||
            uint256(md.eyes) == 30 ||
            uint256(md.eyes) == 32 ||
            uint256(md.head) == 14 ||
            uint256(md.head) == 18 ||
            uint256(md.head) == 19
        ) {
            Mouth[5] memory xs = [
                Mouth.CHROME_RESPIRATOR,
                Mouth.GREEN_RESPIRATOR,
                Mouth.MAGENTA_RESPIRATOR,
                Mouth.NAVY_RESPIRATOR,
                Mouth.RED_RESPIRATOR
            ];
            for (uint256 i = 0; i < xs.length; ++i) {
                total -= rarities[uint256(xs[i])];
                rarities[uint256(xs[i])] = 0;
            }
        }

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.BLUE_SHADES ||
            md.eyes == Eyes.DARK_SUNGLASSES ||
            md.eyes == Eyes.GOLDEN_SHADES ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.PINCENEZ ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SUNGLASSES ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Mouth.MASK)];
            rarities[uint256(Mouth.MASK)] = 0;
        }

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.HIPSTER_GLASSES ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.PINCENEZ ||
            md.eyes == Eyes.RED_LASER ||
            md.eyes == Eyes.SPACE_VISOR ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Mouth.MEMPO)];
            rarities[uint256(Mouth.MEMPO)] = 0;
        }

        if (
            md.eyes == Eyes.BLUE_LASER ||
            md.eyes == Eyes.NOUNS_GLASSES ||
            md.eyes == Eyes.RED_LASER ||
            md.head == Head.CYBER_HELMET__BLUE ||
            md.head == Head.CYBER_HELMET__RED ||
            md.head == Head.SPACESUIT_HELMET
        ) {
            total -= rarities[uint256(Mouth.PILOT_OXYGEN_MASK)];
            rarities[uint256(Mouth.PILOT_OXYGEN_MASK)] = 0;
        }

        md.mouth = Mouth(getRandom(rng, total, rarities));

        staticRng = rng;
        chainScouts.adminSetChainScoutMetadata(tokenId, md);
    }
}
