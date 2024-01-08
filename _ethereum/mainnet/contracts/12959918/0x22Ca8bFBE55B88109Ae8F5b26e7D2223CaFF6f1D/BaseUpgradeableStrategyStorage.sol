pragma solidity 0.7.3;

import "./Initializable.sol";

contract BaseUpgradeableStrategyStorage is Initializable {

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _SLP_REWARD_TOKEN_SLOT = 0x39f6508fa78bf0f8811208dd5eeef269668a89d1dc64bfffde1f9147d9071963;
  bytes32 internal constant _SLP_REWARD_POOL_SLOT = 0x38a0c4d4bce281b7791c697a1359747b8fbd89f22fbe5557828bf15a023175da;
  bytes32 internal constant _ONX_FARM_REWARD_POOL_SLOT = 0x24f4d5cb1e6d05c6fb88a551e1e1659fba608459340d9f45cc3171803a2b8552;
  bytes32 internal constant _ONX_STAKING_REWARD_POOL_SLOT = 0x9cb98b534f7a03048b0fe6d7d318ae0a1818bcdf1b23f010350af3399659d8cf;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  constructor() public {
  }

  function initializeBaseUpgradeableStrategyStorage() public initializer {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
    assert(_SLP_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.slpRewardToken")) - 1));
    assert(_SLP_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.slpRewardPool")) - 1));
    assert(_ONX_FARM_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.onxXSushiFarmRewardPool")) - 1));
    assert(_ONX_STAKING_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.onxStakingRewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  // Sushiswap Onsen farm reward pool functions

  function _setSLPRewardPool(address _address) internal {
    setAddress(_SLP_REWARD_POOL_SLOT, _address);
  }

  function slpRewardPool() public view returns (address) {
    return getAddress(_SLP_REWARD_POOL_SLOT);
  }

  function _setSLPRewardToken(address _address) internal {
    setAddress(_SLP_REWARD_TOKEN_SLOT, _address);
  }

  function slpRewardToken() public view returns (address) {
    return getAddress(_SLP_REWARD_TOKEN_SLOT);
  }

  // Onx Farm Dummy Token Reward Pool Functions

  function _setOnxFarmRewardPool(address _address) internal {
    setAddress(_ONX_FARM_REWARD_POOL_SLOT, _address);
  }

  function onxFarmRewardPool() public view returns (address) {
    return getAddress(_ONX_FARM_REWARD_POOL_SLOT);
  }

  // Onx Staking Functions

  function _setOnxStakingRewardPool(address _address) internal {
    setAddress(_ONX_STAKING_REWARD_POOL_SLOT, _address);
  }

  function onxStakingRewardPool() public view returns (address) {
    return getAddress(_ONX_STAKING_REWARD_POOL_SLOT);
  }

  // ---

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}
