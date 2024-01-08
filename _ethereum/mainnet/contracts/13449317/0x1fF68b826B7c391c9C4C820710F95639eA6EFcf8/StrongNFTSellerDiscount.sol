//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./IERC1155Preset.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract StrongNFTSellerDiscount is Context, Ownable {

  using SafeMath for uint256;

  IERC1155Preset public nftToken;
  IERC20 public strongToken;

  bool public initDone;
  address payable public feeCollector;
  mapping(string => uint256) public nftLowerBound;
  mapping(string => uint256) public nftUpperBound;
  mapping(string => uint256) public nftStrongValue;
  mapping(string => uint256) public nftIdCounter;
  mapping(address => string) public userCanBuyNftName;

  event Claimed(address user, string nftName, uint256 nftId);

  function init(address _nftTokenContract, address _strongTokenContract, address payable _feeCollectorAddress) public {
    require(initDone == false, "init done");

    nftToken = IERC1155Preset(_nftTokenContract);
    strongToken = IERC20(_strongTokenContract);
    feeCollector = _feeCollectorAddress;
    initDone = true;
  }

  function getCurrentNftId(string memory _nftName) public view returns (uint256) {
    return nftIdCounter[_nftName] > 0 ? nftIdCounter[_nftName] : nftLowerBound[_nftName];
  }

  function claimNft(string memory _nftName) public payable {
    uint256 mintNftId = getCurrentNftId(_nftName);

    require(nftStrongValue[_nftName] > 0, "invalid name");
    require(keccak256(abi.encode(userCanBuyNftName[_msgSender()])) == keccak256(abi.encode(_nftName)), "not whitelisted");
    require(mintNftId >= nftLowerBound[_nftName], "invalid id");
    require(mintNftId <= nftUpperBound[_nftName], "sold out");
    require(strongToken.balanceOf(_msgSender()) >= nftStrongValue[_nftName], "insufficient balance");

    nftToken.mint(_msgSender(), mintNftId, 1, "");
    nftIdCounter[_nftName] = mintNftId + 1;
    userCanBuyNftName[_msgSender()] = "";

    feeCollector.transfer(msg.value);
    strongToken.transferFrom(_msgSender(), feeCollector, nftStrongValue[_nftName]);

    emit Claimed(_msgSender(), _nftName, mintNftId);
  }

  // Admin

  function updateNFT(string memory _nftName, uint256 _lowerBound, uint256 _upperBound, uint256 _strongValue) public onlyOwner {
    nftLowerBound[_nftName] = _lowerBound;
    nftUpperBound[_nftName] = _upperBound;
    nftStrongValue[_nftName] = _strongValue;
  }

  function updateCounterValue(string memory _nftName, uint256 _counterValue) public onlyOwner {
    nftIdCounter[_nftName] = _counterValue;
  }

  function updateFeeCollector(address payable _newFeeCollector) public onlyOwner {
    require(_newFeeCollector != address(0));
    feeCollector = _newFeeCollector;
  }

  function updatePrice(string memory _nftName, uint256 _strongValue) public onlyOwner {
    nftStrongValue[_nftName] = _strongValue;
  }

  function whiteList(address _user, string memory _nftName) public onlyOwner {
    userCanBuyNftName[_user] = _nftName;
  }
}
