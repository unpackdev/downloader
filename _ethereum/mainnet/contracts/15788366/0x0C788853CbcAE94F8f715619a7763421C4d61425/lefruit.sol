/* ___      _______    _______  ______    __   __  ___   _______ 
|   |    |       |  |       ||    _ |  |  | |  ||   | |       |
|   |    |    ___|  |    ___||   | ||  |  | |  ||   | |_     _|
|   |    |   |___   |   |___ |   |_||_ |  |_|  ||   |   |   |  
|   |___ |    ___|  |    ___||    __  ||       ||   |   |   |  
|       ||   |___   |   |    |   |  | ||       ||   |   |   |  
|_______||_______|  |___|    |___|  |_||_______||___|   |___|  
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "./Ownable.sol";

contract lefruit is ERC721A, Ownable {
    uint public MINTSIZE = 4799;
    uint public constant MAX_PER_WALLET = 2;
    uint public constant MAX_FREE_PER_WALLET = 1;
    bool public live = false;
    uint public price = 0.007 ether;
    uint public vipPrice = 0.01 ether;
    //team reserve
    uint public constant reserve = 201;
    string public baseURI = "ipfs://QmYKmZJUxN94jnZm8CFqDK1vLrHgwmF1oAWggHS5kTda6v/";

    mapping(uint => bool) public vipToken;

    constructor() ERC721A("Le Fruit", "LEFR") {
        _mint(msg.sender, 1);
    }

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    /// @notice Check out our vipMint function at the bottom to enjoy special discount & benefit!
    function mint(uint _amt) external payable {
        require(live, "Sale is paused!");
        require(tx.origin == msg.sender, "no bot!");
        require(MINTSIZE >= _totalMinted() + _amt, "sold out!");
        require(_amt > 0 ,"must buy 1");
        require(_numberMinted(msg.sender) + _amt <= MAX_PER_WALLET,"Max per wallet exceeded!");

        uint count = _numberMinted(msg.sender) + _amt;
        if(count > MAX_FREE_PER_WALLET){
            require(msg.value >= (count - MAX_FREE_PER_WALLET) * price , "Insufficient funds");
        } 
        _mint(msg.sender, _amt);
    }

    /// @notice Become our VIP! Grab (2) NFTs with discounted price: 0.01e. You'll get special traits! Rarity will affect your future reward and benefit (WL, nft etc).
    function vipMint(uint _amt) external payable {
        require(live, "Sale is paused!");
        require(tx.origin == msg.sender, "no bot!");
        require(MINTSIZE >= _totalMinted() + _amt, "sold out!");
        require(_amt == 2 ,"must buy 2!");
        require(_numberMinted(msg.sender) + _amt <= MAX_PER_WALLET,"Max per wallet exceeded!");
        require(msg.value >= vipPrice, "Insufficient funds");
        for (uint k = 1; k <= _amt; ++k) {
            vipToken[_totalMinted() + k] = true;
        }
        _mint(msg.sender, _amt);
    }

    /// @notice Team reserve for marketing, event, investor and collab
    function storing(uint quantity) external onlyOwner {
        require(_numberMinted(msg.sender) + quantity <= reserve, "exceed reserved amt");
        uint batchMintAmount = quantity > 10 ? 10 : quantity;
        uint numChunks = quantity / batchMintAmount;
        for (uint i = 0; i < numChunks; ++i) {
            _mint(msg.sender, batchMintAmount);
        }
    }

    function vault() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "failed");
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function goLive(bool _live) external onlyOwner {
        live = _live;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "token not exist");
        return string(abi.encodePacked(baseURI,_toString(_tokenId),".json"));
    }

    function getPrice() external view returns (uint){
        return price;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setVIPPrice(uint _vipprice) external onlyOwner {
        vipPrice = _vipprice;
    }
}