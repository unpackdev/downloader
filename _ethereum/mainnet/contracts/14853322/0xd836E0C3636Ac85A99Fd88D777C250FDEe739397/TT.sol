// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TrippyToonz is ERC721A, Ownable {
    uint256 public constant MAX_PAID_MINTS_PER_TX = 20;
    uint256 public constant MAX_FREE_MINTS = 2;
    uint256 public constant MAX_FREE_MINTS_PER_TX = 2;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public TOTAL_FREE_MINTS = 1111;
    uint256 public PUBLIC_MINT_PRICE = 0.004 ether;
    bool public saleIsActive = false;
    string public baseURI = "";
    mapping(address => uint) public addressFreeMintedBalance;

    constructor() ERC721A("Trippy Toonz", "TT") {}

    function mint(uint8 _quantity) external payable
    {
        uint256 currentSupply = totalSupply();
        require(saleIsActive, "Sale must be active to mint");
        require(currentSupply + _quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(_quantity > 0 && _quantity <= MAX_PAID_MINTS_PER_TX, "Max paid mints per transaction reached");
        require((PUBLIC_MINT_PRICE * _quantity) == msg.value, "Incorrect ETH value sent");
        _safeMint(msg.sender, _quantity);
    }

    function freeMint(uint8 _quantity) external payable
    {
        uint256 currentSupply = totalSupply();
        require(saleIsActive, "Sale must be active to mint");
        require(currentSupply + _quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(currentSupply + _quantity <= TOTAL_FREE_MINTS, "Free mint sold out");
        require(_quantity > 0 && _quantity <= MAX_FREE_MINTS_PER_TX, "Max free mints per transaction reached");
        require(addressFreeMintedBalance[msg.sender] + _quantity <= MAX_FREE_MINTS, "Max free mint limit reached");
        addressFreeMintedBalance[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function ownerMint(address[] calldata _addresses, uint256 _quantity) external onlyOwner
    {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds max supply");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _quantity, "");
        }
    }

    function setSaleIsActive(bool _state) external onlyOwner {
        saleIsActive = _state;
    }

    function setPublicMintPrice(uint256 _publicPrice) external onlyOwner
    {
        PUBLIC_MINT_PRICE = _publicPrice;
    }

    function setTotalFreeMints(uint256 _freeMints) external onlyOwner
    {
        TOTAL_FREE_MINTS = _freeMints;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner
    {
        baseURI = _newBaseURI;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}