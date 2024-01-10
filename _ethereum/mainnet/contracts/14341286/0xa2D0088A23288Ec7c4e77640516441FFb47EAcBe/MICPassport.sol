// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract MICPassport is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;

    string public baseURI;
    string public notRevealedUri;

    bool public isRevealed = false;

    enum WorkflowStatus {
        Disabled,
        Enabled
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWallet;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721("MetaIsland Citizen Passport", "MICP") {
        workflow = WorkflowStatus.Disabled;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function hasWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function freeMint(bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(workflow == WorkflowStatus.Enabled, "MICP: Free mint is not started yet!");
        require(tokensPerWallet[msg.sender] + 1 <= 1, string(abi.encodePacked("MICP: Free mint is 1 token only.")));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "MICP: You are not allowed to mint");

        tokensPerWallet[msg.sender] += 1;
        _safeMint(msg.sender, supply + 1);
    }

    function gift(address[] calldata addresses) public onlyOwner {
        uint256 supply = totalSupply();
        require(addresses.length > 0, "MICP : Need to gift at least 1 NFT");
        for (uint256 i = 0; i < addresses.length; i++) {
          _safeMint(addresses[i], supply + 1);
        }
    }

    function enableSale() external onlyOwner {
        workflow = WorkflowStatus.Enabled;
    }

    function disableSale() external onlyOwner {
        workflow = WorkflowStatus.Disabled;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function revokePassport(uint256 _tokenId) public onlyOwner {
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed == false) {
          return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

}
