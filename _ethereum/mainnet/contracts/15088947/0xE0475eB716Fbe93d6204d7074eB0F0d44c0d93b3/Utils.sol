//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Strings.sol";


interface NFTAddress {
    function tokenURI(uint256) external view returns (string memory);
    function uri(uint256) external view returns (string memory);
}

interface TokenBalance {
    function balanceOf(address) external view returns (uint256); 
}

interface OpenSea {
    function getOrderStatus(bytes32 orderHash) external view returns (
        bool, bool, uint256, uint256);
}

interface LooksRare {
    function isUserOrderNonceExecutedOrCancelled(address, uint256) external view returns (bool);
}

interface NFTBalance {
    function balanceOf(address) external view returns (uint256); 
}

contract UtilityContract is Ownable {

    address private _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
    address private _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // mainnet
    address private _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // mainnet

    // address private _usdt = 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD; // Rinkeby
    // address private _usdc = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926; // Rinkeby 
    // address private _weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // Rinkeby

    address public openseaAddress = 0x00000000006CEE72100D161c57ADA5Bb2be1CA79; // Rinkeby
    address public looksRareAddress = 0x59728544B08AB483533076417FbBB2fD0B17CE3a; // Rikeby 

    struct tokenBalances {
        uint256 ETH;
        uint256 WETH;
        uint256 USDC;
        uint256 USDT;
    }

    struct OrderStatus {
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct BluechipContract {
        address _address;
        string _name;
        string _image;
    } 

    BluechipContract[] public bluechipAddress;

    mapping (address => BluechipContract) public getBluechipContract;

    constructor() {}

    function updateOpenSeaAddress(address _address) external onlyOwner {
        openseaAddress = _address;
    }

    function updateLooksRareAddress(address _address) external onlyOwner {
        looksRareAddress = _address;
    }

    function updateTokenAddress(address _wethAddress, address _usdcAddress, address _usdtAddress) external onlyOwner {
        _weth = _wethAddress;
        _usdc = _usdcAddress;
        _usdt = _usdtAddress;
    }

    function getTokenUri(address _address, uint256[] memory _tokenID) public view returns (string[] memory) {
        string[] memory listOfTokenURI = new string[](_tokenID.length);
        for(uint256 i=0; i<_tokenID.length; i++){
            try NFTAddress(_address).tokenURI(_tokenID[i]) {
                listOfTokenURI[i] =  NFTAddress(_address).tokenURI(_tokenID[i]);
            }
            catch {
                try NFTAddress(_address).uri(_tokenID[i]) {
                    listOfTokenURI[i] = NFTAddress(_address).uri(_tokenID[i]);
                }
                catch {
                    listOfTokenURI[i] = "Error in Token";
                }
            }
        }
        return listOfTokenURI; 
    }

    function addBluechipAddress(address[] memory _address, string[] memory _name, string[] memory _image) external onlyOwner {
        require(_address.length == _name.length, "Array length not equal");
        require(_image.length == _name.length, "Array length not equal");
        for(uint256 i=0; i<_address.length; i++){
            require(getBluechipContract[_address[i]]._address == address(0), "Address Already Exists");
            BluechipContract memory _bluechipContract;
            _bluechipContract._address = _address[i];
            _bluechipContract._name = _name[i];
            _bluechipContract._image = _image[i];
            getBluechipContract[_address[i]] = _bluechipContract;
            bluechipAddress.push(_bluechipContract);
        }
    }

    function removeBluechipAddress(address _address) external onlyOwner {
        require(getBluechipContract[_address]._address != address(0), "Address Does Not Exists");
        uint256 index = 0;
        bool flag = false;
        for(uint256 i=0; i<bluechipAddress.length; i++)
        {
            if(bluechipAddress[i]._address == _address){
                index = i;
                flag = true;
                BluechipContract storage _BluechipContract = getBluechipContract[_address];
                _BluechipContract._address = address(0);
                _BluechipContract._image = "";
                _BluechipContract._name = "";
                getBluechipContract[_address] = _BluechipContract;
            }
        }
        if(flag)
        {
            bluechipAddress[index] = bluechipAddress[bluechipAddress.length -1];
            bluechipAddress.pop();
        }
    }

    function getTokenBalances(address _address) public view returns (tokenBalances memory) {
        tokenBalances memory _tokenBalance;
        _tokenBalance.ETH = address(_address).balance;
        _tokenBalance.WETH = TokenBalance(_weth).balanceOf(_address);
        _tokenBalance.USDC = TokenBalance(_usdc).balanceOf(_address);
        _tokenBalance.USDT = TokenBalance(_usdt).balanceOf(_address);
        return _tokenBalance;
    }

    function getNFTBalances(address _address, address _contractAddress) public view returns (BluechipContract[] memory, uint256[] memory, uint256) {
        uint256[] memory nftBalances = new uint256[](bluechipAddress.length);
        for(uint256 i=0; i<bluechipAddress.length; i++){
            nftBalances[i] = NFTBalance(bluechipAddress[i]._address).balanceOf(_address);
        }
        uint256 _contractNFTBalance =  NFTBalance(_contractAddress).balanceOf(_address);
        return (bluechipAddress, nftBalances, _contractNFTBalance);
    }

    function getUserData(address _address, address _contractAddress) external view returns (tokenBalances memory, BluechipContract[] memory, uint256[] memory, uint256) {
        uint256[] memory nftBalances = new uint256[](bluechipAddress.length);
        uint256 _contractNFTBalance;
        (,nftBalances,_contractNFTBalance) = getNFTBalances(_address, _contractAddress);
        return (getTokenBalances(_address),bluechipAddress,nftBalances,_contractNFTBalance);
    }

    function getOrderStatus(bytes32 _orderHash) public view returns (OrderStatus memory) {
        OrderStatus memory orderStatus; 
        (orderStatus.isValidated,orderStatus.isCancelled, orderStatus.totalFilled, orderStatus.totalSize) = OpenSea(openseaAddress).getOrderStatus(_orderHash);
        return orderStatus;
    }

    function getMultipleOrderStatus(bytes32[] memory _orderHash) external view returns (OrderStatus[] memory){
        OrderStatus[] memory orderStatus = new OrderStatus[](_orderHash.length);
        for(uint256 i=0; i<_orderHash.length; i++){
            orderStatus[i] = getOrderStatus(_orderHash[i]);
        } 
        return orderStatus;
    }

    function getUserOrderNonceExecutedOrCancelled(address _address, uint256 _orderNonce) public view returns (bool) {
        return LooksRare(looksRareAddress).isUserOrderNonceExecutedOrCancelled(_address, _orderNonce);
    }

    function getMultipleUserOrderNonce(address[] memory _address, uint256[] memory _orderNonce) external view returns (bool[] memory) {
        require(_address.length == _orderNonce.length, "Length of Array's Passed not equal");
        bool[] memory status = new bool[](_address.length);
        for(uint256 i=0; i<_address.length; i++) {
            status[i] = getUserOrderNonceExecutedOrCancelled(_address[i], _orderNonce[i]);
        }
        return status;
    }

}