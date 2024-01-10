// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract OutdoorKitties is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;


    bytes32 public root;

    uint256  price = 0.05 ether;

    uint256 maxSupply = 5555;
    Counters.Counter private supply;

    uint256 maxGiveaway = 125;
    uint256 currentGivenAway = 0;

    uint256 legendaries = 11;

    bool revealed = false;
    bool presale = true;
    bool private legendaryMintDone = false;

    string baseURI;

    mapping(address => uint256) whitelistMintAmount;

    modifier mintCondition(uint256 amount) {
        require(amount > 0, "You must mint at least 1!");
        require(supply.current() + amount <= maxSupply-maxGiveaway-legendaries);
        require(amount <= 5 || msg.sender == owner(), "Max 5 mints per transaction!");
        require(msg.value >= price * amount || msg.sender == owner(), "Not enough funds in wallet!");
        _;
    }

    constructor () ERC721("OutdoorKitties", "ODK") ReentrancyGuard(){
        _pause();        
    }

    function mintLoop(uint256 amount) internal {
        for (uint256 i = 0; i < amount; ++i) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
    }

    function presaleMint(uint256 amount, bytes32[] calldata _merkleProof) external payable whenNotPaused nonReentrant mintCondition(amount) {
        require(presale, "Presale is closed!");
        require(whitelistMintAmount[msg.sender] + amount <= 2, "Only 2 mints in presale!");
        whitelistMintAmount[msg.sender] += amount;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, root, leaf), "merkle says you are not allowed");
        mintLoop(amount);
    }

    function publicMint(uint256 amount) external payable whenNotPaused nonReentrant mintCondition(amount) {
        require(!presale, "Public sale is not active.");
        mintLoop(amount);
    }
 

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist.");

        string memory currentBaseURI = _baseURI();
        if (revealed) {            
           return bytes(currentBaseURI).length > 0
                 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) 
                 : "";
        } else {
            return currentBaseURI;
        }
    }

    function isPresaleActive() external view returns (bool) {
        return presale;
    }

    function getCurrentSupply() view public returns (uint256) {
        return supply.current();
    }

    function getMaxSupply() view external returns (uint256) {
        return maxSupply;
    }

    function getPrice() external view  returns (uint256) {
        return price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getWhitelistMintAmount(address adr) public view returns (uint256) {
        return whitelistMintAmount[adr];
    }

    /*
    Owner functions
    */
    
    function mintLegendariesForGiveaway() external onlyOwner {
        require(!legendaryMintDone, "Legendaries mint is already done!");
        legendaryMintDone = !legendaryMintDone;
        mintLoop(11);
    }

    function giveaway(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "Wrong input");

        for(uint256 i = 0; i < addresses.length; i++) {
            require(amounts[i] + supply.current() <= maxSupply, "Can't mint that much");
            require(amounts[i] + currentGivenAway <= maxGiveaway, "All given away");
                for(uint256 j = 0; j < amounts[i]; j++) {
                supply.increment();
                currentGivenAway++;
                _safeMint(addresses[i], supply.current());
            }
        }
    }

    function endPresale() external onlyOwner {
        presale = false;
    }

    function setPause(bool value) external onlyOwner {
      if (value) {        
        _pause();
      } else {
        _unpause();
      }
    }

    function reveal(string memory revealedLink) external onlyOwner {
      revealed = true;
      baseURI = revealedLink;
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        baseURI = newUri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function widthraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}