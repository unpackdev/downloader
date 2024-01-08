// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ElonsBoredGovernanceToken.sol";
import "./ElonsBoredXCoin.sol";
import "./InfiniteImprobabilityDrive.sol";

contract ElonsBoredBundle {
  ElonsBoredGovernanceToken public token1;
  ElonsBoredXCoin public token2;
  InfiniteImprobabilityDrive public nft1;

  uint256 public maxAllowBundle;
  uint256 public ethPrice;
  address payable public  owner;
  
  modifier restricted() {
      // only owner can change
      require(msg.sender == owner,"Sender is not the creator!");
        _;
  }

  constructor(address _tokenAddr1,address _tokenAddr2,address _nftAddr1,uint256 _ethPrice,uint256 allowBundle) public {
    token1 = ElonsBoredGovernanceToken(_tokenAddr1);
    token2 = ElonsBoredXCoin(_tokenAddr2);

    nft1 = InfiniteImprobabilityDrive(_nftAddr1);

    ethPrice = _ethPrice;
    maxAllowBundle = allowBundle;
    owner = payable(msg.sender);
  }

    function setMaxAllowBundle(uint256 allowBundle)  external restricted{
        maxAllowBundle = allowBundle;
    }

    function availableBundle() public view returns(uint256){
      return maxAllowBundle - nft1.totalSupply();
    }

    function setOwnertAddr(address payable _owner)  external restricted{
        owner = _owner;
    }

   function setEthPrice(uint256 _ethPrice)  external restricted{
        ethPrice = _ethPrice;
    }

   function buyBundle(uint256 bundle_count) public  payable{
      require(bundle_count >= 1,"Bundle Count Error");
      require(availableBundle() >= bundle_count,"Bundle Amount Too High");

      uint256 price = ethPrice * bundle_count;
      require(msg.value >= price,"Incorrect ETH Price");
      owner.transfer(price);

      for (uint i=0; i< bundle_count; i++) {
        token1.contractMint(msg.sender,1);
        token2.contractMint(msg.sender,1000000);

        nft1.mintWithContract(msg.sender);
      }
   }

}