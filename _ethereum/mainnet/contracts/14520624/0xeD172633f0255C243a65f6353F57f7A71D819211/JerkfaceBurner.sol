// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: Jerkface Burner
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "./Ownable.sol";

//------------------------------------------------------------------------------
// interfaces
//------------------------------------------------------------------------------

/**
 * Burn baby burn.
 */
interface IGenesis {
  function burn(uint256 tokenId) external;
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

//------------------------------------------------------------------------------
// Jerkface Burner
//------------------------------------------------------------------------------

/**
 * @title Jerkface Burner
 */
contract JerkfaceBurner is Ownable
{

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // jerkface genesis contract
    address private immutable _genesis;

    // time burn is open till
    uint256 public burnCutoff;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(address genesis, uint256 burnCutoff_)
    {
        _genesis   = genesis;
        burnCutoff = burnCutoff_;
    }

    //-------------------------------------------------------------------------

    modifier ownsToken(uint256 tokenId) {
        require(IGenesis(_genesis).ownerOf(tokenId) == msg.sender, "not owner");
        _;
    }

    //-------------------------------------------------------------------------

    modifier isLive() {
        require(block.timestamp < burnCutoff, "burning not live");
        _;
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    function setBurnCutoff(uint256 burnCutoff_)
        public
        onlyOwner
    {
        burnCutoff = burnCutoff_;
    }

    //-------------------------------------------------------------------------
    // methods
    //-------------------------------------------------------------------------

    /**
     * Burn token.
     */
    function burn(uint256 tokenId)
        external
        isLive
        ownsToken(tokenId)
    {
        IGenesis(_genesis).burn(tokenId);
    }

}
