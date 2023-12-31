// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./StakeInfo.sol";

abstract contract EncodableSettings is StakeInfo {
  // the index of the first bit of targeted information
  uint256 internal constant UNUSED_SPACE_RIGHT_UINT8 = SLOTS - EIGHT; // 256-8=248
  uint256 internal constant UNUSED_SPACE_RIGHT_UINT16 = SLOTS - SIXTEEN; // 256-16=240
  uint256 internal constant UNUSED_SPACE_RIGHT_UINT64 = SLOTS - SIXTY_FOUR; // 256-64=192
  uint256 internal constant INDEX_RIGHT_HEDRON_TIP = SLOTS - SEVENTY_TWO; // 256-72=184
  uint256 internal constant INDEX_RIGHT_TARGET_TIP = INDEX_RIGHT_HEDRON_TIP - SEVENTY_TWO; // 184-72=112
  uint256 internal constant INDEX_LEFT_TARGET_TIP = SLOTS - 144; // 256-144=112
  uint256 internal constant INDEX_RIGHT_NEW_STAKE = INDEX_RIGHT_TARGET_TIP - SEVENTY_TWO;
  uint256 internal constant INDEX_LEFT_NEW_STAKE = SLOTS - INDEX_RIGHT_NEW_STAKE;
  uint256 internal constant INDEX_RIGHT_NEW_STAKE_DAYS_METHOD = THIRTY_TWO;
  uint256 internal constant INDEX_RIGHT_NEW_STAKE_DAYS_MAGNITUDE = SIXTEEN;
  uint256 internal constant INDEX_RIGHT_COPY_ITERATIONS = EIGHT;
  uint256 internal constant INDEX_RIGHT_HAS_EXTERNAL_TIPS = 7;
  uint256 internal constant INDEX_RIGHT_COPY_EXTERNAL_TIPS = 6;
  uint256 internal constant INDEX_RIGHT_STAKE_IS_TRANSFERABLE = 5;
  uint256 internal constant INDEX_LEFT_STAKE_IS_TRANSFERABLE = SLOTS - INDEX_RIGHT_STAKE_IS_TRANSFERABLE;
  uint256 internal constant INDEX_RIGHT_SHOULD_SEND_TOKENS_TO_STAKER = FOUR;
  uint256 internal constant INDEX_RIGHT_CAN_MINT_HEDRON_AT_END = THREE;
  uint256 internal constant INDEX_RIGHT_CAN_MINT_HEDRON = TWO;
  uint256 internal constant INDEX_RIGHT_CAN_EARLY_STAKE_END = ONE;
  uint256 internal constant INDEX_RIGHT_CAN_STAKE_END = ZERO;

  /**
   * @notice this struct holds a series of flags to allow clients
   * to easily access and understand 1/0 mappings
   */
  struct ConsentAbilities {
    bool canStakeEnd;
    bool canEarlyStakeEnd;
    bool canMintHedron;
    bool canMintHedronAtEnd;
    bool shouldSendTokensToStaker;
    bool stakeIsTransferable;
    bool copyExternalTips;
    bool hasExternalTips;
  }
  /**
   * @notice this struct holds information that can be encoded into a uint256
   */
  struct Settings {
    Linear hedronTip;
    // starts with full amount of end stake
    Linear targetTip;
    // the rest goes into a new stake if the number of days are set
    Linear newStake;
    // useful to use methods 6+7 for stake days
    uint256 newStakeDaysMethod;
    uint256 newStakeDaysMagnitude;
    uint256 copyIterations; // 0 for do not restart, 1-254 as countdown, 255 as restart indefinitely
    /**
     * 00000001(0): can stake end
     * 00000010(1): can early stake end
     * 00000100(2): can mint hedron (any time)
     * 00001000(3): can mint hedron during end stake - future should be 0
     * 00010000(4): should send tokens to staker
     * 00100000(5): stake is transferable
     * 01000000(6): copy external tips to next stake
     * 10000000(7): has external tips (contract controlled)
     */
    ConsentAbilities consentAbilities;
  }
  mapping(uint256 stakeId => uint256 settings) public stakeIdToSettings;
  /**
   * an event to signal that settings to direct funds
   * at the end of a stake have been updated
   * @param stakeId the stake id that was updated
   * @param settings the newly updated settings
   */
  event UpdateSettings(uint256 indexed stakeId, uint256 settings);
  uint256 private constant DEFAULT_ENCODED_SETTINGS
    = uint256(0x000000000000000000000000000000000000000000000000000002020000ff01);
  /**
   * @return the default encoded settings used by end stakers to tip and end stakes
   */
  function defaultEncodedSettings() external virtual pure returns(uint256) {
    return DEFAULT_ENCODED_SETTINGS;
  }
  /**
   * access settings of a stake id and decode it, returning the decoded settings struct
   * @param stakeId the stake id to access and decode
   * @return decoded settings struct that holds all configuration by owner
   */
  function stakeIdSettings(uint256 stakeId) external view returns (Settings memory) {
    return _decodeSettings({
      encoded: stakeIdToSettings[stakeId]
    });
  }
  /**
   * decode a uint's first byte as consent abilities struct
   * @param abilities encoded consent abilities to decode
   * @return a ConsentAbilities struct with flags appropriately set
   */
  function decodeConsentAbilities(uint256 abilities) external pure returns(ConsentAbilities memory) {
    return _decodeConsentAbilities({
      abilities: abilities
    });
  }
  /**
   * decode a uint's first byte as consent abilities struct
   * @param abilities encoded consent abilities to decode
   * @return a ConsentAbilities struct with flags appropriately set
   */
  function _decodeConsentAbilities(uint256 abilities) internal pure returns(ConsentAbilities memory) {
    unchecked {
      return ConsentAbilities({
        hasExternalTips: (abilities >> INDEX_RIGHT_HAS_EXTERNAL_TIPS) % TWO == ONE,
        copyExternalTips: (abilities >> INDEX_RIGHT_COPY_EXTERNAL_TIPS) % TWO == ONE,
        stakeIsTransferable: (abilities >> INDEX_RIGHT_STAKE_IS_TRANSFERABLE) % TWO == ONE,
        shouldSendTokensToStaker: (abilities >> INDEX_RIGHT_SHOULD_SEND_TOKENS_TO_STAKER) % TWO == ONE,
        canMintHedronAtEnd: (abilities >> INDEX_RIGHT_CAN_MINT_HEDRON_AT_END) % TWO == ONE,
        canMintHedron: (abilities >> INDEX_RIGHT_CAN_MINT_HEDRON) % TWO == ONE,
        canEarlyStakeEnd: (abilities >> INDEX_RIGHT_CAN_EARLY_STAKE_END) % TWO == ONE,
        canStakeEnd: abilities % TWO == ONE
      });
    }
  }
  /**
   * updates settings under a stake id to the provided settings struct
   * @param stakeId the stake id to update
   * @param settings the settings to update the stake id to
   * @notice payable is only available to reduce costs, any native token
   * sent to this method will be unattributed and claimable by anyone
   */
  function updateSettings(uint256 stakeId, Settings calldata settings) external virtual payable {
    _updateSettingsEncoded({
      stakeId: stakeId,
      settings: _encodeSettings(settings)
    });
  }
  /**
   * update a stake's settings by providing a new, encoded value
   * @param stakeId the stake id to update settings for
   * @param settings the settings value to update settings for
   */
  function updateSettingsEncoded(uint256 stakeId, uint256 settings) external virtual payable {
    _updateSettingsEncoded({
      stakeId: stakeId,
      settings: settings
    });
  }
  /**
   * update a stake's setting by providing a uint256 encoded settings
   * @param stakeId the stake id to update settings for
   * @param settings the encoded settings to update to (7th index is maintained)
   * @notice This method will validate that the msg.sender owns the stake
   */
  function _updateSettingsEncoded(uint256 stakeId, uint256 settings) internal {
    _verifyStakeOwnership({
      owner: msg.sender,
      stakeId: stakeId
    });
    _logPreservedSettingsUpdate({
      stakeId: stakeId,
      settings: settings
    });
  }
  /**
   * updates a stake id's settings
   * @param stakeId the stake id to update settings for
   * @param settings the settings to update against a provided stakeId.
   * 7th index will be ignored as it is controlled by the contract
   */
  function _logPreservedSettingsUpdate(
    uint256 stakeId,
    uint256 settings
  ) internal {
    // preserve the 7th index which contract controls
    unchecked {
      _logSettingsUpdate({
        stakeId: stakeId,
        settings: (
          (settings >> INDEX_RIGHT_COPY_ITERATIONS << INDEX_RIGHT_COPY_ITERATIONS)
          | uint8(stakeIdToSettings[stakeId] >> INDEX_RIGHT_HAS_EXTERNAL_TIPS << INDEX_RIGHT_HAS_EXTERNAL_TIPS)
          | uint256(uint8(settings << ONE) >> ONE)
        )
      });
    }
  }
  /**
   * update the settings for a stake id
   * @param stakeId the stake id to update settings for
   * @param settings an object that holds settings values
   * to inform end stakers how to handle the stake
   */
  function _logSettingsUpdate(
    uint256 stakeId,
    uint256 settings
  ) internal {
    stakeIdToSettings[stakeId] = settings;
    emit UpdateSettings({
      stakeId: stakeId,
      settings: settings
    });
  }
  /**
   * read a single property from encoded settings
   * @notice most useful for other contracts to pull out 1 property without
   * needing logic for parsing
   * @param settings the settings number to read 1 property from
   * @param fromEnd the index from the end to start at
   * @param length the number of bits to read
   */
  function readEncodedSettings(
    uint256 settings,
    uint256 fromEnd,
    uint256 length
  ) external pure returns(uint256) {
    return _readEncodedSettings({
      settings: settings,
      fromEnd: fromEnd,
      length: length
    });
  }
  /**
   * parse out a single value from an encoded settings uint Only useful
   * if you do not want the whole settings struct to be decoded
   * @param settings the settings value to parse out
   * @param fromEnd the index (from left) to start at. Left most is 0
   * @param length the number of bits to retain after the fromEnd param
   * @return the uint retained by the fromEnd and length arguments of settings
   */
  function _readEncodedSettings(
    uint256 settings,
    uint256 fromEnd,
    uint256 length
  ) internal pure returns(uint256) {
    unchecked {
      return settings << fromEnd >> (SLOTS - length);
    }
  }
  /**
   * encode a settings struct into it's number
   * @param settings the settings struct to be encoded into a number
   * @return encoded a uint256 expression of settings struct
   */
  function encodeSettings(Settings memory settings) external pure returns(uint256 encoded) {
    return _encodeSettings({
      settings: settings
    });
  }
  /**
   * encode a settings struct as a uint value to fit it within 1 word
   * @param settings the settings struct to encode as a uint
   * @return encoded a uint256 expression of settings struct
   */
  function _encodeSettings(Settings memory settings) internal pure returns(uint256 encoded) {
    unchecked {
      return _encodeLinear(settings.hedronTip) << INDEX_RIGHT_HEDRON_TIP
        | _encodeLinear(settings.targetTip) << INDEX_RIGHT_TARGET_TIP
        | _encodeLinear(settings.newStake) << INDEX_RIGHT_NEW_STAKE
        | uint256(uint8(settings.newStakeDaysMethod)) << INDEX_RIGHT_NEW_STAKE_DAYS_METHOD
        | uint256(uint16(settings.newStakeDaysMagnitude)) << INDEX_RIGHT_NEW_STAKE_DAYS_MAGNITUDE
        | uint256(uint8(settings.copyIterations)) << INDEX_RIGHT_COPY_ITERATIONS
        | _encodeConsentAbilities(settings.consentAbilities);
    }
  }
  /**
   * decode an encoded setting into it's settings struct
   * @param encoded the encoded setting to decode
   * @return settings the decoded settings struct
   */
  function decodeSettings(uint256 encoded) external pure returns(Settings memory settings) {
    return _decodeSettings({
      encoded: encoded
    });
  }
  /**
   * decode a settings struct (2 words minimum) from a single uint256
   * @param encoded a number that represents all data needed for an encoded settings struct
   */
  function _decodeSettings(uint256 encoded) internal pure returns(Settings memory settings) {
    unchecked {
      return Settings(
        _decodeLinear(uint72(encoded >> INDEX_RIGHT_HEDRON_TIP)),
        _decodeLinear(uint72(encoded >> INDEX_RIGHT_TARGET_TIP)),
        _decodeLinear(uint72(encoded >> INDEX_RIGHT_NEW_STAKE)),
        uint8( encoded >> INDEX_RIGHT_NEW_STAKE_DAYS_METHOD),
        uint16(encoded >> INDEX_RIGHT_NEW_STAKE_DAYS_MAGNITUDE),
        uint8( encoded >> INDEX_RIGHT_COPY_ITERATIONS),
        _decodeConsentAbilities({
          abilities: uint8(encoded)
        })
      );
    }
  }
  /**
   * encode a ConsentAbilities struct to fit in 1 byte
   * @param consentAbilities the consent abilities struct to encode as a uint
   * @return the encoded list of consetn abilities as a uint
   */
  function encodeConsentAbilities(ConsentAbilities calldata consentAbilities) external pure returns(uint256) {
    return _encodeConsentAbilities({
      consentAbilities: consentAbilities
    });
  }
  /**
   * encode a struct of consent abilities to fit in 1 byte
   * @param consentAbilities encodes a struct of 8 booleans as a uint to fit in 1 byte
   * @return the encoded list of consent abilities as a uint
   */
  function _encodeConsentAbilities(ConsentAbilities memory consentAbilities) internal pure returns(uint256) {
    unchecked {
      return (
        ((consentAbilities.hasExternalTips ? ONE : ZERO) << INDEX_RIGHT_HAS_EXTERNAL_TIPS )
        | ((consentAbilities.copyExternalTips ? ONE : ZERO) << INDEX_RIGHT_COPY_EXTERNAL_TIPS)
        | ((consentAbilities.stakeIsTransferable ? ONE : ZERO) << INDEX_RIGHT_STAKE_IS_TRANSFERABLE)
        | ((consentAbilities.shouldSendTokensToStaker ? ONE : ZERO) << INDEX_RIGHT_SHOULD_SEND_TOKENS_TO_STAKER)
        | ((consentAbilities.canMintHedronAtEnd ? ONE : ZERO) << INDEX_RIGHT_CAN_MINT_HEDRON_AT_END)
        | ((consentAbilities.canMintHedron ? ONE : ZERO) << INDEX_RIGHT_CAN_MINT_HEDRON)
        | ((consentAbilities.canEarlyStakeEnd ? ONE : ZERO) << INDEX_RIGHT_CAN_EARLY_STAKE_END)
        | (consentAbilities.canStakeEnd ? ONE : ZERO)
      );
    }
  }
  /**
   * gets default settings struct
   * @return settings struct with default settings
   */
  function _defaultSettings() internal virtual pure returns(Settings memory settings) {
    // 0x00000000000000000000000000000000000000000000020000000000000000020000ff01
    unchecked {
      return Settings(
        /*
        * by default, there is no hedron tip
        * assume that stakers will manage their own stakes at bare minimum
        */
        Linear({
          method: ZERO,
          xFactor: ZERO,
          x: 0,
          yFactor: ZERO,
          y: ZERO,
          bFactor: ZERO,
          b: 0
        }),
        /*
        * by default, there is no target (hex) tip
        * assume that stakers will manage their own stakes at bare minimum
        */
        Linear({
          method: ZERO,
          xFactor: ZERO,
          x: 0,
          yFactor: ZERO,
          y: ZERO,
          bFactor: ZERO,
          b: 0
        }),
        /*
        * by default, assume that all tokens minted from an end stake
        * should go directly into a new stake
        */
        Linear({
          method: TWO,
          xFactor: ZERO,
          x: 0,
          yFactor: ZERO,
          y: ZERO,
          bFactor: ZERO,
          b: 0
        }),
        /*
        * by default, assume that by using this contract, users want efficiency gains
        * so by default, restarting their stakes are the most efficient means of managing tokens
        */
        uint8(TWO), uint16(ZERO),
        uint8(MAX_UINT_8), // restart forever
        /*
        * by index: 00000001
        * 7: signal to ender that tips exist to be collected (allows contract to avoid an SLOAD) (0)
        * 6: should recreate external tips
        * 5: give dominion over hedron after tip to staker (0)
        * 4: give dominion over target after tip to staker (0)
        * 3: do not allow end hedron mint (0)
        * 2: do not allow continuous hedron mint (0)
        * 1: do not allow early end (0)
        * 0: allow end stake once days have been served (1)
        *
        * restarting is signalled by using settings above
        * no funds are ever pulled from external address
        * is ever allowed except by sender
        *
        * the reason why the hedron flags are 0 by default on the contract level is because
        * it may be worthwhile for hedron developers to build on top of this contract
        * and it is poor form to force people in the future to have to cancel out the past
        * front ends may choose to send a different default (non 0) during stake start
        */
        ConsentAbilities({
          canStakeEnd: true,
          canEarlyStakeEnd: false,
          canMintHedron: false,
          canMintHedronAtEnd: false,
          shouldSendTokensToStaker: false,
          stakeIsTransferable: false,
          copyExternalTips: false,
          hasExternalTips: false
        })
      );
    }
  }
  /**
   * modify the second byteword from the right to appropriately decrement
   * the number of times that these settings should be copied
   * @param settings the settings to start with - only the 2nd byte from the right is modified
   */
  function decrementCopyIterations(uint256 settings) external pure returns(uint256) {
    return _decrementCopyIterations({
      settings: settings
    });
  }
  /**
   * decrement the 2nd byte from the right if the value is < 255
   * @param settings the settings to start with - only the 2nd byte from the right is modified
   * @return updated encoded settings with appropriately decremented value
   */
  function _decrementCopyIterations(uint256 settings) internal pure returns(uint256) {
    unchecked {
      uint256 copyIterations = uint8(settings >> INDEX_RIGHT_COPY_ITERATIONS);
      if (copyIterations == ZERO) {
        return uint8(settings);
      }
      if (copyIterations == MAX_UINT_8) {
        return settings;
      }
      --copyIterations;
      return (
        (settings >> INDEX_RIGHT_NEW_STAKE_DAYS_MAGNITUDE << INDEX_RIGHT_NEW_STAKE_DAYS_MAGNITUDE)
        | (copyIterations << INDEX_RIGHT_COPY_ITERATIONS)
        | uint8(settings)
      );
    }
  }
  /**
   * exposes the default settings to external for ease of access
   * @return a settings struct with default values
   */
  function defaultSettings() external virtual pure returns(Settings memory) {
    return _defaultSettings();
  }
}
