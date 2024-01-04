// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

import "./console.sol";

interface IPondCoin is IERC20 {
    function mint(address to, uint256 amount) external;
    function endMinting() external;
}

interface IPondCoinSpawner {
    function spawn(address invoker, uint256 amount) external returns (bool);
}

contract PondCoin is IERC20, ERC20, IPondCoin {
    address public minter;

    address public constant distilleryAddress = 0x17CC6042605381c158D2adab487434Bde79Aa61C;
    uint256 public constant maxSupply = 420690000000000000000000000000000;

    constructor() ERC20("PondCoin", "PNDC") {
        minter = msg.sender;
    }

    function _safeMint(address to, uint256 amount) internal {
        _mint(to, amount);
        require(totalSupply() <= maxSupply, "Too Much Supply");
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == minter, "Not Minter");
        _safeMint(to, amount);
    }

    function endMinting() public {
        require(msg.sender == minter, "Not Minter");
        minter = address(0);

        if (totalSupply() < maxSupply) {
            _safeMint(distilleryAddress, maxSupply - totalSupply());
        }
    }

    function useSpawner(uint256 amount, IPondCoinSpawner spawner) external {
        // console.log("FROM", msg.sender);
        // console.log(">>BAL", balanceOf(msg.sender));
        // console.log(">>ALLOWANCE", allowanceOf(msg.sender));

        require(transferFrom(msg.sender, distilleryAddress, amount), "Could Not Send");
        require(spawner.spawn(msg.sender, amount), "Could Not Spawn");
    }
}
