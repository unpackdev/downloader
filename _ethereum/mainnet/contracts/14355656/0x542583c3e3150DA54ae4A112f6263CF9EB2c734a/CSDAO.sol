// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CSDAO is ERC1155Supply, Ownable {
  using SafeMath for uint256;

  mapping(uint256 => string) private _tokenURIs;
  mapping(address => bool) private whitelistMap;

  uint256 public stage = 0; // STAGE 0 is for wave 2 presale, STAGE 1 is for wave 2 public sale, STAGE 2 is for wave 3 salve and STAGE 3 is for team tokens

  uint256 public presaleWave2Amount = 1375;
  uint256 public wave2Amount = 2750;
  uint256 public wave3Amount = 3550;

  uint256 public presaleWave2EthPrice = 0.095 ether;
  uint256 public presaleWave2WrldPrice = 999 ether;
  uint256 public wave2EthPrice = 0.12 ether;
  uint256 public wave2WrldPrice = 1111 ether;
  uint256 public wave3EthPrice = 0.15 ether;
  uint256 public wave3WrldPrice = 1777 ether;
  
  uint256 public maxOnceLimit = 10;

  bool public saleIsActive = true;

  address private immutable ceoAddress = 0x9B61a1aAA934808aDb8753f4BdE57d324BA064A5;
  address private immutable wrldAddress = 0xD5d86FC8d5C0Ea1aC1Ac5Dfab6E529c9967a45E9;

  constructor () ERC1155 ("") {
  }

  function withdraw() public onlyOwner {
    uint256 ethBalance = address(this).balance;
    payable(ceoAddress).transfer(ethBalance);
    uint256 wrldBalance = IERC20(wrldAddress).balanceOf(address(this));
    IERC20(wrldAddress).transfer(ceoAddress, wrldBalance);
  }

  function mintPresaleWithEth(uint256 _amount) external payable {
    require(saleIsActive, "Sale has been paused.");
    require(stage == 0, "Presale is not active.");
    require(whitelistMap[msg.sender], "Not whitelisted");
    require(_amount <= maxOnceLimit, "Max once purchase limit");
    require(totalSupply(0).add(_amount) <= presaleWave2Amount, "Maximun holders limit");
    require(msg.value == presaleWave2EthPrice.mul(_amount), "Total price not match");

    _mint(msg.sender, 0, _amount, "");

    if(totalSupply(0) == presaleWave2Amount) {
      stage = 1;
    }
  }

  function mintPresaleWithWrld(uint256 _amount) external {
    require(saleIsActive, "Sale has been paused.");
    require(stage == 0, "Presale is not active.");
    require(whitelistMap[msg.sender], "Not whitelisted");
    require(_amount <= maxOnceLimit, "Max once purchase limit");
    require(totalSupply(0).add(_amount) <= presaleWave2Amount, "Maximun holders limit");
    require(IERC20(wrldAddress).balanceOf(msg.sender) >= presaleWave2WrldPrice.mul(_amount), "Not enough $WRLD.");
    require(IERC20(wrldAddress).allowance(msg.sender, address(this)) >= presaleWave2WrldPrice.mul(_amount), "Not enough $WRLD has been approved to this contract.");

    _mint(msg.sender, 0, _amount, "");
    IERC20(wrldAddress).transferFrom(msg.sender, address(this), presaleWave2WrldPrice.mul(_amount));

    if(totalSupply(0) == presaleWave2Amount) {
      stage = 1;
    }
  }

  function mintWave2WithEth(uint256 _amount) external payable {
    require(saleIsActive, "Sale has been paused.");
    require(stage == 1, "Wave 2 is not active.");
    require(_amount <= maxOnceLimit, "Max once purchase limit");
    require(totalSupply(0).add(_amount) <= wave2Amount, "Maximun holders limit");
    require(msg.value == wave2EthPrice.mul(_amount), "Total price not match");

    _mint(msg.sender, 0, _amount, "");

    if(totalSupply(0) == wave2Amount) {
      stage = 2;
    }
  }

  function mintWave2WithWrld(uint256 _amount) external {
    require(saleIsActive, "Sale has been paused.");
    require(stage == 1, "Wave 2 is not active.");
    require(_amount <= maxOnceLimit, "Max once purchase limit");
    require(totalSupply(0).add(_amount) <= wave2Amount, "Maximun holders limit");
    require(IERC20(wrldAddress).balanceOf(msg.sender) >= wave2WrldPrice.mul(_amount), "Not enough $WRLD.");
    require(IERC20(wrldAddress).allowance(msg.sender, address(this)) >= wave2WrldPrice.mul(_amount), "Not enough $WRLD has been approved to this contract.");

    _mint(msg.sender, 0, _amount, "");
    IERC20(wrldAddress).transferFrom(msg.sender, address(this), wave2WrldPrice.mul(_amount));

    if(totalSupply(0) == wave2Amount) {
      stage = 2;
    }
  }

  function mintWave3WithEth(uint256 _amount) external payable {
    require(saleIsActive, "Sale has been paused.");
    require(stage == 2, "Wave 3 is not active.");
    require(_amount <= maxOnceLimit, "Max once purchase limit");
    require(totalSupply(1).add(_amount) <= wave3Amount, "Maximun holders limit");
    require(msg.value == wave3EthPrice.mul(_amount), "Total price not match");

    _mint(msg.sender, 1, _amount, "");

    if(totalSupply(1) == wave3Amount) {
      stage = 3;
    }
  }

  function mintWave3WithWrld(uint256 _amount) external {
    require(saleIsActive, "Sale has been paused.");
    require(stage == 2, "Wave 3 is not active.");
    require(_amount <= maxOnceLimit, "Max once purchase limit");
    require(totalSupply(1).add(_amount) <= wave3Amount, "Maximun holders limit");
    require(IERC20(wrldAddress).balanceOf(msg.sender) >= wave3WrldPrice.mul(_amount), "Not enough $WRLD.");
    require(IERC20(wrldAddress).allowance(msg.sender, address(this)) >= wave3WrldPrice.mul(_amount), "Not enough $WRLD has been approved to this contract.");

    _mint(msg.sender, 1, _amount, "");
    IERC20(wrldAddress).transferFrom(msg.sender, address(this), wave3WrldPrice.mul(_amount));

    if(totalSupply(1) == wave3Amount) {
      stage = 3;
    }
  }

  function reserveWaves(address _to, uint256 _reserveAmount) external onlyOwner {
    require(stage == 3, "Passes has not been sold out yet.");
    require(totalSupply(1).add(_reserveAmount) <= 3750, "Exceed max supply");

    _mint(_to, 1, _reserveAmount, "");
  }

  function flipSaleState() external onlyOwner {
      saleIsActive = !saleIsActive;
  }

  function startWave2PublicSale() external onlyOwner {
    require(stage == 0);
    stage = 1;
  }

  function setStage(uint256 _stage) external onlyOwner {
    stage = _stage;
  }

  function updateWave3WrldPrice(uint256 _wrldPrice) external onlyOwner {
    wave3WrldPrice = _wrldPrice;
  }

  function setWhiteList(address _address) public onlyOwner {
    whitelistMap[_address] = true;
  }

  function setWhiteListMultiple(address[] memory _addresses) external onlyOwner
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      setWhiteList(_addresses[i]);
    }
  }

  function removeWhiteList(address _address) external onlyOwner {
    whitelistMap[_address] = false;
  }

  function isWhiteListed(address _address) external view returns (bool) {
    return whitelistMap[_address];
  }
  
  function uri(uint256 id) public view virtual override returns (string memory) {
    require(exists(id), "Nonexistent token");
    return _tokenURIs[id];
  }

  function _setTokenURI(uint256 _tokenId, string memory _tokenUri) external onlyOwner {
    _tokenURIs[_tokenId] = _tokenUri;
  }

  function contractURI() public pure returns (string memory) {
    return "https://cinsitynft.mypinata.cloud/ipfs/QmXhRS6f1Q5jPAnqXhcraFHkVvQQYvdHLUXgU1yVNMq7Ze";
  }
}