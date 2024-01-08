// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/**
 * @title ChubbyHippos NFT Interface
 * @dev Extends ERC721 Non-Fungible Token Standard basic interface
 */
interface ChubbyHipposNFTInterfaceUser {

    /***************************************
     *                                     *
     *          Emergency settings         *
     *                                     *
     ***************************************/

    /*
     * Get's the max mintable.
     */
    function getMaxSupply() external view returns (uint);

    function getMaxReserved() external view returns (uint);

    /***************************************
     *                                     *
     *            Contract Logic           *
     *                                     *
     ***************************************/

    /**
    * Mint
    */
    function mintOne() external payable;

    function mintTwo() external payable;

    function mintThree() external payable;

    function mintFour() external payable;

    function tokenURI(uint256 id) external view returns (string memory);

    /***************************************
     *                                     *
     *         Underlying structure        *
     *                                     *
     ***************************************/

    function safeTransferFrom(address _from, address _to, uint256 _id) external;

    function totalSupply() external view returns (uint256);

    function calculatedSupply() external view returns (uint256);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function balanceOf(address owner) external view returns (uint256);

}
