// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

import "./ValenftinesDescriptors.sol";


struct Valentine {
    uint8 h1;
    uint8 h2;
    uint8 h3;
    uint24 requitedTokenId;
    address to;
    address from;
}

/// Reverts
/// 1 - value less than mint fee
/// 2 - mint started yet 
/// 3 - mint ended
/// 4 - GTAP mint ended
/// 5 - GTAP mint claimed
/// 6 - invalid proof
/// 7 - inavlid heart type
/// 8 - token does not exist
contract Valenftines is ERC721, Ownable {
    uint256 public immutable mintStartTimestamp;
    uint256 public immutable mintEndTimestamp;
    bytes32 public immutable merkleRoot;
    mapping(uint256 => Valentine) public _valentineInfo;
    mapping(uint256 => uint256) public matchOf;
    mapping(address => bool) public gtapEarlyMintClaimed;

    uint24 private _nonce;

    function valentineInfo(uint256 tokenId) view public returns(Valentine memory){
        require(tokenId <= _nonce, '8');
        return _valentineInfo[tokenId];
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        require(id <= _nonce, '8');
        return ValenftinesDescriptors.tokenURI(id, address(this));
    }

    function svgImage(uint256 id) external view returns (bytes memory) {
        require(id <= _nonce, '8');
        uint256 copy = matchOf[id];
        if(copy > 0){
            Valentine memory vc = _valentineInfo[copy];
            return ValenftinesDescriptors.svgImage(true, copy, vc);
        } else {
            Valentine memory v = _valentineInfo[id];
            return ValenftinesDescriptors.svgImage(false, id, v);
        }
    }

    constructor(
        address _owner,
        uint256 _mintStartTimestamp, 
        uint256 _mintEndTimestamp,
        bytes32 _merkleRoot
    ) 
        ERC721("Valenftines", "GTAP3")
    {
        transferOwnership(_owner);
        mintStartTimestamp = _mintStartTimestamp;
        mintEndTimestamp = _mintEndTimestamp;
        merkleRoot = _merkleRoot;
    }

    /// Mint

    function mint(address to, uint8 h1, uint8 h2, uint8 h3) payable external returns(uint256 id) {
        require(heartMintCostWei(h1) + heartMintCostWei(h2) + heartMintCostWei(h3) <= msg.value, '1');
        require(block.timestamp > mintStartTimestamp, '2');
        require(block.timestamp < mintEndTimestamp, '3');
        
        id = ++_nonce;
        Valentine storage v = _valentineInfo[id];
        v.from = msg.sender;
        v.to = to;
        v.h1 = h1;
        v.h2 = h2;
        v.h3 = h3;
        _safeMint(to, id);
    }

    function gtapMint(address to, uint8 h1, uint8 h2, uint8 h3, bytes32[] calldata merkleProof) payable external returns(uint256 id) {
        require((((heartMintCostWei(h1) + heartMintCostWei(h2) + heartMintCostWei(h3)) * 50) / 100)  <= msg.value, '1');
        require(block.timestamp < mintStartTimestamp, '4');
        require(!gtapEarlyMintClaimed[msg.sender], '5');

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), '6');

        gtapEarlyMintClaimed[msg.sender] = true;
        
        id = ++_nonce;
        Valentine storage v = _valentineInfo[id];
        v.from = msg.sender;
        v.to = to;
        v.h1 = h1;
        v.h2 = h2;
        v.h3 = h3;
        _safeMint(to, id);
    }

    function heartMintCostWei(uint8 heartType) public pure returns(uint256) {
        require(heartType > 0 && heartType < 24, '7');
        return (heartType < 11 ? 1e16 : 
            (heartType < 18 ? 2e16 : 
                (heartType < 23 ? 1e17 : 1e18)));
    }

    /// Transfer

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.transferFrom(from, to, id);
    } 

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.safeTransferFrom(from, to, id, data);
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 id
    ) private {
        Valentine storage v = _valentineInfo[id];
        if (v.requitedTokenId == 0 && matchOf[id] == 0){
            if(to == v.from){
                uint24 nId = ++_nonce;
                _mint(from, nId);
                v.requitedTokenId = nId;
                matchOf[nId] = id;
            } else {
                v.from = from;
                v.to = to;
            }
        }
    }

    function payOwner(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "amount too high");
        payable(to).transfer(amount);
    }
}
