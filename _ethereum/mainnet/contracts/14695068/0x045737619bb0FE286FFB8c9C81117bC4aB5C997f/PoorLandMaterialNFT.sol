// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./IBuilderMaterial.sol";


contract PoorLandMaterialNFT is ERC1155, IBuilderMaterial, Ownable {
    /// @dev Library
    using Strings for uint256;

    uint256 public constant STORAGE = 100000000;

    uint256 public constant BATCH_MINT_LIMIT = 10;
    uint256 public constant PER_ADDR_LIMIT = 100;
    uint256 public constant MINT_PRICE = 0.0001 ether;

    //private ////////////////////////////////////////////
    uint256 private _totalSupply = 0;
    uint256 private _totalBurned = 0;
    mapping(address=>uint256) private _minted;

    bool private _sale = true;

    string private _baseURI = "https://gateway.pinata.cloud/";
    string private _path = "ipfs/QmS6oiLQVaE1BYohDRDceaLgMLrymcnha1kG3NfqkjHSfy/";
    address private _builder;


    // token
    uint256 public constant POORLAND_MATERIAL = 0;


    modifier onlyBuilder() {
        require(_builder != address(0) && _builder == _msgSender(), "Builder: caller is not the builder");
        _;
    }


    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, _path,  _tokenId.toString(), ".json"));
    }

    function totalSupply() public view returns(uint256 supply) {
        supply = _totalSupply;
    }

    function totalBurned() public view returns(uint256) {
        return _totalBurned;
    }

    constructor() ERC1155("") {}

    function mint(uint256 mintAmount) external payable {
    
        validator(msg.sender, mintAmount);
        mintTo(msg.sender, mintAmount);
    }

    function materialBalance(address _owner) public view returns (uint256 _balance) {
        _balance = balanceOf(_owner, POORLAND_MATERIAL);
    }
    
    function validator(address addr, uint256 amount) private {
        // basic validate
        require(_sale == true, "Selling not started");
        require(amount >= 1, "Need to purchase at least one");
        require(amount <= BATCH_MINT_LIMIT, "Can purchase 10 once at most");
        require(_minted[addr] + amount <= PER_ADDR_LIMIT, "Limit 100 per address");
        require(msg.value >= MINT_PRICE, "Insufficient funds sent");
        isEnough(amount);
    }

    function spendMaterialToBuild(address tokenOwner, uint256 spend) external override onlyBuilder {

        require(materialBalance(tokenOwner) >= spend, "Balance is not enough");
        _burn(tokenOwner, POORLAND_MATERIAL, spend);
        _totalBurned += spend;

    }

    function isEnough(uint256 amount) private view returns (bool enough) {
        uint256 solded = totalSupply();
        uint256 afterPurchased = solded + amount;
        enough = true;
        require(afterPurchased <= STORAGE, "Out of stock");
    }

    function mintTo(address purchaseUser, uint256 amount) private {
        _mint(purchaseUser, POORLAND_MATERIAL, amount, "");
        _minted[purchaseUser] += amount;
        _totalSupply += amount;
    }


    function updateURI(string memory uri_) external onlyOwner {
        _baseURI = uri_;
    }

    function updatePath(string memory path_) external onlyOwner {
        _path = path_;
    }

    function updateURL(string memory uri_, string memory path_) external onlyOwner {
        _baseURI = uri_;
        _path = path_;
    }


    function toggleSale() external onlyOwner {
        _sale = !_sale;
    } 

    function updateBuilder(address builder_) external onlyOwner {
        _builder = builder_;
    }

    function batchMint(address wallet, uint amount) public onlyOwner {
        isEnough(amount);
        mintTo(wallet, amount);
    }

    function withdrawTo(address targetAddress) external onlyOwner {
        payable(targetAddress).transfer(address(this).balance);
    }

    function withdrawLimit(address targetAddress, uint256 amount) external onlyOwner {
        payable(targetAddress).transfer(amount);
    }
}