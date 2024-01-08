// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

// ============ Contract information ============

/**
 * @title  CompoundAdapter
 * @notice Compound integrations for Greenwood interest rate swap pools
 * @author Greenwood Labs
 */

// ============ Imports ============

import "./SafeMath.sol";
import "./ICToken.sol";
import "./IAdapter.sol";
  
  
contract CompoundAdapter is IAdapter {

    using SafeMath for uint256;

    // ============ Immutable storage ============
     
    address public immutable factory;
    address public immutable governance;
    uint256 public constant TEN_EXP_18 = 1000000000000000000;
    uint256 public constant BLOCKS_PER_DAY = 6570;

    // ============ Mutable storage ============
    mapping(address => address) private cTokens;

    // ============ Constructor ============

    constructor(
        address _factory,
        address _governance
    ) {
        factory = _factory;
        governance = _governance;
    }

    // ============ External methods ============

    // ============ Get the current variable borrow rate ============

    function getBorrowRate(address _market) external view override returns(uint256) {
        
        // look up the ctoken address of the specified underlier
        address cToken = cTokens[_market];

        // get the borrow rate per block from the cToken
        uint256 rate = ICToken(cToken).borrowRatePerBlock();

        // calculate term 0
        uint256 t0 = rate.mul(BLOCKS_PER_DAY).add(TEN_EXP_18);

        // calculate term 1
        uint256 t1 = t0.mul(t0).div(TEN_EXP_18);

        // exponentiate using a loop
        for (uint256 i=0; i<362; i++) {
            t1 = t1.mul(t0).div(TEN_EXP_18);
        }

        // calculate term 2 
        return t1.sub(TEN_EXP_18);
    }

    // ============ Get the current borrow index ============

    function getBorrowIndex(address _market) external view override returns(uint256) {

        // look up the ctoken address of the specified underlier
        address cToken = cTokens[_market];

        // return the borrowindex
        return ICToken(cToken).borrowIndex();
    }

    // ============ Update the cTokens mapping ============

    function updateCTokens(address _market, address _c_token) external returns(bool) {

        // assert the the method caller is governance
        require(msg.sender == governance, "GreenwoodIRSAdapter: INVALID_SENDER");

        // uodate the cTokens mapping
        cTokens[_market] = _c_token;

        return true;
    }

}