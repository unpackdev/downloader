
pragma solidity >=0.4.23 <0.5.0;

interface IMakerPriceFeed {
  function read() external view returns (bytes32);
}

contract EtherPrice {
  function getETHUSDPrice() public view returns (uint) {
    address ethUsdPriceFeed = 0x729D19f657BD0614b4985Cf1D82531c67569197B;
    return uint(
      IMakerPriceFeed(ethUsdPriceFeed).read()
    );
  }
}