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
// Genetic Chain: ERC721SeqEnumerableB
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "./IERC721Enumerable.sol";
import "./ERC721SequentialB.sol";

/**
 * @dev This is a no storage implementation of the optional extension {ERC721}
 * defined in the EIP that adds enumerability of all the token ids in the
 * contract as well as their owners. These functions are all O(n) and mainly
 * for convenience and should not be called from a contract on the chain.
 */
abstract contract ERC721SeqEnumerableB is ERC721SequentialB, IERC721Enumerable {

    address constant zero = address(0);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721SequentialB) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual override returns (uint256 tokenId) {
        uint256 length = _owners.length;

        unchecked {
            for (; tokenId < length; ++tokenId) {
                if (_owners[tokenId] == owner) {
                    if (index-- == 0) {
                        break;
                    }
                }
            }
        }

        require(tokenId < length, "ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256 supply) {
        unchecked {
            uint256 length = _owners.length;
            for (uint256 tokenId = 0; tokenId < length; ++tokenId) {
                if (_owners[tokenId] != zero) {
                    ++supply;
                }
            }
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(
        uint256 index
    ) public view virtual override returns (uint256 tokenId) {
        uint256 length = _owners.length;

        unchecked {
            for (; tokenId < length; ++tokenId) {
                if (_owners[tokenId] != zero) {
                    if (index-- == 0) {
                        break;
                    }
                }
            }
        }

        require(tokenId < length, "ERC721Enumerable: global index out of bounds");
    }

    /**
     * @dev Get all tokens owned by owner.
     */
    function ownerTokens(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = ERC721SequentialB.balanceOf(owner);
        require(tokenCount != 0, "ERC721Enumerable: owner owns no tokens");

        uint256 length = _owners.length;
        uint256[] memory tokenIds = new uint256[](tokenCount);
        unchecked {
            uint256 i = 0;
            for (uint256 tokenId = 0; tokenId < length; ++tokenId) {
                if (_owners[tokenId] == owner) {
                    tokenIds[i++] = tokenId;
                }
            }
        }

        return tokenIds;
    }

}
