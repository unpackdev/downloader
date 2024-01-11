// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import "./Ownable.sol";
import "./Strings.sol";
import "./MetadataHelpers.sol";
import "./Base64.sol";
import "./Gene.sol";
import "./IAlphaDogsAttributes.sol";
import "./IAlphaDogs.sol";

// Generated code. Do not modify!
contract AlphaDogsAttributes is IAlphaDogsAttributes, Ownable {
    using Strings for uint256;
    using Gene for uint256;

    error NotChanged();

    bytes32 private constant EMPTY_STRING = keccak256("");

    /// @notice the base URI of the nft image
    string public imageBaseURI;

    constructor(string memory _imageBaseURI) {
        imageBaseURI = _imageBaseURI;
    }

    function setBaseURI(string calldata _imageBaseURI) external onlyOwner {
        if (keccak256(bytes(_imageBaseURI)) == keccak256(bytes(imageBaseURI)))
            revert NotChanged();
        imageBaseURI = _imageBaseURI;
    }

    function tokenURI(
        uint256 gene,
        bytes memory name,
        string memory lore
    ) public view override returns (string memory) {
        string memory metadata = makeMetadata(gene, name, lore);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(metadata))
                )
            );
    }

    function makeMetadata(
        uint256 gene,
        bytes memory name,
        string memory lore
    ) internal view returns (string memory) {
        if (keccak256(bytes(name)) == EMPTY_STRING) {
            name = defaultName(gene);
        }

        return
            MetadataHelpers.makeMetadata(
                name,
                lore,
                abi.encodePacked(imageBaseURI, gene.toString()),
                makeAttributes(gene)
            );
    }

    function makeAttributes(uint256 gene)
        internal
        pure
        returns (string memory)
    {
        string[] memory attributes = new string[](8);
        attributes[0] = MetadataHelpers.makeAttributeJSON(
            "Generation",
            gene.isPuppy() ? "Puppy" : "Genesis"
        );

        attributes[1] = MetadataHelpers.makeAttributeJSON(
            "Background",
            getBackgroundValue(gene)
        );
        attributes[2] = MetadataHelpers.makeAttributeJSON(
            "Fur",
            getFurValue(gene)
        );
        attributes[3] = MetadataHelpers.makeAttributeJSON(
            "Neck",
            getNeckValue(gene)
        );
        attributes[4] = MetadataHelpers.makeAttributeJSON(
            "Eyes",
            getEyesValue(gene)
        );
        attributes[5] = MetadataHelpers.makeAttributeJSON(
            "Hat",
            getHatValue(gene)
        );
        attributes[6] = MetadataHelpers.makeAttributeJSON(
            "Mouth",
            getMouthValue(gene)
        );
        attributes[7] = MetadataHelpers.makeAttributeJSON(
            "Nosering",
            getNoseringValue(gene)
        );

        return MetadataHelpers.makeAttributeListJSON(attributes);
    }

    function defaultName(uint256 gene) internal pure returns (bytes memory) {
        if (gene.isPuppy()) {
            // Ignore puppy flag
            return
                abi.encodePacked(
                    "Puppy #",
                    (gene & 0xFFFFFFFFFFFFFF).toHexString()
                );
        }

        return abi.encodePacked("Genesis #", gene.toHexString());
    }

    function getBackgroundValue(uint256 gene)
        public
        pure
        returns (string memory)
    {
        uint256 chromossome = gene.getBackground();
        if (chromossome == 0) {
            return "Winter";
        }
        if (chromossome == 1) {
            return "Space";
        }
        if (chromossome == 2) {
            return "Night Forest";
        }
        if (chromossome == 3) {
            return "Dreams";
        }
        if (chromossome == 4) {
            return "Snowy Mountains";
        }
        if (chromossome == 5) {
            return "Stars";
        }
        if (chromossome == 6) {
            return "Inferno";
        }
        if (chromossome == 7) {
            return "Woods";
        }
        if (chromossome == 8) {
            return "Alpha System";
        }
        if (chromossome == 9) {
            return "Red Moon";
        }
        if (chromossome == 10) {
            return "Castle";
        }
        if (chromossome == 11) {
            return "Evening";
        }
        if (chromossome == 12) {
            return "Lightining";
        }
        if (chromossome == 13) {
            return "Pink Clouds";
        }
        if (chromossome == 14) {
            return "Night City";
        }
        if (chromossome == 15) {
            return "Underwater";
        }
        if (chromossome == 16) {
            return "Cute Sky";
        }
        if (chromossome == 17) {
            return "Alpha City";
        }
        if (chromossome == 18) {
            return "Cozy Room";
        }
        if (chromossome == 19) {
            return "Clouds";
        }
        if (chromossome == 20) {
            return "Crystal Cave";
        }
        return "";
    }

    function getFurValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getFur();
        if (chromossome == 0) {
            return "Golden";
        }
        if (chromossome == 1) {
            return "Red";
        }
        if (chromossome == 2) {
            return "Snow";
        }
        if (chromossome == 3) {
            return "Brown";
        }
        if (chromossome == 4) {
            return "Grey";
        }
        if (chromossome == 5) {
            return "Radioactive";
        }
        if (chromossome == 6) {
            return "Pink";
        }
        if (chromossome == 7) {
            return "Purple";
        }
        if (chromossome == 8) {
            return "Orange";
        }
        if (chromossome == 9) {
            return "Black";
        }
        if (chromossome == 10) {
            return "Blue";
        }
        if (chromossome == 11) {
            return "Dark";
        }
        return "";
    }

    function getNeckValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getNeck();
        if (chromossome == 0) {
            return "White Polo";
        }
        if (chromossome == 1) {
            return "Black Hoodie";
        }
        if (chromossome == 2) {
            return "Purple Hoodie";
        }
        if (chromossome == 3) {
            return "Blue Sports Hoodie";
        }
        if (chromossome == 4) {
            return "None";
        }
        if (chromossome == 5) {
            return "Blue Bowtie";
        }
        if (chromossome == 6) {
            return "Green Jacket";
        }
        if (chromossome == 7) {
            return "Stars";
        }
        if (chromossome == 8) {
            return "Red Scarf";
        }
        if (chromossome == 9) {
            return "Red Hoodie";
        }
        if (chromossome == 10) {
            return "Bronze Medal";
        }
        if (chromossome == 11) {
            return "Pattern";
        }
        if (chromossome == 12) {
            return "Silver Chain";
        }
        if (chromossome == 13) {
            return "Caesar";
        }
        if (chromossome == 14) {
            return "Golden Bowtie";
        }
        if (chromossome == 15) {
            return "Half Hoodie";
        }
        if (chromossome == 16) {
            return "Golden Chain";
        }
        if (chromossome == 17) {
            return "AD Golden Chain";
        }
        if (chromossome == 18) {
            return "Dog Tag";
        }
        if (chromossome == 19) {
            return "Golden Spikes";
        }
        if (chromossome == 20) {
            return "Silver Medal";
        }
        if (chromossome == 21) {
            return "Red Bowtie";
        }
        if (chromossome == 22) {
            return "Army Hoddie";
        }
        if (chromossome == 23) {
            return "Anime";
        }
        if (chromossome == 24) {
            return "Brown Jacket";
        }
        if (chromossome == 25) {
            return "Fire Hoodie";
        }
        if (chromossome == 26) {
            return "Leonhart Jacket";
        }
        if (chromossome == 27) {
            return "Red Polo";
        }
        if (chromossome == 28) {
            return "Red Jacket";
        }
        if (chromossome == 29) {
            return "Golden Medal";
        }
        if (chromossome == 30) {
            return "Tie Dye Hoddie";
        }
        if (chromossome == 31) {
            return "Emo Hoodie";
        }
        if (chromossome == 32) {
            return "AD Silver Chain";
        }
        if (chromossome == 33) {
            return "Purple Scarf";
        }
        return "";
    }

    function getEyesValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getEyes();
        if (chromossome == 0) {
            return "3D Glasses";
        }
        if (chromossome == 1) {
            return "ET Sunglasses";
        }
        if (chromossome == 2) {
            return "Embarrassed";
        }
        if (chromossome == 3) {
            return "Laser";
        }
        if (chromossome == 4) {
            return "Normal";
        }
        if (chromossome == 5) {
            return "Not Happy";
        }
        if (chromossome == 6) {
            return "Yellow Glasses";
        }
        if (chromossome == 7) {
            return "Purple";
        }
        if (chromossome == 8) {
            return "Gimme Food";
        }
        if (chromossome == 9) {
            return "Very Happy";
        }
        if (chromossome == 10) {
            return "Green Visor";
        }
        if (chromossome == 11) {
            return "Sweat Drop";
        }
        if (chromossome == 12) {
            return "Closed";
        }
        if (chromossome == 13) {
            return "Looking Up";
        }
        if (chromossome == 14) {
            return "Rainbow Glasses";
        }
        if (chromossome == 15) {
            return "Shy";
        }
        if (chromossome == 16) {
            return "Golden Monocle";
        }
        if (chromossome == 17) {
            return "Slim Green Glasses";
        }
        if (chromossome == 18) {
            return "Red Visor";
        }
        if (chromossome == 19) {
            return "High";
        }
        if (chromossome == 20) {
            return "Red Eyes";
        }
        if (chromossome == 21) {
            return "Golden Glasses";
        }
        if (chromossome == 22) {
            return "Angry";
        }
        if (chromossome == 23) {
            return "Shades";
        }
        if (chromossome == 24) {
            return "Crying";
        }
        if (chromossome == 25) {
            return "Golden Sunglasses";
        }
        if (chromossome == 26) {
            return "White Eyes";
        }
        if (chromossome == 27) {
            return "Edgy";
        }
        if (chromossome == 28) {
            return "Purple Glasses";
        }
        if (chromossome == 29) {
            return "Big Eyes";
        }
        if (chromossome == 30) {
            return "Slim Pink Glasses";
        }
        if (chromossome == 31) {
            return "Heart Glasses";
        }
        if (chromossome == 32) {
            return "Moon";
        }
        if (chromossome == 33) {
            return "Black Rim";
        }
        if (chromossome == 34) {
            return "Sleeping";
        }
        if (chromossome == 35) {
            return "Heart Eyes";
        }
        if (chromossome == 36) {
            return "Robot";
        }
        if (chromossome == 37) {
            return "Red Glasses";
        }
        if (chromossome == 38) {
            return "Distrust";
        }
        if (chromossome == 39) {
            return "Anime";
        }
        if (chromossome == 40) {
            return "Eye Patch";
        }
        if (chromossome == 41) {
            return "Scott's";
        }
        if (chromossome == 42) {
            return "VR";
        }
        return "";
    }

    function getHatValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getHat();
        if (chromossome == 0) {
            return "Airforce";
        }
        if (chromossome == 1) {
            return "Magical Crown";
        }
        if (chromossome == 2) {
            return "Blue Pirate";
        }
        if (chromossome == 3) {
            return "Poke Cap";
        }
        if (chromossome == 4) {
            return "Aviator";
        }
        if (chromossome == 5) {
            return "Purple Cap";
        }
        if (chromossome == 6) {
            return "Pink Pocker";
        }
        if (chromossome == 7) {
            return "Bitten";
        }
        if (chromossome == 8) {
            return "Purple Beanie";
        }
        if (chromossome == 9) {
            return "Goggles";
        }
        if (chromossome == 10) {
            return "Silver Earring";
        }
        if (chromossome == 11) {
            return "None";
        }
        if (chromossome == 12) {
            return "Alpha Cap";
        }
        if (chromossome == 13) {
            return "Trainer Cap";
        }
        if (chromossome == 14) {
            return "Creepy Mage";
        }
        if (chromossome == 15) {
            return "Black Bucket Hat";
        }
        if (chromossome == 16) {
            return "AD Cap";
        }
        if (chromossome == 17) {
            return "Red Mohawk";
        }
        if (chromossome == 18) {
            return "White Bucket Hat";
        }
        if (chromossome == 19) {
            return "Pink Cloth";
        }
        if (chromossome == 20) {
            return "Angel";
        }
        if (chromossome == 21) {
            return "Navy";
        }
        if (chromossome == 22) {
            return "Classic Witch";
        }
        if (chromossome == 23) {
            return "Straw Hat";
        }
        if (chromossome == 24) {
            return "Black Pocker";
        }
        if (chromossome == 25) {
            return "Red Dog Bucket";
        }
        if (chromossome == 26) {
            return "Ninja Bandana";
        }
        if (chromossome == 27) {
            return "Golden Skull";
        }
        if (chromossome == 28) {
            return "Caesar";
        }
        if (chromossome == 29) {
            return "Leprechaun";
        }
        if (chromossome == 30) {
            return "Black Fedora";
        }
        if (chromossome == 31) {
            return "Top Hat";
        }
        if (chromossome == 32) {
            return "Pirate";
        }
        if (chromossome == 33) {
            return "Black Cap";
        }
        if (chromossome == 34) {
            return "Concussion";
        }
        if (chromossome == 35) {
            return "Arrow";
        }
        if (chromossome == 36) {
            return "BrownGreen Cap";
        }
        if (chromossome == 37) {
            return "Yellow Beanie";
        }
        if (chromossome == 38) {
            return "Gray Fedora";
        }
        if (chromossome == 39) {
            return "Fairy";
        }
        if (chromossome == 40) {
            return "Wizzard";
        }
        if (chromossome == 41) {
            return "Red Pocker";
        }
        if (chromossome == 42) {
            return "Frankie";
        }
        if (chromossome == 43) {
            return "BlackRed Cap";
        }
        if (chromossome == 44) {
            return "Blue Cap";
        }
        if (chromossome == 45) {
            return "Black Beanie";
        }
        if (chromossome == 46) {
            return "White Fedora";
        }
        if (chromossome == 47) {
            return "Cowboy";
        }
        if (chromossome == 48) {
            return "Red Beanie";
        }
        if (chromossome == 49) {
            return "Green Beanie";
        }
        if (chromossome == 50) {
            return "Robin";
        }
        if (chromossome == 51) {
            return "Destroyed";
        }
        if (chromossome == 52) {
            return "Red Crown";
        }
        if (chromossome == 53) {
            return "Purple Pocker";
        }
        if (chromossome == 54) {
            return "Black Cloth";
        }
        if (chromossome == 55) {
            return "Golden Earring";
        }
        if (chromossome == 56) {
            return "Officer";
        }
        if (chromossome == 57) {
            return "Blue Beanie";
        }
        if (chromossome == 58) {
            return "Blue Bucket Hat";
        }
        if (chromossome == 59) {
            return "Green Mohawk";
        }
        if (chromossome == 60) {
            return "Red Pirate";
        }
        if (chromossome == 61) {
            return "Golden Egg";
        }
        if (chromossome == 62) {
            return "Green Pocker";
        }
        if (chromossome == 63) {
            return "Big Crown";
        }
        if (chromossome == 64) {
            return "Army Cap";
        }
        if (chromossome == 65) {
            return "Tie Dye Bucket Hat";
        }
        if (chromossome == 66) {
            return "Half Bucket hat";
        }
        if (chromossome == 67) {
            return "Anime Bucket Hat";
        }
        return "";
    }

    function getMouthValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getMouth();
        if (chromossome == 0) {
            return "Biscuit";
        }
        if (chromossome == 1) {
            return "Sticking Tongue";
        }
        if (chromossome == 2) {
            return "None";
        }
        if (chromossome == 3) {
            return "Premium Cigar";
        }
        if (chromossome == 4) {
            return "Tiny Fang";
        }
        if (chromossome == 5) {
            return "Smoking Pipe";
        }
        if (chromossome == 6) {
            return "Homemade";
        }
        if (chromossome == 7) {
            return "Blood Fangs";
        }
        if (chromossome == 8) {
            return "Ball";
        }
        if (chromossome == 9) {
            return "Vape";
        }
        if (chromossome == 10) {
            return "Coin";
        }
        if (chromossome == 11) {
            return "Steak";
        }
        if (chromossome == 12) {
            return "Bone";
        }
        if (chromossome == 13) {
            return "Drooling";
        }
        if (chromossome == 14) {
            return "Donut";
        }
        if (chromossome == 15) {
            return "Frisbee";
        }
        if (chromossome == 16) {
            return "Fang";
        }
        if (chromossome == 17) {
            return "Cigarrete";
        }
        return "";
    }

    function getNoseringValue(uint256 gene)
        public
        pure
        returns (string memory)
    {
        uint256 chromossome = gene.getNosering();
        if (chromossome == 0) {
            return "None";
        }
        if (chromossome == 1) {
            return "Golden";
        }
        if (chromossome == 2) {
            return "Bronze";
        }
        if (chromossome == 3) {
            return "Silver";
        }
        return "";
    }
}
