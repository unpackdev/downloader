// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

import "./ISuper1155.sol";

/**
  @title TokenRedeemer: a contract for redeeming ERC-1155 token claims with
    optional burns.
  @author 0xthrpw
  @author Tim Clancy

  This contract allows a specific ERC-1155 token of a given group ID to be
  redeemed or burned in exchange for a new token from a new group in an
  optionally-new ERC-1155 token contract.
*/
contract TokenRedeemer is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  /// The smart contract being used in redemptions.
  ISuper1155 public super1155;

  /// The address being used as a custom burn address.
  address public burnAddress;

  bool public customBurn;

  /**
  */
  struct RedemptionConfig {
    uint256 groupIdOut;
    uint256 amountOut;
    bool burnOnRedemption;
  }

  // groupIdIn => collection out => config
  mapping (uint256 => mapping(address => RedemptionConfig)) public redemptionConfigs;

  // collection out => tokenId in => address of redeemer
  mapping (address => mapping (uint256 => address)) public redeemer;

  /**
  */
  event TokenRedemption(address indexed user, uint256 indexed tokenIn, address indexed contractOut, uint256[] tokensOut);

  /**
  */
  event ConfigUpdate(uint256 groupIdIn, uint256 groupIdOut, address tokenOut, uint256 amountOut, bool burnOnRedemption);

  /**
    On deployment, set `_super1155` as the collection to redeem,  set the burn
    address as `_burnTarget` and enable use of a custom burn address by setting
    `_customBurn`.

    @param _super1155 The item collection for which this contract will allow
      redemptions.
    @param _burnTarget The address that will be used for burning tokens.
    @param _customBurn Whether or not a custom burn address is used.
  */
  constructor(ISuper1155 _super1155, address _burnTarget, bool _customBurn) public {
    super1155 = _super1155;
    customBurn = _customBurn;
    if (customBurn) {
      require(_burnTarget != address(0), "TokenRedeemer::constructor: Custom burn address cannot be 0 address");
      burnAddress = _burnTarget;
    }
  }

  /**
    Redeem a specific token `_tokenId` for a token from group `_groupIdOut`

    @param _tokenId The bitpacked 1155 token id
    @param _tokenOut The address of the token to receive
  */
  function redeem(uint256 _tokenId, address _tokenOut) external nonReentrant {
    _redeemToken(_tokenId, _tokenOut);
  }

  /**
    Redeem a specific set of tokens `_tokenIds` for a set of token from group `_groupIdOut`

    @param _tokenIds An array of bitpacked 1155 token ids
    @param _tokenOut The address of the token to receive
  */
  function redeemMult(uint256[] calldata _tokenIds, address _tokenOut) external nonReentrant {
    for(uint256 n = 0; n < _tokenIds.length; n++){
      _redeemToken(_tokenIds[n], _tokenOut);
    }
  }

  /**
    Redeem a token for n number of tokens in return.  This function parses the
    tokens group id, determines the appropriate exchange token and amount, if
    necessary burns the deposited token and mints the receipt token(s)

    @param _tokenId The bitpacked 1155 token id
    @param _tokenOut The address of the token being received
  */
  function _redeemToken(uint256 _tokenId, address _tokenOut) internal {
    uint256 _groupIdIn = _tokenId >> 128;
    require(redeemer[_tokenOut][_tokenId] == address(0), "TokenRedeemer::redeem: token has already been redeemed for this group" );

    RedemptionConfig memory config = redemptionConfigs[_groupIdIn][_tokenOut];
    uint256 redemptionAmount = config.amountOut;
    uint256 groupIdOut = config.groupIdOut;

    {
      require(groupIdOut != uint256(0), "TokenRedeemer::redeem: invalid group id from token");
      require(redemptionAmount != uint256(0), "TokenRedeemer::redeem: invalid redemption amount");

      uint256 balanceOfSender = super1155.balanceOf(_msgSender(), _tokenId);
      require(balanceOfSender != 0, "TokenRedeemer::redeem: msg sender is not token owner");
    }

    (bool groupInit, , , , , , , , , uint256 mintCount,) = ISuper1155(_tokenOut).itemGroups(groupIdOut);
    require(groupInit, "TokenRedeemer::redeem: item group not initialized");

    uint256[] memory ids = new uint256[](redemptionAmount);
    uint256[] memory amounts = new uint[](redemptionAmount);

    uint256 newgroupIdPrep = groupIdOut << 128;
    for(uint256 i = 0; i < redemptionAmount; i++) {
      ids[i] = newgroupIdPrep.add(mintCount).add(1).add(i);
      amounts[i] = uint256(1);
    }

    redeemer[_tokenOut][_tokenId] = _msgSender();

    if (config.burnOnRedemption) {
      if (customBurn) {
        super1155.safeTransferFrom(msg.sender, burnAddress, _tokenId, 1, "");
      } else {
        super1155.burnBatch(msg.sender, _asSingletonArray(_tokenId), _asSingletonArray(1));
      }
    }

    ISuper1155(_tokenOut).mintBatch(msg.sender, ids, amounts, "");

    emit TokenRedemption(msg.sender, _tokenId, _tokenOut, ids);
  }

  /**
    Configure redemption amounts for each group.  ONE token of _groupIdin results
    in _amountOut number of _groupIdOut tokens

    @param _groupIdIn The group ID of the token being redeemed
    @param _groupIdIn The group ID of the token being received
    @param _data The redemption config data input.
  */

  function setRedemptionConfig(uint256 _groupIdIn, uint256 _groupIdOut, address _tokenOut, RedemptionConfig calldata _data) external onlyOwner {
    redemptionConfigs[_groupIdIn][_tokenOut] = RedemptionConfig({
      groupIdOut: _groupIdOut,
      amountOut: _data.amountOut,
      burnOnRedemption: _data.burnOnRedemption
    });

    // uint256 groupId;
    // uint256 amountOut;
    // bool burnOnRedemption;

    emit ConfigUpdate(_groupIdIn, _groupIdOut, _tokenOut, _data.amountOut, _data.burnOnRedemption);
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
