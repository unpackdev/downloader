// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./Ownable.sol";

/*        _____                    _____                    _____          
         /\    \                  /\    \                  /\    \         
        /::\    \                /::\    \                /::\____\        
       /::::\    \              /::::\    \              /:::/    /        
      /::::::\    \            /::::::\    \            /:::/   _/___      
     /:::/\:::\    \          /:::/\:::\    \          /:::/   /\    \     
    /:::/__\:::\    \        /:::/__\:::\    \        /:::/   /::\____\    
   /::::\   \:::\    \      /::::\   \:::\    \      /:::/   /:::/    /    
  /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/   /:::/   _/___  
 /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/___/:::/   /\    \ 
/:::/  \:::\   \:::\____\/:::/__\:::\   \:::\____\|:::|   /:::/   /::\____\
\::/    \:::\   \::/    /\:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /
 \/____/ \:::\   \/____/  \:::\   \:::\   \/____/  \:::\/:::/   /:::/    / 
          \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /  
           \:::\____\       \:::\   \:::\____\       \::::/___/:::/    /   
            \::/    /        \:::\   \::/    /        \:::\__/:::/    /    
             \/____/          \:::\   \/____/          \::::::::/    /     
                               \:::\    \               \::::::/    /      
                                \:::\____\               \::::/    /       
                                 \::/    /                \::/____/        
                                  \/____/                  ~~              */

contract Fewwwww is Ownable {
    string public NAME_PROJECT = "Fewwwww";
    string public CREATED_BY = "0xBosz";
    uint256 public PREMIUM_PRICE = 0.1 ether;
    uint256 public PERCENT_FEE = 3; // Fee default is 0.3%
    bool public premiumSale = true;
    bool public feeActive;

    uint256 public premiumUsers;
    mapping(address => bool) public _premiumList;

    function sendEthersBundle(address payable [] memory _receiver) public payable {
        uint256 balance = address(msg.sender).balance;
        require(balance > msg.value , "Insufficent balance");

        for(uint256 i = 0; i < _receiver.length; i++) {
            uint256 amount = msg.value / _receiver.length;
            require(_receiver[i] != address(0), "Cannot transfer to null address");

            if (feeActive) {
                if (_premiumList[msg.sender]) {
                    _receiver[i].transfer(amount);
                } else {
                    _receiver[i].transfer(amount - (amount * PERCENT_FEE) / 1000);
                }
            } else {
                _receiver[i].transfer(amount);
            }
        }
    }

    function sendEther(address payable _receiver) public payable {
        uint256 balance = address(msg.sender).balance;
        require(balance > msg.value , "Insufficent balance");
        require(_receiver != address(0), "Cannot transfer to null address");
        _receiver.transfer(msg.value);
    }

    function purchasePremium() public payable {
        require(premiumSale, "Premium sale is not active");
        require(!_premiumList[msg.sender], "You already on premium list");
        require(msg.value == PREMIUM_PRICE, "Ether value sent should be 0.1 eth");

        _premiumList[msg.sender] = true;
        premiumUsers++;
    }

    function donation() public payable {
        require(msg.value > 0, "Ether value sent should not 0 eth");

     /* ████████╗██╗░░██╗░█████╗░███╗░░██╗██╗░░██╗░██████╗
        ╚══██╔══╝██║░░██║██╔══██╗████╗░██║██║░██╔╝██╔════╝
        ░░░██║░░░███████║███████║██╔██╗██║█████═╝░╚█████╗░
        ░░░██║░░░██╔══██║██╔══██║██║╚████║██╔═██╗░░╚═══██╗
        ░░░██║░░░██║░░██║██║░░██║██║░╚███║██║░╚██╗██████╔╝
        ░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

        ███████╗░█████╗░██████╗░
        ██╔════╝██╔══██╗██╔══██╗
        █████╗░░██║░░██║██████╔╝
        ██╔══╝░░██║░░██║██╔══██╗
        ██║░░░░░╚█████╔╝██║░░██║
        ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝

        ░██████╗██╗░░░██╗██████╗░██████╗░░█████╗░██████╗░████████╗░░░
        ██╔════╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝░░░
        ╚█████╗░██║░░░██║██████╔╝██████╔╝██║░░██║██████╔╝░░░██║░░░░░░
        ░╚═══██╗██║░░░██║██╔═══╝░██╔═══╝░██║░░██║██╔══██╗░░░██║░░░░░░
        ██████╔╝╚██████╔╝██║░░░░░██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██╗
        ╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝ */

    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        PREMIUM_PRICE = _newPrice;
    }

    function setPercentFee(uint256 _percentageFee) public onlyOwner {
        PERCENT_FEE = _percentageFee;
    }

    function setPremiumSale(bool _premiumSale) public onlyOwner {
        premiumSale = _premiumSale;
    }

    function setFeeActive(bool _feeActive) public onlyOwner {
        feeActive = _feeActive;
    }

    function addPremiumUsers(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            _premiumList[_address[i]] = true;
            premiumUsers++;
        }
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success,) = owner().call{value: amount}("");
        require(success, "Failed to send ether");
    }
}