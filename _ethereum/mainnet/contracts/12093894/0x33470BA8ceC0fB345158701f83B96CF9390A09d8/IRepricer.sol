// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity 0.7.6;

import "./IVault.sol";

interface IRepricer {

    function isRepricer() external pure returns(bool);

    function symbol() external pure returns (string memory);

    function reprice(
        uint _pMin,
        int _volatility,
        IVault _vault,
        uint[2] memory _primary,
        uint[2] memory _complement,
        int _liveUnderlingValue
    )
    external view returns(
        uint newPrimaryLeverage, uint newComplementLeverage, int estPricePrimary, int estPriceComplement
    );
}
