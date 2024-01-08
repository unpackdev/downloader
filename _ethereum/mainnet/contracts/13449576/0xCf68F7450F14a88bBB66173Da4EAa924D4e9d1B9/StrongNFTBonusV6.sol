//SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ServiceInterface.sol";
import "./IERC1155Preset.sol";
import "./StrongNFTBonusLegacyInterface.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./ERC1155Receiver.sol";

contract StrongNFTBonusV6 is Context {

  using SafeMath for uint256;

  event Staked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);
  event Unstaked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);

  ServiceInterface public CService;
  IERC1155Preset public CERC1155;
  StrongNFTBonusLegacyInterface public CStrongNFTBonus;

  bool public initDone;

  address public serviceAdmin;
  address public superAdmin;

  string[] public nftBonusNames;
  mapping(string => uint256) public nftBonusLowerBound;
  mapping(string => uint256) public nftBonusUpperBound;
  mapping(string => uint256) public nftBonusValue;
  mapping(string => uint256) public nftBonusEffectiveBlock;

  mapping(uint256 => address) public nftIdStakedToEntity;
  mapping(uint256 => uint128) public nftIdStakedToNodeId;
  mapping(uint256 => uint256) public nftIdStakedAtBlock;
  mapping(address => mapping(uint128 => uint256)) public entityNodeStakedNftId;

  mapping(bytes4 => bool) private _supportedInterfaces;

  mapping(string => uint8) public nftBonusNodesLimit;
  mapping(uint256 => uint8) public nftIdStakedToNodesCount;
  mapping(uint128 => uint256) public nodeIdStakedAtBlock;
  mapping(address => uint256[]) public entityStakedNftIds;

  mapping(address => mapping(uint128 => uint256)) public entityNodeStakedAtBlock;

  mapping(address => bool) private serviceContracts;
  mapping(address => mapping(address => mapping(uint128 => uint256))) public entityServiceNodeStakedNftId;
  mapping(address => mapping(address => mapping(uint128 => uint256))) public entityServiceNodeStakedAtBlock;

  event StakedToNode(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block, address serviceContract);
  event UnstakedFromNode(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block, address serviceContract);

  function init(address serviceContract, address nftContract, address strongNFTBonusContract, address serviceAdminAddress, address superAdminAddress) public {
    require(initDone == false, "init done");

    _registerInterface(0x01ffc9a7);
    _registerInterface(
      ERC1155Receiver(0).onERC1155Received.selector ^
      ERC1155Receiver(0).onERC1155BatchReceived.selector
    );

    serviceAdmin = serviceAdminAddress;
    superAdmin = superAdminAddress;
    CService = ServiceInterface(serviceContract);
    CERC1155 = IERC1155Preset(nftContract);
    CStrongNFTBonus = StrongNFTBonusLegacyInterface(strongNFTBonusContract);
    initDone = true;
  }

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function isNftStaked(uint256 _nftId) public view returns (bool) {
    return nftIdStakedToNodeId[_nftId] != 0 || nftIdStakedToNodesCount[_nftId] > 0;
  }

  function isNftStakedLegacy(uint256 _nftId) public view returns (bool) {
    return CStrongNFTBonus.isNftStaked(_nftId);
  }

  function getStakedNftId(address _entity, uint128 _nodeId, address _serviceContract) public view returns (uint256) {
    uint256 stakedNftId = entityNodeStakedNftId[_entity][_nodeId];
    uint256 stakedNftIdNew = entityServiceNodeStakedNftId[_entity][_serviceContract][_nodeId];
    uint256 stakedNftIdLegacy = CStrongNFTBonus.getStakedNftId(_entity, _nodeId);
    return stakedNftIdNew != 0 ? stakedNftIdNew : (stakedNftId != 0 ? stakedNftId : stakedNftIdLegacy);
  }

  function getStakedNftIds(address _entity) public view returns (uint256[] memory) {
    return entityStakedNftIds[_entity];
  }

  function getNftBonusNames() public view returns (string[] memory) {
    return nftBonusNames;
  }

  function getNftNodesLeft(uint256 _nftId) public view returns (uint256) {
    return nftBonusNodesLimit[getNftBonusName(_nftId)] - nftIdStakedToNodesCount[_nftId];
  }

  function getNftBonusName(uint256 _nftId) public view returns (string memory) {
    for (uint8 i = 0; i < nftBonusNames.length; i++) {
      if (_nftId >= nftBonusLowerBound[nftBonusNames[i]] && _nftId <= nftBonusUpperBound[nftBonusNames[i]]) {
        return nftBonusNames[i];
      }
    }

    return "";
  }

  function getBonus(address _entity, uint128 _nodeId, uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
    address serviceContract = _msgSender();
    require(serviceContracts[serviceContract], "service doesnt exist");

    uint256 nftId = getStakedNftId(_entity, _nodeId, serviceContract);
    string memory bonusName = getNftBonusName(nftId);
    if (keccak256(abi.encode(bonusName)) == keccak256(abi.encode(""))) return 0;

    uint256 stakedAtBlock = entityServiceNodeStakedAtBlock[_entity][serviceContract][_nodeId] > 0
    ? entityServiceNodeStakedAtBlock[_entity][serviceContract][_nodeId]
    : (entityNodeStakedAtBlock[_entity][_nodeId] > 0
      ? entityNodeStakedAtBlock[_entity][_nodeId] : nftIdStakedAtBlock[nftId]);

    uint256 effectiveBlock = nftBonusEffectiveBlock[bonusName];
    uint256 startFromBlock = stakedAtBlock > _fromBlock ? stakedAtBlock : _fromBlock;
    if (startFromBlock < effectiveBlock) {
      startFromBlock = effectiveBlock;
    }

    if (stakedAtBlock == 0 && keccak256(abi.encode(bonusName)) == keccak256(abi.encode("BRONZE"))) {
      return CStrongNFTBonus.getBonus(_entity, _nodeId, startFromBlock, _toBlock);
    }

    if (nftId == 0) return 0;
    if (stakedAtBlock == 0) return 0;
    if (effectiveBlock == 0) return 0;
    if (startFromBlock >= _toBlock) return 0;
    if (CERC1155.balanceOf(address(this), nftId) == 0) return 0;

    return _toBlock.sub(startFromBlock).mul(nftBonusValue[bonusName]);
  }

  function isStaked(uint256 _nftId, uint128 _nodeId, address _serviceContract) public returns (bool) {
    return (_serviceContract == address(CService) && entityNodeStakedNftId[_msgSender()][_nodeId] == _nftId)
    || entityServiceNodeStakedNftId[_msgSender()][_serviceContract][_nodeId] == _nftId;
  }

  //
  // Staking
  // -------------------------------------------------------------------------------------------------------------------

  function stakeNFT(uint256 _nftId, uint128 _nodeId, address _serviceContract) public payable {
    string memory bonusName = getNftBonusName(_nftId);
    require(keccak256(abi.encode(bonusName)) != keccak256(abi.encode("")), "not eligible");
    require(CERC1155.balanceOf(_msgSender(), _nftId) != 0
    || (CERC1155.balanceOf(address(this), _nftId) != 0 && nftIdStakedToEntity[_nftId] == _msgSender()), "not enough");
    require(nftIdStakedToNodesCount[_nftId] < nftBonusNodesLimit[bonusName], "over limit");
    require(serviceContracts[_serviceContract], "service doesnt exist");
    require(ServiceInterface(_serviceContract).doesNodeExist(_msgSender(), _nodeId), "node doesnt exist");
    require(!isStaked(_nftId, _nodeId, _serviceContract), "already staked");

    entityServiceNodeStakedNftId[_msgSender()][_serviceContract][_nodeId] = _nftId;
    nftIdStakedToEntity[_nftId] = _msgSender();
    entityServiceNodeStakedAtBlock[_msgSender()][_serviceContract][_nodeId] = block.number;
    nftIdStakedToNodesCount[_nftId] += 1;

    bool alreadyExists = false;
    for (uint8 i = 0; i < entityStakedNftIds[_msgSender()].length; i++) {
      if (entityStakedNftIds[_msgSender()][i] == _nftId) {
        alreadyExists = true;
        break;
      }
    }
    if (!alreadyExists) {
      entityStakedNftIds[_msgSender()].push(_nftId);
    }

    if (CERC1155.balanceOf(address(this), _nftId) == 0) {
      CERC1155.safeTransferFrom(_msgSender(), address(this), _nftId, 1, bytes(""));
    }

    emit StakedToNode(_msgSender(), _nftId, _nodeId, block.number, _serviceContract);
  }

  function unStakeNFT(uint256 _nftId, uint128 _nodeId, uint256 _blockNumber, address _serviceContract) public payable {
    require(isStaked(_nftId, _nodeId, _serviceContract), "wrong node");
    require(nftIdStakedToEntity[_nftId] != address(0), "not staked");
    require(nftIdStakedToEntity[_nftId] == _msgSender(), "not staker");
    require(serviceContracts[_serviceContract], "service doesnt exist");

    if (!ServiceInterface(_serviceContract).hasNodeExpired(_msgSender(), _nodeId)) {
      ServiceInterface(_serviceContract).claim{value : msg.value}(_nodeId, _blockNumber, false);
    }

    entityNodeStakedNftId[_msgSender()][_nodeId] = 0;
    entityServiceNodeStakedNftId[_msgSender()][_serviceContract][_nodeId] = 0;
    nftIdStakedToNodeId[_nftId] = 0;

    if (nftIdStakedToNodesCount[_nftId] > 0) {
      nftIdStakedToNodesCount[_nftId] -= 1;
    }

    if (nftIdStakedToNodesCount[_nftId] == 0) {
      nftIdStakedToEntity[_nftId] = address(0);

      for (uint8 i = 0; i < entityStakedNftIds[_msgSender()].length; i++) {
        if (entityStakedNftIds[_msgSender()][i] == _nftId) {
          _deleteIndex(entityStakedNftIds[_msgSender()], i);
          break;
        }
      }

      CERC1155.safeTransferFrom(address(this), _msgSender(), _nftId, 1, bytes(""));
    }

    emit UnstakedFromNode(_msgSender(), _nftId, _nodeId, _blockNumber, _serviceContract);
  }

  //
  // Admin
  // -------------------------------------------------------------------------------------------------------------------

  function updateBonus(string memory _name, uint256 _lowerBound, uint256 _upperBound, uint256 _value, uint256 _block, uint8 _nodesLimit) public {
    require(_msgSender() == serviceAdmin || _msgSender() == superAdmin, "not admin");

    bool alreadyExists = false;
    for (uint8 i = 0; i < nftBonusNames.length; i++) {
      if (keccak256(abi.encode(nftBonusNames[i])) == keccak256(abi.encode(_name))) {
        alreadyExists = true;
      }
    }

    if (!alreadyExists) {
      nftBonusNames.push(_name);
    }

    nftBonusLowerBound[_name] = _lowerBound;
    nftBonusUpperBound[_name] = _upperBound;
    nftBonusValue[_name] = _value;
    nftBonusEffectiveBlock[_name] = _block != 0 ? _block : block.number;
    nftBonusNodesLimit[_name] = _nodesLimit;
  }

  function updateContracts(address _nftContract) public {
    require(_msgSender() == superAdmin, "not admin");
    CERC1155 = IERC1155Preset(_nftContract);
  }

  function addServiceContract(address _contract) public {
    require(_msgSender() == superAdmin, "not admin");
    serviceContracts[_contract] = true;
  }

  function removeServiceContract(address _contract) public {
    require(_msgSender() == superAdmin, "not admin");
    serviceContracts[_contract] = false;
  }

  function updateServiceAdmin(address newServiceAdmin) public {
    require(_msgSender() == superAdmin, "not admin");
    serviceAdmin = newServiceAdmin;
  }

  function updateEntityNodeStakedAtBlock(address _entity, uint128 _nodeId, uint256 _block) public {
    require(_msgSender() == serviceAdmin || _msgSender() == superAdmin, "not admin");

    entityNodeStakedAtBlock[_entity][_nodeId] = _block;
  }

  function updateEntityServiceNodeStakedAtBlock(address _entity, uint128 _nodeId, address _serviceContract, uint256 _block) public {
    require(_msgSender() == serviceAdmin || _msgSender() == superAdmin, "not admin");

    entityServiceNodeStakedAtBlock[_entity][_serviceContract][_nodeId] = _block;
  }

  //
  // ERC1155 support
  // -------------------------------------------------------------------------------------------------------------------

  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal virtual {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }

  function _deleteIndex(uint256[] storage array, uint256 index) internal {
    uint256 lastIndex = array.length.sub(1);
    uint256 lastEntry = array[lastIndex];
    if (index == lastIndex) {
      array.pop();
    } else {
      array[index] = lastEntry;
      array.pop();
    }
  }
}
