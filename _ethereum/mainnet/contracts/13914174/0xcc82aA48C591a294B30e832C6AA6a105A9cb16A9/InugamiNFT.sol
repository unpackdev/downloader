// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

//  ██ ███    ██ ██    ██  ██████   █████  ███    ███ ██     ██   ██ ██ ██████  ██    ██  ██████  
//  ██ ████   ██ ██    ██ ██       ██   ██ ████  ████ ██     ██  ██  ██ ██   ██  ██  ██  ██    ██ 
//  ██ ██ ██  ██ ██    ██ ██   ███ ███████ ██ ████ ██ ██     █████   ██ ██████    ████   ██    ██ 
//  ██ ██  ██ ██ ██    ██ ██    ██ ██   ██ ██  ██  ██ ██     ██  ██  ██ ██   ██    ██    ██    ██ 
//  ██ ██   ████  ██████   ██████  ██   ██ ██      ██ ██     ██   ██ ██ ██   ██    ██     ██████  
//     
// http://www.inugamigame.com/
// Contract - https://t.me/geimskip

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract InugamiNFT is ERC721, Ownable {
    using MerkleProof for bytes32[];
    bytes32 merkleRoot;
    bool public allowAll;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) minted;

    constructor() ERC721("InugamiNFT", "Kiryo") {
    }

    function mint(bytes32[] memory proof) public returns (uint256 tokenId) {
        if (!allowAll) {
            require (merkleRoot != 0, "No whitelist set");
            require (canClaim(proof), "Not in whitelist");
        }
        require (minted[msg.sender] == false, "Already minted");

        minted[msg.sender] = true;

        _tokenIds.increment();
        tokenId = _tokenIds.current();

        _safeMint(msg.sender, tokenId);

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public override pure returns (string memory) {
        string memory tokenIdStr = string(abi.encodePacked(uintToBytes(tokenId)));
        return string(abi.encodePacked("https://us-central1-inugaminft-42b46.cloudfunctions.net/getMetadata?tokenId=", tokenIdStr));
    }

    function setMerkleRoot(bytes32 root) onlyOwner public 
    {
        merkleRoot = root;
    }

    function canClaim(bytes32[] memory proof) public view returns (bool) {
        if (allowAll) {
            return true;
        }
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function setAllowAll(bool _new) onlyOwner public {
        allowAll = _new;
    }

    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }
}