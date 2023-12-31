// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ICrewToken.sol";
import "./ICrewFeatures.sol";
import "./ICrewmateToken.sol";
import "./IStarknetCore.sol";
import "./InfluenceRoles.sol";
import "./InfluenceUtils.sol";

contract CrewmateBridge is AccessControlUpgradeable, OwnableUpgradeable {
  ICrewToken public l1CrewTokenContract;
  ICrewmateToken public l1CrewmateTokenContract;
  ICrewFeatures public crewFeaturesContract;
  IStarknetCore public starknetCore;
  uint256 public l2BridgeContract;
  uint256 public l2BridgeSelector;
  uint256 constant BRIDGE_MODE_WITHDRAW = 1;
  mapping (address => bool) private _managers;
  mapping (uint256 => address) private _crossings; // maps nonce to sender address

  function initialize (
      address _starknetCore,
      address _l1CrewTokenContract,
      address _l1CrewmateTokenContract,
      address _crewFeaturesContract,
      uint256 _l2BridgeContract
    ) public initializer {
      require(_starknetCore != address(0), "Bridge/invalid-starknet-core-address");
      require(_l1CrewTokenContract != address(0), "Bridge/invalid-l1-token-address");
      require(_l1CrewmateTokenContract != address(0), "Bridge/invalid-l1-token-v2-address");
      require(_crewFeaturesContract != address(0), "Bridge/invalid-crew-features-address");
      require(_l2BridgeContract != 0, "Bridge/invalid-l2-bridge-address");

      starknetCore = IStarknetCore(_starknetCore);
      l1CrewTokenContract = ICrewToken(_l1CrewTokenContract);
      l1CrewmateTokenContract = ICrewmateToken(_l1CrewmateTokenContract);
      crewFeaturesContract = ICrewFeatures(_crewFeaturesContract);
      l2BridgeContract = _l2BridgeContract;

      // bridge_from_l1
      l2BridgeSelector = 1157548185917827836691019656633924546219803202764187478285065005547416801023;

      __Ownable_init();

      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(InfluenceRoles.MANAGER_ROLE, _msgSender());
  }

  // Utils
  function addressToUint(address value) internal pure returns (uint256 convertedValue) {
    convertedValue = uint256(uint160(address(value)));
  }

  // Events
  event BridgeToStarknet(
    address l1Contract,
    address l1Account,
    uint256 l2Account,
    uint256 tokenId,
    uint features
  );

  event BridgeFromStarknet(
    uint256 l2Account,
    address l1Contract,
    address l1Account,
    uint256 tokenId
  );

  // setters
  function setL1CrewTokenContract(address _l1CrewTokenContract) external onlyRole(InfluenceRoles.MANAGER_ROLE) {
    l1CrewTokenContract = ICrewToken(_l1CrewTokenContract);
  }

  function setL1CrewmateTokenContract(address _l1CrewmateTokenContract) external onlyRole(InfluenceRoles.MANAGER_ROLE) {
    l1CrewmateTokenContract = ICrewmateToken(_l1CrewmateTokenContract);
  }

  function setL2BridgeContract(uint256 _l2BridgeContract) external onlyRole(InfluenceRoles.MANAGER_ROLE) {
    l2BridgeContract = _l2BridgeContract;
  }

  function setL2BridgeSelector(uint256 _l2BridgeSelector) external onlyRole(InfluenceRoles.MANAGER_ROLE) {
    l2BridgeSelector = _l2BridgeSelector;
  }

  // Bridging to Starknet
  function bridgeToStarknet(uint256[] calldata tokenIds, uint256 l2AccountAddress) external payable {
    require(l2AccountAddress != 0, "Bridge/invalid-account-address");
    require(tokenIds.length <= 25, "Bridge/too-many-tokens");

    // build payload
    uint256 valuesPerCrewmate = 2; // token id and features
    uint256 length = tokenIds.length * valuesPerCrewmate;
    uint256[] memory payload = new uint256[](2 + length);
    payload[0] = l2AccountAddress;
    payload[1] = length;

    // check ownership, burn or transfer
    uint256 offset = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      address _contract;
      uint256 features = 0;

      if (l1CrewTokenContract.ownerOf(tokenId) == _msgSender()) {
        l1CrewTokenContract.burn(tokenId);
        _contract = address(l1CrewTokenContract);
        features = crewFeaturesContract.getFeatures(tokenId); // get features only from v1
      } else if (l1CrewmateTokenContract.ownerOf(tokenId) == _msgSender()) {
        l1CrewmateTokenContract.burn(tokenId);
        _contract = address(l1CrewmateTokenContract);
      } else {
        revert('Invalid token');
      }

      offset = (valuesPerCrewmate * i);
      payload[2 + offset] = tokenId;
      payload[3 + offset] = features;

      emit BridgeToStarknet(_contract, _msgSender(), l2AccountAddress, tokenId, features);
    }

    // send message to L2
    (, uint256 nonce) = starknetCore.sendMessageToL2{value: msg.value}(l2BridgeContract, l2BridgeSelector, payload);

    // Store the sender with the nonce in case we need to cancel
    _crossings[nonce] = _msgSender();
  }

  function startBridgeToStarknetCancellation(
    uint256[] calldata tokenIds,
    uint256 l2AccountAddress,
    uint256 nonce
  ) external {
    address origSender = _crossings[nonce];
    require(_msgSender() == origSender, 'Bridge/only-original-sender');

    // build payload
    uint256[] memory payload = new uint256[](2 + tokenIds.length);
    payload[0] = l2AccountAddress;
    payload[1] = tokenIds.length;

    // start cancellation process
    starknetCore.startL1ToL2MessageCancellation(l2BridgeContract, l2BridgeSelector, payload, nonce);
  }

  function finishBridgeToStarknetCancellation(
    uint256[] calldata tokenIds,
    uint256 l2AccountAddress,
    uint256 nonce
  ) external {
    address origSender = _crossings[nonce];
    require(_msgSender() == origSender, 'Bridge/only-original-sender');

    // build payload
    uint256[] memory payload = new uint256[](2 + tokenIds.length);
    payload[0] = l2AccountAddress;
    payload[1] = tokenIds.length;

    // finish cancellation process
    starknetCore.cancelL1ToL2Message(l2BridgeContract, l2BridgeSelector, payload, nonce);

    // Re-mint assets
    for (uint256 i = 0; i < tokenIds.length; i++) {
      l1CrewmateTokenContract.mint(origSender, tokenIds[i]);
    }

    // Clear nonce mapping (a bit of a gas refund to defray costs)
    _crossings[nonce] = address(0);
  }

  // Bridging back from Starknet
  function bridgeFromStarknet(uint256[] calldata tokenIds, uint256 l2AccountAddress) external {
    uint256[] memory payload = new uint256[](4 + tokenIds.length);

    // build withdraw message payload
    payload[0] = BRIDGE_MODE_WITHDRAW;
    payload[1] = l2BridgeContract;
    payload[2] = l2AccountAddress;
    payload[3] = addressToUint(_msgSender());

    for (uint256 i = 0; i < tokenIds.length; i++) {
      address currentOwner = l1CrewTokenContract.ownerOf(tokenIds[i]);
      if (currentOwner != address(0)) {
        revert('Bridge/token-exists-on-v1');
      }

      l1CrewmateTokenContract.mint(_msgSender(), tokenIds[i]);
      payload[4 + i] = tokenIds[i];

      emit BridgeFromStarknet(l2AccountAddress, address(l1CrewmateTokenContract), _msgSender(), tokenIds[i]);
    }

    // consume withdraw message
    starknetCore.consumeMessageFromL2(l2BridgeContract, payload);
  }
}
