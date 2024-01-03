// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;

import "./Counters.sol";
import "./Pausable.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./DNFTLibrary.sol";
import "./IDNFTProduct.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract DNFTMain is Pausable, Ownable {

    struct Player {
        address addr;
        address parent;
        address[] children;
        uint256 buyCount;
        uint256 rewardCount;
        uint256 withdrawTotalValue;
    }
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint32;

    address public mainCreator;
    address payable public withdrawTo;
    IERC20 public dnftToken;

    mapping(string => address) private _products;
    mapping(string => Lib.ProductCount) private _productsCount;
    string[] private _productNames;
    string public rewardProductName;

    mapping(address => Player) private _players;

    mapping(address => address) public _playerParents;

    mapping(address => address[]) public _playerChildren;

    uint256 public playerCount;

    event AddPlayer(address indexed player);
    event ProductBuy(address indexed player, string product, uint256 tokenId);
    event ProductReward(address indexed to, address indexed from, string fromProduct, string toProduct, uint256 cost, uint256 fromTokenId, uint256 toTokenId);
    event ProductMintBegin(address indexed player, string product, uint256 indexed tokenId);
    event ProductMintWithdraw(address indexed player, string product, uint256 indexed tokenId, uint256 value, uint256 timeNum);
    event ProductMintRedeem(address indexed player, string product, uint256 indexed tokenId, uint256 value, uint256 timeNum);


    constructor(address _dnftAddr, address payable _withdrawTo) {
        mainCreator = msg.sender;
        withdrawTo = _withdrawTo;
        dnftToken = IERC20(_dnftAddr);
    }

    function _getPlayer(address addr) private returns (Player storage){
        if (_players[addr].addr == address(0)) {
            Player memory player;
            player.addr = addr;
            _players[addr] = player;
            playerCount++;
            emit AddPlayer(addr);
        }
        return _players[addr];
    }

    function _getProduct(string memory name) private view returns (IDNFTProduct){
        require(_products[name] != address(0), "Product not exists.");
        return IDNFTProduct(_products[name]);
    }


    function getPlayer(address addr) external view returns (Player memory){
        return _players[addr];
    }

    function getProductAddress(string calldata name) external view returns (address){
        require(_products[name] != address(0), "Product not exists.");
        return _products[name];
    }

    function getProductCount(string calldata name) external view returns (Lib.ProductCount memory){
        require(_products[name] != address(0), "Product not exists.");
        return _productsCount[name];
    }

    function getProductNames() external view returns (string[] memory){
        return _productNames;
    }

    function setWithdrawTo(address payable addr) external {
        require(msg.sender == withdrawTo, "Must be withdraw account.");
        withdrawTo = addr;
    }

    function withdrawToken(address token, uint256 value) external {
        require(msg.sender == withdrawTo, "Must be withdraw account.");
        if (token == address(0))
            withdrawTo.transfer(value);
        else
            IERC20(token).safeTransfer(withdrawTo, value);
    }

    function withdrawProductToken(string calldata name, address token, uint256 value) external {
        require(msg.sender == withdrawTo, "Must be withdraw account.");
        IDNFTProduct p = _getProduct(name);
        p.withdrawToken(withdrawTo, token, value);
    }

    function setRewardProductName(string calldata name) onlyOwner external {
        require(_products[name] != address(0), "Product not exists.");
        rewardProductName = name;
    }

    function addProduct(address paddr, uint256 dnftValue) onlyOwner external {
        IDNFTProduct p = IDNFTProduct(paddr);
        string memory name = p.name();
        require(_products[name] == address(0), "Product already exists.");
        require(p.mainAddr() == address(this), "Product main addr not this.");
        _products[name] = paddr;
        _productNames.push(name);
        dnftToken.safeTransfer(paddr, dnftValue);
    }

    function buyProduct(string calldata name, address playerParent) external payable {
        require(playerParent != msg.sender, "Pay parent wrong.");
        IDNFTProduct p = _getProduct(name);
        if (bytes(rewardProductName).length != 0)
            require(address(p) != _products[rewardProductName], "This product cannot be purchased.");
        address costTokenAddr = p.costTokenAddr();
        uint256 cost = p.cost();
        if (costTokenAddr == address(0))
            require(msg.value == cost, "Pay value wrong.");
        else {
            require(msg.value == 0, "Pay value must be zero.");
            IERC20(costTokenAddr).safeTransferFrom(msg.sender, address(this), cost);
        }
        Player storage player = _getPlayer(msg.sender);
        if (playerParent != address(0)) {
            Player storage parentPlayer = _getPlayer(playerParent);
            player.parent = playerParent;
            parentPlayer.children.push(player.addr);
        }
        _productsCount[name].buyCount++;
        player.buyCount++;
        uint256 tokenId = p.buy(msg.sender);
        emit ProductBuy(msg.sender, name, tokenId);
        if (player.buyCount == 1 && player.parent != address(0) && bytes(rewardProductName).length != 0) {
            IDNFTProduct rp = IDNFTProduct(_products[rewardProductName]);
            if (_productsCount[rewardProductName].buyCount < rp.maxTokenSize()) {
                _getPlayer(player.parent).rewardCount++;
                _productsCount[rewardProductName].buyCount++;
                uint256 toTokenId = rp.buy(player.parent);
                emit ProductReward(player.parent, msg.sender, name, rewardProductName, msg.value, tokenId, toTokenId);
            }
        }
    }

    function mintBegin(string calldata name, uint256 tokenId) external {
        IDNFTProduct p = _getProduct(name);
        p.mintBegin(msg.sender, tokenId);
        _productsCount[name].miningCount++;
        emit ProductMintBegin(msg.sender, name, tokenId);
    }

    function mintWithdraw(string calldata name, uint256 tokenId) external {
        IDNFTProduct p = _getProduct(name);
        Player storage player = _getPlayer(msg.sender);
        (uint256 withdrawNum,uint256 timeNum) = p.mintWithdraw(msg.sender, tokenId);
        player.withdrawTotalValue += withdrawNum;
        _productsCount[name].withdrawCount++;
        _productsCount[name].withdrawSum += withdrawNum;
        emit ProductMintWithdraw(msg.sender, name, tokenId, withdrawNum, timeNum);
    }

    function redeemProduct(string calldata name, uint256 tokenId) external {
        IDNFTProduct p = _getProduct(name);
        Player storage player = _getPlayer(msg.sender);
        (uint256 withdrawNum,uint256 timeNum) = p.redeem(msg.sender, tokenId);
        player.withdrawTotalValue += withdrawNum;
        _productsCount[name].miningCount--;
        _productsCount[name].withdrawSum += withdrawNum;
        _productsCount[name].redeemedCount++;
        emit ProductMintRedeem(msg.sender, name, tokenId, withdrawNum, timeNum);
    }

}