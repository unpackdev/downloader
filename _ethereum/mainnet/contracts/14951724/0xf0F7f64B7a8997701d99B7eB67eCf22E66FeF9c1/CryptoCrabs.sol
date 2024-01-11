//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";

contract CryptoCrabs is ERC721A, ERC2981, Ownable {
    struct Slot0 {
        address cheebiez;
        address ghouls;
        address v1ghouls;
        address v1crabs;
        uint32 startTime;
        uint32 endTime;
        uint16 maxMint;
        string revealedURI;
    }

    Slot0 public slot0;
    mapping(address => bool) private hasCrabMinted;
    mapping(address => bool) private hasCheeborGhoulMinted;
    mapping(address => bool) private hasPublicMinted;

    uint16 public constant MAXSUPPLY = 6969;

    constructor() ERC721A("CryptoCrabs", "CRBS") {
        slot0.cheebiez = 0x731fa995D38cAdE13175FDb62452232f4deC7b27;
        slot0.ghouls = 0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90;
        slot0.v1ghouls = 0x938e5ed128458139A9c3306aCE87C60BCBA9c067;
        slot0.startTime = 1655060400;
        slot0.endTime = 1655146800;
        slot0.maxMint = 20;
        slot0.revealedURI = "https://crabs.s3.amazonaws.com/data/";
        _mint(0x31AE2c2cAEC2Bc9211cC6E55D73Dc3e874BaBdbb, 5);
        _setDefaultRoyalty(0x31AE2c2cAEC2Bc9211cC6E55D73Dc3e874BaBdbb, 690);
        transferOwnership(0x31AE2c2cAEC2Bc9211cC6E55D73Dc3e874BaBdbb);
    }

    modifier onlyActive() {
        require(block.timestamp >= slot0.startTime, "Not Active");
        require(block.timestamp <= slot0.endTime, "Not Active");
        _;
    }

    modifier onlyHolder() {
        bool holdsCheebs = IERC721(slot0.cheebiez).balanceOf(msg.sender) > 0;
        bool holdsGhouls = IERC721(slot0.ghouls).balanceOf(msg.sender) > 0;
        require((holdsCheebs || holdsGhouls), "Not Holder");
        _;
    }

    function setTime(uint32 startTime) external onlyOwner {
        slot0.startTime = startTime;
        slot0.endTime = startTime + 86400;
    }

    function setURI(string memory newURI) external onlyOwner {
        slot0.revealedURI = newURI;
    }

    function setMaxMint(uint16 maxMint) external onlyOwner {
        slot0.maxMint = maxMint;
    }

    function crabMint(uint16 amount) external {
        require(block.timestamp >= slot0.startTime - 86400, "Not Crab Time");
        require(block.timestamp <= slot0.endTime);
        require(IERC721(slot0.v1crabs).balanceOf(msg.sender) > 0, "No Crab");
        require(!hasCrabMinted[msg.sender], "Already Minted");
        require(amount <= slot0.maxMint + 10, "Too Many");
        require(totalSupply() + amount <= MAXSUPPLY, "Too Many");
        hasCrabMinted[msg.sender] = true;
        _mint(msg.sender, amount);
    }

    function cheebOrGhoulMint(uint16 amount) external onlyActive onlyHolder {
        require(amount <= slot0.maxMint, "Too Many");
        require(totalSupply() + amount <= MAXSUPPLY, "Too Many");
        require(!hasCheeborGhoulMinted[msg.sender], "Already Minted");
        hasCheeborGhoulMinted[msg.sender] = true;
        _mint(msg.sender, amount);
    }

    function publicMint(uint16 amount) external {
        require(block.timestamp >= slot0.endTime, "Not Time");
        require(amount <= slot0.maxMint - 10, "Too Many");
        require(totalSupply() + amount <= MAXSUPPLY, "Too Many");
        require(!hasPublicMinted[msg.sender], "Already Minted");
        hasPublicMinted[msg.sender] = true;
        _mint(msg.sender, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return slot0.revealedURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721A).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
