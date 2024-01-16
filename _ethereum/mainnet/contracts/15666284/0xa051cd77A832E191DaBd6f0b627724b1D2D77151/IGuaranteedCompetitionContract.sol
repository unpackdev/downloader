// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Metadata.sol";
import "./IRegularCompetitionContract.sol";

interface IGuaranteedCompetitionContract is IRegularCompetitionContract {
    function setMaxEntrantAndGuaranteedFee(
        uint256 _guaranteedFee,
        uint256 _maxEntrant
    ) external;
}
