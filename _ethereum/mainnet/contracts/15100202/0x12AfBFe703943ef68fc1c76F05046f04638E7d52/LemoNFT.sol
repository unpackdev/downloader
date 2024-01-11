// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract LemoNFT is ERC721Enumerable ,Ownable{

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    string private _baseTokenURI = "ipfs://";
    mapping(address => uint) public nonces;
    mapping(uint256 => string) public tokencids;

    constructor() ERC721("LemoNFT", "LN") {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name())),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

  function mintTo(address to,uint256 tokenId,string memory cid) public onlyOwner {
        _mint(to, tokenId);
        tokencids[tokenId] = cid;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view  override returns (string memory) {
        return _baseTokenURI;
    }
 
    function tokenURI(uint256 tokenId) public view  override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        string memory cid = tokencids[tokenId];
        return bytes(cid).length > 0 ? string(abi.encodePacked(baseURI, cid)) : "";
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'LemoNFT: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress != address(0) && recoveredAddress == owner, 'LemoNFT: INVALID_SIGNATURE');
         _safeTransfer(owner, spender, value, "");
    }

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender());
        _burn(tokenId); 
    }
}