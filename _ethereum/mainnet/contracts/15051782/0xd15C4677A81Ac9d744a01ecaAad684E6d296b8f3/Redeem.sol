// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IMVD.sol";

import "./MetaVaultAC.sol";

contract Redeem is MetaVaultAC {
    using SafeMath for uint256;

    address public principle; // Principle token
    address public mvd; // Staking token

    //address public MVD;
    //address public DAI;

    uint256 public RFV; // 272

    uint256 public mvdBurned;
    uint256 public dueDate = 1719724769; // Sun Jun 30 2024 05:19:29 GMT+0000

    constructor(
        address _mvd,
        address _principle,
        uint256 _RFV,
        address _authority
    ) MetaVaultAC(IMetaVaultAuthority(_authority)) {
        mvd = _mvd;
        principle = _principle;
        RFV = _RFV;
    }

    // _RFV must be given with 2 decimals -> $2.72 = 272
    function setRfv(uint256 _RFV) external onlyGovernor {
        RFV = _RFV;
    }

    function setTokens(address _mvd, address _principle) external onlyGovernor {
        mvd = _mvd;
        principle = _principle;
    }

    function setDueDate(uint256 _dueDate) external onlyGovernor {
        dueDate = _dueDate;
    }

    function transfer(
        address _to,
        uint256 _amount,
        address _token
    ) external onlyGovernor {
        require(_amount <= IERC20(_token).balanceOf(address(this)), "Not enough balance");

        IERC20(_token).transfer(_to, _amount);
    }

    // Amount must be given in MVD, which has 9 decimals
    function swap(uint256 _amount) external {
        require(block.timestamp <= dueDate, "Swap disabled.");

        require(_amount <= IERC20(mvd).balanceOf(msg.sender), "You need more MVD");
        require(_amount > 0, "amount is 0");

        require(IERC20(mvd).allowance(msg.sender, address(this)) >= _amount, "You need to approve this contract to spend your MVD");

        uint256 _value = _amount.mul(RFV).mul(10000000);

        require(_value <= IERC20(principle).balanceOf(address(this)), "Please wait or contact Metavault team");

        IMVD(mvd).burnFrom(msg.sender, _amount);

        mvdBurned = mvdBurned.add(_amount);

        IERC20(principle).transfer(msg.sender, _value);
    }
}
