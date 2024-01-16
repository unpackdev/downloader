// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";


contract SageWallet is  Ownable, ERC721A, ReentrancyGuard,IERC2981 {
    
    uint public constant MAX_SUPPLY = 300;
    string public baseTokenURI;    
    address private _royaltiesReceiver = msg.sender;
    uint256 public constant royaltiesPercentage = 500;
    /*
	 * Constructor
	 */
    constructor(string memory baseURI) ERC721A("SageWallet", "SAGE") {
        setBaseURI(baseURI); 
          
    }

    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// Set the base URI for the metadata
	/// @dev modifies the state of the `_tokenBaseURI` variable
	/// @param _baseTokenURI the URI to set as the base token URI
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    

	
    /// Public minting open to all
	/// @dev mints tokens during public sale
	/// @param _count number of tokens to mint in transaction
    function mintNFTs(uint _count, address _receiver) public onlyOwner {
        require(totalSupply() + _count < MAX_SUPPLY +1 , "Not enough NFTs left!");
               
        _safeMint(_receiver, _count);  
        
    }    

    
    
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
                
        return 
            string(
                    abi.encodePacked(
                        baseTokenURI , 
                        Strings.toString(tokenId)                        
                    )
                );
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount) {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 10000;
        return (_royaltiesReceiver, _royalties);
    }
    /// @notice Getter function for _royaltiesReceiver
    /// @return the address of the royalties recipient
    function royaltiesReceiver() external view returns(address) {
        return _royaltiesReceiver;
    }

    /// @notice Changes the royalties' recipient address (in case rights are
    ///         transferred for instance)
    /// @param newRoyaltiesReceiver - address of the new royalties recipient
    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
    external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }
    /// @notice Informs callers that this contract supports ERC2981
    
    function supportsInterface(bytes4 interfaceId) public view virtual override( IERC165, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}