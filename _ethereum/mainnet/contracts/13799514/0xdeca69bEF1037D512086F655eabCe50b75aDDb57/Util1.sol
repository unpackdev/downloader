// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./NFT.sol";

contract Util1 is Ownable {
    using SafeMath for uint256;

    NFT private _nft_contract;
    bytes1 public constant _TYPE_UNKNOWN = 0x00;
    bytes1 public constant _TYPE_TILE = 0x01;

    mapping(address => uint256) private _tilesWhitelist;
    uint256 private _tileWhitelistEnds;
    uint256 private _tilePriceWhiteList;
    uint256 private _tilePriceCurveMin;
    uint256 private _tilePriceCurveMax;
    uint256 private _tilesMintedInWhitelist; // set once
    uint256 private _tilePriceCurveIncrement; // set once
    uint256 private _tilePriceCurveNumberTicksForIncrease = 50;
    uint256 private _tilesMinted; // ticks up with each minting tx
    uint256 private constant _totalSupplyTiles = 949;

    constructor(NFT nft_contract) {
        _nft_contract = nft_contract;
        _tileWhitelistEnds = block.timestamp + 16 hours; // whitelist ends in 12h after contract creation
        _tilePriceWhiteList = 5e16; //
        _tilePriceCurveMin = 6e16;
        _tilePriceCurveMax = 125e15;
    }

    function changeTilePrice(uint256 price) public onlyOwner {
        _tilePriceWhiteList = price;
    }

    function addTileWhitelist(address account, uint256 amount) public onlyOwner {
        _tilesWhitelist[account] += amount;
    }

    function addTileWhitelistMany(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
        uint8 i = 0;
        for (i; i < accounts.length; i++) {
          _tilesWhitelist[accounts[i]] += amounts[i];
        }
    }

    function addTileWhitelistManySameAmount(address[] memory accounts, uint256 amount) public onlyOwner {
        uint8 i = 0;
        for (i; i < accounts.length; i++) {
          _tilesWhitelist[accounts[i]] += amount;
        }
    }

    function removeTileWhitelist(address account, uint256 amount) public onlyOwner {
        _tilesWhitelist[account] -= amount;
    }

    function getTileWhitelist(address account) public view returns (uint256) {
        return _tilesWhitelist[account];
    }

    function mintTile(uint256 amount) public payable {
        require(msg.value >=  getTilePrice() * amount, "Wrong funds");
        require(_tilesMinted + amount <= _totalSupplyTiles, "Over the limit");

        for (uint256 i; i < amount; i++) {
            _nft_contract.minterMint(msg.sender, _TYPE_TILE);
        }

        if (block.timestamp <= _tileWhitelistEnds) { // still in whitelist
            require(_tilesWhitelist[msg.sender] >= amount, "Not enough whitelisted");
            _tilesWhitelist[msg.sender] -= amount;
        }

        _tilesMinted += amount;
    }

    function getTilesMintedNumber() public view returns (uint256) {
        return _tilesMinted;
    }

    function getTilePrice() public returns (uint256) {
        if (block.timestamp <= _tileWhitelistEnds) {
            return _tilePriceWhiteList;
        }
        else {
            if(_tilePriceCurveIncrement == 0){
                _tilesMintedInWhitelist = _tilesMinted;
                uint256 tilesLeft = _totalSupplyTiles - _tilesMintedInWhitelist;
                require(tilesLeft > 0, "No tiles left");
                uint256 priceDiffOverCurve = _tilePriceCurveMax - _tilePriceCurveMin;
                _tilePriceCurveIncrement = priceDiffOverCurve * _tilePriceCurveNumberTicksForIncrease / tilesLeft;
            }

            // price curve
            uint256 numIncrements = (_tilesMinted - _tilesMintedInWhitelist) / _tilePriceCurveNumberTicksForIncrease;
            return _tilePriceCurveMin + _tilePriceCurveIncrement * numIncrements;
        }
    }

    function getTilePriceView() public view returns (uint256) {
        if (block.timestamp <= _tileWhitelistEnds) {
            return _tilePriceWhiteList;
        }
        else {
            uint256 _tilePriceCurveIncrementLocal = _tilePriceCurveIncrement;
            if(_tilePriceCurveIncrementLocal == 0){
                uint256 tilesLeft = _totalSupplyTiles - _tilesMinted;
                require(tilesLeft > 0, "No tiles left");
                uint256 priceDiffOverCurve = _tilePriceCurveMax - _tilePriceCurveMin;
                _tilePriceCurveIncrementLocal = priceDiffOverCurve * _tilePriceCurveNumberTicksForIncrease / tilesLeft;
            }

            // price curve
            uint256 numIncrements = (_tilesMinted - _tilesMintedInWhitelist) / _tilePriceCurveNumberTicksForIncrease;
            return _tilePriceCurveMin + _tilePriceCurveIncrementLocal * numIncrements + 1e14;  // add 1e-4Eth (= 1e14wei) to the price to ensure the price won't be too low
        }
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
