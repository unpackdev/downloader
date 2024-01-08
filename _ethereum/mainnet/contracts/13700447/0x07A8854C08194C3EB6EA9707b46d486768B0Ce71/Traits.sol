// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./IVampireGame.sol";
import "./TraitMetadata.sol";
import "./TraitDraw.sol";
import "./TokenTraits.sol";
import "./Base64.sol";
import "./ITraits.sol";

contract Traits is Ownable, ITraits {
    using Strings for uint256;

    /// ==== Structs

    /// @dev struct to store each trait name and base64 encoded image
    struct Trait {
        string name;
        string png;
    }

    /// ==== Immutable

    /// @notice traits mapping
    /// 0~8 Vampire; 9~17 Humans.
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;

    /// @dev mapping from predator index to predator score
    string[4] private predatorScores = ["8", "7", "6", "5"];

    IVampireGame public vgame;

    string unrevealedImage;

    // ==== Mutable

    constructor() {}

    /// ==== Internal

    /// @dev return the SVG of a Vampire
    /// make sure the token is actually a Vampire by checking tt.isVampire before calling this function
    /// @param tt the token traits
    /// @return the svg string of the vampire
    function makeVampireSVG(TokenTraits memory tt)
        internal
        view
        returns (string memory)
    {
        string[] memory images = new string[](5);
        images[3] = TraitDraw.drawImageTag(traitData[16][tt.cape].png);
        images[0] = TraitDraw.drawImageTag(traitData[9][tt.skin].png);
        images[2] = TraitDraw.drawImageTag(traitData[11][tt.clothes].png);
        images[1] = TraitDraw.drawImageTag(traitData[10][tt.face].png);
        images[4] = TraitDraw.drawImageTag(traitData[17][tt.predatorIndex].png);
        return TraitDraw.drawSVG(images);
    }

    /// @dev return the SVG of a Human
    /// make sure the token is actually a Human by checking tt.isVampire before calling this function
    /// @param tt the token traits
    /// @return the svg string of the human
    function makeHumanSVG(TokenTraits memory tt)
        internal
        view
        returns (string memory)
    {
        string[] memory images = new string[](7);
        images[0] = TraitDraw.drawImageTag(traitData[0][tt.skin].png);
        images[4] = TraitDraw.drawImageTag(traitData[4][tt.boots].png);
        images[3] = TraitDraw.drawImageTag(traitData[3][tt.pants].png);
        images[1] = TraitDraw.drawImageTag(traitData[1][tt.face].png);
        images[6] = TraitDraw.drawImageTag(traitData[6][tt.hair].png);
        images[2] = TraitDraw.drawImageTag(traitData[2][tt.clothes].png);
        images[5] = TraitDraw.drawImageTag(traitData[5][tt.accessory].png);
        return TraitDraw.drawSVG(images);
    }

    /// @dev return the metadata attributes of a Vampire
    /// make sure the token is actually a Vampire by checking tt.isVampire before calling this function
    /// @param tt the token traits
    /// @param genZero if the token is part of the first 20% tokens
    /// @return the JSON metadata string of the Vampire
    function makeVampireMetadata(TokenTraits memory tt, bool genZero)
        internal
        view
        returns (string memory)
    {
        string[] memory attributes = new string[](7);
        attributes[0] = TraitMetadata.makeAttributeJSON("Type", "Vampire");
        attributes[1] = TraitMetadata.makeAttributeJSON(
            "Generation",
            genZero ? "Gen 0" : "Gen 1"
        );
        attributes[2] = TraitMetadata.makeAttributeJSON(
            "Skin",
            traitData[0][tt.skin].name
        );
        attributes[3] = TraitMetadata.makeAttributeJSON(
            "Face",
            traitData[1][tt.face].name
        );
        attributes[4] = TraitMetadata.makeAttributeJSON(
            "Clothes",
            traitData[2][tt.clothes].name
        );
        attributes[5] = TraitMetadata.makeAttributeJSON(
            "Cape",
            traitData[7][tt.cape].name
        );
        attributes[6] = TraitMetadata.makeAttributeJSON(
            "Predator Score",
            predatorScores[tt.predatorIndex]
        );
        return TraitMetadata.makeAttributeListJSON(attributes);
    }

    /// @dev return the metadata attributes of a Human
    /// make sure the token is actually a Human by checking tt.isVampire before calling this function
    /// @param tt the token traits
    /// @param genZero if the token is part of the first 20% tokens
    /// @return the JSON metadata string of the Human
    function makeHumanMetadata(TokenTraits memory tt, bool genZero)
        internal
        view
        returns (string memory)
    {
        string[] memory attributes = new string[](9);
        attributes[0] = TraitMetadata.makeAttributeJSON("Type", "Human");
        attributes[1] = TraitMetadata.makeAttributeJSON(
            "Generation",
            genZero ? "Gen 0" : "Gen 1"
        );
        attributes[2] = TraitMetadata.makeAttributeJSON(
            "Skin",
            traitData[0][tt.skin].name
        );
        attributes[3] = TraitMetadata.makeAttributeJSON(
            "Face",
            traitData[1][tt.face].name
        );
        attributes[4] = TraitMetadata.makeAttributeJSON(
            "T-Shirt",
            traitData[2][tt.clothes].name
        );
        attributes[5] = TraitMetadata.makeAttributeJSON(
            "Pants",
            traitData[3][tt.pants].name
        );
        attributes[6] = TraitMetadata.makeAttributeJSON(
            "Boots",
            traitData[4][tt.boots].name
        );
        attributes[7] = TraitMetadata.makeAttributeJSON(
            "Accessory",
            traitData[5][tt.accessory].name
        );
        attributes[8] = TraitMetadata.makeAttributeJSON(
            "Hair",
            traitData[6][tt.hair].name
        );
        return TraitMetadata.makeAttributeListJSON(attributes);
    }

    /// ==== Public / View

    /// @notice return the svg for a specific tokenId
    /// using to help with testing and debugging
    /// @param tokenId the id of the token to draw the SVG
    /// @return string with the svg tag with all the token layers assembled
    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        TokenTraits memory tt = vgame.getTokenTraits(tokenId);
        return tt.isVampire ? makeVampireSVG(tt) : makeHumanSVG(tt);
    }

    /// @notice generates the metadata for a token
    /// @param tokenId the token id
    /// @return a string with a JSON array containing the traits
    function tokenMetadata(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        if (vgame.isTokenRevealed(tokenId)) {
            TokenTraits memory tt = vgame.getTokenTraits(tokenId);
            bool genZero = tokenId <= vgame.getGenZeroSupply();

            return
                TraitMetadata.makeMetadata(
                    abi.encodePacked(
                        tt.isVampire ? "Vampire #" : "Human #",
                        tokenId.toString()
                    ),
                    "The world has ended and humanity lost. Vampires rule over mankind with no mercy, locking Humans away in Blood Farms. This does not means that Vampires are safe, Farms can lose all Blood Bags or Coffins when other Vampires attack. All metadata and images are generated and stored on-chain.",
                    // create the svg > base64 encode > prefix with data:image/svg...
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            bytes(
                                tt.isVampire
                                    ? makeVampireSVG(tt)
                                    : makeHumanSVG(tt)
                            )
                        )
                    ),
                    tt.isVampire
                        ? makeVampireMetadata(tt, genZero)
                        : makeHumanMetadata(tt, genZero)
                );
        }

        return
            string(
                abi.encodePacked(
                    '{"name":"Coffin #',
                    tokenId.toString(),
                    '","description":"A coffin from The Vampire Game. Whats inside? A Human or a Vampire?","image":"',
                    unrevealedImage,
                    '"}'
                )
            );
    }

    /// @notice generate the on-chain token metadata
    /// @param tokenId the token id to be generated
    /// @return the metadata string using data:application/json;base64
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory metadata = tokenMetadata(tokenId);

        // create metadata |> base64 encode |> prefix with data:application/json...
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(metadata))
                )
            );
    }

    /// ==== Only Owner

    /// @notice sets the image that will be shown when nft is not yet revealed
    /// @param _unrevealedImage the image, could be a link or base64 encoded img
    function setUnrevealedImage(string calldata _unrevealedImage)
        external
        onlyOwner
    {
        unrevealedImage = _unrevealedImage;
    }

    /// @notice set the address of the VampireGame contract
    /// @param vgameAddress the VampireGame contract address
    function setVampireGame(address vgameAddress) external onlyOwner {
        vgame = IVampireGame(vgameAddress);
    }

    /// @notice Upload trait variants for each trait type
    /// list of trait types:
    /// 0  - Human - Skin
    /// 1  - Human - Face
    /// 2  - Human - T-Shirt
    /// 3  - Human - Pants
    /// 4  - Human - Boots
    /// 5  - Human - Accessory
    /// 6  - Human - Hair
    /// 7  - NONE
    /// 8  - NONE
    /// 9  - Vampire - Skin
    /// 10 - Vampire - Face
    /// 11 - Vampire - Clothes
    /// 12 - NONE
    /// 13 - NONE
    /// 14 - NONE
    /// 15 - NONE
    /// 16 - Vampire - Cape
    /// 17 - Vampire - Predator Index
    /// @param traitType the index of the traitType.
    /// @param traitIds the list of ids of each trait
    /// @param traits the list of traits with name and base64 encoded png. Should match the length of traitIds.
    function setTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        Trait[] calldata traits
    ) external onlyOwner {
        require(traitIds.length == traits.length, "INPUTS_DIFFERENT_LENGTH");
        for (uint256 i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }
}
