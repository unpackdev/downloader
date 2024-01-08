// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";

contract LuckyDuck is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 9999;
    uint256 public constant PRICE = 0.04 ether;
    uint256 private startSales = 1629748800; // 2021-08-23 à 20:00:00
    uint256 private canMerge = 0;
    uint256 private _balanceCreator = 0;
    uint256 private _balanceNFT = 0;
    uint256 private _balanceDev = 0;
    uint256 private _balanceArtist = 0;

    address public constant creatorAddress = 0x02AE2a244E7Ef69153B3a599ca412cef4079eb47; // 19%
    address public constant artistAddress = 0x66F7d38aa7e0fC5b5daDa6BafAF38e2090327Ac5;  // 6%
    address public constant devAddress = 0xcBCc84766F2950CF867f42D766c43fB2D2Ba3256;  // 24%
    address public constant nftAddress = 0xee297917DC25F0ED13eEE97Aebc34312C75EF9d3; // 31%

    string public baseTokenURI;

    mapping(uint256 => uint256) private ETH_VALUES;
    mapping(uint256 => Duck) private _ducks;

    // Lucky ducks
    struct Duck {
        uint256 tokenId;
        uint256 luck;
        address owner;
    }
    constructor(string memory baseURI) ERC721("LuckyDuck", "LD") {
        setBaseURI(baseURI);
        ETH_VALUES[0] = 0.02 ether;
        ETH_VALUES[1] = 0.04 ether;
        ETH_VALUES[2] = 0.1 ether;
        ETH_VALUES[3] = 0.25 ether;
        ETH_VALUES[4] = 0.5 ether;
        ETH_VALUES[5] = 1 ether;
    }

    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end.");
        if (_msgSender() != owner()) {
            require(block.timestamp >= startSales, "Sales not open.");
        }
        _;
    }
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }
    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= 16, "Exceeds number");
        uint256 _price = msg.value;
        require(_price >= price(_count), "Value below price");

        _balanceCreator += _price.mul(19).div(100);
        _balanceArtist += _price.mul(6).div(100);
        _balanceDev += _price.mul(24).div(100);
        _balanceNFT += _price.mul(31).div(100);

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
    function _mintAnElement(address _to) private {
        uint id = _totalSupply() + 1;

        _tokenIdTracker.increment();

        _safeMint(_to, id);

        _ducks[id].tokenId = id;
        _ducks[id].luck = 1;
        _ducks[id].owner = _to;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (Duck[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        Duck[] memory ducks = new Duck[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            ducks[i] = _ducks[tokenOfOwnerByIndex(_owner, i)];
        }

        return ducks;
    }

    function setStartSales(uint _start) public onlyOwner {
        startSales = _start;
    }

    function getStartSales() public view returns(uint) {
        return startSales;
    }

    function withdrawAll() public onlyOwner {

        if(_balanceCreator > 0){
            uint256 bCreator = _balanceCreator;
            _balanceCreator = 0;
            _widthdraw(creatorAddress, bCreator);
        }

        if(_balanceArtist > 0){
            uint256 bArtist = _balanceArtist;
            _balanceArtist = 0;
            _widthdraw(artistAddress, bArtist);
        }

        if(_balanceDev > 0){
            uint256 bDev = _balanceDev;
            _balanceDev = 0;
            _widthdraw(devAddress, bDev);
        }

        if(_balanceNFT > 0){
            uint256 bNFT = _balanceNFT;
            _balanceNFT = 0;
            _widthdraw(nftAddress, bNFT);
        }
    }

    function fullWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        _balanceCreator = 0;
        _balanceArtist = 0;
        _balanceDev = 0;
        _balanceNFT = 0;

        _widthdraw(devAddress, balance.mul(24).div(100));
        _widthdraw(artistAddress, balance.mul(6).div(100));
        _widthdraw(creatorAddress, address(this).balance);
    }

    function getBalance() public view onlyOwner returns(uint256[] memory) {

        uint256[] memory balances = new uint256[](4);
        balances[0] = _balanceCreator;
        balances[1] = _balanceArtist;
        balances[2] = _balanceDev;
        balances[3] = _balanceNFT;

        return balances;
    }

    function _widthdraw(address _address, uint256 _amount) private {
        if(_amount > 0){
            (bool success, ) = _address.call{value: _amount}("");
            require(success, "Transfer failed.");
        }
    }

    function reserve(uint256 _count) public onlyOwner {
        uint256 total = _totalSupply();
        require(total + _count <= 150, "Exceeded giveaways.");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }

    function duckGet(uint256 _tokenId) public view returns (Duck memory){
        return _ducks[_tokenId];
    }

    function duckGetAll(uint256 offset, uint256 limit) public view returns (Duck[] memory){
        Duck[] memory ducks = new Duck[](limit);
        for(uint i=0;i<limit;i++){
            ducks[i] = _ducks[i+offset];
        }
        return ducks;
    }
    function setLuck(uint256[] memory _tokensId, uint256[] memory _lucks) public onlyOwner{
        for(uint i=0;i<_tokensId.length;i++){
            _ducks[_tokensId[i]].luck = _lucks[i];
        }
    }
    function activeMerge(uint256 active) public onlyOwner{
        canMerge = active;
    }
    function getCanMerge() public view returns (uint256){
        return canMerge;
    }
    function mergeDucks(uint256 _duck1, uint256 _duck2) public {
        // if no more like 5 duck
        require(canMerge == 1, "Merge is not available.");
        if(
            (ownerOf(_duck1) != _msgSender()) ||
            (ownerOf(_duck2) != _msgSender()) ||
            (_ducks[_duck1].luck != _ducks[_duck2].luck) ||
            _ducks[_duck1].luck >= 50
        ){
            revert( 'Something is wrong.' );
        }

        // merge luck
        uint256 totalLuck = 0;
        if (_ducks[_duck1].luck == 1){totalLuck = 3;} // x2 + 1 : 2 ducks = +2 => +3 => +50% | 1 burned
        else if (_ducks[_duck1].luck == 3){totalLuck = 8;} // x2 + 2 : 4 ducks => +4 => +8 => +100% | 3 burned
        else if (_ducks[_duck1].luck == 8){totalLuck = 20;} // x2 + 4 : 8 ducks => +8 => +20 => +250% | 7 burned
        else if (_ducks[_duck1].luck == 20){totalLuck = 50;} // x2 + 5 : 16 ducks => +16 => +50 => +320% | 15 burned

        require(totalLuck > 0 && totalLuck != _ducks[_duck1].luck, "Error calculation luck.");

        // burn _duck2
        _ducks[_duck2].luck = 0;
        _burn(_duck2);

        // save new luck
        _ducks[_duck1].luck = totalLuck;
    }

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        _ducks[tokenId].owner = to;
    }

    function sendETHtoWinners(uint256 _valueId, address[] memory _winners) public onlyOwner{
        for(uint i=0; i < _winners.length; i++){
            _widthdraw(_winners[i], ETH_VALUES[_valueId]);
        }
    }

    receive() external payable {}
}
