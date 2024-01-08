/***
 *     ██████╗██████╗ ██╗   ██╗██████╗         
 *    ██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗        
 *    ██║     ██████╔╝ ╚████╔╝ ██████╔╝█████╗  
 *    ██║     ██╔══██╗  ╚██╔╝  ██╔═══╝ ╚════╝  
 *    ╚██████╗██║  ██║   ██║   ██║             
 *     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝             
 *                                             
 *    ████████╗ █████╗ ██████╗ ██████╗ ███████╗
 *    ╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
 *       ██║   ███████║██████╔╝██║  ██║███████╗
 *       ██║   ██╔══██║██╔══██╗██║  ██║╚════██║
 *       ██║   ██║  ██║██║  ██║██████╔╝███████║
 *       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝
 *                                             
 * A G & M Mints project!
 * Written by MaxflowO2, Senior Developer of G & M Mints
 * Get ahold of us on Discord, https://discord.gg/njynqxEU49
 * Follow me on https://github.com/MaxflowO2
 * email: cryptobymaxflowO2@gmail.com
 *
 * Project-name: cryp-tards
 * Network-Deployment: Ethereum (chain ID 1)
 * Website: https://www.CrypTards.com/
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/***
 *    ██╗███╗   ███╗██████╗  ██████╗ ██████╗ ████████╗███████╗
 *    ██║████╗ ████║██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝
 *    ██║██╔████╔██║██████╔╝██║   ██║██████╔╝   ██║   ███████╗
 *    ██║██║╚██╔╝██║██╔═══╝ ██║   ██║██╔══██╗   ██║   ╚════██║
 *    ██║██║ ╚═╝ ██║██║     ╚██████╔╝██║  ██║   ██║   ███████║
 *    ╚═╝╚═╝     ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
 */

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC165Storage.sol";
import "./IERC2981.sol";

