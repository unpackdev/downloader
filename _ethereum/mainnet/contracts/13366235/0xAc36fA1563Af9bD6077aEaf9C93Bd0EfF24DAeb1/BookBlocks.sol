// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

contract BookBlocks is ERC721Enumerable, Ownable {
    using Address for address;
    mapping(string => Edition) private editions;
    mapping(uint256 => string) private editionNamesById;
    mapping(address => bool) private admins;

    uint256 private maxPerTransaction; // Should always be set one higher than desired. Saves gas.
    uint256 private editionNumber; // Used to limit checks for all editions in the contract.
    uint256 private maxSupply; // Used to set aside ranges of token ids for certain editions.
    string private _baseTokenURI;

    constructor(string memory baseURI) ERC721("BookBlocks", "BOOKBLOCKS") {
        setBaseURI(baseURI);
        admins[msg.sender] = true;
        maxPerTransaction = 6;
    }

    event Minted(
        address indexed minter,
        string indexed editionName,
        uint256 indexed tokenId
    );

    event EditionProceedsTaken(
        string indexed editionName,
        uint256 amount
    );

    event EditionCreated(
        string indexed editionName,
        uint256 price,
        uint256 supply,
        uint256 saleTime,
        uint256 saleDuration
    );

    struct Edition {
        string name;
        uint256 price;
        uint256 supply;
        uint256 saleTime;
        uint256 saleDuration;
        uint256 mintIndex;
        uint256 totalMinted;
        uint256 balance;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Not an admin.");
        _;
    }

    modifier isValidMint() {
        require(
            !address(msg.sender).isContract() && msg.sender == tx.origin, 
            "Can't be called from a contract."
            );
        _;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        _baseTokenURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getMaxPerTransaction() public view returns (uint256) {
        return maxPerTransaction;
    }

    function setMaxPerTransaction(uint256 _newMaxPerTx) external onlyOwner {
        maxPerTransaction = _newMaxPerTx;
    }

    function getEdition(string memory _editionName) public view returns (Edition memory){
        return editions[_editionName];
    }

    function setPrice(string memory _editionName, uint256 _price) external onlyAdmin {
        editions[_editionName].price = _price;
    }

    function getPrice(string memory _editionName) public view returns (uint256) {
        return editions[_editionName].price;
    }

    function setSupply(string memory _editionName, uint256 _supply) external onlyAdmin {
        editions[_editionName].supply = _supply;
    }

    function getSupply(string memory _editionName) public view returns (uint256) {
        return editions[_editionName].supply;
    }

    function setSaleTime(string memory _editionName, uint256 _time) external onlyAdmin {
        editions[_editionName].saleTime = _time;
    }

    function getSaleTime(string memory _editionName) public view returns (uint256) {
        return editions[_editionName].saleTime;
    }

    function setSaleDuration(string memory _editionName, uint256 _duration) external onlyAdmin {
        editions[_editionName].saleTime = _duration;
    }

    function getSaleDuration(string memory _editionName) public view returns (uint256) {
        return editions[_editionName].saleTime;
    }

    function isSaleOpen(string memory _editionName) public view returns (bool) {
        uint256 sale_time = editions[_editionName].saleTime;
        return (block.timestamp >= sale_time &&
            block.timestamp < sale_time + editions[_editionName].saleDuration);
    }

    function getAllEditionNames() public view returns (string[] memory) {
        string[] memory names = new string[](editionNumber);
        for (uint256 i; i < editionNumber; i++) {
            names[i] = editionNamesById[i];
        }

        return names;
    }

    function mint(string memory _editionName, uint256 _count) external payable isValidMint {
        require(isSaleOpen(_editionName), "Sale is closed.");
        require(_count < maxPerTransaction, "Exceeds max per tx.");
        uint256 _price = editions[_editionName].price;
        uint256 _saleTotal = _price * _count;
        require(msg.value == _saleTotal, "Invalid value.");
        require(
            editions[_editionName].supply - editions[_editionName].totalMinted >= _count,
            "Exceeds max supply."
            );

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, editions[_editionName].mintIndex + i);
            emit Minted(msg.sender, _editionName, editions[_editionName].mintIndex + i);
        }

        editions[_editionName].mintIndex += _count;
        editions[_editionName].totalMinted += _count;
        editions[_editionName].balance += _saleTotal;
    }

    function reserve(string memory _editionName, uint256 _count, address _address) external onlyAdmin {
        require(
            editions[_editionName].supply - editions[_editionName].totalMinted >= _count,
            "Exceeds max supply."
            );

        for (uint256 i; i < _count; i++) {
            _safeMint(_address, editions[_editionName].mintIndex + i);
            emit Minted(_address, _editionName, editions[_editionName].mintIndex + i);
        }

        editions[_editionName].mintIndex += _count;
        editions[_editionName].totalMinted += _count;
    }

    function createEdition(
        string memory _name, 
        uint256 _price,
        uint256 _supply,
        uint256 _saleTime,
        uint256 _saleDuration ) 
        external onlyAdmin {

        editions[_name] = Edition(_name, _price, _supply, _saleTime, _saleDuration, maxSupply, 0, 0);
        editionNamesById[editionNumber] = _name;
        emit EditionCreated(_name, _price, _supply, _saleTime, _saleDuration);
        editionNumber++;

        maxSupply += _supply;
    }

    function withdrawEdition(string memory _name) external onlyAdmin {
        uint256 proceeds = editions[_name].balance;
        editions[_name].balance -= proceeds;
        emit EditionProceedsTaken(_name, proceeds);
        require(payable(msg.sender).send(proceeds), "Withdraw Failed.");
    }

    function withdrawEditions(string[] memory _names) external onlyAdmin {
        uint256 proceeds;
        uint256 total_proceeds;

        for (uint256 i; i < _names.length; i++) {
            proceeds = editions[_names[i]].balance;
            total_proceeds += proceeds;
            editions[_names[i]].balance -= proceeds;
            emit EditionProceedsTaken(_names[i], proceeds);
        }

        require(payable(msg.sender).send(total_proceeds), "Withdraw Failed.");
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}
