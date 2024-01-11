// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC20.sol";

interface ILGGNFT {
    function safeMintBlindBox(address to) external;
}

contract IdoNftNew is Ownable {

    bool public open;
    bool public done;
    bool public publicSell;
    mapping (address => bool) public whitelist;
    mapping (address => bool) public doneAddress;
    uint256 public sellcount = 388;
    uint256 public sales;
    uint256 public boxTokenPrices = 8 * 10 ** 16;
    ILGGNFT public token;
    address public beneficiary = address(0xB02ae6be01E1920798561C21eb26952Af7549e69);
    uint256 public whitelistCount = 200;
    uint256 public whitelistSales;

    constructor(ILGGNFT _token){
        token = _token;
    }

    function buyBox() external payable {
        uint256 _boxesLength = 1;
        require(publicSell, "No launch");
        require(!done, "Finish");
        require(_boxesLength > 0, "Boxes length must > 0");
        address sender = msg.sender;
        require(!doneAddress[sender], "Purchase only once");
        uint256 price = _boxesLength * boxTokenPrices;
        uint256 amount = msg.value;
        require(amount >= price, "Transfer amount error");
        doneAddress[sender] = true;
        
        for (uint256 i = 0; i < _boxesLength; i++) {
            require(sales < sellcount, "Sell out");
            sales += 1;
            if(sales >= sellcount){
                done = true;
            }
            token.safeMintBlindBox(sender);
        }
            
        payable(beneficiary).transfer(price);  
        emit Buy(sender, beneficiary, price);
    }

    function whitelistBuy() external payable {
        require(whitelistSales < whitelistCount, "Sell out...");
        require(open, "No launch");
        address sender = msg.sender;
        uint256 price = boxTokenPrices;
        uint256 amount = msg.value;
        require(amount >= price, "Transfer amount error");
        require(whitelist[sender], "Account is not already whitelist");
        whitelist[sender] = false;
        whitelistSales += 1;
        token.safeMintBlindBox(sender);
        payable(beneficiary).transfer(price);
    }

    function setWhitelist(address[] memory _accounts) public onlyOwner {
        for (uint i = 0; i < _accounts.length; i+=1) {
            whitelist[_accounts[i]] = true;
        }
    }
    function delWhitelist(address[] memory _accounts) public onlyOwner {
        for (uint i = 0; i < _accounts.length; i+=1) {
            whitelist[_accounts[i]] = false;
        }
    }

    function setSellcount(uint256 _count) public onlyOwner {
        sellcount = _count;
    }

    function setWhitelistCount(uint256 _whitelistCount) public onlyOwner {
        whitelistCount = _whitelistCount;
    }

    function setBoxTokenPrices(uint256 _boxTokenPrices) public onlyOwner {
        boxTokenPrices = _boxTokenPrices;
    }

    function setOpen(bool _open) public onlyOwner {
        open = _open;
    }

    function setDone(bool _done) public onlyOwner {
        done = _done;
    }

    function setPublicSell(bool _publicSell) public onlyOwner {
        publicSell = _publicSell;
    }

    function setToken(ILGGNFT _token) public onlyOwner {
        token = _token;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    receive() external payable {}
    fallback() external payable {}

    /* ========== EMERGENCY ========== */
    /*
        Users make mistake by transferring usdt/busd ... to contract address.
        This function allows contract owner to withdraw those tokens and send back to users.
    */
    function rescueStuckToken(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), amount);
    }

    function refund(address _addr, uint256 _amount) external onlyOwner {
        payable(_addr).transfer(_amount);
    }

    /* ========== EVENTS ========== */
    event Buy(address indexed user, address indexed beneficiary, uint256 amount);
}