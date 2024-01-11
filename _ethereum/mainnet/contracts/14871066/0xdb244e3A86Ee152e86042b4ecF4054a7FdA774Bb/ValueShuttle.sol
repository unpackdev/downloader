// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8;
import {IERC20}          from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MinimalValueShuttle {

    event ValueShuttled(
        uint256 indexed time,
        uint256 indexed value
    );

    address public immutable staking;
    address public immutable token;
    address public immutable treasury;

    constructor(
        address _staking,
        address _token,
        address _treasury
    ) {
        staking     = _staking;
        token       = _token;
        treasury    = _treasury;
    }

    function valueAccumulated() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function shuttleValue() external returns (uint256 totalValue) {
        require(msg.sender == staking, "!STAKING");
        totalValue = valueAccumulated();
        require(IERC20(token).transfer(treasury, totalValue), "!TRANSFER");
        emit ValueShuttled(block.timestamp,totalValue);
    }
}