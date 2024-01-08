// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ISuper1155.sol";

/**
  @title TokenRedeemer
  @author 0xthrpw

  This contract allows an erc1155 of a given group to be redeemed or burned
  in exchange for a token from a new group
*/
contract TokenRedeemer is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  ISuper1155 public super1155;

  address public burnAddress;

  bool public customBurn;

  struct RedemptionConfig {
    uint256 amountOut;
    bool burnOnRedemption;
  }

  // groupIdIn => groupIdOut => config
  mapping (uint256 => mapping(uint256 => RedemptionConfig)) public redemptionConfigs;

  // groupId => tokenId => redeemer
  mapping (uint256 => mapping(uint256 => address)) public redeemers;

  // groupId => tokenId => redeemed
  mapping (uint256 => mapping(uint256 => bool)) public redeemed;

  event TokenRedemption(address user, uint256 tokenIn, uint256[] tokensOut);
  event ConfigUpdate(uint256 groupIdIn, uint256 groupIdOut, uint256 amountOut, bool burnOnRedemption);

  /**
    On deployment, set `_super1155` as the token to redeem,  set the burn
    address as `_burnTarget` and enable use of a custom burn address by setting
    _customBurn

    @param _super1155 The token for which this contract will allow redemptions
    @param _burnTarget The address that will be used for burning tokens
    @param _customBurn Boolean for enabling a custom burn address
  */
  constructor(ISuper1155 _super1155, address _burnTarget, bool _customBurn) public {
    super1155 = _super1155;
    customBurn = _customBurn;
    if(customBurn){
      require(_burnTarget != address(0), "TokenRedeemer::constructor: Custom burn address cannot be 0 address");
      burnAddress = _burnTarget;
    }
  }

  /**
    Redeem a specific token `_tokenId` for a token from group `_groupIdOut`

    @param _tokenId The bitpacked 1155 token id
    @param _groupIdOut The group id of the token to receive
  */
  function redeem(uint256 _tokenId, uint256 _groupIdOut) external nonReentrant {
    _redeemToken(_tokenId, _groupIdOut);
  }

  /**
    Redeem a specific set of tokens `_tokenIds` for a set of token from group `_groupIdOut`

    @param _tokenIds An array of bitpacked 1155 token ids
    @param _groupIdOut The group id of the token to receive
  */
  function redeemMult(uint256[] calldata _tokenIds, uint256 _groupIdOut) external nonReentrant {
    for(uint256 n = 0; n < _tokenIds.length; n++){
      _redeemToken(_tokenIds[n], _groupIdOut);
    }
  }

  /**
    Redeem a token for n number of tokens in return.  This function parses the
    tokens group id, determines the appropriate exchange token and amount, if
    necessary burns the deposited token and mints the receipt token(s)

    @param _tokenId The bitpacked 1155 token id
    @param _groupIdOut The group ID of the token being received
  */
  function _redeemToken(uint256 _tokenId, uint256 _groupIdOut) internal {
    uint256 _groupIdIn = _tokenId >> 128;
    require(!redeemed[_groupIdOut][_tokenId], "TokenRedeemer::redeem: token has already been redeemed for this group" );

    RedemptionConfig memory config = redemptionConfigs[_groupIdIn][_groupIdOut];
    uint256 redemptionAmount = config.amountOut;

    {
      require(_groupIdOut != uint256(0), "TokenRedeemer::redeem: invalid group id from token");
      require(redemptionAmount != uint256(0), "TokenRedeemer::redeem: invalid redemption amount");

      uint256 balanceOfSender = super1155.balanceOf(address(msg.sender), _tokenId);
      require(balanceOfSender != 0, "TokenRedeemer::redeem: msg sender is not token owner");
    }

    (bool groupInit, , , , , , , , , uint256 mintCount,) = super1155.itemGroups(_groupIdOut);
    require(groupInit, "TokenRedeemer::redeem: item group not initialized");

    uint256[] memory ids = new uint256[](redemptionAmount);
    uint256[] memory amounts = new uint[](redemptionAmount);

    uint256 newgroupIdPrep = _groupIdOut << 128;
    for(uint256 i = 0; i < redemptionAmount; i++){
      ids[i] = newgroupIdPrep.add(mintCount).add(1).add(i);
      amounts[i] = uint256(1);
    }

    redeemers[_groupIdOut][_tokenId] = address(msg.sender);
    redeemed[_groupIdOut][_tokenId] = true;

    if(config.burnOnRedemption){
      if(customBurn){
        super1155.safeTransferFrom(msg.sender, burnAddress, _tokenId, 1, "");
      }else{
        super1155.burnBatch(msg.sender, _asSingletonArray(_tokenId), _asSingletonArray(1));
      }
    }

    super1155.mintBatch(msg.sender, ids, amounts, "");

    emit TokenRedemption(msg.sender, _tokenId, ids);
  }

  /**
    Configure redemption amounts for each group.  ONE token of _groupIdin results
    in _amountOut number of _groupIdOut tokens

    @param _groupIdIn The group ID of the token being redeemed
    @param _groupIdIn The group ID of the token being received
    @param _data The redemption config data input.
  */

  function setRedemptionConfig(uint256 _groupIdIn, uint256 _groupIdOut, RedemptionConfig calldata _data) external onlyOwner {
    require(_groupIdIn != _groupIdOut, "TokenRedeemer:setRedemptionAmounts: token in must be different from token out");

    redemptionConfigs[_groupIdIn][_groupIdOut] = RedemptionConfig({
      amountOut: _data.amountOut,
      burnOnRedemption: _data.burnOnRedemption
    });

    emit ConfigUpdate(_groupIdIn, _groupIdOut, _data.amountOut, _data.burnOnRedemption);
  }

  /**
    This private helper function converts a number into a single-element array.

    @param _element The element to convert to an array.
    @return The array containing the single `_element`.
  */
  function _asSingletonArray(uint256 _element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = _element;
    return array;
  }
}
