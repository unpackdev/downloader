// SPDX-License-Identifier: MIT

// $$$$$$\                                 $$\                               $$\                 $$\      $$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$\            
//$$  __$$\                                $$ |                              $$ |                $$$\    $$$ |$$  _____|$$  _____|$$  __$$\           
//$$ /  \__| $$$$$$\  $$\   $$\  $$$$$$\ $$$$$$\    $$$$$$\   $$$$$$\   $$$$$$$ | $$$$$$$\       $$$$\  $$$$ |$$ |      $$ |      $$ |  $$ | $$$$$$$\ 
//$$ |      $$  __$$\ $$ |  $$ |$$  __$$\\_$$  _|  $$  __$$\  \____$$\ $$  __$$ |$$  _____|      $$\$$\$$ $$ |$$$$$\    $$$$$\    $$$$$$$  |$$  _____|
//$$ |      $$ |  \__|$$ |  $$ |$$ /  $$ | $$ |    $$ /  $$ | $$$$$$$ |$$ /  $$ |\$$$$$$\        $$ \$$$  $$ |$$  __|   $$  __|   $$  __$$< \$$$$$$\  
//$$ |  $$\ $$ |      $$ |  $$ |$$ |  $$ | $$ |$$\ $$ |  $$ |$$  __$$ |$$ |  $$ | \____$$\       $$ |\$  /$$ |$$ |      $$ |      $$ |  $$ | \____$$\ 
//\$$$$$$  |$$ |      \$$$$$$$ |$$$$$$$  | \$$$$  |\$$$$$$  |\$$$$$$$ |\$$$$$$$ |$$$$$$$  |      $$ | \_/ $$ |$$ |      $$$$$$$$\ $$ |  $$ |$$$$$$$  |
// \______/ \__|       \____$$ |$$  ____/   \____/  \______/  \_______| \_______|\_______/       \__|     \__|\__|      \________|\__|  \__|\_______/ 
//                    $$\   $$ |$$ |                                                                                                                  
//                    \$$$$$$  |$$ |                                                                                                                  
//                     \______/ \__|                                                                                                                  
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
contract CryptoadzMfers is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public maxMintablePerTxn = 20;

    mapping(address => uint256) public freeMints; 
    uint256[] public priceArray;
 
    string private _baseURIExtended;

    bool public saleActive;
    bool public locked;

    constructor(string memory _uri) ERC721A("CryptoadzMfers","CTMfers"){
        _baseURIExtended = _uri;
        priceArray.push(0);
        priceArray.push(0.02 ether);
        priceArray.push(0.03 ether);
        priceArray.push(0.04 ether);
    }

    function mint(uint _amount) external payable{
        uint currentPrice = getCurrentPrice();
        uint _freeMinted = freeMints[msg.sender];
        if(currentPrice == 0){
            require(_freeMinted+_amount <= 20, "Max Free mints exceeded");
            freeMints[msg.sender] = _freeMinted + _amount;
        }
        require(saleActive, "Sale is not active");
        require(_amount <= maxMintablePerTxn && _amount > 0,"Max mint per tx exceeded");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Mint finished");
        require(msg.value >= _amount*currentPrice, "Incorrect eth sent");
        _safeMint(msg.sender, _amount);
    }

    function getCurrentPrice() public view returns(uint price){
        uint _tokenCounter = totalSupply();
        if(_tokenCounter < 1000){
            return priceArray[0];
        }
        else if (_tokenCounter >= 1000 && _tokenCounter < 4000){
            return priceArray[1];
        }
        else if (_tokenCounter >= 4000 && _tokenCounter < 5000){
            return priceArray[2];
        }
        else if (_tokenCounter >= 5000){
            return priceArray[3];
        }
        else {
            return priceArray[3];
        }
    }

    function setPriceArray(uint256[] memory _priceArray) external onlyOwner {
        priceArray = _priceArray;
    }
    function setmaxMintablePerTxn(uint256 no) external onlyOwner {
        maxMintablePerTxn = no;
    }
    
    function toggleSale() external onlyOwner {
    saleActive = !saleActive;
  }
    function setBaseURI(string memory __baseURI) external onlyOwner {
    require(!locked, "locked for eternity");
    _baseURIExtended = __baseURI;
  }
    function withdrawAll(address payable receiver) external onlyOwner {
    uint256 balance = address(this).balance;
    receiver.transfer(balance);
  }
    function setLocked() external onlyOwner {
        locked = true;
    }
    function _baseURI() internal view override returns (string memory) {
    return _baseURIExtended;
  }
}