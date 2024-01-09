// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title MEV Army On-Chain Trait Data
/// @author x0r

import "./Ownable.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    .............+*****;;*+..........+*****;.*+....;******;.***********+...;******+............*******............    //
//    .............@#####;;#&;........;@####@;+#@....+##&###+;&######&#&#%...;&#####&;..........!#&####?............    //
//    .............@#####;;&#!........!#####*.$&@....+##&###+;&##########%....!######?.........;&#&&##@;............    //
//    .............@#&&#&;;&#&;......;&####@.*##@....+##&&&#+.!??????????*.....$######+........?######+.............    //
//    .............@####&;;###?......?#####*.$##@....+#&@###+..................+######%.......+######?..............    //
//    .............@#&#&&;;###&;....;&####$.*##&@....+######+.!!?????????*......?######+......%#####@;..............    //
//    .............@##&#&;;#&&#?....?#####+.@#&&@....+######+;@&##&&&&###%......;@#####$.....+######+...............    //
//    .............@##&#&;;#####;..;&####%.*####@....+###&&#+;&###@###&##%.......+######*....@#####?................    //
//    .............@#&@#&;;&####%..%#####+.@###&@....+######+.***********+........?#####@;..!#####@;................    //
//    .............@####&;.%#####+;&@###%.;&####@....+######+.....................;&#####!.;&#####*.................    //
//    .............@##&&&;.;&####%%#&&#&;.;&####@....+######+......................*###&#@;*#####?..................    //
//    .............@####&;..?####&@&#&#?..;&####@....+######+.......................$#####!.@###@;..................    //
//    .............@####&;..;&###@&###&;..;&####@....+######+.!!!!!!!!!!?*..........;&#&@#&;*###*...................    //
//    .............@####&;...?###&&###!...;&####@....+######+;&##########%...........!#####?.$#%....................    //
//    .............@####&;...;&##@$$#&;...;&####@....+######+;&#####&##&#%............@#####++@;....................    //
//    .............+*****.....+****+*+.....*****+....;******;.***********+............;!***!;.;.....................    //
//    ..............................................................................................................    //
//    .................;!!!...............+!!!!!!!*+;...........;!!!!;...;!!!!;.........+!!*.....;!!!;..............    //
//    .................$###?..............%###&&&###@+..........;####%...!####!.........;@##?...+&##*...............    //
//    ................?##@##*.............%##*...;!##$..........;##&##+..@#&##!..........;%##%.+&#&+................    //
//    ...............+##%;&#&;............%##?+++*%##?..........;##%@#%.*##?##!............?##$&#@;.................    //
//    ..............;@#&;.*##$............%#######&$*...........;##%!##;@#$*##!.............!###$;..................    //
//    ..............%###&&&###?...........%##!;*$##%;...........;##%;&#@##+*##!..............$##+...................    //
//    .............!##$?????&##+..........%##*...?##&+..........;##%.?###@.*##!..............$##+...................    //
//    ............+&#&;.....+##@;.........%##*....!##&*.........;##%.;&##*.*##*..............$##+...................    //
//    ............;++;.......+++;.........;++;.....;+++..........++;..+++..;++;..............+++;...................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//    ..............................................................................................................    //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MEVArmyTraitData is Ownable {

    address public constant MEV_ARMY_NFT_CONTRACT = 0x99cd66b3D67Cd65FbAfbD2fD49915002d4a2E0F2;

    struct EditionIndices {
        uint8 binary;
        uint8 legion;
        uint8 light;
        uint8 mouth;
        uint8 helmet;
        uint8 eyes;
        uint8 faces;
    }
    
    // offset each trait list by an empty string so no need to subtract by 1 when unpacking traits
    string [] public binary = ["", "1", "0"];
    string [] public legion = ["", "generalized frontrunner", "searcher", "time bandit", "sandwicher", "backrunner", "liquidator"];
    string [] public light = ["", "x0r spinning light","triangle light","triple light","eth light","double band light","one band light","basic light","x0r static light"];
    string [] public mouth = ["", "skull mouth","toothless mouth","electric mouth","lego mouth","muzzle mouth","fang mouth","o mouth","smile mouth","jagged mouth","box mouth","v mouth","stitched mouth"];
    string [] public helmet = ["", "elite three prong helmet","elite one prong","one prong helmet","three prong helmet","basic helmet"];
    string [] public eyes = ["", "angry eyes","x eyes","fly eyes","cry eyes","circle eyes","eth eyes","snake eyes","spider pupil eyes","closed eyes","glass eyes","glass rim eyes","scoop eyes","spider eyes","wink eyes","moon eyes","eth pupil eyes"];
    string [] public faces = ["", "skull face","hollow face","mushroom face","octa face","cube face","diamond face","hourglass face","lego face","arrow face"];

    mapping(uint256 => uint256) public EDITION_SLOTS;
    

    /** 
    * @dev Get the raw trait indices for a given tokenId
    * @param tokenId of a MEV Army NFT 
    * @return An array of integers that are indices for the trait arrays stored in this contract
    *   example: [ binary index, legion index, light index, mouth index, helmet index, eyes index, faces index ]
    **/
    function getTraitsIndices(uint256 tokenId) public view returns (EditionIndices memory){
        require(tokenId > 0 && tokenId < 10000, "nonexistent tokenId");

        // calculate the slot for a given token id
        uint256 slotForTokenId = (tokenId - 1) >> 2;

        // calculate the index within a slot for a given token id
        uint256 slotIndex = ((tokenId - 1) % 4);

        // get the slot from storage and unpack it
        uint256 slot = EDITION_SLOTS[slotForTokenId];
        uint256 unpackedSlot = _unPackSlot(slot, slotIndex);

        // get the edition from the slot and unpack it
        return _unPackEdition(unpackedSlot);
    }



    /** 
    * @dev Get the decoded traits for a given tokenId
    * @param tokenId of a MEV Army NFT 
    * @return An array of strings containing each trait
    **/
    function getTraitsDecoded(uint256 tokenId) external view returns (string [7] memory){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);

        return [
            binary[unpackedEdition.binary],
            legion[unpackedEdition.legion],
            light[unpackedEdition.light],
            mouth[unpackedEdition.mouth],
            helmet[unpackedEdition.helmet],
            eyes[unpackedEdition.eyes],
            faces[unpackedEdition.faces] 
        ];
    }



    ////// FUNCTIONS TO GET INDIVIDUAL TRAITS  //////

    function getBinaryDecoded(uint256 tokenId) external view returns (string memory){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return binary[unpackedEdition.binary];
    }
    function getBinaryIndex(uint256 tokenId) external view returns (uint256){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return unpackedEdition.binary;
    }


    function getLegionDecoded(uint256 tokenId) external view returns (string memory){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return legion[unpackedEdition.legion];
    }
    function getLegionIndex(uint256 tokenId) external view returns (uint256){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return unpackedEdition.legion;
    }


    function getLightDecoded(uint256 tokenId) external view returns (string memory){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return light[unpackedEdition.light];
    }
    function getLightIndex(uint256 tokenId) external view returns (uint256){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return unpackedEdition.light;
    }


    function getMouthDecoded(uint256 tokenId) external view returns (string memory){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return mouth[unpackedEdition.mouth];
    }
    function getMouthIndex(uint256 tokenId) external view returns (uint256){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return unpackedEdition.mouth;
    }


    function getHelmetDecoded(uint256 tokenId) external view returns (string memory){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return helmet[unpackedEdition.helmet];
    }
    function getHelmetIndex(uint256 tokenId) external view returns (uint256){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return unpackedEdition.helmet;
    }


    function getEyesDecoded(uint256 tokenId) external view returns (string memory){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return eyes[unpackedEdition.eyes];
    }
    function getEyesIndex(uint256 tokenId) external view returns (uint256){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return unpackedEdition.eyes;
    }


    function getFacesDecoded(uint256 tokenId) external view returns (string memory){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return faces[unpackedEdition.faces];
    }
    function getFacesIndex(uint256 tokenId) external view returns (uint256){
        EditionIndices memory unpackedEdition = getTraitsIndices(tokenId);
        return unpackedEdition.faces;
    }



    /**
    * @dev Unpack a slot. Each slot contains 4 packed trait arrays for 4 MEV Army editions.
    *   Each packed trait array is represented as a 64-bit unsigned integer. 
    **/
    function _unPackSlot(uint256 slot, uint256 slotIndex) internal pure returns (uint256){
        return (slot >> (slotIndex * 64)) & uint256(type(uint64).max);
    }



    /**
    * @dev Unpack an edition. Each edition contains 7 traits packed into an unsigned integer.
    *   Each packed trait is an 8-bit unsigned integer.
    **/

    function _unPackEdition(uint256 edition) internal pure returns (EditionIndices memory){
        return EditionIndices(
            uint8((edition) & uint256(type(uint8).max)),
            uint8((edition >> 8) & uint256(type(uint8).max)),
            uint8((edition >> 16) & uint256(type(uint8).max)),
            uint8((edition >> 24) & uint256(type(uint8).max)),
            uint8((edition >> 32) & uint256(type(uint8).max)),
            uint8((edition >> 40) & uint256(type(uint8).max)),
            uint8((edition >> 48) & uint256(type(uint8).max))
        );
    }



    ////// SETUP FUNCTIONS //////

    function storeEditionSlots(uint256 startIndex, uint256 [] calldata editionSlots) external onlyOwner {

        for(uint256 i = 0; i < editionSlots.length; i++){
            EDITION_SLOTS[startIndex] = editionSlots[i];
            startIndex++;
        }

    }


    function setEditionSlot(uint256 index, uint256 editionSlot) external onlyOwner {
        EDITION_SLOTS[index] = editionSlot;
    }


    function setTraitStrings(
        string [] memory _faces,
        string [] memory _eyes,
        string [] memory _helmet,
        string [] memory _mouth,
        string [] memory _light,
        string [] memory _legion,
        string [] memory _binary
        ) external onlyOwner {
            if (_faces.length > 0){ faces = _faces; }
            if (_eyes.length > 0){ eyes = _eyes; }
            if (_helmet.length > 0){ helmet = _helmet; }
            if (_mouth.length > 0){ mouth = _mouth; }
            if (_light.length > 0){ light = _light; }
            if (_legion.length > 0){ legion = _legion; }
            if (_binary.length > 0){ binary = _binary; }
        }


}