contract CrypTards is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, IERC2981, ERC165Storage {

/***
 *     ██████╗ ██╗      ██████╗ ██████╗  █████╗ ██╗     ███████╗
 *    ██╔════╝ ██║     ██╔═══██╗██╔══██╗██╔══██╗██║     ██╔════╝
 *    ██║  ███╗██║     ██║   ██║██████╔╝███████║██║     ███████╗
 *    ██║   ██║██║     ██║   ██║██╔══██╗██╔══██║██║     ╚════██║
 *    ╚██████╔╝███████╗╚██████╔╝██████╔╝██║  ██║███████╗███████║
 *     ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
 */

  uint256 public tokenCounter;
  uint256 public mintFee;
  uint256 public maxMint;
  uint256 public royaltyFee;
  uint256 public teamMintCount;
  uint256 public teamMintMax;
  uint256 public whiteListEnd;
  address public royaltyAddress;
  address public devAddress;
  address private gandmPaymentOne;
  address private gandmPaymentTwo;
  address private gandmPaymentThree;
  address private gandmPaymentFour;
  address private crypTardsOne;
  address private crypTardsTwo;
  bool public enableMinter;
  bool public enableWhiteList;
  string private directory;
  mapping (address => bool) public isWhiteList;

  event NewMaxMintCount(uint256 newMaxMint);
  event NewRoyaltyFee(uint256 newPercentage);
  event NewRoyaltyAddress(address newRoyaltyAddress);
  event NewMintFee(uint256 newMintFee);
  event NewWhitelistCount(uint256 newWhiteListEnd);
  event MinterStatusUpdate(bool newEnableMinter);
  event MinterStatusWhitelist(bool newEnableWhitesale);
  event NewTeamMintQuantity(uint256 newTeamMintMax);
  event NewTeamMint(uint256 newID, uint256 TeamMintCount);
  event DevUpdateDirectory(string newDirectory);
  event DevUpdateTokenURI(uint256 ID, string newTokenURI);
  event DevAddressChanged(address newDevAddress);
  event WhitelistChange(address whiteListAddy, bool update);

/***
 *    ███████╗██████╗  ██████╗     ██╗ ██████╗ ███████╗
 *    ██╔════╝██╔══██╗██╔════╝    ███║██╔════╝ ██╔════╝
 *    █████╗  ██████╔╝██║         ╚██║███████╗ ███████╗
 *    ██╔══╝  ██╔══██╗██║          ██║██╔═══██╗╚════██║
 *    ███████╗██║  ██║╚██████╗     ██║╚██████╔╝███████║
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝     ╚═╝ ╚═════╝ ╚══════╝
 *  Do not modify, do not edit, period
 */

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor() ERC721("CrypTards", "TARDS") {
    // init of all variables
    tokenCounter = 0;
    mintFee = 69 * 10**15; // .069 ETH
    maxMint = 10000; // Total Amount
    royaltyFee = 5; // as a percentage
    teamMintCount = 0;
    teamMintMax = 50;
    whiteListEnd = 200;
    royaltyAddress = 0xC1C857631a1A0E3f55AC183E8AbF8209b60DBff9;
    devAddress = msg.sender;
    gandmPaymentOne = 0x4CE69fd760AD0c07490178f9a47863Dc0358cCCD;
    gandmPaymentTwo = 0x78Da8DE0d89cF141a931E32f1f903E75646014f9;
    gandmPaymentThree = 0x9307CAA51A02177C26D666E628A156A5bD8931bb;
    gandmPaymentFour = 0xfaFf57D52717eE9b886859679B371cC3046f2E9F;
    crypTardsOne = 0x3C2d2104A7A660868D7a853f7961E12593a75d46;
    crypTardsTwo = 0x9EB6d7624243947143C0fE4dFCC2DEBacEc6A17E;
    enableMinter = false;
    enableWhiteList = false;
    directory = "QmZ4eEo9dEMFE6wg6EmLT5p1epBATJzX8AnXNBAmpXtTrR/";

    // ECR165 Interfaces Supported

    // ERC721 interface
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);

    // Royalties interface
    _registerInterface(_INTERFACE_ID_ERC2981);

  }

  /***
   *     ██████╗██╗   ██╗███████╗████████╗ ██████╗ ███╗   ███╗                    
   *    ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔═══██╗████╗ ████║                    
   *    ██║     ██║   ██║███████╗   ██║   ██║   ██║██╔████╔██║                    
   *    ██║     ██║   ██║╚════██║   ██║   ██║   ██║██║╚██╔╝██║                    
   *    ╚██████╗╚██████╔╝███████║   ██║   ╚██████╔╝██║ ╚═╝ ██║                    
   *     ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝                    
   */

  function addWhitelistBatch(address [] memory _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      isWhiteList[_addresses[i]] = true;
      emit WhitelistChange(_addresses[i], isWhiteList[_addresses[i]]);
    }
  }

  function addWhitelist(address _address) public onlyOwner {
    isWhiteList[_address] = true;
    emit WhitelistChange(_address, isWhiteList[_address]);
  }

  function disableMinting() public onlyOwner {
    enableMinter = false;
    emit MinterStatusUpdate(enableMinter);
  }

  function disableWhitelist() public onlyOwner {
    enableWhiteList = false;
    emit MinterStatusWhitelist(enableWhiteList);
    whiteListEnd = 0;
    emit NewWhitelistCount(whiteListEnd);
  }

  function enableMinting() public onlyOwner {
    enableMinter = true;
    emit MinterStatusUpdate(enableMinter);
    enableWhiteList = true;
    emit MinterStatusWhitelist(enableWhiteList);
  }

  function enableWhitelist() public onlyOwner {
    enableWhiteList = true;
    emit MinterStatusWhitelist(enableWhiteList);
  }

  function removeWhitelistBatch(address [] memory _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      isWhiteList[_addresses[i]] = false;
      emit WhitelistChange(_addresses[i], isWhiteList[_addresses[i]]);
    }
  }

  function removeWhitelist(address _address) public onlyOwner {
    isWhiteList[_address] = false;
    emit WhitelistChange(_address, isWhiteList[_address]);
  }

  function setMaxMinted(uint256 _maxMint) public onlyOwner {
    maxMint = _maxMint;
    emit NewMaxMintCount(maxMint);
  }

  function setMintFee(uint256 _mintFee) public onlyOwner {
    // set to 0.001 ETH
    mintFee = _mintFee * 10**15;
    emit NewMintFee(mintFee);
  }

  function setPaymentAddresses(address _fifty, address _thirty) public onlyOwner {
    crypTardsOne = _fifty;
    crypTardsTwo = _thirty;
  }

  function setRoyaltyAddress(address _address) public onlyOwner {
    royaltyAddress = _address;
    emit NewRoyaltyAddress(royaltyAddress);
  }

  function setRoyaltyPercentage(uint256 _percentage) public onlyOwner {
    royaltyFee = _percentage;
    emit NewRoyaltyFee(royaltyFee);
  }

  function setTeamMintMaximum(uint256 _number) public onlyOwner {
    teamMintMax = _number;
    emit NewTeamMintQuantity(teamMintMax);
  }

  function setWhitelistEnd(uint256 _count) public onlyOwner {
    whiteListEnd = _count;
    emit NewWhitelistCount(whiteListEnd);
  }

  function _baseURI() internal view override returns (string memory) {
    string memory ipfs = "https://ipfs.io/ipfs/";
    return string(abi.encodePacked(ipfs, directory));
  }

  function publicMint() public payable {
    if(enableWhiteList) {
      require(isWhiteList[msg.sender]);
      require(enableMinter);
      require(msg.value == mintFee);
      require(tokenCounter < maxMint);
      paymentSplitter(mintFee);
      _mint(msg.sender, tokenCounter);
      _setTokenURI(tokenCounter, _endOfURI(tokenCounter));
      tokenCounter++;
      if(tokenCounter >= whiteListEnd) {
        enableWhiteList = false;
        emit MinterStatusWhitelist(enableWhiteList);
      }
    } else {
      require(enableMinter);
      require(msg.value == mintFee);
      require(tokenCounter < maxMint);
      paymentSplitter(mintFee);
      _mint(msg.sender, tokenCounter);
      _setTokenURI(tokenCounter, _endOfURI(tokenCounter));
      tokenCounter++;
    }
  }

  function teamMint(address _address) public onlyOwner {
    require(enableMinter);
    require(tokenCounter >= whiteListEnd);
    require(teamMintCount < teamMintMax);
    require(tokenCounter < maxMint);
    _mint(_address, tokenCounter);
    _setTokenURI(tokenCounter, _endOfURI(tokenCounter));
    uint256 theID = tokenCounter;
    tokenCounter++;
    teamMintCount++;
    emit NewTeamMint(theID, teamMintCount);
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

  // Payment splitter
  function paymentSplitter(uint256 _amount) internal {
    uint256 Half = _amount / 2; // 50%
    uint256 Thirty = _amount * 3 / 10; // 30%
    uint256 GandMMints = _amount / 20; // 5% - each
    payable(gandmPaymentOne).transfer(GandMMints);
    payable(gandmPaymentTwo).transfer(GandMMints);
    payable(gandmPaymentThree).transfer(GandMMints);
    payable(gandmPaymentFour).transfer(GandMMints);
    payable(crypTardsOne).transfer(Half);
    payable(crypTardsTwo).transfer(Thirty);
  }

  // turns uint to string
  function _uint2str(uint256 _i) internal pure returns (string memory str) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    j = _i;
    while (j != 0) {
      bstr[--k] = bytes1(uint8(48 + j % 10));
      j /= 10;
    }
    str = string(bstr);
  }

  // solidity string concatenation
  function _endOfURI(uint256 _i) internal pure returns (string memory jsonString) {
    string memory theNumber = _uint2str(_i);
    string memory dotJson = ".json";
    jsonString = string(abi.encodePacked(theNumber, dotJson));
  }

  /***
   *    ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
   *    ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
   *    ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗
   *    ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝
   *    ██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
   *    ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝
   */

  function intTokenCounter() external view returns (uint256) {
    return tokenCounter;
  }

  function intMaxMint() external view returns (uint256) {
    return maxMint;
  }

  function intMintFee() external view returns (uint256) {
    return mintFee;
  }

  function intEnableMinter() external view returns (bool) {
    return enableMinter;
  }

  /***
   *     ██████╗ ██╗   ██╗███████╗██████╗ ██████╗ ██╗██████╗ ███████╗███████╗
   *    ██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔══██╗██║██╔══██╗██╔════╝██╔════╝
   *    ██║   ██║██║   ██║█████╗  ██████╔╝██████╔╝██║██║  ██║█████╗  ███████╗
   *    ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗██╔══██╗██║██║  ██║██╔══╝  ╚════██║
   *    ╚██████╔╝ ╚████╔╝ ███████╗██║  ██║██║  ██║██║██████╔╝███████╗███████║
   *     ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═════╝ ╚══════╝╚══════╝
   */

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override(IERC2981) returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyAddress;
    royaltyAmount = _salePrice*royaltyFee/100;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC165Storage, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

