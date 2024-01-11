// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/// @author: upheaver.eth

import "./IAdminControl.sol";

import "./IERC721Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";

interface ILand is IAdminControl, IERC721Upgradeable, IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable {

    event Discover(uint256 indexed tokenId);
    event Explore(uint256 indexed tokenId, uint256 count);
    event Colonize(uint256 indexed tokenId, address indexed founder);
    event Settle(address indexed from, uint256 indexed tokenId, uint256 count);
    event Portal(address indexed from, uint256 indexed tokenId, uint256 indexed colonyId);
    event Merge(uint256 indexed tokenFrom, uint256 indexed tokenTo );
    event Burn(uint256 indexed tokenId);
    event ActivateExploration();
    event DeactivateExploration();
    event ActivateDiscovery();
    event DeactivateDiscovery();
    event ActivatePortals();
    event DeactivatePortals();
    event ActivateColonization();
    event DeactivateColonization();
    event ActivateMerge();
    event DeactivateMerge();


    /**
     * @dev Conjure one token
     */
    function safeMint(address to) external;

    /**
     * @dev Set the image base uri
     */

    function colonize(bytes memory signature, address _from, uint256 _tokenId, uint256 _action) external;

    function getSignerAddress() external returns (address);

    function setSignerAddress(address signer) external;

    function setRecoveryAddress(address payable recovery) external;
    
    function setBaseURI(string calldata uri) external;

    function setAvailableLand(uint256 count) external;

    function hasColony(uint256 tokenId) external view returns(bool);

    function hasPortal(uint256 colonyId, uint256 tokenId) external view returns(bool);

    function getColony(uint256 tokenId) external view returns (uint256, address, address[] memory, uint256[] memory, uint256[] memory);

    function getExplorationLevel(uint256 tokenId) external view returns (uint256);

    function getColonyLevel(uint256 tokenId) external view returns(uint256);

    function getColonyFounder(uint256 tokenId) external view returns (address);

    function getOwnershipShare(uint256 tokenId, address owner) external view returns(uint256);

    function getColonySettlers(uint256 tokenId) external view returns (address[] memory);

    function totalSupply() external view returns (uint256);

    /**
     * @dev Return list of lands linked via portals
     */
    function getColonyPortals(uint256 tokenId) external view returns (uint256[] memory);

    /**
     * @dev Enable burn to mint land
     */
    function enableDiscovery() external;

    /**
     * @dev Disable burn to mint land
     */
    function disableDiscovery() external;

    /**
     * @dev Enable burn to explore land
     */
    function enableExploration() external;

    /**
     * @dev Disable burn to explore land
     */
    function disableExploration() external;

    /**
     * @dev Enable burn to link portals
     */
    function enablePortals() external;

    /**
     * @dev Disable burn to link portals
     */
    function disablePortals() external;

    /**
     * @dev Enable burn to colonize
     */
    function enableColonization() external;

    /**
     * @dev Disable burn to colonize
     */
    function disableColonization() external;

    /**
     * @dev Enable land merge
     */
    function enableMerge() external;

    /**
     * @dev Disable land merge
     */
    function disableMerge() external;

    /**
     * @dev Update ERC1155 token address
     */
    function updateERC1155Address(address erc1155address) external;

    /**
     * @dev Update ERC721 token address
     */
    function updateERC721Address(address erc721address) external;

    /** 
     * @dev Get ERC721 token address
     */
    function getERC721Address() external view returns (address);

    /**     
     * @dev Get ERC1155 token address
     */
    function getERC1155Address() external view returns (address);

    /**
     * @dev Get eth balance of the contract
     */
    function getEthBalance() external view returns (uint256);

    /**
     * @dev Recover any ETH tokens accidentally sent in
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev Recover any ERC20 tokens accidentally sent in
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    /**
     * @dev Recover any ERC721 tokens accidentally sent in
     */
    function recoverERC721(address tokenAddress, uint256 tokenId) external;
    
    /**
     * @dev Recover any ERC1155 tokens accidentally sent in
     */
    function recoverERC1155(address tokenAddress, uint256 tokenId, uint256 amount) external;

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external;

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps);
    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients);
    function getFeeBps(uint256) external view returns (uint[] memory bps);
    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256);

}