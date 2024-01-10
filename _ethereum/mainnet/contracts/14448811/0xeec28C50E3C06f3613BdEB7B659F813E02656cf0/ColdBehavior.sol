// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract ColdBehavior is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAXIMUM_SUPPLY = 5555;

    uint256 public constant MAXIMUM_MINT_WL = 3;
    uint256 public constant MAXIMUM_MINT_PUBLIC = 5;

    uint256 WL_PRICE = 0.15 ether;
    uint256 PUBLIC_PRICE = 0.17 ether;

    bytes32 public merkleRoot;

    string public baseURI;
    string public notRevealedUri;

    bool public isRevealed = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut,
        Reveal
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWalletPublic;
    mapping(address => uint256) public tokensPerWalletWhitelist;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A("COLD BEHAVIOR", "CB") {
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function privateSalePrice() public view returns (uint256) {
        return WL_PRICE;
    }

    function getPrice() public view returns (uint256) {
        return PUBLIC_PRICE;
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function hasWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function presaleMint(uint256 ammount, bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 price = privateSalePrice();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(workflow == WorkflowStatus.Presale, "COLD BEHAVIOR: Presale is not started yet!");
        require(tokensPerWalletWhitelist[msg.sender] + ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("COLD BEHAVIOR: Presale mint is ", MAXIMUM_MINT_WL.toString(), " token only.")));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "COLD BEHAVIOR: You are not whitelisted");
        require(msg.value >= price * ammount, "COLD BEHAVIOR: Not enough ETH sent");

        tokensPerWalletWhitelist[msg.sender] += ammount;
        _safeMint(msg.sender, ammount);
    }

    function publicMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "COLD BEHAVIOR: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "COLD BEHAVIOR: Public is not started yet");
        require(msg.value >= price * ammount, "COLD BEHAVIOR: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("COLD BEHAVIOR: You can only mint up to ", MAXIMUM_MINT_PUBLIC.toString(), " token at once!")));
        require(tokensPerWalletPublic[msg.sender] + ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("COLD BEHAVIOR: You cant mint more than ", MAXIMUM_MINT_PUBLIC.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "COLD BEHAVIOR: Mint too large!");

        tokensPerWalletPublic[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function airdrop(address[] calldata addresses) public onlyOwner {
        require(addresses.length > 0, "COLD BEHAVIOR : Need to airdrop at least 1 NFT");
        for (uint256 i = 0; i < addresses.length; i++) {
          _safeMint(addresses[i], 1);
        }
    }

    function gift(address addresses, uint256 quantity) public onlyOwner {
        require(quantity > 0, "COLD BEHAVIOR : Need to gift at least 1 NFT");
        _safeMint(addresses, quantity);
    }

    function restart() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
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

    function updateWLPrice(uint256 _newPrice) public onlyOwner {
        WL_PRICE = _newPrice;
    }

    function updatePublicPrice(uint256 _newPrice) public onlyOwner {
        PUBLIC_PRICE = _newPrice;
    }

    function updateSupply(uint256 _newSupply) public onlyOwner {
        MAXIMUM_SUPPLY = _newSupply;
    }

    function withdraw() public onlyOwner {
        payable(0xe33A17E9Ebf683228a2dC4c9E80d4aAF217e91B9).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

}
