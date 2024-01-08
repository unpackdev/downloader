// contracts/Baseballs.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "./ERC20.sol";
import "./Context.sol";
import "./BitMaps.sol";
import "./ERC20Burnable.sol";

import "./MLBC.sol";

contract Baseballs is Context, ERC20Burnable {
    using BitMaps for BitMaps.BitMap;

    MLBC public _mlbc;

    BitMaps.BitMap private _baseballsBitMap;

    uint256 public totalMinted;


    constructor(address mlbcAddress) ERC20("Baseball", "BASEBALL") {
        _mlbc = MLBC(mlbcAddress);
    }

    function mint(uint256[] calldata tokenIds) public {

        for (uint i=0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            validateMintableToken(tokenId);
        }

        for (uint i=0; i < tokenIds.length; i++) {
            //Mark as claimed
            _markMinted(tokenIds[i]);
            totalMinted++;
        }

        _mint(_msgSender(), tokenIds.length * (10**18) );
    } 



    function validateMintableToken(uint256 tokenId) public view {

        //Don't mint past the supply at launch.
        require(tokenId < 249173, "Token too high");
        require(tokenId >= 0, "Token too low");

        //Validate the tokens exist
        require(_mlbc.exists(tokenId) == true, "Invalid MLBC token");

        //Validate user owns the token
        require(_mlbc.ownerOf(tokenId) == _msgSender(), "Not token owner");

        //Validate these haven't been claimed
        require(isMinted(tokenId) == false, "Already minted");

    }


    function isMinted(uint256 tokenId) public view returns (bool) {
        return _baseballsBitMap.get(tokenId);
    }

    function _markMinted(uint256 tokenId) private {
        _baseballsBitMap.set(tokenId);
    }
    
}