// SPDX-License-Identifier: GPL-3.0

/*                    
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@((((((((                @@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((((((((            ((((((((@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((((((((            ((((((((@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@((((((((((((            ((((((((@@@@@@@@@@@@@@@@
@@@@@@@@@@@@    ((((((((                ((((((((((((@@@@@@@@@@@@
@@@@@@@@@@@@    ((((((((                ((((((((((((@@@@@@@@@@@@
@@@@@@@@@@@@                                ((((((((@@@@@@@@@@@@
@@@@@@@@@@@@                                ((((((((@@@@@@@@@@@@
@@@@@@@@((((            ////////////                    @@@@@@@@
@@@@@@@@            ////////////////////                @@@@@@@@
@@@@@@@@            ////////////////////                @@@@@@@@
@@@@@@@@            ////////////////////        ((((((((@@@@@@@@
@@@@@@@@,,,,,,,,    ////////////////////    ((((((((((((@@@@@@@@
@@@@@@@@,,,,,,,,    ////////////////////    ((((((((((((@@@@@@@@
@@@@@@@@@@@@,,,,,,,,    ////////////        ((((((((@@@@@@@@@@@@
@@@@@@@@@@@@,,,,,,,,    ////////////        ((((((((@@@@@@@@@@@@
@@@@@@@@@@@@,,,,,,,,                        ((((((((@@@@@@@@@@@@
@@@@@@@@@@@@@@@@,,,,                            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@,,,,                            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    

        EGGZ, the CryptoPolz and Polzilla utility token.

                Visit https://metapond.io

                
                   @@@@              @@@@@@@@@(                        
               @@@@@@@@@@@@        @@@@@@@@@@@@@@                      
              @@@@@    @@@@@      @@@@@      @@@@@                     
             @@@@        @@@@     @@@@@      @@@@@                     
             @@@@        @@@@      @@@@@@@@@@@@@@                      
              @@          @@         &@@@@@@@@*                        
                                                                      
                   @@@@                                                
                   @@@@           @@@@        @@@@                     
             @@@@@@@@@@@@@@@@     @@@@       %@@@@                     
              @@@@@@@@@@@@@@       @@@@@@//@@@@@@                      
                   @@@@              @@@@@@@@@@                        
                   @@@@                       


                  Created by no+u @notuart    
*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface INFT {
  function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract Eggz is ERC20, Ownable {
  using SafeMath for uint256;

  // Emission rates
  uint256 constant public FAST = 12 ether;
  uint256 constant public SLOW = 3 ether;

  // Application state
  mapping(uint256 => uint256) private _cryptoPolzHarvests; // Token ID => Day
  mapping(uint256 => uint256) private _polzillaHarvests;   // Token ID => Day
  
  // Time constraints
  uint256 public start;
  uint256 public end;

  // Contracts
  INFT public cryptoPolzContract;
  INFT public polzillaContract;
  address public burnerAddress;

  constructor (
    address cryptoPolzContractAddress,
    address polzillaContractAddress
  ) ERC20("Eggz", "EGGZ") {
    start = block.timestamp.sub(3628800); // 42 days ago
    end = block.timestamp.add(1324512042); // in 42 years and 42 seconds

    cryptoPolzContract = INFT(cryptoPolzContractAddress);
    polzillaContract = INFT(polzillaContractAddress);
  }

  function _paired(uint256 _tokenId, uint256[] memory _wallet) internal pure returns (bool) {
    for (uint256 i; i < _wallet.length; i++) {
      if (_wallet[i] == _tokenId) {
        return true;
      }
    }

    return false;
  }

  function lastCryptoPolzHarvestByTokenId(uint256 _tokenId) external view returns (uint256) {
    require ((_tokenId > 0) && (_tokenId <= 9696), "Invalid CryptoPolz ID");

    return _cryptoPolzHarvests[_tokenId];
  }

  function lastPolzillaHarvestByTokenId(uint256 _tokenId) external view returns (uint256) {
    require ((_tokenId > 0) && (_tokenId <= 9696), "Invalid Polzilla ID");
    
    return _polzillaHarvests[_tokenId];
  }

  function harvest() public returns (uint256) {
    require (block.timestamp <= end, "Too late");

    uint256 today = block.timestamp.sub(start).div(86400);
    uint256[] memory cryptoPolzWallet = cryptoPolzContract.walletOfOwner(msg.sender);
    uint256[] memory polzillaWallet = polzillaContract.walletOfOwner(msg.sender);

    require ((polzillaWallet.length > 0) || (cryptoPolzWallet.length > 0), "Emtpy wallet");

    uint256 amount = 0;

    for (uint256 i; i < cryptoPolzWallet.length; i++) {
      uint256 tokenId = cryptoPolzWallet[i];
      uint256 daysSinceLastHarvest = today.sub(_cryptoPolzHarvests[tokenId]);
      
      if (! _paired(tokenId, polzillaWallet)) {
        amount = amount.add(daysSinceLastHarvest.mul(SLOW));
      }

      _cryptoPolzHarvests[tokenId] = today;
    }

    for (uint256 i; i < polzillaWallet.length; i++) {
      uint256 tokenId = polzillaWallet[i];
      uint256 daysSinceLastHarvest = today.sub(_polzillaHarvests[tokenId]);

      if (_paired(tokenId, cryptoPolzWallet)) {
        amount = amount.add(daysSinceLastHarvest.mul(FAST));
      } else {
        amount = amount.add(daysSinceLastHarvest.mul(SLOW));
      }
      
      _polzillaHarvests[tokenId] = today;
    }

    require (amount > 0, "Empty carton");

    _mint(msg.sender, amount);

    return amount;
  }

  function setBurnerAddress(address _address) external onlyOwner {
    burnerAddress = _address;
  }

  function burn(address _from, uint256 _amount) external {
    require (msg.sender == burnerAddress, "Forbidden");

    _burn(_from, _amount);
  }
}