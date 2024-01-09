// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BlindboxStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract Utils is Ownable, BlindboxStorage{
    
    using SafeMath for uint256;

    constructor() {
       

    }
    function init() public {
         MATIC = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //for eth chain wrapped ethereum 
        USD = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        platform = 0x9c427ea9cE5fd3101a273815Ff8530f2AC75Db37;
        nft = INFT(0x326Cae76A11d85b5c76E9Eb81346eFa5e4ea7593);
        dex = IDEX(0x9d5dc3cc15E5618434A2737DBF76158C59CA1e65);
        LPMATIC = LPInterface(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852);
        _setOwner(0xcfd872E3E8FB719EBEce7e872eD5DC287BB1E329);
    }

    function setOnwerManually() public {
      require(owner() == address(0x0), "already set");
      _setOwner(_msgSender());
    }
   function addWhiteListUsers(bytes32[] memory users, uint256 seriesId) onlyOwner public {
    for(uint256 i = 0; i<users.length; i++){
      _whitelisted[users[i]][seriesId] = true;
    }
  }

  function removeWhiteListUsers(bytes32[] memory users, uint256 seriesId) onlyOwner public {
      for(uint256 i = 0; i<users.length; i++){
      _whitelisted[users[i]][seriesId] = false;
    }
  }

  function isSeriesWhiteListed(uint256 seriesId) public view returns(bool) {
    return _isWhiteListed[seriesId];
  }
   function isUserWhiteListed(bytes32 user, uint256 seriesId) public view returns(bool) {
    return _whitelisted[user][seriesId];
  }

   function calculatePrice(uint256 _price, uint256 base, uint256 currencyType) public view returns(uint256 price) {
    price = _price;
     (uint112 _reserve0, uint112 _reserve1,) =LPMATIC.getReserves();
    if(currencyType == 0 && base == 1){
      price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(_reserve1,1000000000000)),_reserve0);
    } else if(currencyType == 1 && base == 0){
      price = SafeMath.div(SafeMath.mul(price,_reserve0),SafeMath.mul(_reserve1,1000000000000));
    }
    
  }
    
}