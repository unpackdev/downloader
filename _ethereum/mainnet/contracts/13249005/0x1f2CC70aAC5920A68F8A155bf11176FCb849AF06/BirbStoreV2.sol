// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";

interface Gen2Contract{
  function getTimesMated(uint birbID) external view returns (uint256);
}

contract BirbStoreV2 is Context, Pausable, Ownable{
  address internal Gen2Address;
  address internal Gen1Address;

  address payable internal communityWallet = payable(0x690d89B461dD2038b3601382b485807eac45741D);
  address payable internal smith = payable(0x8fEC7D1Ac56ddAB94A14F8395a19D83387aD2af9); 
  address payable internal fappablo = payable(0xb72e9541FE46384D6942291F7B11db6bBB7dA956);
  address payable internal astronio = payable(0x9cCF31738Efcd642ABbe39202F7BD78f1495B8A4);
  address payable internal devasto = payable(0xC6c3fBdE140DdF82723c181Ee390de5b63087411);

  uint feePercent = 5;

  mapping(uint => uint) public prices;
  mapping(uint => address) public owners;
  mapping(uint => uint) public expirations;

  constructor(address _Gen1Address, address _Gen2Address) {
    Gen1Address = _Gen1Address;
    Gen2Address = _Gen2Address;
  }
  
  event depositedInStore(uint birbId, uint price, address seller, uint expireBlock);
  event removedFromStore(uint birbId, uint price, bool sale, address receiver);

  function multiDepositForSale(uint[] memory birbIds, uint[] memory birbPrices, uint expireBlock) external whenNotPaused{
    uint i;

    require(birbIds.length <= 32,"Too many Birbs");
    for(i = 0; i < birbIds.length; i++){
      require(birbIds[i] < 16383,"One of the birbs does not exist");
      require(Gen2Contract(Gen2Address).getTimesMated(birbIds[i]) == 0,"All Birbs must be virgin");
      require(birbPrices[i] > 0 ether && birbPrices[i] < 10000 ether,"Invalid price"); 
      if(birbIds[i] <= 8192){
        require(IERC721(Gen1Address).ownerOf(birbIds[i]) == _msgSender(),"You must own all the Birbs");
      }else{
        require(IERC721(Gen2Address).ownerOf(birbIds[i]) == _msgSender(),"You must own all the Birbs");
      }
      prices[birbIds[i]] = birbPrices[i];
      owners[birbIds[i]] = _msgSender();
      expirations[birbIds[i]] = expireBlock;
      emit depositedInStore(birbIds[i], birbPrices[i], _msgSender(), expireBlock);
    }
  }

  function sendViaCall(address payable _to, uint amount) internal {
      (bool sent, bytes memory data) = _to.call{value: amount}("");
      require(sent, "Failed to send Ether");
  }

  function multiBuy(uint[] memory birbIds) external payable whenNotPaused{
    uint i;
    uint totalPrice = 0;
      
    require(birbIds.length <= 32,"Too many Birbs");
    for(i = 0; i < birbIds.length; i++){
      require(birbIds[i] < 16383,"One of the Birbs does not exists");
      require(prices[birbIds[i]] > 0,"One of the Birbs has an invalid price");
      require(expirations[birbIds[i]] > block.number || expirations[birbIds[i]] == 0,"One of the Birbs is not on sale anymore");
      require(Gen2Contract(Gen2Address).getTimesMated(birbIds[i]) == 0,"One of the Birbs is not virgin");
      if(birbIds[i] <= 8192){
        require(IERC721(Gen1Address).ownerOf(birbIds[i]) == owners[birbIds[i]],"One of the Birbs changed owner");
      }else{
        require(IERC721(Gen2Address).ownerOf(birbIds[i]) == owners[birbIds[i]],"One of the Birbs changed owner");
      }
      totalPrice = totalPrice + prices[birbIds[i]];
    }

    require(msg.value == totalPrice,"Invalid msg.value");

    address owner;
    for(i = 0; i < birbIds.length; i++){
      uint amountAfterFee = prices[birbIds[i]] - (prices[birbIds[i]]*5)/100;
      owner = owners[birbIds[i]];
      owners[birbIds[i]] = address(0x0);
      prices[birbIds[i]] = 0;
      if(birbIds[i] <= 8192){
        IERC721(Gen1Address).safeTransferFrom(owner, _msgSender(), birbIds[i]);
      }else{
        IERC721(Gen2Address).safeTransferFrom(owner, _msgSender(), birbIds[i]);
      }
      sendViaCall(payable (owner),amountAfterFee);
      emit removedFromStore(birbIds[i], prices[birbIds[i]], true, _msgSender());
    }
  }

  function removeBirbsFromSale(uint[] memory birbIds) external whenNotPaused{
    uint i;
    require(birbIds.length <= 32,"Too many Birbs");
    for(i = 0; i < birbIds.length; i++){
      require(birbIds[i] < 16383,"One of the Birbs does not exists");
      require(owners[birbIds[i]] == _msgSender(),"You must be the owner of all the Birbs");
      if(birbIds[i] <= 8192){
        require(IERC721(Gen1Address).ownerOf(birbIds[i]) == owners[birbIds[i]],"One of the Birbs changed owner");
      }else{
        require(IERC721(Gen2Address).ownerOf(birbIds[i]) == owners[birbIds[i]],"One of the Birbs changed owner");
      }
      owners[birbIds[i]] = address(0x0);
      prices[birbIds[i]] = 0;
      emit removedFromStore(birbIds[i], prices[birbIds[i]], false, _msgSender());
    } 
  }

  function withdrawFunds() external {
    uint halfBalance = address(this).balance / 2;
    uint halfOfHalfBalance = halfBalance / 2;
    uint thirdOfHalfOfHalfBalance = halfOfHalfBalance / 3;
    communityWallet.transfer(halfBalance);
    smith.transfer(halfOfHalfBalance);
    fappablo.transfer(thirdOfHalfOfHalfBalance);
    astronio.transfer(thirdOfHalfOfHalfBalance);
    devasto.transfer(thirdOfHalfOfHalfBalance);
  }

  function pause() external onlyOwner whenNotPaused{
    _pause();
  }

  function unpause() external onlyOwner whenPaused{
    _unpause();
  }

  function setFees(uint _feePercent) external onlyOwner{
    feePercent = _feePercent;
  }

}