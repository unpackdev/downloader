// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./SelectionLib.sol";
import "./Strings.sol";

contract SelectionContract is Ownable {

    using Strings for uint256;
    SelectionLib.NFTSelection[] public selectionsNFT;

    //set the max supply of NFT's
    SelectionLib.Selection[] public selectionSupplies;


    function getSelection(string memory selectionName)
        public
        view
        virtual
        returns (SelectionLib.Selection memory)
    {
        for (uint256 index = 0; index < selectionSupplies.length; index++) {
            SelectionLib.Selection memory selection = selectionSupplies[index];
            if (
                keccak256(abi.encodePacked(selectionName)) ==
                keccak256(abi.encodePacked(selection.name))
            ) return selection;
        }
        return selectionSupplies[0];
    }

    function getSelections() public view virtual returns (SelectionLib.Selection[] memory) {
        return selectionSupplies;
    }

    function getNFTSelections() public view virtual returns (SelectionLib.NFTSelection[] memory) {
        return selectionsNFT;
    }

    function getNFTSelection(uint256 tokenId, string memory currentBaseURI)
        public
        view
        virtual
        returns (string memory)
    {
        for (uint256 index = 0; index < selectionsNFT.length; index++) {
            SelectionLib.NFTSelection memory selectionNFT = selectionsNFT[index];
            if (tokenId == selectionNFT.id) {
                uint256 selectionIndex = selectionNFT.selectionIndex;
                SelectionLib.Selection memory selection = selectionSupplies[selectionIndex];
                uint256 selectionId = selectionNFT.selectionId;
                return
                    bytes(currentBaseURI).length > 0? string(abi.encodePacked(currentBaseURI,selection.name,'-', selectionId.toString())) : "";
            }
        }
        return "";
    }

    function addNewSelection(
        string memory selectionName,
        uint256 maxSupply,
        uint256 totalSupply,
        uint256 mintCost
    ) public onlyOwner {
        selectionSupplies.push(
            SelectionLib.Selection(selectionName, maxSupply, totalSupply, mintCost)
        );
    }

    function changeSelectionCost(string memory selectionName, uint256 mintCost)
        public
        onlyOwner
    {
        SelectionLib.Selection memory selection = getSelection(selectionName);
        uint256 selectionIndex;

        for (uint256 index = 0; index < selectionSupplies.length; index++) {
            SelectionLib.Selection memory actualSelection = selectionSupplies[index];
            if (
                keccak256(abi.encodePacked(selectionName)) ==
                keccak256(abi.encodePacked(actualSelection.name))
            ) selectionIndex = index;
        }

        selectionSupplies[selectionIndex] = SelectionLib.Selection(
            selection.name,
            selection.maxSupply,
            selection.totalSupply,
            mintCost
        );
    }
}