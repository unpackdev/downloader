// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface Lido {
    /**
     * @notice Send funds to the pool with optional _referral parameter
     * @dev This function is alternative way to submit funds. Supports optional referral address.
     * @return Amount of StETH shares generated
     */
    function submit(address) external payable returns (uint256);

    /**
     * @return the amount of tokens owned by the `_account`.
     *
     * @dev Balances are dynamic and equal the `_account`'s share in the amount of the
     * total Ether controlled by the protocol. See `sharesOf`.
     */
    function balanceOf(address) external view returns (uint256);

    function getPooledEthByShares(uint256) external view returns (uint256);
}

library StEthMarket {

    address constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function balanceOf(address _account) internal view returns (uint256) {
        return Lido(stETH).balanceOf(_account);     
    }    

    function submit(address _referral, uint256 _value) internal returns (uint256) {
        uint256 shareAmount = Lido(stETH).submit{ value: _value }(_referral);
        return Lido(stETH).getPooledEthByShares(shareAmount);
    }
}