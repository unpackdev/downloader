//SPDX-License-Identifier: Unlicense

// @title: The Tiger Cub Club
// @author: TigerCubClub Team

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IJungle {
    function burn(address _from, uint256 _amount) external;
    function updateReward(address _from, address _to) external;
} 

contract TigerCubClub is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private baseURI;
    string public notRevealedUri;

    bool public paused = false;
    bool public revealed = false;

    uint16 public maxSupply;
    uint16 public maxGenCount;
    uint16 public presaleCount;
    uint16 public rescueCount;
    uint256 public price;
    uint256 public maxPurchaseAmount;

    bool public presaleActive;
    bool public saleActive;

    mapping (address => uint8) public presaleWhitelist;

    address private w1;
    address private w2;

    struct TigerData {
        string name;
        string bio;
    }

    IJungle public Jungle;

    uint256 constant public RESCUE_PRICE = 1000 ether;
    uint256 constant public NAME_CHANGE_PRICE = 200 ether;
    uint256 constant public BIO_CHANGE_PRICE = 200 ether;

    mapping(uint256 => TigerData) public tigerData;

    event TigerCreated(uint256 tigerId, uint256 rescuer);
    event NameChanged(uint256 tigerId, string tigerName);
    event BioChanged(uint256 tigerId, string tigerBio);

    constructor(string memory _initNotRevealedUri) ERC721("Tiger Cub Club", "TigerCubClub") {
        maxSupply = 8100;
        maxGenCount = 6600;
        rescueCount = 0;
        price = 0.04 ether;
        maxPurchaseAmount = 15;
        presaleActive = false;
        saleActive = false;
        w1 = 0x221aaeC36b78a57081BE5541796B544803Eb8627;
        w2 = 0xCe790C8E68C90D6f0C8fbC31E6AB8f96E1588ef7;

        setNotRevealedURI(_initNotRevealedUri);
    }

    receive() external payable {}
    
    //MODIFIERS
    modifier notPaused {
         require(!paused, "the contract is paused");
         _;
    }

   function mintReserve(uint16 numberOfMints) public onlyOwner {
        uint16 supply = uint16(totalSupply()) - rescueCount;
        uint16 supplyAfter = supply + numberOfMints;
        require(supplyAfter <= maxGenCount, "Invalid amount");
        
        if(presaleActive) presaleCount = supplyAfter;

        for(uint16 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
            emit TigerCreated(supply + i, 0);
        }
    }

    function mintPresale(uint8 numberOfMints) public payable notPaused {
        uint16 supply = uint16(totalSupply()) - rescueCount;
        uint8 reserved = presaleWhitelist[msg.sender];
        uint16 supplyAfter = supply + numberOfMints;
        require(presaleActive,                              "Presale must be active to mint");
        require(numberOfMints <= reserved,                  "Can't mint more than reserved");
        require(supplyAfter <= maxGenCount,   "Purchase would exceed max supply of Genesis Tigers");
        require(price.mul(numberOfMints) <= msg.value,      "Ether value sent is not correct");
        presaleWhitelist[msg.sender] = reserved - numberOfMints;
        presaleCount = supplyAfter;

        for(uint256 i; i < numberOfMints; i++){
            _safeMint(msg.sender, supply + i);
            emit TigerCreated(supply + i, 0);
        }
    }

   function mint(uint256 numberOfMints) public payable notPaused {
        uint256 supply = totalSupply() - rescueCount;
        require(saleActive,                                 "Sale must be active to mint");
        require(numberOfMints <= maxPurchaseAmount,     "Invalid purchase amount");
        require(supply.add(numberOfMints) <= maxGenCount,   "Purchase would exceed max supply of Genesis Tigers");
        require(price.mul(numberOfMints) <= msg.value,      "Ether value sent is not correct");
        
        for(uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
            emit TigerCreated(supply + i, 0);
        }
    }

    function editPresale(address[] calldata presaleAddresses) external onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = 10;
        }
    }

    function balanceOfOwner(address owner) external view returns(uint256 _presaleBalance, uint256 _genesisBalance) {
        uint256 tokenCount = balanceOf(owner);

        for(uint256 i; i < tokenCount; i++){
            if(tokenOfOwnerByIndex(owner, i) < presaleCount) _presaleBalance++;
            if(tokenOfOwnerByIndex(owner, i) < maxGenCount) _genesisBalance++;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!revealed) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? super.tokenURI(tokenId) : "";
        }
    }

    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function setPresaleStatus(bool _status) public onlyOwner {
        presaleActive = _status;
    }

    function setSaleStatus(bool _status) public onlyOwner {
        saleActive = _status;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setMaxPurchaseAmount(uint256 _amount) public onlyOwner {
        maxPurchaseAmount = _amount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    //ONLY OWNER SETTERS
    function reveal() public onlyOwner {
        revealed = true;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

   function withdraw() public {
        require(_msgSender() == w1 || _msgSender() == w2 || _msgSender() == owner(), "Withdraw not allowed");

        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(w1, balance.mul(20).div(100));
        _widthdraw(w2, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success,) = _address.call{value : _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier tigerOwner(uint256 tigerId) {
        require(ownerOf(tigerId) == msg.sender, "Cannot interact with a Tiger you do not own");
        _;
    }

    function rescue(uint256 rescuer) external tigerOwner(rescuer) notPaused {
        require(rescueCount < maxSupply - maxGenCount, "Cannot rescue any more Tigers");
        require(rescuer < maxGenCount, "Cannot rescue with rescued Tiger");

        Jungle.burn(msg.sender, RESCUE_PRICE);
        uint256 tigerId = maxGenCount + rescueCount;
        rescueCount++;
        _safeMint(msg.sender, tigerId);
        emit TigerCreated(tigerId, rescuer);
    }

    function changeName(uint256 tigerId, string memory newName) external tigerOwner(tigerId) {
        bytes memory n = bytes(newName);
        require(n.length > 0 && n.length < 25,                          "Invalid name length");
        require(sha256(n) != sha256(bytes(tigerData[tigerId].name)),    "New name is same as current name");
        
        Jungle.burn(msg.sender, NAME_CHANGE_PRICE);
        tigerData[tigerId].name = newName;
        emit NameChanged(tigerId, newName);
    }

    function changeBio(uint256 tigerId, string memory newBio) external tigerOwner(tigerId) {
        Jungle.burn(msg.sender, BIO_CHANGE_PRICE);
        tigerData[tigerId].bio = newBio;
        emit BioChanged(tigerId, newBio);
    }

    function setJungle(address jungle) external onlyOwner {
        Jungle = IJungle(jungle);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (tokenId < maxGenCount) {
            Jungle.updateReward(from, to);
        }
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (tokenId < maxGenCount) {
            Jungle.updateReward(from, to);
        }
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }
}