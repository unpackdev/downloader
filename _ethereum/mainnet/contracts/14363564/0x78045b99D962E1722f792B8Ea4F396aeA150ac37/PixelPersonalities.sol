// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-----------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//-----------------------------------------------------------------------------
 /*\_/-|-\_____________________________________________________________________
 ______  __             __
 |   __ \__.--.--.-----.  |
 |    __/  |_   _|  -__|  |
 |___|  |__|__.__|_____|__|
  ______                                     __ __ __   __
 |   __ \.-----.----.-----.-----.-----.---.-.  |__|  |_|__.-----.-----.
 |    __/|  -__|   _|__ --|  _  |     |  _  |  |  |   _|  |  -__|__ --|
 |___|   |_____|__| |_____|_____|__|__|___._|__|__|____|__|_____|_____|
 ---------------------------------------------------------------------/-/-/-\*/
//-----------------------------------------------------------------------------
// Genetic Chain: Pixel Personalities
//-----------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//-----------------------------------------------------------------------------

import "./GeneticChain721.sol";

//------------------------------------------------------------------------------
// GeneticChainMetadata
//------------------------------------------------------------------------------

/**
 * @title GeneticChain - Project #13 - Pixel Personalities
 */
contract PixelPersonalities is GeneticChain721
{

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // token info
    string private _baseUri;

    // contract info
    string public _contractUri;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        string memory baseUri_,
        string memory contractUri_,
        uint256[2] memory tokenMax_)
        GeneticChain721(
          tokenMax_)
    {
        _baseUri     = baseUri_;
        _contractUri = contractUri_;
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    function setBaseTokenURI(string memory baseUri)
        public
        onlyOwner
    {
        _baseUri = baseUri;
    }

    //-------------------------------------------------------------------------
    // ERC721Metadata
    //-------------------------------------------------------------------------

    function baseTokenURI()
        public
        view
        returns (string memory)
    {
        return _baseUri;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Returns uri of a token.  Not guarenteed token exists.
     */
    function tokenURI(uint256 tokenId)
        override
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(
            baseTokenURI(), "/", Strings.toString(tokenId)));
    }

    //-------------------------------------------------------------------------
    // contractUri
    //-------------------------------------------------------------------------

    function setContractURI(string memory contractUri)
        external onlyOwner
    {
        _contractUri = contractUri;
    }

    //-------------------------------------------------------------------------

    function contractURI()
        public view
        returns (string memory)
    {
        return _contractUri;
    }

}
