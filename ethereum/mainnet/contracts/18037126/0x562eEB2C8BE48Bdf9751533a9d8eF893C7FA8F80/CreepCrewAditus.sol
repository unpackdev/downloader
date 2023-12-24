// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./ERC721AUpgradeable.sol";
import "./OperatorFiltererUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract CreepCrewAditus is
ERC721AUpgradeable,
Initializable,
PausableUpgradeable,
OperatorFiltererUpgradeable,
Ownable2StepUpgradeable {
    
    string public baseURI;
    uint256 public MAX_SUPPLY;
    uint256 public MAX_MINT_PER_WALLET;
    uint256 public maxMintPerTx;
    uint256 public MINT_PRICE;
    
    mapping(address => uint256) public mintCount;
    
    
    function initialize(string memory _uri,address _operatorFilterer) external
    initializerERC721A
    initializer {
        __ERC721A_init("Creep Crew Aditus", "CCA");
        __Ownable2Step_init();
        __Pausable_init();
        __OperatorFilterer_init(_operatorFilterer, true);
        baseURI = _uri;
        MINT_PRICE = 0;
        MAX_SUPPLY = 777;
        MAX_MINT_PER_WALLET = 1;
        maxMintPerTx = 1;
    }
    
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }
    
    function setMaxMintPerWallet(uint256 _maxMintPerWallet) public onlyOwner {
        MAX_MINT_PER_WALLET = _maxMintPerWallet;
    }
    
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        MINT_PRICE = _mintPrice;
    }
    
    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }
    
    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function mint(uint256 amount) external payable whenNotPaused {
        unchecked {
            require(totalSupply() + amount <= MAX_SUPPLY, "Max supply reached");
            require(
                mintCount[msg.sender] + amount <= MAX_MINT_PER_WALLET,
                "Max mint per wallet reached"
            );
            require(amount <= maxMintPerTx, "Max mint per tx reached");
            require(msg.value == MINT_PRICE * amount, "Insufficient funds");
            mintCount[msg.sender] += amount;
            _mint(msg.sender, amount);
        }
    }
    
    function airdrop(address[] memory to, uint256 tokenAmount) external onlyOwner {
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], tokenAmount);
        }
    }
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
    
    function withdraw(address payable to) public onlyOwner {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;
        
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    
    // Opensea overiding functions
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
}
