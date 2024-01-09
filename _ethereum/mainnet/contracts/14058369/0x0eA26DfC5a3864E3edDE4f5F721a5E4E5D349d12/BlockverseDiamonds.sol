// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IBlockverseDiamonds.sol";
import "./IBlockverseStaking.sol";

contract BlockverseDiamonds is ERC20, IBlockverseDiamonds, Ownable, ReentrancyGuard {
    IBlockverseStaking staking;

    constructor() ERC20("Blockverse Diamonds", "DIAMOND") {}

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function mint(address to, uint256 amount) external override nonReentrant requireContractsSet {
        require(_msgSender() == address(staking) || _msgSender() == owner(), "Not authorized");

        _mint(to, amount);
    }

    // SETUP
    modifier requireContractsSet() {
        require(address(staking) != address(0), "Contracts not set");
        _;
    }

    function setContracts(address _staking) external onlyOwner {
        staking = IBlockverseStaking(_staking);
    }
}
