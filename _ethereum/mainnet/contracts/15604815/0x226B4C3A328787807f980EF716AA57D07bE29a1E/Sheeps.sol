// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Sheeps is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    string private _baseExt;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant PRICE_PER_TOKEN = 0.01 ether;
    uint256 public constant BLOCK_PER_DAY = 6650;
    uint256 public startBlock;

    mapping(address => uint8) private _allowList;
    address public sheepToken;

    struct Sheep {
        //[0-9];
        uint256 category;
        // max 30
        uint256 level;
        // control max level -> star
        uint256 star;
        // used to control the level of upgrade
        uint256 experience;
        uint256 powerValue;
    }

    Sheep[] public sheeps;

    constructor(uint256 _startBlock) ERC721("Sheeps", "SHEEP") {
        startBlock = _startBlock;
    }
    function setSheepToken(address _sheep) public onlyOwner {
        sheepToken = _sheep;
    }
    function gameMintSkin(address _user) external returns(uint256) {
        require(sheepToken == msg.sender, "Accessible: caller is not the ido address");
        uint256 _id = totalSupply();
        _mint(_user, _id);
        return _id;
    }
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function price() public view returns(uint256) {
        uint256 i = (block.number - startBlock)/BLOCK_PER_DAY;
        return PRICE_PER_TOKEN*(i+1);
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(block.number>startBlock, 'not start!');
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(price() * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual override{
        super._safeMint(to, tokenId, data);
        uint256 random;
        assembly {
            random := difficulty()
        }
        bytes32 s = keccak256(abi.encodePacked(block.timestamp, random, tokenId, to));

        sheeps.push(Sheep(uint8(s[5])%10, uint8(s[6])%100, uint8(s[10])%5, 0, uint8(s[15])%1000));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function approve(address to, uint256 tokenId) public virtual override {
        super.approve(to, tokenId);
        checkStatus();
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        super.setApprovalForAll(operator, approved);
        checkStatus();
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        checkStatus();
    }
    function checkStatus() public {
        require(block.number - startBlock >= BLOCK_PER_DAY*10, "Purchasing can not transfer");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseExt(string memory baseExt_) external onlyOwner() {
        _baseExt = baseExt_;
    }
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return  bytes(_baseExt).length > 0 ? string(abi.encodePacked(uri, _baseExt)) : uri;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(block.number>startBlock, 'not start!');
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(price() * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}