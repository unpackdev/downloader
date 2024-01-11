// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721Holder.sol";
import "./IERC1271.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

interface IWrappedEther {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IPoolManager {
    function close(uint256 tokenId) external payable;
}

interface IOpenSeaProxy {
    function registerProxy() external returns (address);
}

contract SimplePoolBuyNowAny is Ownable, ERC721Holder, IERC1271 {
    using ECDSA for bytes32;

    IWrappedEther immutable public wrappedEther;
    IPoolManager immutable public poolManager;
    IERC20 immutable public landDao;
    uint256 public tokenId;
    address public openSeaExchange;
    address public openSeaProxy;
    address public openSeaProxyRegister;
    address public openSeaTokenProxy;

    address public updateManager;
    mapping(address => mapping(uint256 => address)) public updateOperator;

    event UpdateOperatorSet(address, uint256, address);

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || address(poolManager) == msg.sender, "Pool: caller is not the owner or manager");
        _;
    }

    modifier onlyUpdateManager() {
        require(updateManager == msg.sender, "Pool: caller is not the update manager");
        _;
    }

    constructor(
        address poolManager_,
        address wrappedEther_,
        address landDao_,
        address openSeaExchange_,
        address openSeaProxyRegister_,
        address openSeaTokenProxy_
    ) {
        poolManager = IPoolManager(poolManager_);
        wrappedEther = IWrappedEther(wrappedEther_);
        landDao = IERC20(landDao_);
        openSeaExchange = openSeaExchange_;
        openSeaProxyRegister = openSeaProxyRegister_;
        openSeaTokenProxy = openSeaTokenProxy_;
    }

    function setUpdateManager(address updateManager_) external onlyOwner {
        require(updateManager_ != address(0));
        updateManager = updateManager_;
    }

    function setUpdateOperator(address tokenContract_, uint256 assetId, address operator) external onlyUpdateManager {
        updateOperator[tokenContract_][assetId] = operator;
        emit UpdateOperatorSet(tokenContract_, assetId, operator);
    }

    function updateOpenSeaData(address openSeaExchange_, address openSeaProxyRegister_, address openSeaTokenProxy_) external onlyOwner {
        openSeaExchange = openSeaExchange_;
        openSeaProxyRegister = openSeaProxyRegister_;
        openSeaTokenProxy = openSeaTokenProxy_;
    }

    function approveOpenSea(address tokenContract_) external onlyOwner {
        IERC721(tokenContract_).setApprovalForAll(openSeaProxy, true);
    }

    function prepareOpenSea() external onlyOwner {
        openSeaProxy = IOpenSeaProxy(openSeaProxyRegister).registerProxy();
        require(wrappedEther.approve(openSeaTokenProxy, type(uint).max), "Pool: error approving WETH");
    }

    function exchangeOpenSea(bytes calldata _calldata, uint256 value) external onlyOwner {
        (bool _success,) = openSeaExchange.call{value: value}(_calldata);
        require(_success, "Pool: error sending data to exchange");
    }

    receive() external payable {
    }

    function start(uint256 tokenId_) external payable {
        require(tokenId_ > 0, "Pool: tokenId can not be 0");
        require(tokenId == 0, "Pool: tokenId is already set");
        require(msg.value > 0, "Pool: pool can not be started without funds");
        require(msg.sender == address(poolManager), "Pool: pool manager should start the pool");
        tokenId = tokenId_;
        landDao.approve(address(poolManager), type(uint).max);
    }

    function wrap() public onlyOwnerOrManager {
        wrappedEther.deposit{value : address(this).balance}();
    }

    function unWrap() public onlyOwnerOrManager {
        uint256 balance = wrappedEther.balanceOf(address(this));
        wrappedEther.withdraw(balance);
    }

    function finish() external onlyOwnerOrManager {
        require(tokenId > 0, "Pool: tokenId not set");
        unWrap();
        poolManager.close{value : address(this).balance}(tokenId);
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature) external override view returns (bytes4) {
        address signer = _hash.recover(_signature);
        if (signer == owner()) {
            return 0x1626ba7e;
        }
        return 0x00000000;
    }
}
