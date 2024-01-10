// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

interface iPuppetParts {
    function burnParts(uint256[6] memory _partsId, address _from) external;
}

contract PuppetStars is ERC721Enumerable, Ownable {
    iPuppetParts public PuppetParts;

    bool public assembleIsActive = false;
    uint256 private constant maxPuppetSupply = 500;

    mapping(uint256 => string) public puppetsBaseURI;
    mapping(string => bool) public sigUsed;

    constructor (address _puppetPartsContract) ERC721("PuppetStars", "Puppets") {
        PuppetParts = iPuppetParts(_puppetPartsContract);
    }

    //override
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return puppetsBaseURI[tokenId];
    }

    //external
    function assemblePuppet(uint256[6] memory _tokenIds, string memory _cid, bytes32[] calldata _proof, string memory _key) external {
        require(assembleIsActive,                  "assemble not yet enable");
        require(totalSupply() < maxPuppetSupply,   "Puppets fully assembled");
        require(!sigUsed[_key],                    "Sig used");

        bytes32 merkleTreeRoot = 0x039d04f33522f50101b9ce5e4c997b41caf26ab454a12fd366eb11f15f5d590d;
        bytes32 leaf = keccak256(abi.encodePacked(_key));
        require(MerkleProof.verify(_proof, merkleTreeRoot, leaf),  "Invalid sig");

        //burn parts to assemble puppet
        PuppetParts.burnParts(_tokenIds, msg.sender);

        uint256 tokenId = (_tokenIds[0] + 5) / 6;

        puppetsBaseURI[tokenId] = _cid;
        sigUsed[_key] = true;
        _safeMint(msg.sender, tokenId);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        
        return tokenIds;
    }

    //only Owner
    function setPuppetsBaseURI(uint256 _tokenId, string memory _newBaseUri) external onlyOwner {
        puppetsBaseURI[_tokenId] = _newBaseUri;
    }

    function resetSigUsed(string memory _key) external onlyOwner {
        sigUsed[_key] = false;
    }

    function flipAssemble() external onlyOwner {
        assembleIsActive = !assembleIsActive;
    }

    function setPuppetPartsContract(address _contract) external onlyOwner {
        PuppetParts = iPuppetParts(_contract);
    }
}