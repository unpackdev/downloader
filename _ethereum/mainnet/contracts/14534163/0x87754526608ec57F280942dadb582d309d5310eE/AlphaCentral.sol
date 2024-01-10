// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";

import "./ERC721A.sol";


/// @author 0xNom
/// @title ERC721A Contract for AlphaCentral
contract AlphaCentral is Ownable, ERC721A {
    event PassMinted(address to, uint quantity);

    uint16 MAX_SUPPLY = 1000;

    string private _tokenURI;
    uint mintPrice = 250000000000000000;
    uint8 maxTokens = 10;

    /// Initialises our AlphaCentral contract.
    constructor() ERC721A("Alpha Central", "ALPHA") {
        _tokenURI = "https://alphacentral.xyz/token";
    }

    /// Ensure called is direct and not a contract.
	modifier callerIsUser() {
		require(tx.origin == msg.sender, "The caller is another contract");
		_;
	}

    /// Mints a number of tokens for the caller.
    /// @param quantity The number of tokens to be minted
  	function mint(uint quantity) external payable callerIsUser {
  		require(msg.value >= mintPrice * quantity, "Invalid ETH amount sent");
        require(quantity <= maxTokens, "Invalid quantity in tx");
    	require(totalSupply() + quantity <= MAX_SUPPLY, "Reached max supply");

    	_safeMint(msg.sender, quantity);

        emit PassMinted(msg.sender, quantity);
  	}

    /// Fallback function executed on a payable call if no other functions matches.
    receive() external payable {
        revert();
    }

    /// Fallback function executed on a call if no other functions matches.
    fallback() external payable {
        revert();
    }

    /// Allows our token metadata URI to be updated.
    /// @dev All tokens will share this same token URI
    /// @param tokenURI_ New token URI to implement
  	function setTokenURI(string calldata tokenURI_) external onlyOwner {
    	_tokenURI = tokenURI_;
  	}

    /// Allow admin to update the mint price.
    /// @param _newMintPrice New mint price to be updated to.
    function setMintPrice(uint _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }

    /// Allow admin to update the max number of tokens mintable per tx.
    /// @param _newMaxTokens New max number of tokens to be updated to.
    function setMaxTokens(uint8 _newMaxTokens) external onlyOwner {
        maxTokens = _newMaxTokens;
    }

    /// Allows contract owner to withdraw balance from the contract.
    function withdrawBalance() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /// Gets ownership information for a specified token.
    /// @param tokenId Token to return ownership information of
    /// @return TokenOwnership
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    /// Returns our token URI for the specified token.
    /// @dev All tokens will return the same URI as they share metadata.
    /// @param tokenId ID of the token being specified
    /// @return string Token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _tokenURI;
    }

    /// Gets our total number of minted tokens for an owner
    /// @param owner Address of the owner
    /// @return uint Number of tokens minted by user
  	function numberMinted(address owner) public view returns (uint) {
    	return _numberMinted(owner);
  	}

}
