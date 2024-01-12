// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

//@title 0x613b10.
//@creator v.

import "./ERC721.sol";

contract _0x613b10 is ERC721 {
    using Strings for uint256;

    uint256 minted = 1;
    mapping(address => bool) lock;
    address public _0x613b10_ = 0x613b101B0C2dfa25d08BF7423Dce9E9443B9D759;
    string r = '<_r>';
    string[7] portalpt = ["<svg xmlns='http://www.w3.org/2000/svg' width='500' height='500'>",
    "<style>.x613b10 {animation: x613b10 1.5s ease-in-out infinite alternate;}@keyframes x613b10 ",
    "{from {filter: drop-shadow( 0 0 0 #fff0) drop-shadow( 0 0 15px #920) drop-shadow( 0 0 20px #910);}",
    "to {filter: drop-shadow( 0 0 20px #fff1) drop-shadow( 0 0 30px #ffff00) drop-shadow( 0 0 20px #e60073);}}</style>",
    "<rect width='100%' height='100%' /><circle r='1",r,"0' cx='50%' cy='50%' fill='none' stroke='black' stroke-width='500' stroke-dasharray='61310' class='x613b10'/></svg>"];

        constructor() 
            ERC721("0x613b10","0x613b10") {
            _mint(_0x613b10_, 1);
            lock[_0x613b10_] = true;
        }

    function mint() external {
        require(minted < 613 && !lock[msg.sender]  , "cant mint");
        uint256 tokenId = minted + 1;
        require(!_exists(tokenId), "Portal exist");
        lock[msg.sender] = true;
        _safeMint(msg.sender, tokenId);
        minted = tokenId;
    }

    function _generatePortal(uint256 tokenId) private view returns (string memory) {
        uint256 r_;
        if (tokenId == 1) {
            r_ = 1;
        } else {
            r_ = (uint256(uint160(ownerOf(tokenId)))%5)+2;
        }
        bytes memory portal;
        for (uint i = 0; i < portalpt.length; i++) {
            if (_checkTag(portalpt[i], r)) {
                portal = abi.encodePacked(portal, r_.toString());
            } else {
                portal = abi.encodePacked(portal, portalpt[i]);
            }
        }
        return string(abi.encodePacked("data:image/svg+xml;utf8,", portal));
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function totalSupply() public view returns (uint256) {
        return minted;
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
            bytes memory _0x613b10Json = abi.encodePacked(
                'data:application/json;utf8,{"name": "[0x613b10] #', tokenId.toString() ,'","description": "0x613b10 Portals."', 
                ',"created_by": "v","image": "',_generatePortal(tokenId),'"}'    
            );
        return string(abi.encodePacked(_0x613b10Json));
    }

}