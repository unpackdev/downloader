// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";


contract Cemetery is OwnableUpgradeable, IERC721ReceiverUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; 

                                                        
  event ZombieAdded(address owner, uint256 tokenId, uint256 value);


  mapping (address => bool) private whitelistedContracts;      
  mapping(uint256 => Grave) private graveyard;      
  mapping(address => EnumerableSetUpgradeable.UintSet) private _deposits;

  CountersUpgradeable.Counter private numberofGraves;
  EnumerableSetUpgradeable.UintSet private graveTokens;

  struct BigDragon {bool isKnight; uint8 alphaIndex; bool isDonkey; }
  struct Grave {uint256 tokenId; uint256 value; address owner;}

  address public den;

  function initialize(address _den) initializer public {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    den = _den;

  }

  function depositsOf(address account) external view blockExternalContracts  returns (uint256[] memory) {

    EnumerableSetUpgradeable.UintSet storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[] (depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
      tokenIds[i] = depositSet.at(i);
    }

    return tokenIds;
  }

  function addZombie(address account, uint256 tokenId) external blockExternalContracts {    // called in mint
    require(_msgSender() == address(den), "Zombies only rise from the dead");

    graveyard[tokenId] = Grave({
      owner: account,
      tokenId: uint256(tokenId),
      value: uint80(block.timestamp)
    });


    numberofGraves.increment();
    _deposits[account].add(tokenId);
    graveTokens.add(tokenId);
    
    emit ZombieAdded(account, tokenId, block.timestamp);

  }

  function setWhitelistContract(address contract_address, bool status) public onlyOwner{
    whitelistedContracts[contract_address] = status;
  }

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }
 
  function onERC721Received(address, address from, uint256, bytes calldata) external view override blockExternalContracts returns (bytes4) {

    require(from == address(0x0), "Cannot send tokens to Grave directly");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;

  }

  modifier blockExternalContracts() {
    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
      _;
      
    } else {

      _;

    }
    
  }

  function setDen(address _den) external onlyOwner {
    den = _den;
  }

}