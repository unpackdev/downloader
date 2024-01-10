// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract BoredPunks is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAXIMUM_SUPPLY = 2222;

    uint256 public constant MAXIMUM_MINT_WL = 2;
    uint256 public constant MAXIMUM_MINT_PUBLIC = 2;

    uint256 WL_PRICE = 0.18 ether;
    uint256 PUBLIC_PRICE = 0.18 ether;

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
    ) ERC721A("BORED PUNKS", "BP") {
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

        require(workflow == WorkflowStatus.Presale, "BORED PUNKS: Presale is not started yet!");
        require(tokensPerWalletWhitelist[msg.sender] + ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("BORED PUNKS: Presale mint is ", MAXIMUM_MINT_WL.toString(), " token only.")));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "BORED PUNKS: You are not whitelisted");
        require(msg.value >= price * ammount, "BORED PUNKS: Not enough ETH sent");

        tokensPerWalletWhitelist[msg.sender] += ammount;
        _safeMint(msg.sender, ammount);
    }

    function publicMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "BORED PUNKS: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "BORED PUNKS: Public is not started yet");
        require(msg.value >= price * ammount, "BORED PUNKS: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("BORED PUNKS: You can only mint up to ", MAXIMUM_MINT_PUBLIC.toString(), " token at once!")));
        require(tokensPerWalletPublic[msg.sender] + ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("BORED PUNKS: You cant mint more than ", MAXIMUM_MINT_PUBLIC.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "BORED PUNKS: Mint too large!");

        tokensPerWalletPublic[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function gift(address[] calldata addresses) public onlyOwner {
        require(addresses.length > 0, "BORED PUNKS : Need to gift at least 1 NFT");
        for (uint256 i = 0; i < addresses.length; i++) {
          _safeMint(addresses[i], 1);
        }
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
        uint256 _balance = address(this).balance;
        payable(0x040c71DeE36b1ed168a731205831Ac80173D9F7A).transfer(((_balance * 5000) / 10000));
        payable(0xB2cE87Db853b1275b7F16F9d908CBbd886AC9c78).transfer(((_balance * 5000) / 10000));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

}
