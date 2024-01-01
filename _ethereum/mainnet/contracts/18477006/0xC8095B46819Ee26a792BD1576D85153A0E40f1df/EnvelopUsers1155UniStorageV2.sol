// SPDX-License-Identifier: MIT
// ENVELOP protocol for NFT. Mintable User NFT Collection
pragma solidity 0.8.19;

import "ERC1155URIStorage.sol";
import "Ownable.sol";
import "ECDSA.sol";


contract EnvelopUsers1155UniStorageV2 is ERC1155URIStorage, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Strings for uint160;

    string public  name;
    string public  symbol;
    string private _baseDefaultURI;

    
    // mapping from url prefix to baseUrl
    mapping(string => string) public baseByPrefix;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) 
        //ERC1155(string(abi.encodePacked(_baseDefaultURI, "{id}")))
        ERC1155(_baseDefaultURI)
    {
        name = name_;
        symbol = symbol_;
        _baseDefaultURI = string(
            abi.encodePacked(
                _baseurl,
                block.chainid.toString(),
                "/",
                uint160(address(this)).toHexString(),
                "/"
            )
        );
        //_setBaseURI(_baseTokenURI);

    }

    ///////////////////////////////////////////////////////////////////////////
    ////  Section below is OppenZeppelin ERC1155Supply inmplementation     ////
    ///////////////////////////////////////////////////////////////////////////
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////

    function mintWithURI(
        address _to, 
        uint256 _tokenId, 
        uint256 _amount,
        string calldata _tokenURI
    ) public {
        _mintWithURI(_to, _tokenId, _amount, _tokenURI);
    }

    function mintWithURIBatch(
        address[] calldata _to, 
        uint256[] calldata _tokenId,
        uint256[] calldata _amounts, 
        string[] calldata _tokenURI
    ) external {
        for (uint256 i = 0; i < _to.length; i ++){
            mintWithURI(_to[i], _tokenId[i], _amounts[i], _tokenURI[i]);
        }
    }
    ////////////////////////////////////////////////////////////
    // Overriding from ERC1155URIStorage
    function uri(uint256 tokenId) public view override(ERC1155URIStorage) returns (string memory) {
        //string memory tokenURI = _tokenURIs[tokenId];
        string memory tokenURI = super.uri(tokenId);
        string memory _baseURI = _baseDefaultURI;
        ///////////////////////////////////////////////////////////////// 
        // Try get and check schema from token Uri           ////////////
        /////////////////////////////////////////////////////////////////
        uint256 colonPosition;
        for (uint256 i; i < bytes(tokenURI).length; ++ i){
            if (bytes(tokenURI)[i] == ':'){
                colonPosition = i;
                break;
            }
        }
        if (colonPosition > 0){
            //1. Check that special scheme prefix exist
            bytes memory prefixB = new bytes(colonPosition);
            for (uint256 i; i < colonPosition; ++ i){
                prefixB[i] = bytes(tokenURI)[i];
            }
            if (bytes(baseByPrefix[string(prefixB)]).length > 0) {
                _baseURI = baseByPrefix[string(prefixB)];
                
                //2. Remove `scheme://` from original token URI
                bytes memory tempURI = new bytes(
                    bytes(tokenURI).length
                    - prefixB.length  - 3

                );
                for (uint256 i; i < bytes(tempURI).length; ++ i){
                    tempURI[i] = bytes(tokenURI)[i + colonPosition + 3]; // because `scheme://`
                }
                tokenURI = string(tempURI);

            } else {
                _baseURI = '';
            }
            
        }
        /////////////////////////////////////////////////////////////////

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 
            ? string(abi.encodePacked(_baseURI, tokenURI)) 
            : string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    function burn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }

    

    //////////////////////////////
    //  Admin functions        ///
    //////////////////////////////
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setPrefixURI(string memory _prefix, string memory _base)
        public 
        virtual
        onlyOwner 
    {
        baseByPrefix[_prefix] = _base;
    }
    ///////////////////////////////

    function _mintWithURI(
        address _to, 
        uint256 _tokenId, 
        uint256 _amount, 
        string memory _tokenURI
    ) internal {
        require(!exists(_tokenId),"This id already minted");
        _mint(_to, _tokenId, _amount, "");
        _setURI(_tokenId, _tokenURI);
    }

}