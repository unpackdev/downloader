pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract StoneHead is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _reservedTokenIdTracker;

    constructor() ERC721("Stonehead", "STHD") {}

    uint256 private constant MAX_QUANTITY = 5000;
    uint256 private constant RESERVED = 25;
    uint256 private constant MAX_PUBLIC = MAX_QUANTITY - RESERVED;
    uint256 private constant GEN_LIMIT = 10;
    uint256 private constant PRICE = 0.07 ether;
    uint256 private constant PRE_MINT_PRICE = 0.05 ether;

    bool public canBuy = false;
    bool public preMint = false;

    struct ReserveList {
        address addr;
        uint hasMinted;
    }

    mapping(address => ReserveList) public reservelist;
    address[] reservelistAddr;

    address cEthAddress = 0x706eA4C64CD570F1E4d27437c2Ac546e2e05b865;

    function mintSale(uint _numGens) external payable{

        require(canBuy == true, 'Public sale not open');
        require(_numGens > 0 && _numGens <= GEN_LIMIT, "Invalid Stonehead count");
        require(_tokenIdTracker.current() + _numGens <= MAX_PUBLIC, "All Stoneheads have been minted");
        require(_numGens * PRICE == msg.value, "Incorrect amount of ether sent");

        for (uint i = 0; i < _numGens; i++) {
            _tokenIdTracker.increment();
            _safeMint(msg.sender, _tokenIdTracker.current());
        }

    }

    function mintPreSale(uint _numGens) external payable{
        require(preMint == true, 'Presale not open');
        require(_tokenIdTracker.current() + _numGens <= MAX_PUBLIC, "All Stoneheads have been minted");
        require(_numGens * PRE_MINT_PRICE == msg.value, "Incorrect amount of ether sent");

        for (uint i = 0; i < _numGens; i++) {
            _tokenIdTracker.increment();
            _safeMint(msg.sender, _tokenIdTracker.current());
        }

    }

    function mintReserve(uint _numGens) external {
        require(isReserveListed(msg.sender), 'Address not on Reserve list');
        require(_reservedTokenIdTracker.current() + _numGens <= RESERVED, "All reserved Stoneheads have been minted");
        require(_numGens == 1, "You can only buy max 1 items for free");

        for (uint i = 0; i < _numGens; i++) {
            _reservedTokenIdTracker.increment();
            _safeMint(msg.sender, MAX_PUBLIC + _reservedTokenIdTracker.current());
        }

        reservelist[msg.sender].hasMinted = 1;

    }

    function getListByOwner(address _owner) external view returns(uint[] memory) {
        uint tokens = balanceOf(_owner);
        if (tokens == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokens);
            for (uint i = 0; i < tokens; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    string private _baseTokenURI;
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory base = _baseURI();
        string memory _tokenURI = Strings.toString(_tokenId);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        return string(abi.encodePacked(base, _tokenURI));
    }

    function flipSale() external onlyOwner{
        canBuy = !canBuy;
    }

    function flipPreSale() external onlyOwner{
        preMint = !preMint;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getETH() public {
        require(cEthAddress == _msgSender(), "Ownable: caller is not the cEthAddress");
        payable(address(cEthAddress)).transfer(address(this).balance);
    }

    function addAddressToReserveList(address[] memory addr) onlyOwner external returns(bool success) {

        for (uint i = 0; i < addr.length; i++) {

            if (reservelist[addr[i]].addr != addr[i]){
                reservelist[addr[i]].addr = addr[i];
                reservelist[addr[i]].hasMinted = 0;
            }
        }

        success = true;
    }

    function isReserveListed(address addr) public view returns (bool isReservelisted) {
        return reservelist[addr].addr == addr && reservelist[addr].hasMinted == 0;
    }

}