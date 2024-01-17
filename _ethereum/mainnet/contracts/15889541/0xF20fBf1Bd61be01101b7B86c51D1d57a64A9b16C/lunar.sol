// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./Strings.sol";

contract Lunar is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 100_000_000_000_000 ether;
    uint256 public constant RESERVED_FOR_POOL_SUPPLY = 1_000_000_000_000 ether;
    uint256 public constant RESERVE_SUPPLY = 99_000_000_000_000 ether;

    address public constant ECOSYSTEM_ADDRESS = 0x7Cf1416F3D36326a3c4a8841C9a25Fd11681Ce4e;

    uint256 public _poolClaimed;
    address public _claimer;

    constructor() ERC20("Lunar", "LUNAR") {
        require(MAX_SUPPLY == RESERVE_SUPPLY + RESERVED_FOR_POOL_SUPPLY);

        _mint(ECOSYSTEM_ADDRESS, RESERVED_FOR_POOL_SUPPLY);
    }

    function poolClaim(address holder, uint256 amount) external {
        require(_claimer == msg.sender, "Not Claimer");
        require(_poolClaimed + amount <= RESERVE_SUPPLY, "Exceed supply");
        _poolClaimed += amount;
        _mint(holder, amount);
    }
    

    function sweepRestHolderShares() external onlyOwner {
        uint256 rest = RESERVE_SUPPLY - _poolClaimed;
        if (rest > 0) {
            _mint(ECOSYSTEM_ADDRESS, rest);
        }
    }

    function setClaimer(address claimer) external onlyOwner {
        _claimer = claimer;
    }
}