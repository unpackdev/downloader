// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract MutantSmartBeast is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAXIMUM_SUPPLY = 750;

    uint256 public constant MAXIMUM_MINT_WL = 2;
    uint256 public MAXIMUM_MINT_PUBLIC = MAXIMUM_SUPPLY;

    uint256 WL_PRICE = 0.15 ether;
    uint256 PUBLIC_PRICE = 0.20 ether;

    bytes32 public merkleRoot;
    bytes32 public merkleRoot_Freemint;

    string public baseURI;
    string public notRevealedUri;

    bool public isRevealed = false;
    bool public isFreeMint = false;

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
    mapping(address => uint256) public tokensPerWalletFreemint;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A("MUTANT SMART BEAST", "MSB") {
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

    function _checkFreeAmount(uint256 maxCount, bytes32[] calldata proof) internal view returns(bool)  {
      require(MerkleProof.verify(proof, merkleRoot_Freemint, keccak256(abi.encode(msg.sender, maxCount))));
      return true;
    }

    function freeMint(uint256 amount, uint256 maxAmount, bytes32[] calldata _merkleProof) external nonReentrant {
        require(workflow == WorkflowStatus.Before && isFreeMint, "MUTANT SMART BEAST: Freemint is not started yet!");

        bool access = _checkFreeAmount(maxAmount, _merkleProof);
        uint256 freeBalance = tokensPerWalletFreemint[msg.sender];

        require(access);
        require(amount + freeBalance <= maxAmount, "MUTANT SMART BEAST : Amount exceed your total allocation for free mint");

        tokensPerWalletFreemint[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function presaleMint(uint256 ammount, bytes32[] calldata _merkleProof) external payable nonReentrant
    {
        uint256 supply = totalSupply();
        uint256 price = privateSalePrice();

        require(workflow != WorkflowStatus.SoldOut, "MUTANT SMART BEAST: SOLD OUT!");
        require(workflow == WorkflowStatus.Presale, "MUTANT SMART BEAST: Presale is not started yet!");
        require(msg.value >= price * ammount, "MUTANT SMART BEAST: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("MUTANT SMART BEAST: You can only mint up to ", MAXIMUM_MINT_WL.toString(), " token at once!")));
        require(tokensPerWalletWhitelist[msg.sender] + ammount <= MAXIMUM_MINT_WL, string(abi.encodePacked("MUTANT SMART BEAST: You cant mint more than ", MAXIMUM_MINT_WL.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "MUTANT SMART BEAST: Mint too large!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "MUTANT SMART BEAST: You are not whitelisted");

        tokensPerWalletWhitelist[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function publicMint(uint256 ammount) public payable nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice();

        require(workflow != WorkflowStatus.SoldOut, "MUTANT SMART BEAST: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "MUTANT SMART BEAST: Public is not started yet");
        require(msg.value >= price * ammount, "MUTANT SMART BEAST: Not enough ETH sent");
        require(ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("MUTANT SMART BEAST: You can only mint up to ", MAXIMUM_MINT_PUBLIC.toString(), " token at once!")));
        require(tokensPerWalletPublic[msg.sender] + ammount <= MAXIMUM_MINT_PUBLIC, string(abi.encodePacked("MUTANT SMART BEAST: You cant mint more than ", MAXIMUM_MINT_PUBLIC.toString(), " tokens!")));
        require(supply + ammount <= MAXIMUM_SUPPLY, "MUTANT SMART BEAST: Mint too large!");

        tokensPerWalletPublic[msg.sender] += ammount;

        if(supply + ammount == MAXIMUM_SUPPLY) {
          workflow = WorkflowStatus.SoldOut;
        }

        _safeMint(msg.sender, ammount);
    }

    function airdrop(address[] calldata addresses) public onlyOwner {
        require(addresses.length > 0, "MUTANT SMART BEAST : Need to airdrop at least 1 NFT");
        for (uint256 i = 0; i < addresses.length; i++) {
          _safeMint(addresses[i], 1);
        }
    }

    function gift(address addresses, uint256 quantity) public onlyOwner {
        require(quantity > 0, "MUTANT SMART BEAST : Need to gift at least 1 NFT");
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

    function setFreeMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot_Freemint = root;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function toggleFreeMint() public onlyOwner {
        isFreeMint = !isFreeMint;
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
        payable(0x800db90656E278bb70263e3318A3fdfC8025e249).transfer(((_balance * 5000) / 10000));
        payable(0x90B382ffaeD8bB7304c4c547eDB41c4fa20741b2).transfer(((_balance * 5000) / 10000));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

}
