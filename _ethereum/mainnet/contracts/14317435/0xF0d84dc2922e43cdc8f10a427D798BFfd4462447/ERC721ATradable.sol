// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./SafeMath.sol";
import "./IERC2981.sol";

contract OwnableDelegateProxy {
}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721ATradable
 * @author onisquad.gg
 * ERC721ATradable - contract that allowlists a user's OpenSea proxy accounts to enable gas-less listings.
 * In addition, contract owner can add other Proxy contracts in the future. 
 * This enables a user to to have gas-less listings on other future marketplaces (coinbase, kraken) and games.
 * This contract safeguards the collection for integrability for the metaverse.
 */
abstract contract ERC721ATradable is ERC721A, ReentrancyGuard, IERC2981, Ownable, Pausable {
    using Strings for uint256;

    string public baseTokenURI;

    mapping(address => bool) public proxyToApprove;
    address[] public includedProxies;

    // Used to send royalties
    address public receiverAddress;

    /**
    * @notice Contract Constructor
    */
    constructor(
      string memory _name,
      string memory _symbol,
      string memory baseTokenURI_
    ) ERC721A(_name, _symbol) {
        baseTokenURI = baseTokenURI_;
        receiverAddress = address(this);
    }

    // Only Owner public API

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    // SETTERS

    /**
     * Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * Function to disable gasless listings for security in case
     * opensea or other contracts ever shut down or are compromised
     */
    function flipProxyState(address proxyAddress)
        public
        onlyOwner
    {
        proxyToApprove[proxyAddress] = !proxyToApprove[proxyAddress];
    }

    function setReceiverAddress(address _receiverAddress) external onlyOwner {
        require(_receiverAddress != address(0));
        receiverAddress = _receiverAddress;
    }

    // GETTERS

    /**
     * Returns all the token ids owned by a given address
     */
    function ownedTokensByAddress(address owner) external view returns (uint256[] memory) {
        uint256 totalTokensOwned = balanceOf(owner);
        uint256[] memory allTokenIds = new uint256[](totalTokensOwned);
        for (uint256 i = 0; i < totalTokensOwned; i++) {
            allTokenIds[i] = (tokenOfOwnerByIndex(owner, i));
        }
        return allTokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // MONEY RELATED FUNCTIONS 

    function withdrawMoney() external onlyOwner nonReentrant {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (receiverAddress, SafeMath.div(SafeMath.mul(salePrice, 10), 100));
    }

    receive() external payable {}

    function addApprovedProxy(address _newAddress) external onlyOwner() {
       includedProxies.push(_newAddress);
    }

    function removeApprovedProxyIndex(uint index) external onlyOwner() {
        require(index < includedProxies.length, "Array does not have this index");

        for (uint i = index; i < includedProxies.length - 1; i++){
             includedProxies[i] = includedProxies[i+1];
        }
        includedProxies.pop();
    }

    /**
     * Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     * and In addition, you can add other Proxy Approvals in the future.
     * Perhaps, you can skip the approval tx for future NFT Marketplaces (coinbase, kraken) or games.
     * This safeguards the collection for integrability.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < includedProxies.length; i++) {
          address currentProxy = includedProxies[i];
          ProxyRegistry proxyRegistry = ProxyRegistry(currentProxy);
          if (
              proxyToApprove[currentProxy] &&
              address(proxyRegistry.proxies(owner)) == operator
          ) {
              return true;
          }
        }
        return super.isApprovedForAll(owner, operator);
    }
}
