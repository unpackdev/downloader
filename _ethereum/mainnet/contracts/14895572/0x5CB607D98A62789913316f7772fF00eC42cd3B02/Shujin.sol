// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Shujin is Ownable, ERC721A, ReentrancyGuard {
    uint256 public maxPerAddressDuringMint = 2;
    uint256 public immutable collectionSize = 5000;
    uint256 public immutable duration = 604800; //7days
    uint256 public price = 0;
    uint256 _batch = 0;
    uint256 _timeBeforeNextBatch = 0;

    bool public paused = true;
    //metadata URI
    string _baseTokenURI;
    string baseExtension = ".json";

    mapping(uint256 => Specimen) specimens;
    mapping(address => uint256) public allowedList;

    enum Status { CLOSED, ACTIVE  }

    struct Specimen {
        uint256 price;
        uint holdUntil;
        Status status;
    }

    event PriceUpdated(uint256 newPrice);
    event BatchUpdated(uint256 newBatch, uint256 time);
    event PauseUpdated(bool state);
    event PerMintUpdated(uint max);

    constructor()
    ERC721A("SHUJIN", "SHJN") {
        _baseTokenURI = "https://gateway.moralisipfs.com/ipfs/QmfEe927y3bY2NDGE7RVSDfygywSfYZ5myAAJeVcVYigam/";
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 quantity)
    external
    payable
    callerIsUser
    {
        //check for input 0
        require(quantity > 0, "Select a valid quantity");

        require(!paused, "Minting is paused");

        require(totalMinted() + quantity <= _batch, "Current batch max reached.");

        require(quantity <= maxPerAddressDuringMint, "You can't mint this quantity");

        require(totalMinted() + quantity <= collectionSize, "Maximum supply reached");

        refundIfOver(price * quantity);

        Specimen memory sp;

        for (uint256 i = totalMinted() + 1; i <= uint256(quantity) + totalMinted(); i++) {
            sp.price = price;
            sp.holdUntil = uint256(block.timestamp) + duration;
            sp.status = Status.ACTIVE;
            specimens[i] = sp;
        }

        _safeMint(msg.sender, quantity);
    }

    // For marketing etc.
    function devMint(uint256 _quantity, uint256 _price) external onlyOwner {
        require(
            totalMinted() + _quantity <= collectionSize,
            "quantity exceeds collection"
        );

        require(totalMinted() + _quantity <= _batch, "Current batch max reached.");

        Specimen memory sp;

        for (uint256 i = totalMinted() + 1; i <= _quantity + totalMinted(); i++) {
            sp.price = _price;
            sp.holdUntil = uint256(block.timestamp);
            sp.status = Status.ACTIVE;
            specimens[i] = sp;
        }

        _safeMint(msg.sender, _quantity);

    }

    function burn (uint token_id) external callerIsUser nonReentrant{
        require(_exists(token_id), "Token not minted or invalid.");
        require(ownerOf(token_id) == msg.sender, "Must be owner to burn.");
        require(block.timestamp >= specimens[token_id].holdUntil, 'Not eligible for burning yet.');

        (bool success, ) = payable(msg.sender).call{value: specimens[token_id].price}("");
        require(success, "Transfer failed");

        specimens[token_id].status = Status.CLOSED;
        _burn(token_id);
    }

    //funding contract
    function addMoney()
    external
    payable
    onlyOwner {}

    function withdrawMoney(uint256 amount) external payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function refundIfOver(uint256 price_) private {
        require(msg.value >= price_, "Insufficient balance. Update your balance");
        if (msg.value > price_) {
            payable(msg.sender).transfer(msg.value - price_);
        }
    }

    function updateBatch(uint256 quantity, uint256 _time) external onlyOwner {
        paused = true; emit PauseUpdated(true);
        _batch = _batch + quantity;
        _timeBeforeNextBatch = uint256(block.timestamp) + _time;
        emit BatchUpdated(_batch, _timeBeforeNextBatch);
    }

    function updateMaxPerMint(uint256 quantity) external onlyOwner {
        maxPerAddressDuringMint = quantity;
        emit PerMintUpdated(quantity);
    }

    function updatePrice(uint256 price_) external onlyOwner callerIsUser{
        price = uint256(price_);
        emit PriceUpdated(price_);
    }

    function getBatch() external view returns (uint256){
        return _batch;
    }

    function getTime() external view returns (uint256){
        return _timeBeforeNextBatch;
    }

    function getSpecimen(uint256 token_id) external view returns (Specimen memory) {
        return specimens[token_id];
    }

    function getPrice() external view returns(uint256) {
        return price;
    }

    function pauseMint(bool _state) external onlyOwner callerIsUser {
        paused = _state;
        emit PauseUpdated(_state);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 token_id)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(token_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(token_id), baseExtension))
        : "";
    }


    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256){
        return _totalMinted();
    }

    function allowListMint() external payable callerIsUser {

        require(allowedList[msg.sender] > 0, "Not eligible for whiteList mint");
        require(totalMinted() + 1 <= collectionSize, "Reached max supply");

        refundIfOver(price);

        _safeMint(msg.sender, 1);

        Specimen memory sp;
        sp.price = price;
        sp.holdUntil = uint256(block.timestamp) + duration;
        sp.status = Status.ACTIVE;
        specimens[uint256(totalMinted())] = sp;

        allowedList[msg.sender]--;
    }

    function seedAllowedList(address[] memory addresses)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowedList[addresses[i]] = 1;
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}