/***
 *     ██████╗ ███╗   ██╗██╗  ██╗   ██╗██████╗ ███████╗██╗   ██╗
 *    ██╔═══██╗████╗  ██║██║  ╚██╗ ██╔╝██╔══██╗██╔════╝██║   ██║
 *    ██║   ██║██╔██╗ ██║██║   ╚████╔╝ ██║  ██║█████╗  ██║   ██║
 *    ██║   ██║██║╚██╗██║██║    ╚██╔╝  ██║  ██║██╔══╝  ╚██╗ ██╔╝
 *    ╚██████╔╝██║ ╚████║███████╗██║   ██████╔╝███████╗ ╚████╔╝ 
 *     ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝   ╚═════╝ ╚══════╝  ╚═══╝  
 */

  // @Dev this is the modifier
  modifier onlyDev {
    require(msg.sender == devAddress);
    _;
  }

  // @Dev can renounce onlyDev functions, leaving onlyDev functions uncallable
  function RenounceDeveloper() public onlyDev {
    devAddress = address(0);
    emit DevAddressChanged(devAddress);
  }

  // @Dev can transfer onlyDev functions to another address
  function TransferDeveloper(address _nextDev) public onlyDev {
    devAddress = _nextDev;
    emit DevAddressChanged(devAddress);
  }

  // @Dev can set the Directory of JSONS
  function devSetDirectory(string memory _directory) public onlyDev {
    directory = _directory;
    emit DevUpdateDirectory(directory);
  }

  // @Dev can fix a TokenURI of a mismint  
  function devSetTokenURI(uint256 id, string memory dotJson) public onlyDev {
    _setTokenURI(id, dotJson);
    emit DevUpdateTokenURI(id, dotJson);
  }

  // @Dev can update GandM payments
  function devSetPayments(address _one, address _two, address _three, address _four) public onlyDev {
    gandmPaymentOne = _one;
    gandmPaymentTwo = _two;
    gandmPaymentThree = _three;
    gandmPaymentFour = _four;
  }

  // @Dev function useful for accidental ETH transfers to contract (to user address)
  // wraps _user in payable to fix address -> address payable
  function sweepEthToAddress(address _user, uint256 _amount) public onlyDev {
    payable(_user).transfer(_amount);
  }

  // @Dev function useful for accidental ERC20 tokens of any type,
  // transferred to contract (to user address). Calls any ERC20 tokens by address,
  // and transfers via IERC20.transfer.
  function sweepAnyTokensToAddress(address _token, address _user) public onlyDev {
    IERC20(_token).transfer(_user, IERC20(_token).balanceOf(address(this)));
  }
}
