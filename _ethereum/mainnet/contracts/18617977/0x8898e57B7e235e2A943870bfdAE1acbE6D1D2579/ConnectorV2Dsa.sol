// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./Interfaces.sol";

// ConnectorId : 0
contract ConnectorV2Dsa {
    using SafeERC20 for IERC20;

    /* ========== Layout ========== */
    address public owner;
    address public doughV2Index = address(0);

    /* ========== Constant ========== */
    address private constant _ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address private constant _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _doughV2Index) {
        if (_doughV2Index == address(0)) revert CustomError("invalid _doughV2Index");
        doughV2Index = _doughV2Index;
    }

    /* ========== FUNCTIONS ========== */
    function getOwner() public view returns (address) {
        return IDoughV2Index(doughV2Index).owner();
    }

    function withdrawToken(address _tokenAddr, uint256 _amount) external {
        if (msg.sender != getOwner()) revert CustomError("ConnectorV2Dsa: not owner of doughV2Index");
        if (_amount == 0 || _amount > IERC20(_tokenAddr).balanceOf(address(this))) revert CustomError("ConnectorV2Dsa:withdrawTokenFromDsa: invalid amount");
        IERC20(_tokenAddr).safeTransfer(getOwner(), _amount);
    }

    // delegate Call
    function delegateDoughCall(uint256 _actionId, address _token, uint256 _amount, bool _opt) external payable {
        if (_amount == 0) revert CustomError("ConnectorV2Dsa: invalid amount");
        if (_actionId > 1) revert CustomError("ConnectorV2Dsa: invalid actionId");
        if (_token == address(0)) revert CustomError("ConnectorV2Dsa: invalid token1");
        if (_opt) revert CustomError("ConnectorV2Dsa: invalid option");

        if (_actionId == 0) {
            // withdrawEthFromDsa
            if (_token != _ETH) revert CustomError("ConnectorV2Dsa: withdrawEthFromDsa: invalid token");
            if (_amount > address(this).balance) revert CustomError("ConnectorV2Dsa: withdrawEthFromDsa: invalid amount");
            payable(owner).transfer(_amount);
        } else {
            // withdrawTokenFromDsa
            if (_amount > IERC20(_token).balanceOf(address(this))) revert CustomError("ConnectorV2Dsa: withdrawTokenFromDsa: invalid amount");
            if (_token == _WETH) {
                IWETH(_WETH).withdraw(_amount);
                payable(owner).transfer(_amount);
            } else {
                IERC20(_token).safeTransfer(owner, _amount);
            }
        }
    }
}
