// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Strings.sol";

library Data {
    struct Pool {
        string CID;
        Counters.Counter counter;
        uint[] data;
        bool initialized;
        uint currentMax;
    }
}


contract LossNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Data for Data.Pool;

    uint public constant PRICE = 0.1 ether;
    uint public constant MAX_SUPPLY = 10000;
    uint public constant MAX_PER_MINT = 10;
    uint public constant MAX_TEAM_MINT = 60;
    address public constant UKRAINE_WITHDRAWAL_ADDRESS = address(0x165CD37b4C644C2921454429E7F9358d18A45e14);
    address public constant TEAM_ADDRESS = address(0xEaD2fc838EC8b3DFBc105bD52A6e7ea3D6004275);

    mapping (uint256 => string) private _tokenURIs;
    mapping (string => Data.Pool) private _pools;

    /*string[] private tanks;
    string[] private armored;
    string[] private cannons;
    string[] private planes;
    string[] private helicopters;
    string[] private drones;
    string[] private fuelTanks;
    string[] private rocketLaunchers;
    string[] private airDefense;
    string[] private ships;
    string[] private specials;*/

    string public baseTokenURI;

    Counters.Counter private _tokenIds;

    uint public teamMinted = 0;

    constructor() ERC721("Road to freedom", "RTF") {
        setBaseURI("ipfs://");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function reserveNFTs(string memory poolName, uint amount) public onlyOwner {
        uint totalMinted = _tokenIds.current();
        uint _teamMinted = teamMinted;
        require(
            totalMinted.add(amount) < MAX_SUPPLY, "Not enough NFTs"
        );
        require(
            _teamMinted.add(amount) < MAX_TEAM_MINT, "Cant mint that amount"
        );
        for (uint i = 0; i < amount; i++) {
            _mintSingleNFT(poolName);
        }
        teamMinted.add(amount);
    }

    function mintNFTs(string memory poolName, uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= PRICE.mul(_count), "Not enough ether to purchase NFTs.");

        Data.Pool storage pool = getPool(poolName);
        require(pool.counter.current() < pool.currentMax + 1, "Max minted for selected pool for now");
        require(pool.data.length > 0, "No NFT in selectedPool");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT(poolName);
        }
    }

    function _mintSingleNFT(string memory poolName) private {
        Counters.Counter storage counter = getMintCounter(poolName);
        counter.increment();
        _tokenIds.increment();
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        setRandomURI(poolName, newTokenID);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        return string(abi.encodePacked(base, _tokenURI));
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        uint toUkraine = (balance / 100) * 90;
        uint toTeam = (balance / 100) * 10;

        (bool successTeam, ) = payable(TEAM_ADDRESS).call{value: toTeam}("");
        require(successTeam, "Transfer to ukraine failed.");

        (bool success, ) = payable(UKRAINE_WITHDRAWAL_ADDRESS).call{value: toUkraine}("");
        require(success, "Transfer to ukraine failed.");
    }

    function getPool(string memory poolName) private view returns (Data.Pool storage) {
        require(_pools[poolName].initialized == true, "Invalid pool");

        return _pools[poolName];
    }

    function getPoolLength(string memory poolName) public view returns (uint) {
        Data.Pool storage selectedPool = getPool(poolName);
        return selectedPool.data.length;
    }

    function getMintCounter(string memory poolName) private view returns (Counters.Counter storage) {
        Data.Pool storage pool = getPool(poolName);
        return pool.counter;
    }

    function getMintedCount(string memory poolName) public view returns (uint) {
        Counters.Counter storage counter = getMintCounter(poolName);
        return counter.current();
    }

    function addToPool(uint newMax, string memory poolName) public onlyOwner {
        Data.Pool storage selectedPool = getPool(poolName);
        require(newMax > selectedPool.currentMax, "Invalid newMax");

        for (uint i = selectedPool.currentMax + 1; i < newMax + 1; i++) {
            selectedPool.data.push(i);
        }
        selectedPool.currentMax = newMax;
    }

    function modifyPoolCID(string memory poolName, string memory CID) public onlyOwner {
        Data.Pool storage pool = _pools[poolName];
        pool.initialized = true;
        pool.CID = CID;
    }

    function setRandomURI(string memory poolName, uint tokenId) internal
    {
        Data.Pool storage selectedPool = getPool(poolName);

        uint index = rand(selectedPool.data.length);
        string memory selectedData = string(abi.encodePacked(selectedPool.CID, '/', Strings.toString(selectedPool.data[index]), ".json"));
        selectedPool.data[index] = selectedPool.data[selectedPool.data.length - 1];
        selectedPool.data.pop();
        _setTokenURI(tokenId, selectedData);
    }

    function rand(uint limit) public view returns(uint256) {

        require(limit > 0, "Invalid limit parameter");

        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed - ((seed / limit) * limit));
    }

    function stringEquals(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}