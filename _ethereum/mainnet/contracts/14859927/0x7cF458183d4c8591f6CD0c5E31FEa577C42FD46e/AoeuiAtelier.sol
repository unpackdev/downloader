// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//       **       *******   ******** **     ** **       **     ********** ******** **       ** ******** *******
//      ****     **/////** /**///// /**    /**/**      ****   /////**/// /**///// /**      /**/**///// /**////**
//     **//**   **     //**/**      /**    /**/**     **//**      /**    /**      /**      /**/**      /**   /**
//    **  //** /**      /**/******* /**    /**/**    **  //**     /**    /******* /**      /**/******* /*******
//   **********/**      /**/**////  /**    /**/**   **********    /**    /**////  /**      /**/**////  /**///**
//  /**//////**//**     ** /**      /**    /**/**  /**//////**    /**    /**      /**      /**/**      /**  //**
//  /**     /** //*******  /********//******* /**  /**     /**    /**    /********/********/**/********/**   //**
//  //      //   ///////   ////////  ///////  //   //      //     //     //////// //////// // //////// //     //

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract AoeuiAtelier is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory tokenName, string memory symbol) ERC721(tokenName, symbol) {}

    function changeTokenURI(uint256 id, string memory tokenURI) public onlyOwner {
        _setTokenURI(id, tokenURI);
    }

    function mint(address owner, string memory tokenURI) public onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(owner, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}