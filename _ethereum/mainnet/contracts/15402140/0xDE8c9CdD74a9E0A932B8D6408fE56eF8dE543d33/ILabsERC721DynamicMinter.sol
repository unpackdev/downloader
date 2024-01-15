// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*

*/
 
interface ILabsERC721DynamicMinter {

    /**
     * @dev premints gifted nfts
     */
    function premint(address[] memory to) external;

    /**
     * @dev external mint function 
     */
    function mint(uint256 quantity) external payable;

    /**
     * @dev Set the token uri prefix
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev sets the mint price
     */
    function setMintPrice(uint256 mintPrice) external;

    /**
     * @dev sets the max mints
     */
    function setMaxMints(uint256 maxMints) external;
        
    /**
     * @dev get the max mints
     */
	function maxMints() external view returns (uint256);

    /**
     * @dev Withdraw funds from the contract
     */
    function withdraw(address to, uint amount) external;

    function pause() external;

    function unpause() external;    
}
