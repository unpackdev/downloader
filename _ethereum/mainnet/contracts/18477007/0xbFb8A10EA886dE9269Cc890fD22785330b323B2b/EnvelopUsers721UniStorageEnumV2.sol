// SPDX-License-Identifier: MIT
// ENVELOP protocol for NFT. Mintable User NFT Collection
pragma solidity 0.8.19;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "ECDSA.sol";


contract EnvelopUsers721UniStorageEnumV2 is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Strings for uint160;

    bool public needCheckSign;
    string private _baseTokenURI;

    
    
    // mapping from url prefix to baseUrl
    mapping(string => string) public baseByPrefix;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) 
        ERC721(name_, symbol_)
    {
        _baseTokenURI = string(
            abi.encodePacked(
                _baseurl,
                block.chainid.toString(),
                "/",
                uint160(address(this)).toHexString(),
                "/"
            )
        );

    }

    
    //////////////////////////////////////////////////////////////////////
    ///  Section below is OppenZeppelin ERC721URIStorage inmplementation /
    //////////////////////////////////////////////////////////////////////

     // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory _baseURItemp = _baseURI();
        // ------------------------------------
        ///////////////////////////////////////////////////////////////// 
        // Try get and check schema from token Uri           ////////////
        /////////////////////////////////////////////////////////////////
        uint256 colonPosition;
        for (uint256 i; i < bytes(_tokenURI).length; ++ i){
            if (bytes(_tokenURI)[i] == ':'){
                colonPosition = i;
                break;
            }
        }
        if (colonPosition > 0){
            //1. Check that special scheme prefix exist
            bytes memory prefixB = new bytes(colonPosition);
            for (uint256 i; i < colonPosition; ++ i){
                prefixB[i] = bytes(_tokenURI)[i];
            }
            if (bytes(baseByPrefix[string(prefixB)]).length > 0) {
                _baseURItemp = baseByPrefix[string(prefixB)];
                
                //2. Remove `scheme://` from original token URI
                bytes memory tempURI = new bytes(
                    bytes(_tokenURI).length
                    - prefixB.length  - 3

                );
                for (uint256 i; i < bytes(tempURI).length; ++ i){
                    tempURI[i] = bytes(_tokenURI)[i + colonPosition + 3]; // because `scheme://`
                }
                _tokenURI = string(tempURI);

            } else {
                _baseURItemp = '';
            }
            
        }
        /////////////////////////////////////////////////////////////////

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(_tokenURI).length > 0 
            ? string(abi.encodePacked(_baseURItemp, _tokenURI)) 
            : string(abi.encodePacked(_baseURItemp, tokenId.toString()));
        
    }

    
    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////

    function mintWithURI(
        address _to, 
        string calldata _tokenURI
    ) public {
         uint256 _tokenId = totalSupply();
        _mintWithURI(_to, _tokenId, _tokenURI);
    }

    function mintWithURIBatch(
        address[] calldata _to, 
        string[] calldata _tokenURI
    ) external {
        for (uint256 i = 0; i < _to.length; i ++){
            mintWithURI(_to[i],  _tokenURI[i]);
        }
    }

    // function burn(uint256 _tokenId) external {
    //      require(ownerOf(_tokenId) == msg.sender, "Only for token owner");
    //     _burn(_tokenId);
    // }
    //////////////////////////////
    //  Admin functions        ///
    //////////////////////////////
    function setPrefixURI(string memory _prefix, string memory _base)
        public 
        virtual
        onlyOwner 
    {
        baseByPrefix[_prefix] = _base;
    }
    
    
    ///////////////////////////////

    function _mintWithURI(address _to, uint256 _tokenId, string memory _tokenURI)
        internal 
    {
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function baseURI() external view  returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view  override returns (string memory) {
        return _baseTokenURI;
    }
}