// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";
import "./MintInterface.sol";

contract NFTc is ERC721, ERC721URIStorage, AccessControl, ERC721_Mint {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // 9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6

    uint256 private tokenIndex;
    string private tokenBaseUri;
    mapping(uint256 => bool) public tokenClaim;
    uint256 private preMint;
    bool private preMintEnd;

    constructor() ERC721("NFTc - Claimable NFT - REF:01", "NFTc") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        preMint = 100;
        preMintEnd = false;
    }

    function endPreMint()public 
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        preMintEnd = true;
    }

    function setTokenBaseUri(string memory _value)public 
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenBaseUri = _value;
    }

    function setClaimToken(uint256 _tokenId)public 
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenClaim[_tokenId] = true;
    }

    function safeMint(address to)
    external override
    onlyRole(MINTER_ROLE)
    {
        tokenIndex +=1;
        _safeMint(to, tokenIndex);
    }

    function safeMint(address to,uint256 _amount)
    external override
    onlyRole(MINTER_ROLE)
    {
       for(uint256 i;i<_amount;i++){
           tokenIndex +=1;
        _safeMint(to, tokenIndex);
       }
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if(!preMintEnd && tokenId > preMint)
            return string(abi.encodePacked(tokenBaseUri, "preMint.json"));
        return  string(abi.encodePacked(tokenBaseUri, uint256ToString(tokenId),".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uint256ToString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}