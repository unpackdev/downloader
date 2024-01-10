// SPDX-License-Identifier: MIT
// Artist - myitchyfinger.eth
// Dev - mongodillo.eth


/*                                                                    
MMMMMMMM               MMMMMMMM                    FFFFFFFFFFFFFFFFFFFFFF
M:::::::M             M:::::::M                    F::::::::::::::::::::F
M::::::::M           M::::::::M                    F::::::::::::::::::::F
M:::::::::M         M:::::::::M                    FF::::::FFFFFFFFF::::F
M::::::::::M       M::::::::::Mxxxxxxx      xxxxxxx  F:::::F       FFFFFF
M:::::::::::M     M:::::::::::M x:::::x    x:::::x   F:::::F             
M:::::::M::::M   M::::M:::::::M  x:::::x  x:::::x    F::::::FFFFFFFFFF   
M::::::M M::::M M::::M M::::::M   x:::::xx:::::x     F:::::::::::::::F   
M::::::M  M::::M::::M  M::::::M    x::::::::::x      F:::::::::::::::F   
M::::::M   M:::::::M   M::::::M     x::::::::x       F::::::FFFFFFFFFF   
M::::::M    M:::::M    M::::::M     x::::::::x       F:::::F             
M::::::M     MMMMM     M::::::M    x::::::::::x      F:::::F             
M::::::M               M::::::M   x:::::xx:::::x   FF:::::::FF           
M::::::M               M::::::M  x:::::x  x:::::x  F::::::::FF           
M::::::M               M::::::M x:::::x    x:::::x F::::::::FF           
MMMMMMMM               MMMMMMMMxxxxxxx      xxxxxxxFFFFFFFFFFF           

March 2022                                                              
*/

pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

contract MxF is ERC1155, AccessControl, Ownable {
  uint256 public constant MAX = 888;
  uint256 private constant _tokenId = 1;
  uint256 private constant _tokenQty = 1; //max per transaction and giveaway
  uint256 public PRICE = 0.1 ether;
  uint256 public amountMinted;

  string public name;
  string public symbol;

  address add_Dev = 0x44011807660b00649e2ac6dF271D348806ced0aC;
  address add_Artist = 0xe027488fc54732E38596F0E99320547Cc3ad2eB7;
  address add_DG = 0x620b330c2e1d32Ee40D912F82FbA270a857EA0dF;
  address add_JL = 0xb45eB7097Fef91eBF2ee238Fd4E44D8FE7C6C91E;

  mapping(address => uint256) private _walletClaimed;

  event priceChanged(uint256 newPrice);
  event saleStatus(bool isSaleLive);

  bool public saleLive = false;

  constructor() ERC1155("ipfs://QmXZCTM85xMoX258unvVJ6qQQqgZ1MUyNJ8GUqoBbSCT8Z") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, add_Dev);
    _setupRole(DEFAULT_ADMIN_ROLE, add_Artist);
    _setupRole(DEFAULT_ADMIN_ROLE, add_DG);
    _setupRole(DEFAULT_ADMIN_ROLE, add_JL);

    name = "MxF Pass";
    symbol = "MxF";
  }

  //**** Purchase functions ****//

  /**
   * @dev minting function
   */
  function mint() external payable {
    uint256 newMinted = _walletClaimed[msg.sender] + _tokenQty;
    require(saleLive, "SALE_NOT_STARTED");
    require(amountMinted + _tokenQty <= MAX, "OUT_OF_STOCK");
    require(newMinted <= 1, "EXCEED_MAX_PER_WALLET");
    require(PRICE * _tokenQty <= msg.value, "INSUFFICIENT_ETH");

    _walletClaimed[msg.sender] = newMinted;
    amountMinted += _tokenQty;
    _mint(msg.sender, _tokenId, _tokenQty, "");

    delete newMinted;
  }

  //**** Admin functions ****//

  /**
   * @dev Change the URI
   */
  function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setURI(newuri);
  }

  /**
   * @dev Withdraw ether
   */
  function withdrawAll() external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 devAmt = (address(this).balance * 5) / 100; // 5%
    uint256 artAmt = (address(this).balance * 625) / 1000; //62.5%
    payable(add_Dev).transfer(devAmt);
    payable(add_Artist).transfer(artAmt);
    payable(add_DG).transfer(address(this).balance);
  }

  /**
   * @dev giveaway function
   */
  function giveaway(address[] calldata giftreceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < giftreceiver.length; i++) {
      require(amountMinted + _tokenQty <= MAX, "OUT_OF_STOCK");
      amountMinted += _tokenQty;
      _mint(giftreceiver[i], _tokenId, _tokenQty, "");
    }
  }

  /**
   * @dev toggle Sale status
   */
  function toggleSale() external onlyRole(DEFAULT_ADMIN_ROLE) {
    saleLive = !saleLive;
    emit saleStatus(saleLive);
  }

  /**
   * @dev set the Price for sale
   */
  function setPrice(uint256 _newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
    PRICE = _newPrice;
    emit priceChanged(PRICE);
  }

  //**** Other functions ****//

  /**
   * @dev Total claimed passes
   */
  function totalSupply() public view returns (uint256) {
    return amountMinted;
  }

  /**
   * @dev The following functions are overrides required by Solidity.
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
