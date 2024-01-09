// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//________________________________________________________________   .¿yy¿.   __
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM```````/MMM\\\\\  \\$$$$$$S/  .
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM``   `/  yyyy    ` _____J$$$*^^*/%#//
//MMMMMMMMMMMMMMMMMMMYYYMMM````      `\/  .¿yü  /  $ùpüüü%%% | ``|//|` __
//MMMMMYYYYMMMMMMM/`     `| ___.¿yüy¿.  .d$$$$  /  $$$$SSSSM |   | ||  MMNNNNNNM
//M/``      ``\/`  .¿ù%%/.  |.d$$$$$$$b.$$$*°^  /  o$$$  __  |   | ||  MMMMMMMMM
//M   .¿yy¿.     .dX$$$$$$7.|$$$$"^"$$$$$$o`  /MM  o$$$  MM  |   | ||  MMYYYYYYM
//  \\$$$$$$S/  .S$$o"^"4$$$$$$$` _ `SSSSS\        ____  MM  |___|_||  MM  ____
// J$$$*^^*/%#//oSSS`    YSSSSSS  /  pyyyüüü%%%XXXÙ$$$$  MM  pyyyyyyy, `` ,$$$o
//.$$$` ___     pyyyyyyyyyyyy//+  /  $$$$$$SSSSSSSÙM$$$. `` .S&&T$T$$$byyd$$$$\
//\$$7  ``     //o$$SSXMMSSSS  |  /  $$/&&X  _  ___ %$$$byyd$$$X\$`/S$$$$$$$S\
//o$$l   .\\YS$$X>$X  _  ___|  |  /  $$/%$$b.,.d$$$\`7$$$$$$$$7`.$   `"***"`  __
//o$$l  __  7$$$X>$$b.,.d$$$\  |  /  $$.`7$$$$$$$$%`  `*+SX+*|_\\$  /.     ..\MM
//o$$L  MM  !$$$$\$$$$$$$$$%|__|  /  $$// `*+XX*\'`  `____           ` `/MMMMMMM
///$$X, `` ,S$$$$\ `*+XX*\'`____  /  %SXX .      .,   NERV   ___.¿yüy¿.   /MMMMM
// 7$$$byyd$$$>$X\  .,,_    $$$$  `    ___ .y%%ü¿.  _______  $.d$$$$$$$S.  `MMMM
// `/S$$$$$$$\\$J`.\\$$$ :  $\`.¿yüy¿. `\\  $$$$$$S.//XXSSo  $$$$$"^"$$$$.  /MMM
//y   `"**"`"Xo$7J$$$$$\    $.d$$$$$$$b.    ^``/$$$$.`$$$$o  $$$$\ _ 'SSSo  /MMM
//M/.__   .,\Y$$$\\$$O` _/  $d$$$*°\ pyyyüüü%%%W $$$o.$$$$/  S$$$. `  S$To   MMM
//MMMM`  \$P*$$X+ b$$l  MM  $$$$` _  $$$$$$SSSSM $$$X.$T&&X  o$$$. `  S$To   MMM
//MMMX`  $<.\X\` -X$$l  MM  $$$$  /  $$/&&X      X$$$/$/X$$dyS$$>. `  S$X%/  `MM
//MMMM/   `"`  . -$$$l  MM  yyyy  /  $$/%$$b.__.d$$$$/$.'7$$$$$$$. `  %SXXX.  MM
//MMMMM//   ./M  .<$$S, `` ,S$$>  /  $$.`7$$$$$$$$$$$/S//_'*+%%XX\ `._       /MM
//MMMMMMMMMMMMM\  /$$$$byyd$$$$\  /  $$// `*+XX+*XXXX      ,.      .\MMMMMMMMMMM
//GENETIC/MMMMM\.  /$$$$$$$$$$\|  /  %SXX  ,_  .      .\MMMMMMMMMMMMMMMMMMMMMMMM
//CHAIN/MMMMMMMM/__  `*+YY+*`_\|  /_______//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//------------------------------------------------------------------------------
// Genetic Chain: GeneticChainMetadata
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "./GeneticChain721.sol";

//------------------------------------------------------------------------------
// GeneticChainMetadata
//------------------------------------------------------------------------------

/**
 * @title GeneticChainMetadata
 * Holds all required metadata for Genetic Chain projects.
 */
abstract contract GeneticChainMetadata is GeneticChain721
{

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------

    uint256 constant private kActiveIdx      = 0;
    uint256 constant private kDeactivatedIdx = 1;

    uint256 constant public projectId  = 8;
    string constant public artist      = "Alejandro Mirabal";
    string constant public description = "The Rainbow7 Pass provides holders with membership to the Genetic Chain Platform.  Passes will unlock access to pre-sales, free mints, future GC programs, as well as access to live events at the GC gallery.";

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    string[2] private _tokenIpfsHashes;
    string private _baseUri;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        address spirals,
        string[2] memory tokenIpfsHashes_,
        string memory baseUri_,
        uint256 seed,
        address proxyRegistryAddress)
        GeneticChain721(
          spirals,
          seed,
          proxyRegistryAddress)
    {
        _tokenIpfsHashes = tokenIpfsHashes_;
        _baseUri         = baseUri_;
    }

    //-------------------------------------------------------------------------
    // functions
    //-------------------------------------------------------------------------

    /**
     * Each pass is associated with the spiral it was mint to.
     */
    function isActive(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (bool)
    {
        return ownerOf(tokenId) == IERC721(_spirals).ownerOf(_spiralIds[tokenId]);
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    function tokenIpfsHash(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return isActive(tokenId)
            ? _tokenIpfsHashes[kActiveIdx]
            : _tokenIpfsHashes[kDeactivatedIdx];
    }

    //-------------------------------------------------------------------------

    function baseTokenURI()
        override public view returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, "/api/project/", Strings.toString(projectId), "/token"));
    }

    //-------------------------------------------------------------------------

    function contractURI()
        public view returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, "/api/project/", Strings.toString(projectId), "/contract"));
    }

}
