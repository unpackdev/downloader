// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ERC721Pausable.sol";
import "./Gem.sol";

contract CocoDraco is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {

    using Strings for uint256;
    uint256 public idTracker = 0;
    uint256 public publicTracker = 0;
    uint256 public teamTracker = 0;
    uint256 public rareTracker = 0;

    Gem public gem;

    uint256 public constant PUBLIC_SALE = 2888;
    uint256 public constant TEAM_SUPPLY = 444;
    uint256 public constant MAX_BLACK_GOLD_DRACO = 1556;

    string public constant BASE_EXTENSION = ".json";
 
    uint256 public price = 68 * 1e15;
    uint256 public rarePrice = 120 * 1e18;
    
    uint256 public constant MAX_BY_MINT = 10;
    uint256 public constant WHITELIST_START = 1638162000; // Monday, 29 November 2021 05:00:00 GMT
    bool public onlyWhitelist = true;
    mapping(address => uint256) public whitelistAddresses;
   
    string public baseTokenURI;

    event CreateDraco(uint256 indexed id);

    constructor(string memory _baseTokenURI, Gem _gem) ERC721("CocoDraco", "CCD") {
        setBaseURI(_baseTokenURI);
        gem = _gem;
    }

    modifier saleIsOpen {
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function addWhitelist(address[] memory _addresses) public onlyOwner {
        for(uint256 i = 0 ; i < _addresses.length; i++){
            whitelistAddresses[_addresses[i]] = 3;
        }
    }
    
    function setWhitelist(bool _onlyWhitelist) public onlyOwner {
        onlyWhitelist = _onlyWhitelist;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setRarePrice(uint256 _rarePrice) public onlyOwner {
        rarePrice = _rarePrice;
    }

    function devMint(address _to, uint256 _count) public onlyOwner {
        require(teamTracker + _count <= TEAM_SUPPLY, "Max limit");
        require(_count <= 30, "Exceeds number");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to, idTracker);
            teamTracker += 1;
            idTracker += 1;
        }
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = price * _count;
        require(WHITELIST_START <= block.timestamp, "Not started");
        require(publicTracker + _count <= PUBLIC_SALE, "Max limit");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= total, "Value below price");
        if(onlyWhitelist){
            require(whitelistAddresses[msg.sender] >= _count, "Can't mint more than 3");
            whitelistAddresses[msg.sender] -= _count;
        }

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to, idTracker);
            publicTracker += 1;
            idTracker += 1;
        }
    }

    function rareMint(address _to, uint256 _count) public saleIsOpen {
        uint256 total = rarePrice * _count;
        require(rareTracker + _count <= MAX_BLACK_GOLD_DRACO, "Max limit");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(gem.balanceOf(msg.sender) >= total, "Not enough GEM balance");
        
        gem.burn(
            msg.sender,
            total
        );

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to, rareTracker + PUBLIC_SALE + TEAM_SUPPLY);
            rareTracker += 1;
        }
    }

    function _mintAnElement(address _to, uint id) private {
        // uint id = _totalSupply();
        _safeMint(_to, id);
        emit CreateDraco(id);
    }

    function maxElement() public pure returns (uint256) {
        return PUBLIC_SALE + TEAM_SUPPLY + MAX_BLACK_GOLD_DRACO;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
         require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _id.toString(), BASE_EXTENSION))
            : "";
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdraw() public onlyOwner {
        require(
        payable(owner()).send(address(this).balance),
        "Withdraw unsuccessful"
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}