// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract Unfold is Context, Ownable, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_EMISSION_PER_YEAR_BP = 500;
    uint256 public EMISSION_PER_YEAR_BP = 500;
    uint256 public constant YEAR_DURATION = 365 days;
    uint256 public constant EMISSION_CLIFF = 1095 days;
    uint256 public nextEmissionTime = 0;

    constructor(uint256 _initial, address _governance) public ERC20('Unfold', 'UNFOLD') {
        _mint(_governance, _initial);
        transferOwnership(_governance);
        nextEmissionTime = block.timestamp.add(EMISSION_CLIFF);
    }

    function setEmissionPerYearBp(uint256 _bp) public onlyOwner {
        require(_bp <= MAX_EMISSION_PER_YEAR_BP, 'Unfold: Emission per year gt MAX_EMISSION_PER_YEAR_BP');
        EMISSION_PER_YEAR_BP = _bp;
    }

    function claimEmission() public onlyOwner {
        require(nextEmissionTime < block.timestamp, 'Unfold: Emission not available yet');
        _mint(_msgSender(), availableEmission());
        nextEmissionTime = block.timestamp.add(YEAR_DURATION);
    }

    function availableEmission() public view returns (uint256 amount) {
        amount = 0;
        if (nextEmissionTime < block.timestamp) {
            amount = totalSupply().mul(EMISSION_PER_YEAR_BP).div(10000);
        }
    }

    function recoverERC20(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
    }
}
