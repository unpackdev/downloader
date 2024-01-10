// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";
import "./LibGetters.sol";

library LibRoundToken {

    /// @notice The Transfer Event.
    ///
    /// @param  _metaNftId  The Meta NFT ID.
    /// @param  _from       The address of the sender.
    /// @param  _to         The address of the recipient.
    /// @param  _value      The amount transferred.
    ///
    event Transfer(uint256 _metaNftId, address indexed _from, address indexed _to, uint128 _value);

    function _balanceOf(uint256 _metaNftId, address _account) internal view returns (uint128 _balance) {
        _balance = LibGetters._getPairInfo(_metaNftId).roundBalanceOf[_account];
    }

    function _mint(uint256 _metaNftId, address _to, uint128 _value) internal {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        pairInfo.roundTotalSupply += _value;
        pairInfo.roundBalanceOf[_to] += _value;
        emit Transfer(_metaNftId, address(0), _to, _value);
    }

    function _burn(uint256 _metaNftId, address _from, uint128 _value) internal {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        pairInfo.roundBalanceOf[_from] -= _value;
        pairInfo.roundTotalSupply -= _value;
        emit Transfer(_metaNftId, _from, address(0), _value);
    }

    function _transfer(uint256 _metaNftId, address _from, address _to, uint128 _value) internal {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);
        pairInfo.roundBalanceOf[_from] -= _value;
        pairInfo.roundBalanceOf[_to] += _value;
        emit Transfer(_metaNftId, _from, _to, _value);
    }
}
