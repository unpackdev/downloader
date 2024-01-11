//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

import "./I100kRenderer.sol";

contract Only100kPFPs is Ownable, ERC721A {
    uint256 constant public MAX_SUPPLY = 10000;
    uint256 constant public TEAM_MINT_MAX = 100;
    
    uint256 public publicPrice = 0.004665 ether;

    uint256 constant public FREE_MINT_LIMIT = 10;

    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 10;

    uint256 public TOTAL_SUPPLY_TEAM;

    // Variables to protect the collection's value
    uint256 public mintingStartTime;
    uint256 public minimumPrice = 50 ether;

    string public revealedURI;

    string constant public HIDDEN_URI = "ipfs://QmZdq8UQ1eXVuieXY6GgFgGQKeAAHDQuasv95Hx2mkEuu5";

    string public CONTRACT_URI = "ipfs://QmZdq8UQ1eXVuieXY6GgFgGQKeAAHDQuasv95Hx2mkEuu5";

    bool public paused = true;
    bool public revealed = false;
    
    bool public freeSale = true;
    bool public publicSale = false;

    address constant internal DEV_ADDRESS = 0x31f8933601497fD6Ade6EaEaA6a66b281d238E70;

    address public only100kRenderer;

    mapping(address => uint256) public numUserFreeMints;

    constructor() ERC721A("Only 100k PFPs", "Only100kPFPs") { }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        // It has been over a week since minting has started
        if (block.timestamp >= mintingStartTime + 604800) {
            require(msg.value >= minimumPrice, "Can only sell for $100k+");
        }
    }

    function refundOverpay(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    function teamMint(uint256 quantity) public payable mintCompliance(quantity) {
        require(msg.sender == owner(), "Team minting only");
        require(TOTAL_SUPPLY_TEAM + quantity <= TEAM_MINT_MAX, "No team mints left");
        require(totalSupply() >= 1000, "Team mints after free");

        TOTAL_SUPPLY_TEAM += quantity;

        _safeMint(msg.sender, quantity);
    }

    function freeMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");

        uint256 newSupply = totalSupply() + quantity;
        
        require(newSupply <= 1000, "Not enough free supply");

        uint256 currMints = numUserFreeMints[msg.sender];
                
        require(currMints + quantity <= FREE_MINT_LIMIT, "User max free limit");
        
        numUserFreeMints[msg.sender] = (currMints + quantity);

        if(newSupply == 1000) {
            freeSale = false;
            publicSale = true;
        }

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(publicSale, "Public sale inactive");
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 price = publicPrice;
                
        refundOverpay(price * quantity);

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed) {
            return I100kRenderer(only100kRenderer).tokenURI(_tokenId);
        }
        else {
            return HIDDEN_URI;
        }
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setPublicPrice(uint256 _price) public onlyOwner {
        publicPrice = _price;
    }

    function setRendererAddress(address _renderer) public onlyOwner {
        only100kRenderer = _renderer;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    function revealCollection(bool _revealed, string memory _baseUri) public onlyOwner {
        revealed = _revealed;
        revealedURI = _baseUri;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }
    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    function setMintingStartTime(uint256 _startTime) public onlyOwner {
        mintingStartTime = _startTime;
    }

    function setMinimumPrice(uint256 _minimumPrice) public onlyOwner {
        minimumPrice = _minimumPrice;
    }

    function withdraw() external payable onlyOwner {
        (bool succ, ) = payable(DEV_ADDRESS).call{
            value:address(this).balance
        }("");
        require(succ, "Withdraw failed");
    }

    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}