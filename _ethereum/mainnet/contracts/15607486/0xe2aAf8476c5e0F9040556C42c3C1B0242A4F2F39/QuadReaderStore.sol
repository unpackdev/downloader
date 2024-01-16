//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./IQuadPassport.sol";
import "./IQuadGovernance.sol";

import "./QuadConstant.sol";

contract QuadReaderStore is QuadConstant{
    IQuadGovernance public governance;
    IQuadPassport public passport;
}
