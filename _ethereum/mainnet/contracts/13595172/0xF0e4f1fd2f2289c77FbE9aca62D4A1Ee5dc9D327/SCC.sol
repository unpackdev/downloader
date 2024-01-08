// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";


contract SCC is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    struct Card {
        uint256 level;
        uint256 price;
        string tokenURI;
    }

    // level to Card
    mapping (uint256 => Card) private cardList;
    mapping (uint256 => bytes32) public roots;
    // tokenId to level
    mapping (uint256 => uint256) public cardIds;
    // level for sale
    mapping (uint256 => bool) public cardForSale;
    
    mapping (address => bool) public minted;
    
    mapping (uint256 => mapping (address => bool)) public wlMinted;
    uint256 public cardNum;
    
    constructor() ERC721("SuperCollectorCard", "SCC") {
    }

    /** mint */
    function _mintCard(uint256 level, uint256 num, address to) internal {
        for(uint256 i = 0; i < num; i++) {
            uint256 tokenIndex = totalSupply();
            _safeMint(to, tokenIndex);
            cardIds[tokenIndex] = level;
        }
    }
    
    // mint for sale
    function mint(uint256 level) external payable {
        Card memory card = cardList[level];
        require(bytes(card.tokenURI).length != 0, "card not exist");
        require(cardForSale[level], "card not for sale");
        require(!minted[msg.sender], "already minted");
        require(msg.value >= card.price, "wrong ether value");
        _mintCard(level, 1, msg.sender);
        minted[msg.sender] = true;
    }

    // mint for whitelist
    function mintWhiteList(uint256 level, bytes32[] calldata proof) external {
        Card memory card = cardList[level];
        require(bytes(card.tokenURI).length != 0, "card not exist");
        require(!wlMinted[level][msg.sender], "already minted");
        require(
            MerkleProof.verify(
                proof, roots[level], keccak256(abi.encodePacked(msg.sender))
            ), 
            "invalid proof");
        _mintCard(level, 1, msg.sender);
        wlMinted[level][msg.sender] = true;
    }

    function verifyWhiteList(uint256 level, address user, bytes32[] calldata proof) external view returns (bool) {
        return MerkleProof.verify(proof, roots[level], keccak256(abi.encodePacked(user)));
    }

    function isWhiteListed(address user) public view returns (bool[] memory) {
        bool[] memory res = new bool[](cardNum);
        for(uint256 i = 0; i < cardNum; i++) {
            res[i] = wlMinted[i][user];
        }
        return res;
    }

    function giveAway(address to, uint256 level, uint256 num) public onlyOwner {
        Card memory card = cardList[level];
        require(bytes(card.tokenURI).length != 0, "card not exist");
        _mintCard(level, num, to);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return tokenId < totalSupply() ? cardList[cardIds[tokenId]].tokenURI : "";
    }
    
    function addCard(uint256 level, uint256 price, string memory uri) public onlyOwner {
        require(bytes(cardList[level].tokenURI).length == 0, "card already exist");
        Card memory newCard = Card(
            level,
            price,
            uri
        );
        cardList[level] = newCard;
        cardNum = cardNum.add(1);
    }

    function removeCard(uint256 level) public onlyOwner {
        require(bytes(cardList[level].tokenURI).length != 0, "card not exist");
        delete cardList[level];
        cardNum = cardNum.sub(1);
    }

    function setPrice(uint256 cardId, uint256 price) public onlyOwner {
        Card memory card = cardList[cardId];
        require(bytes(card.tokenURI).length != 0, "card not exist");
        card.price = price;
        cardList[cardId] = card;
    }

    function setUri(uint256 level, string calldata uri) public onlyOwner {
        require(bytes(cardList[level].tokenURI).length != 0, "card not exist");
        cardList[level].tokenURI = uri;
    }

    function setRoot(uint256 level, bytes32 root) public onlyOwner {
        roots[level] = root;
    }

    function pauseSale(uint256 cardId) public onlyOwner {
        require(cardForSale[cardId], "already paused");
        cardForSale[cardId] = false;
    }

    function unpauseSale(uint256 cardId) public onlyOwner {
        require(!cardForSale[cardId], "already unpaused");
        cardForSale[cardId] = true;
    }

    receive() external payable {}
    
    function withdraw() public onlyOwner {
        uint256 val = address(this).balance;
        payable(owner()).transfer(val);
    }
}
