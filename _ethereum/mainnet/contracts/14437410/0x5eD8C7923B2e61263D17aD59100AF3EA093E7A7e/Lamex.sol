// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IYieldSwitch {
  function activateLamex(address _user) external;
  function hasUserPortaled(address _user) external view returns (bool);
}
interface IStaking {
  function getStakerTokens(address staker) external view returns (uint256[] memory, uint256[] memory, uint256[] memory);
}
interface ILoomi {
  function getUserBalance(address user) external view returns (uint256);
  function spendLoomi(address user, uint256 amount) external;
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Lamex is ERC721EnumerableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable  {
  using Strings for uint256;

  uint256 public loomiToLamexRate;
  uint256 public minDepositAmount;

  IStaking public staking;
  IYieldSwitch public yieldSwitch;
  ILoomi public loomi;

  bool public isPaused;
  bool public transfersPaused;

  string public baseURI;
  mapping(address => uint256) private _nonces;

  event LamexMinted(address indexed mintedBy, uint256 indexed tokenId);
  event LamexTopUp(address indexed userLamex, uint256 nonce, uint256 amount);

  modifier whenNotPaused {
    if (_msgSender() != owner()) {
      require(!isPaused, "Contract paused!");
    }
    _;
  }

  function initialize(address _loomi, address _staking, string memory _baseURI) external initializer {
    loomi = ILoomi(_loomi);
    staking = IStaking(_staking);
    baseURI = _baseURI;

    loomiToLamexRate = 5000;
    minDepositAmount = 5000 ether;

    isPaused = true;
    transfersPaused = true;

    __ERC721_init("LAMEX", "LAMEX");
    __Ownable_init();
    __ReentrancyGuard_init();
  }

  function claimLamex(bool _loomiTransfer) public whenNotPaused {
    require(balanceOf(_msgSender()) == 0, "You cannot mint more than 1 Lamex");
    
    yieldSwitch.activateLamex(_msgSender());

    if (_loomiTransfer) {
      uint256 balance = loomi.getUserBalance(_msgSender());
      _topUpLamex(_msgSender(), balance);
    }

    uint256 tokenId = totalSupply();
    _mint(_msgSender(), tokenId);

    emit LamexMinted(_msgSender(), tokenId);
  }

  function topUpLamex(uint256 _amount) public whenNotPaused {
    _topUpLamex(_msgSender(), _amount);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    address owner = ownerOf(tokenId);
    (uint256[] memory stakedCreeps,,) = IStaking(staking).getStakerTokens(owner);
    bool hasUserSwitched = IYieldSwitch(yieldSwitch).hasUserPortaled(owner);
    return _baseUriByCreepzStaked(stakedCreeps.length, hasUserSwitched);
  }

  function _topUpLamex(address _user, uint256 _amount) internal {
    require(_amount > minDepositAmount, "Amount less than min deposit");

    loomi.spendLoomi(_user, _amount);
    uint256 lamexFromLoomi = _amount / loomiToLamexRate;
    
    _nonces[_user]++;

    emit LamexTopUp(_user, _nonces[_user], lamexFromLoomi);
  }

  function _baseUriByCreepzStaked(uint256 stakedCreepz, bool hasUserSwitched) internal view returns (string memory) {
    uint256 currentTier;
    if (!hasUserSwitched) return string(abi.encodePacked(baseURI, currentTier.toString(), ".json"));

    if (stakedCreepz > 0 && stakedCreepz <= 5) currentTier = 1;
    if (stakedCreepz > 5 && stakedCreepz <= 10) currentTier = 2;
    if (stakedCreepz > 10 && stakedCreepz <= 16) currentTier = 3;
    if (stakedCreepz > 16 && stakedCreepz <= 24) currentTier = 4;
    if (stakedCreepz > 24) currentTier = 5;

    return string(abi.encodePacked(baseURI, currentTier.toString(), ".json"));
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    baseURI = newBaseURI;
  }

  function updateMinDepositAmount(uint256 _minAmount) public onlyOwner {
    minDepositAmount = _minAmount;
  }

  function pause(bool _pause) public onlyOwner {
    isPaused = _pause;
  }

  function pauseTransfers(bool _pause) public onlyOwner {
    transfersPaused = _pause;
  }

  function updateLamexPrice(uint256 _newRate) public onlyOwner {
    loomiToLamexRate = _newRate;
  }

  function updateYieldSwitchAddress(address _yieldSwitch) public onlyOwner {
    yieldSwitch = IYieldSwitch(_yieldSwitch);
  }
  
  function _beforeTokenTransfer(
      address from,
      address,
      uint256
  ) internal override virtual {
    if (from != address(0)) {
      require(!transfersPaused, "Non-transferable NFT");
    }
  }

  function _msgSender() internal view override(Context, ContextUpgradeable) virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view override(Context, ContextUpgradeable) virtual returns (bytes calldata) {
        return msg.data;
    }
}
