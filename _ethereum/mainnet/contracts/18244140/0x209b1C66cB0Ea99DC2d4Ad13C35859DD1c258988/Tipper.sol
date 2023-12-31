// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./UnderlyingStakeable.sol";
import "./Bank.sol";
import "./CurrencyList.sol";
import "./EncodableSettings.sol";

abstract contract Tipper is Bank, UnderlyingStakeable, CurrencyList, EncodableSettings {
  // 2^56 is a lot harder to grief than 2^32
  uint256 internal constant INDEX_EXTERNAL_TIP_CURRENCY = 200;
  uint256 internal constant INDEX_EXTERNAL_TIP_CURRENCY_ONLY = INDEX_EXTERNAL_TIP_CURRENCY + ONE;
  uint256 internal constant INDEX_EXTERNAL_TIP_LIMIT = SEVENTY_TWO; // 128 bits long
  constructor()
    Bank()
    UnderlyingStakeable()
    CurrencyList()
    EncodableSettings()
  {
    _addCurrencyToList(address(0));
    // this line allows hex to be tipped by factor of basefee
    _addCurrencyToList(TARGET);
    _addCurrencyToList(HEDRON);
  }
  /**
   * @dev this mapping is needed for the case where a tip is added to a stake
   * but the staker ends the stake on a lower level which never checks for tips
   * this mapping slightly increases the cost of initializing tips as well as transferring them
   * but that is ok, because we generally do not want people to be trading stakes at this level
   * of anyone wants to be swapping ownership over stakes then they can create
   * an erc721 and trade at a higher level
   * also end stakers get a larger refund due to more information being zero'd out
   * it is set to internal because, generally, the stake id should be going
   * to the lower level `stakeIdInfo` mapping and individuals who do not wish to tip
   * should not be charged 2k gas for checking if this mapping exists
   */
  mapping(uint256 stakeId => address staker) internal tipStakeIdToStaker;
  mapping(uint256 stakeId => uint256[] tips) public stakeIdTips;
  event AddTip(
    uint256 indexed stakeId,
    address indexed token,
    uint256 indexed index,
    uint256 settings
  );
  event RemoveTip(
    uint256 indexed stakeId,
    address indexed token,
    uint256 indexed index,
    uint256 settings
  );
  /**
   * tip an address a defined amount and token
   * @param stakeId the stake id being targeted
   * @param token the token being accounted
   * @param to the address to attribute rewards to
   * @param amount the amount of the token
   */
  event Tip(
    uint256 indexed stakeId,
    address indexed token,
    address indexed to,
    uint256 amount
  );
  /**
   * check the count of a list of tips provided by the staker
   * @param stakeId the stake id to check the list of tips
   */
  function stakeIdTipSize(uint256 stakeId) external view returns(uint256) {
    return _stakeIdTipSize({
      stakeId: stakeId
    });
  }
  /**
   * check the count of a list of tips provided by the staker
   * @param stakeId the stake id to check the list of tips
   */
  function _stakeIdTipSize(uint256 stakeId) internal view returns(uint256) {
    return stakeIdTips[stakeId].length;
  }
  function computeTip(uint256 tip) external view returns(uint256 limit, uint256 consumed) {
    return _computeTip(tip);
  }
  function _computeTip(uint256 tip) internal view returns (uint256 limit, uint256 consumed) {
    unchecked {
      limit = uint128(tip >> INDEX_EXTERNAL_TIP_LIMIT);
      if (uint72(tip) == ZERO) {
        // checking for existance of a tip number
        // allows us to use ZERO as simplest pathway
        consumed = limit;
      } else {
        consumed = _computeMagnitude({
          limit: limit,
          linear: uint72(tip),
          v2: limit,
          v1: block.basefee
        });
      }
      return (limit, consumed);
    }
  }
  /**
   * execute a list of tips and leave them in the unattributed space
   * @param stakeId the stake id whose tips should be executed
   * @param staker the staker that owns the stake id
   * @param nextStakeId the next stake id if tips are to be copied / rolled over
   */
  function _executeTipList(
    uint256 stakeId, address staker, uint256 nextStakeId, address tipTo
  ) internal returns(uint256 nextStakeTipsLength) {
    uint256 i;
    uint256 len = stakeIdTips[stakeId].length;
    uint256 tip;
    uint256 cachedTip;
    uint256 limit;
    // disallows future removal of tips
    tipStakeIdToStaker[stakeId] = address(0);
    unchecked {
      do {
        // tips get executed in reverse order so that the contract
        // can clean itself up (gas refund) as it goes along
        tip = stakeIdTips[stakeId][len - ONE - i];
        cachedTip = tip;
        stakeIdTips[stakeId].pop();
        uint256 idx = tip << ONE >> INDEX_EXTERNAL_TIP_CURRENCY_ONLY;
        address token = indexToToken[idx];
        uint256 withdrawableBalance = withdrawableBalanceOf[token][staker];
        uint256 cachedWithdrawableBalance = withdrawableBalance;
        (limit, tip) = _computeTip(tip);
        // this is a refund
        withdrawableBalance += (limit - tip);
        if (tip > ZERO) {
          emit Tip({
            stakeId: stakeId,
            token: token,
            to: tipTo,
            amount: tip
          });
          if (tipTo == address(0)) {
            attributed[token] -= tip;
          } else {
            if (tipTo == staker) {
              withdrawableBalance += tip;
            } else {
              withdrawableBalanceOf[token][tipTo] = withdrawableBalanceOf[token][tipTo] + tip;
              // because attributed already has the tip, we should not double count it
            }
          }
        }
        if (_isOneAtIndex({
          settings: cachedTip,
          index: MAX_UINT_8
        })) {
          if (nextStakeId > ZERO) {
            limit = _clamp({
              amount: limit,
              max: withdrawableBalance
            });
            if (limit > ZERO) {
              cachedTip = _encodeTipSettings(true, idx, limit, cachedTip);
              withdrawableBalance -= limit;
              // we no longer need currency idx
              // so this line takes it over / reuses it
              stakeIdTips[nextStakeId].push(cachedTip);
              if (tipStakeIdToStaker[nextStakeId] == address(0)) {
                tipStakeIdToStaker[nextStakeId] = staker;
              }
              emit AddTip({
                stakeId: nextStakeId,
                token: token,
                index: nextStakeTipsLength,
                settings: cachedTip
              });
              ++nextStakeTipsLength;
            }
          }
        }
        if (withdrawableBalance != cachedWithdrawableBalance) {
          withdrawableBalanceOf[token][staker] = withdrawableBalance;
        }
        ++i;
      } while (i < len);
    }
  }
  /**
   * encodes a series of data in 32+96+64+64 to fit into 256 bits to define
   * how a tip should be executed
   * @param currencyIndex the index of the currency on the list
   * @param amount the number of tokens to delineate as tips
   * @param encodedLinear the method+xyb function to use
   */
  function encodeTipSettings(
    bool reusable,
    uint256 currencyIndex,
    uint256 amount,
    uint256 encodedLinear
  ) external pure returns(uint256) {
    return _encodeTipSettings({
      reusable: reusable,
      currencyIndex: currencyIndex,
      amount: amount,
      encodedLinear: encodedLinear
    });
  }
  /**
   * encodes tip settings into a uint256
   * @param reusable the tip can be reused if there is amount left over
   * @param currencyIndex the index of the currency on the list
   * @param amount the number of tokens deposited into the contract
   * @param encodedLinear an (x/y)+b equation inside of uint72
   */
  function _encodeTipSettings(
    bool reusable,
    uint256 currencyIndex,
    uint256 amount,
    uint256 encodedLinear
  ) internal pure returns(uint256) {
    if (uint8(encodedLinear) == ZERO) {
      if (encodedLinear != ZERO) {
        revert NotAllowed();
      }
    }
    unchecked {
      return uint256(reusable ? ONE : ZERO) << MAX_UINT_8
        | (uint256(currencyIndex) << INDEX_EXTERNAL_TIP_CURRENCY)
        | (uint256(uint128(amount)) << INDEX_EXTERNAL_TIP_LIMIT)
        | uint256(uint72(encodedLinear));
    }
  }
  /**
   * create a tip and back it with a token, to be executed by the stake ender
   * @param reusable the tip can be reused if value is still present after it has been executed
   * @param token the token to fund the tip
   * @param stakeId the stake id that the tip belongs to
   * @param amount the number of tokens to back the tip with use zero to move all withdrawableBalanceOf value
   * @param encodedLinear the (x/y)+b equation to define how much of the tip to spend
   * @return index of the tip in the list
   * @return tipAmount the final backing value of the tip
   */
  function depositAndAddTipToStake(
    bool reusable,
    address token,
    uint256 stakeId,
    uint256 amount,
    uint256 encodedLinear
  ) external virtual payable returns(uint256, uint256) {
    uint256 depositedAmount = _depositTokenFrom({
      token: token,
      depositor: msg.sender,
      amount: amount
    });
    address recipient = _verifyTipAmountAllowed({
      stakeId: stakeId,
      amount: amount
    });
    _addToTokenWithdrawable({
      token: token,
      to: recipient,
      amount: depositedAmount
    });
    _checkStakeCustodian({
      stakeId: stakeId
    });
    return _addTipToStake({
      reusable: reusable,
      token: token,
      account: recipient,
      stakeId: stakeId,
      amount: amount,
      encodedLinear: encodedLinear
    });
  }
  /**
   * remove all tips from a stake id and moves them to the
   * withdrawableBalanceOf the owner of the stake
   * @param stakeId the stake id to remove all tips from
   * @dev if the sender does not own the stake id, the call will fail
   */
  function removeAllTips(uint256 stakeId) external {
    _verifyStakeOwnership({
      owner: msg.sender,
      stakeId: stakeId
    });
    _removeAllTips({
      stakeId: stakeId,
      settings: stakeIdToSettings[stakeId]
    });
  }
  /**
   * remove all tips from a stake id and moves them to the
   * withdrawableBalanceOf the owner of the stake
   * @param stakeId the stake id to remove all tips from
   * @param settings the settings of the stake used for
   * determining whether or not to send funds back to staker
   */
  function _removeAllTips(uint256 stakeId, uint256 settings) internal {
    uint256 tipCount = _stakeIdTipSize({
      stakeId: stakeId
    });
    unchecked {
      if (tipCount > ZERO) {
        uint256 i;
        uint256[] memory indexes = new uint256[](tipCount);
        --tipCount;
        do {
          indexes[i] = tipCount - i;
          ++i;
        } while (i <= tipCount);
        _removeTipsFromStake({
          stakeId: stakeId,
          settings: settings,
          indexes: indexes
        });
      }
    }
  }
  /**
   * remove a list of tip indexes from a given stake
   * @param stakeId the stake id to remove tips from
   * @param indexes the list of indexes of tips to be removed from the list
   * @dev notice that the list of stakes will be mutated as each tip is removed
   * so you will have to calculate off chain where tips will move to or provide a list
   * such as [0, 0, 0] or decrementing [5,4,3,2,1,0] that will not be affected by the list mutating
   */
  function removeTipsFromStake(
    uint256 stakeId,
    uint256[] calldata indexes
  ) external payable {
    _removeTipsFromStake({
      stakeId: stakeId,
      settings: stakeIdToSettings[stakeId],
      indexes: indexes
    });
  }
  function _removeTipsFromStake(
    uint256 stakeId,
    uint256 settings,
    uint256[] memory indexes
  ) internal {
    // if the stake has already ended, we don't care
    // who sends funds back to staking address
    // only one who is incensed to unwind tips is the staker
    // but realistically, anyone can if they wish
    address staker;
    if (stakeIdInfo[stakeId] != ZERO) {
      _verifyStakeOwnership({
        owner: msg.sender,
        stakeId: stakeId
      });
      staker = msg.sender;
    } else {
      staker = tipStakeIdToStaker[stakeId];
    }
    uint256[] storage tips = stakeIdTips[stakeId];
    // this will fail if no tips exist
    uint256 tipsLast = tips.length - 1;
    uint256 len = indexes.length;
    uint256 i;
    do {
      uint256 index = indexes[i];
      uint256 tip = tips[index];
      if (tipsLast > index) {
        // if we are not currently targeting the last in the tips array
        // then we have to move tips around to prevent gaps in list
        tips[index] = tips[tipsLast];
      }
      tips.pop();
      unchecked {
        // now do something with the tip
        address token = address(indexToToken[tip << ONE >> INDEX_EXTERNAL_TIP_CURRENCY_ONLY]);
        _attributeFunds({
          token: token,
          settings: settings,
          staker: staker,
          amount: uint128(tip >> INDEX_EXTERNAL_TIP_LIMIT)
        });
        emit RemoveTip({
          stakeId: stakeId,
          token: token,
          index: index,
          settings: tip
        });
        // this overflows when tips are empty
        --tipsLast;
        ++i;
      }
    } while (i < len);
    if (tipsLast == MAX_UINT_256) {
      // remove from settings
      uint256 currentSettings = stakeIdToSettings[stakeId];
      unchecked {
        _logSettingsUpdate({
          stakeId: stakeId,
          settings: (
            (currentSettings >> INDEX_RIGHT_COPY_ITERATIONS << INDEX_RIGHT_COPY_ITERATIONS)
            // only remove information about the existance of a list
            // not whether or not to copy said list in subsequent stakes
            // should it exist again
            // in other words, copying remains in the hands of the staker
            | (uint8(currentSettings << TWO) >> TWO)
          )
        });
      }
    }
  }
  /**
   * create and back a tip with a given number of tokens
   * @param reusable the tip is reusable
   * @param token the token to use in the tip
   * @param stakeId the stake id to attribute the tip to
   * @param amount the number of tokens to tip
   * @param encodedLinear the (x/y)+b equation to use for determining the magnitude of the tip
   * @return the index of the tip in the list
   * @return the final tip amount
   */
  function addTipToStake(
    bool reusable,
    address token,
    uint256 stakeId,
    uint256 amount,
    uint256 encodedLinear
  ) external virtual payable returns(uint256, uint256) {
    _verifyTipAmountAllowed({
      stakeId: stakeId,
      amount: amount
    });
    _checkStakeCustodian({
      stakeId: stakeId
    });
    // deduct from sender account
    return _addTipToStake({
      reusable: reusable,
      token: token,
      account: msg.sender,
      stakeId: stakeId,
      amount: amount,
      encodedLinear: encodedLinear
    });
  }
  /**
   * verify that the inputs of the tip are allowed and will
   * not conflict with downstream requirements
   * @param stakeId the stake id to verify
   * @param amount the amount to verify. notice that zero cannot
   * be used unless the sender owns the stake. this is to prevent addresses
   * from taking other accounts funding
   * @return recipient who will be the effective owner of the tip
   */
  function _verifyTipAmountAllowed(uint256 stakeId, uint256 amount) internal view returns(address recipient) {
    (, recipient) = _stakeIdToInfo(stakeId);
    if (amount == ZERO) {
      if (msg.sender != recipient) {
        // cannot allow other people to take staker deposits
        revert NotAllowed();
      }
    }
  }
  /**
   * check that this contract is custodian of the given stake id
   * @param stakeId the stake id to check that this address is the custodian
   */
  function _checkStakeCustodian(uint256 stakeId) internal virtual view {
    if (_stakeCount({
      staker: address(this)
    }) == ZERO) {
      revert NotAllowed();
    }
    // cannot add a tip to a stake that has already ended
    // if (_stakeById(stakeId).stakeId != stakeId) {
    if (_getStake({
      custodian: address(this),
      index: _stakeIdToIndex({
        stakeId: stakeId
      })
    }).stakeId != stakeId) {
      revert NotAllowed();
    }
  }
  /**
   * create a tip and back it with given tokens
   * @param reusable the tip should be reused if it is not consumed during execution
   * @param token the token that is backing the tips value
   * @param account the account that is providing the tokens
   * @param stakeId the stake id to point the tip to
   * @param amount the number of tokens to back the tip
   * @param encodedLinear the (x/y)+b equation
   * @return index the index of the tip in the tips list
   * @return tipAmount the amount of tokens added to the tip
   */
  function _addTipToStake(
    bool reusable,
    address token,
    address account,
    uint256 stakeId,
    uint256 amount,
    uint256 encodedLinear
  ) internal returns(uint256 index, uint256 tipAmount) {
    tipAmount = _clamp({
      amount: amount,
      max: withdrawableBalanceOf[token][account]
    });
    if (tipAmount == ZERO) {
      return (ZERO, ZERO);
    }
    if (tipStakeIdToStaker[stakeId] == address(0)) {
      address owner = _stakeIdToOwner({
        stakeId: stakeId
      });
      tipStakeIdToStaker[stakeId] = owner;
    }
    // set the tip flag to 1
    // 0b00000001 | 0b10000000 => 0b10000001
    // 0b10000001 | 0b10000000 => 0b10000001
    uint256 currentSettings = stakeIdToSettings[stakeId];
    unchecked {
      uint256 updatedSettings = currentSettings | (ONE << INDEX_RIGHT_HAS_EXTERNAL_TIPS);
      if (updatedSettings != currentSettings) {
        _logSettingsUpdate({
          stakeId: stakeId,
          settings: updatedSettings
        });
      }
      // we do not change attributed here because the funds are still attributed
      // but the number will instead be stored in a tip
      withdrawableBalanceOf[token][account] -= tipAmount;
    }
    // settings must be provided with each addition
    // this result provides 15*basefee/2, up to 10m hedron as a contrived example
    // 0x0000000200000000002386f26fc10000000000000000000f0000000000000002
    uint256 currencyIndex = currencyToIndex[token];
    if (currencyIndex == ZERO) {
      if (token != address(0)) {
        revert NotAllowed();
      }
    }
    uint256 settings = _encodeTipSettings({
      reusable: reusable,
      currencyIndex: currencyIndex,
      amount: tipAmount,
      encodedLinear: encodedLinear
    });
    index = stakeIdTips[stakeId].length;
    stakeIdTips[stakeId].push(settings);
    emit AddTip({
      stakeId: stakeId,
      token: token,
      index: index,
      settings: settings
    });
    return (index, tipAmount);
  }
  // thank you for your contribution to the protocol
  // the mev bots smile upon thee
  receive() external payable {}
}
