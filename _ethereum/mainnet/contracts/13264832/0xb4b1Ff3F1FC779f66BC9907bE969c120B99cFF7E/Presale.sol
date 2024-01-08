// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


//    .::::::::::::*********=::::::::::::::::::::::::::::::::::::::::::::.
//    =          -@@@@@@@@@@@*                                      *#   -
//    =          +-*=*==%=**@@+                                     @@:  -
//    =         ====-#==%:*:@@%                        -@=  . :*%%-+@@=  -
//    =         ::*:**=+%+*%@@+              ..=:      =@==@+=@*=@@.@@   -
//    =           %%@@@@@@@@@+          -+*%@%-*: =%@@+=@#@* %@%#+= @@-  -
//    =            -*%@@@@#=.          .@%@@-.=@=+@+:+-=@@@@.%@==%# %%=  -
//    =                   .::*:          .@%  =@=@@  :=+@#+@#-%%#=       -
//    =               =*.+@*+@- +@@@=    .@%  =@=@@++@*=@- =:            -
//    =              =@*.%@++@-#@=+@@    .@%  =@=-#%*-                   -
//    = :=+#%%  .=+= %@@=@@=+@=@@*+=-    .@%  :-.                        -
//    = @@#+%@=*@#%@=#@= #@.+@-@@+#@-     .                              -
//    = @@:-%@:+**%@==@= #@.+@-:**+.                                     -
//    = @@@@@=.@#:#@==@= ** ::                                           -
//    = @@:*@#-@@@%%-:-.                                                 -
//    =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
//    =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
//    =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
//    =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
//    =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+
//    -  -+#- .=+*. .-+#=: +===*=+=:---:-+=+-==--+:-*=+-==-=+:=====.     =
//     :.::-::.:--:..:--:........::.....:.:..::::..:.:...:.::::::::.....:
//
//    Run It Wild + PrimeFlare


contract Presale is ERC721Enumerable, Ownable {
  constructor() ERC721("WSB Raffle", "WSBR") {}

  using SafeMath for uint256;

  uint256 public constant BUY_PRICE = 0.1 ether;
  uint16 public constant MAX_TOKEN = 30000;
  uint16 public constant MAX_PER_ACCOUNT = 5;
  bool public active = false;
  uint256 public presaleOpenTime;
  uint256 public presaleCloseTime;

  address private redeemableContract;
  uint16[] private tokens;
  address payable private ownerA = payable(0xB240D3aAD9093a08B62ce96343d8A47e22266AdD);
  address payable private ownerB = payable(0x75dF311CE8E000CaDD8E4382B42483530bCC6355);
  address payable private ownerC = payable(0x724696c017902944ADD5916eA36776435c64B306);
  address payable private ownerD = payable(0x8DE725291fB05e238dC1c974a74835BDB9f01E21);

  function claim(uint amount) external payable {
    require(active, "Claim: Pre-mint is not active.");
    require(block.timestamp >= presaleOpenTime && block.timestamp <= presaleCloseTime, "Claim: Pre-mint closed.");
    require(msg.value >= amount.mul(BUY_PRICE), "Claim: Ether value incorrect.");
    require(tx.origin == msg.sender, "Claim: Can not be called using a contract.");
    require(tokens.length.add(amount) <= MAX_TOKEN, "Claim: All pre-mint are sold out.");
    require(balanceOf(msg.sender).add(amount) <= MAX_PER_ACCOUNT, "Claim: Can not pre-mint that many.");

    for(uint8 i = 0; i < amount; i++){
      _safeMint(msg.sender, tokens.length);
      tokens.push(uint16(tokens.length));
      shiftTokens();
    }
  }

  function setRedeemContract(address contractAddress) external onlyOwner {
    redeemableContract = contractAddress;
  }

  function setPresaleTime(uint256 openTime, uint256 closeTime) external onlyOwner {
    presaleOpenTime = openTime;
    presaleCloseTime = closeTime;
  }

  function burnRedeem(uint256 index) external {
    require(redeemableContract == msg.sender, "BurnRedeem: Can only burn from redeem contract");
    _burn(index);
  }

  function shiftTokens() private {
    uint16 index = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender, tokens.length, address(this)))) % tokens.length);
    uint16 temp = tokens[index];
    tokens[index] = tokens[tokens.length-1];
    tokens[tokens.length-1] = temp;
  }

  function toggleActive() external onlyOwner {
    active = !active;
  }

  function withdraw() public onlyOwner {
    uint balanceA = address(this).balance.mul(275).div(1000);
    uint balanceB = address(this).balance.mul(175).div(1000);
    uint balanceC = address(this).balance.mul(50).div(1000);
    uint balanceD = address(this).balance.sub(balanceA).sub(balanceB).sub(balanceC);

    ownerA.transfer(balanceA);
    ownerB.transfer(balanceB);
    ownerC.transfer(balanceC);
    ownerD.transfer(balanceD);
  }

  function getTokenValue(uint16 index) external view returns (uint16) {
    require(redeemableContract == msg.sender, "GetTokenValue: Can only be called from redeem contract");
    return tokens[index];
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return "ipfs://QmX6qSHYXE4jGXeYaprDftgJVjKf9A29ohxZJ5SPtZPceG";
  }
}
