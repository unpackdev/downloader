// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-----------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//-----------------------------------------------------------------------------
 /*\_____________________________________________________________   .¿yy¿.   __
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM```````/MMM\\\\\  \\$$$$$$S/  .
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM``   `/  yyyy    ` _____J$$$^^^^/%#//
 MMMMMMMMMMMMMMMMMMMYYYMMM````      `\/  .¿yü  /  $ùpüüü%%% | ``|//|` __
 MMMMMYYYYMMMMMMM/`     `| ___.¿yüy¿.  .d$$$$  /  $$$$SSSSM |   | ||  MMNNNNNNM
 M/``      ``\/`  .¿ù%%/.  |.d$$$$$$$b.$$$*°^  /  o$$$  __  |   | ||  MMMMMMMMM
 M   .¿yy¿.     .dX$$$$$$7.|$$$$"^"$$$$$$o`  /MM  o$$$  MM  |   | ||  MMYYYYYYM
   \\$$$$$$S/  .S$$o"^"4$$$$$$$` _ `SSSSS\        ____  MM  |___|_||  MM  ____
  J$$$^^^^/%#//oSSS`    YSSSSSS  /  pyyyüüü%%%XXXÙ$$$$  MM  pyyyyyyy, `` ,$$$o
 .$$$` ___     pyyyyyyyyyyyy//+  /  $$$$$$SSSSSSSÙM$$$. `` .S&&T$T$$$byyd$$$$\
 \$$7  ``     //o$$SSXMMSSSS  |  /  $$/&&X  _  ___ %$$$byyd$$$X\$`/S$$$$$$$S\
 o$$l   .\\YS$$X>$X  _  ___|  |  /  $$/%$$b.,.d$$$\`7$$$$$$$$7`.$   `"***"`  __
 o$$l  __  7$$$X>$$b.,.d$$$\  |  /  $$.`7$$$$$$$$%`  `*+SX+*|_\\$  /.     ..\MM
 o$$L  MM  !$$$$\$$$$$$$$$%|__|  /  $$// `*+XX*\'`  `____           ` `/MMMMMMM
 /$$X, `` ,S$$$$\ `*+XX*\'`____  /  %SXX .      .,   NERV   ___.¿yüy¿.   /MMMMM
  7$$$byyd$$$>$X\  .,,_    $$$$  `    ___ .y%%ü¿.  _______  $.d$$$$$$$S.  `MMMM
  `/S$$$$$$$\\$J`.\\$$$ :  $\`.¿yüy¿. `\\  $$$$$$S.//XXSSo  $$$$$"^"$$$$.  /MMM
 y   `"**"`"Xo$7J$$$$$\    $.d$$$$$$$b.    ^``/$$$$.`$$$$o  $$$$\ _ 'SSSo  /MMM
 M/.__   .,\Y$$$\\$$O` _/  $d$$$*°\ pyyyüüü%%%W $$$o.$$$$/  S$$$. `  S$To   MMM
 MMMM`  \$P*$$X+ b$$l  MM  $$$$` _  $$$$$$SSSSM $$$X.$T&&X  o$$$. `  S$To   MMM
 MMMX`  $<.\X\` -X$$l  MM  $$$$  /  $$/&&X      X$$$/$/X$$dyS$$>. `  S$X%/  `MM
 MMMM/   `"`  . -$$$l  MM  yyyy  /  $$/%$$b.__.d$$$$/$.'7$$$$$$$. `  %SXXX.  MM
 MMMMM//   ./M  .<$$S, `` ,S$$>  /  $$.`7$$$$$$$$$$$/S//_'*+%%XX\ `._       /MM
 MMMMMMMMMMMMM\  /$$$$byyd$$$$\  /  $$// `*+XX+*XXXX      ,.      .\MMMMMMMMMMM
 GENETIC/MMMMM\.  /$$$$$$$$$$\|  /  %SXX  ,_  .      .\MMMMMMMMMMMMMMMMMMMMMMMM
 CHAIN/MMMMMMMM/__  `*+YY+*`_\|  /_______//MMMMMMMMMMMMMMMMMMMMMMMMMMM/-/-/-\*/
//-----------------------------------------------------------------------------
// Genetic Chain: Rainbow7
//-----------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//-----------------------------------------------------------------------------

import "./GeneticChainMetadata.sol";

/**
 * @title Rainbow7
 * GeneticChain - Project #8 - Rainbow7
 */
contract Rainbow7 is GeneticChainMetadata
{

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        address spiral,
        string[2] memory tokenIpfsHashes,
        string memory baseUri,
        uint256 seed,
        address proxyRegistryAddress)
        GeneticChainMetadata(
          spiral,
          tokenIpfsHashes,
          baseUri,
          seed,
          proxyRegistryAddress)
    {
    }

}
