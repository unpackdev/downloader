//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC1155Preset.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";

contract StrongNFTSeller is Context {

  using SafeMath for uint256;

  IERC1155Preset public nftToken;
  IERC20 public strongToken;

  bool public initDone;
  address public serviceAdmin;
  address public superAdmin;
  address payable public feeCollector;

  string[] public nftNames;
  mapping(string => uint256) public nftLowerBound;
  mapping(string => uint256) public nftUpperBound;
  mapping(string => uint256) public nftEthValue;
  mapping(string => uint256) public nftStrongValue;
  mapping(string => uint256) public nftIdCounter;

  event Sold(address to, string name, uint256 nftId);

  function init(address _nftTokenContract, address _strongTokenContract, address _serviceAdminAddress, address _superAdminAddress, address payable _feeCollectorAddress) public {
    require(initDone == false, "init done");

    nftToken = IERC1155Preset(_nftTokenContract);
    strongToken = IERC20(_strongTokenContract);
    serviceAdmin = _serviceAdminAddress;
    superAdmin = _superAdminAddress;
    feeCollector = _feeCollectorAddress;
    initDone = true;
  }

  function getCurrentNftId(string memory _name) public view returns (uint256) {
    return nftIdCounter[_name] > 0 ? nftIdCounter[_name] : nftLowerBound[_name];
  }

  function getNftNames() public view returns (string[] memory) {
    return nftNames;
  }

  function buyNft(string memory _name) public payable {
    uint256 mintNftId = getCurrentNftId(_name);

    require(nftEthValue[_name] > 0, "invalid name");
    require(mintNftId >= nftLowerBound[_name], "invalid id");
    require(mintNftId <= nftUpperBound[_name], "sold out");
    require(msg.value >= nftEthValue[_name], "invalid fee");
    require(strongToken.balanceOf(_msgSender()) >= nftStrongValue[_name], "insufficient balance");

    nftToken.mint(_msgSender(), mintNftId, 1, "");
    nftIdCounter[_name] = mintNftId + 1;

    feeCollector.transfer(msg.value);
    strongToken.transferFrom(_msgSender(), feeCollector, nftStrongValue[_name]);

    emit Sold(_msgSender(), _name, mintNftId);
  }

  // Admin

  function updateNFT(string memory _name, uint256 _lowerBound, uint256 _upperBound, uint256 _ethValue, uint256 _strongValue) public {
    require(_msgSender() == serviceAdmin || _msgSender() == superAdmin, "not admin");

    bool alreadyExists = false;
    for (uint8 i = 0; i < nftNames.length; i++) {
      if (keccak256(abi.encode(nftNames[i])) == keccak256(abi.encode(_name))) {
        alreadyExists = true;
      }
    }

    if (!alreadyExists) {
      nftNames.push(_name);
    }

    nftLowerBound[_name] = _lowerBound;
    nftUpperBound[_name] = _upperBound;
    nftEthValue[_name] = _ethValue;
    nftStrongValue[_name] = _strongValue;
  }

  function updatePrice(string memory _name, uint256 _ethValue, uint256 _strongValue) public {
    require(_msgSender() == serviceAdmin || _msgSender() == superAdmin, "not admin");

    nftEthValue[_name] = _ethValue;
    nftStrongValue[_name] = _strongValue;
  }

  function updateServiceAdmin(address _newServiceAdmin) public {
    require(_msgSender() == superAdmin, "not admin");
    serviceAdmin = _newServiceAdmin;
  }

  function updateFeeCollector(address payable _newFeeCollector) public {
    require(_newFeeCollector != address(0));
    require(_msgSender() == superAdmin);
    feeCollector = _newFeeCollector;
  }

  function updateCounterValue(string memory _name, uint256 _counterValue) public {
    require(_msgSender() == serviceAdmin || _msgSender() == superAdmin, "not admin");

    nftIdCounter[_name] = _counterValue;
  }
}
