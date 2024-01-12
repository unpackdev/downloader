// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

error FunctionNotSupported();

/*
                         %@@@@*  @@@  *#####
                   &@@@@@@@@ ,@@@@@@@@@  #########
              ,@@@@@@@@  #                  %. @@@@@@@
           &@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@ .@@@@@@@@
         @@@@@@@@@@@. @@@@@@@@@@@@ @@@@@@@@@@@@@  @@@@@@@@@@
       ####       @  @@@@@@@@@@@@@ @@@@@@@@@@@@@@.       .&@@@
     ########. @@@@@@@@@@ @@@@@%#///#%@@@@@@ @@@@@@@@@@@  @@@@@.
    ########  @@@@@@@@@@  @@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@. @@@@@@
   ######### @@@@@@@@@@@ &@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@  @@@@@@
  %@@(       ,@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@,      &@
  @@@# @@@@@@@@@@@@ ,#####*                 . ,@@@@  %@@@@@@@@@@@@@@/
  @@@  @@@@@@@@@@@@ ##############  @@@@@@@@@@@@ ,@@@@.   @@@&  @@@@@@..#
  @@@ &@@@@@@@@@@@@ ##############  @@@@@@@@@@ @@@@@@@@@@@&   @@@@@@@@ #####
  @@@ @@@@@@@@@@@@@ ##############  @@@@@@@@ *@@@@@@@@@@  @@@. @@@@@@ ########
  @@        %@@@@@@ ##############  @@@@@@@ @@@@@@@@@@@ @@@@@@@ @@@&@ ####### /
  &&@@@@@  @@@@@@@@@@&*                    @@@@@@@@@@# @@@@@@@  &&&&&&& ##  @@@
  &&&&&@@  @@@@@@@@@@@@* @@@@@@@@@@@@@@@@* @@@    .@% @@@@@@ &&&&&&&&&&& @@@@@@
  @&&&&&&  @@@@@@@@@@@@* @@@@@@@@@@@@@@@@ @@@@@@@@@@ @@@    &&&&&&&&&&&&& @@@@@
      &&&  &@@@@@@@@@@@* @@@@@@@@@@@@@@@@ @@@@@@@@@ @@@@@@    . #&&&&&&&& @@@@/
   (((  &&       /@@@@@* @@@@@@@@@@@@@@@,.@@@@@@@@@ @@@@@& &&&&& &&&&&&     @@@
   (((* &&&&&&&&&/ @@@@@@@@@@@@@@@ @@@@@ .   .@@@@@ @@@@@  &&&&& &&&&&&&& @@@@@
   (((( &&&&&&&&&/ &&&@@@@@@@@@@@@ @@@@@  ######### %@@@@  &&&&& &&&&&&&& @@@@@
     (( &&&&&&&&&/ &&&&&&&@@@@@@@@ @@@@@% ######### @@@@@%          &&&&& @@@.
           .&&&&&/ &&&&&&&&&&&&&&@ @@@@@@ ######### @@@@@@
                                           ######## @@@@@@

 * @notice Implementation of a "Soulbound Token" to mark truePengu's. 
 * This is an ERC1155 NFT with modification to remove transferability.

    Dear Pengu,

    No matter the obstacle we will make it through
    They said Penguins cannot fly but together we flew
    We are one Huddle, red and blue 
    May this symbolize that there is nothing we cannot do
    Here is a token of gratitude from me to you
    Permanently marking you a truePengu

    With Love,
    The Pudgy Penguins Team

 */

contract truePengu is ERC1155, Ownable {
    using Strings for uint256;

    string private baseURI;
    string private baseURISuffix;
    
    constructor(string memory _base, string memory _suffix) ERC1155("") {
        baseURI = _base; 
        baseURISuffix = _suffix;
    }

    function setURI(string calldata _base, string calldata _suffix) external onlyOwner {
        baseURI = _base;
        baseURISuffix = _suffix;
    }

    function airdropTruePengu(
        uint256 tier,
        address [] calldata holders
    ) external onlyOwner {
        for(uint i = 0; i < holders.length; i++){
            _mint(holders[i], tier, 1, "");
        }
    }

    function burnTruePengu(uint256 tier) external {
        _burn(msg.sender, tier, 1);
    }

    function uri(uint256 tier) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tier.toString(), baseURISuffix));
    }

    /*
     * All functions having to do with the transfer of the NFT's have been overridden.
     * Although the approval functions don't need to be overridden, there is no use 
     * for them, so I am overriding to save users gas in case they try and execute them.
     */
    function setApprovalForAll(
        address,
        bool
    ) public pure override {
        revert FunctionNotSupported();
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert FunctionNotSupported();
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert FunctionNotSupported();
    }
}
