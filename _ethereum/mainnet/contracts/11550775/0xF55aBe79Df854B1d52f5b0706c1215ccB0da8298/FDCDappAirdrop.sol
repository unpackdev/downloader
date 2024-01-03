pragma solidity 0.5.16;

contract FDCDappAirdrop {

  constructor()
  public
  {
    owner = msg.sender;
  }

  address private owner;

  string private airdropVersion = "v1";

  uint256 private DappReward = 1333400;

  mapping (address => uint256) private airdropAddresses;

  address private FDCContract=0x311C6769461e1d2173481F8d789AF00B39DF6d75;

  function airdrop(address Address) public returns (bool) {

    require(Address != address(0), "Need to use a valid Address");
    require(airdropAddresses[Address] == 1, "Address not valid or already got air drop");

    (bool successBalance, bytes memory dataBalance) = FDCContract.call(abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), address(this)));
    require(successBalance, "Freedom Dividend Coin air drop balanceOf failed.");
    uint256 rewardLeft = abi.decode(dataBalance, (uint256));

    if (rewardLeft >= DappReward) {
        (bool successTransfer, bytes memory dataTransfer) = FDCContract.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), Address, DappReward));
        require(successTransfer, "Freedom Dividend Coin air drop failed.");
        airdropAddresses[Address] = 2;
        return true;
    } else {
        return false;
    }

  }

  function addAirdropAddress(address Address) public returns (bool) {
    require(msg.sender == owner, "Only owner can set");
    airdropAddresses[Address] = 1;
    return true;
  }

  function getAirdropAddresses(address Address) public view returns (uint256) {
    return airdropAddresses[Address];
  }

  function getAirdropVersion() public view returns (string memory) {
    return airdropVersion;
  }

}