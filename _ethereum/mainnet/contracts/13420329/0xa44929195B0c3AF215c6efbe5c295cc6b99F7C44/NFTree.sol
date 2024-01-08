// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";

//               ,@@@@@@@,
//       ,,,.   ,@@@@@@/@@,  .oo8888o.
//    ,&%%&%&&%,@@@@@/@@@@@@,8888\88/8o
//   ,%&\%&&%&&%,@@@\@@@/@@@88\88888/88'
//   %&&%&%&/%&&%@@\@@/ /@@@88888\88888'
//   %&&%/ %&%%&&@@\ V /@@' `88\8 `/88'
//   `&%\ ` /%&'    |.|        \ '|8'
//       |o|        | |         | |
//       |.|        | |         | |
//    \\/ ._\//_/__/  ,\_//__\\/.  \_//__/_

/**  
    @title NFTree
    @author Lorax + Bebop
    @notice ERC-721 token that keeps track of total carbon offset.
 */
contract NFTree is Ownable, ERC721URIStorage {
    
    uint256 tokenId;
    uint256 public carbonOffset;
    address[] whitelists;
    
    mapping(address => Whitelist) whitelistMap;

    struct Whitelist {
        bool isValid;
        address contractAddress;
    }

    /**
        @dev Sets values for {_name} and {_symbol}. Initializes {tokenId} to 1, {totalOffset} to 0, and {treesPlanted} to 0.
     */
    constructor() ERC721('NFTree', 'TREE')
    {
        tokenId = 1;
        carbonOffset = 0;
    }

    /**
        @dev Emitted after a succesful NFTree mint.
        @param _recipient Address that the NFTree was minted to.
        @param _tokenId IPFS hash of token metadata.
        @param _carbonOffset Number of carbon offset (tonnes).
        @param _collection Name of NFTree collection. 
     */
    event Mint(address _recipient, uint256 _tokenId, uint256 _carbonOffset, string _collection);

    /**
        @dev Creates new Whitelist instance and maps to the {whitelists} array.
        @param _contractAddress Address of the contract to be whitelisted.

        requirements:
            - {_contractAddress} must not already be the address of a contract on the whitelist.
     */
    function addWhitelist(address _contractAddress) external onlyOwner {
        require(!whitelistMap[_contractAddress].isValid, 'Contract already whitelisted.');

        whitelistMap[_contractAddress] = Whitelist(true, _contractAddress);
        whitelists.push(_contractAddress);
    }

    /**
        @dev Deletes Whitelist instance and removes from {whitelists} array.
        @param _contractAddress Address of the contract to be removed from the whitelist.

        requirements: 
            - {_contractAddress} must be the address of a whitelisted contract.

     */
    function removeWhitelist(address _contractAddress) external onlyOwner {
        require(whitelistMap[_contractAddress].isValid, 'Not a valid whitelisted contract.');

        uint256 index;

        for (uint256 i = 0; i < whitelists.length; i++) {
            if (whitelists[i] == _contractAddress) {
                index = i;
            }
        }

        whitelists[index] = whitelists[whitelists.length - 1];

        whitelists.pop();
        delete whitelistMap[_contractAddress];
    }
    
    /**
        @dev Retrieves array of valid whitelisted contracts.
        @return address[] {whitelists}.
     */
    function getValidWhitelists() external view onlyOwner returns(address[] memory) {
        return whitelists;
    }

    /**
        @dev Retrieves next token id to be minted.
        @return uint256 {tokenId}.
     */
    function getNextTokenId() external view returns(uint256) {
        return tokenId;
    }

    /**
        @dev Retrieves list of tokens owned by {_owner}
        @return uint256[] {tokenIds}.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);

        } else {

            uint256 resultIndex = 0;
            uint256[] memory tokenIds = new uint256[](tokenCount);

            for (uint256 i = 1; i <= tokenId - 1; i++) {
                if (ownerOf(i) == _owner) {
                    tokenIds[resultIndex] = i;
                    resultIndex++;
                }
            }

            return tokenIds;
        }

    }

    /**
        @dev Mints NFTree to {_recipient}. Emits Mint event.
        @param _recipient Address to mint the NFTree to.
        @param _tokenURI IPFS hash of token metadata.
        @param _carbonOffset Number of carbon offset (tonnes).
        @param _collection Name of NFTree collection. 

        Requirements:
            - {msg.sender} must be a whitelisted contract.
     */
    function mintNFTree(address _recipient, string memory _tokenURI, uint256 _carbonOffset, string memory _collection) external {
        require(whitelistMap[msg.sender].isValid, 'Only whitelisted addresses can mint NFTrees.');
        
        _safeMint(_recipient, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        tokenId += 1;
        carbonOffset += _carbonOffset;

        emit Mint(_recipient, tokenId - 1, _carbonOffset, _collection);
    }
}