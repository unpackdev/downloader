// SPDX-License-Identifier: Apache 2.

// source can be found at: https://github.com/twtaylor/ethw-promissory-note

import "./ERC20.sol";
import "./IWETH.sol";

pragma solidity 0.8.17;

contract wETHPow is ERC20 {

    address public immutable WETH;

    mapping(address => uint256) public originalOwnerNotes;

    event Mint(address indexed sender, uint256 amount);

    constructor(address _WETH) ERC20("ETHw Promissory Note", "wETHPow") {
        WETH = _WETH;
    }

    modifier isEthereumMainnetPreFork() {
        require(block.chainid == 1 && 2**64 >= block.difficulty, "NOT_ETH_PREFORK");
        _;
    }

    modifier isEthereumMainnetPostFork() {
        require(block.chainid == 1, "NOT_MAINCHAIN");

        // set as a fail-safe for October 15th, let any owner burn at that point
        if (1665840433 >= block.timestamp) {
            require(block.difficulty > 2**64, "PRE_MERGE");
        }
        _;
    }

    modifier isEthereumWPostFork() {
        require(block.chainid == 10001, "NOT_FORK_CHAIN");
        _;
    }

    function mint(uint256 amount) public isEthereumMainnetPreFork() {
        assert(IWETH(WETH).transferFrom(msg.sender, address(this), amount));

        __mint(msg.sender, amount);
    }

    function mintWithEth() public payable isEthereumMainnetPreFork() {
        IWETH(WETH).deposit{value: msg.value}();

        __mint(msg.sender, msg.value);
    }

    function __mint(address orig, uint256 amount) internal {
        originalOwnerNotes[orig] += amount;

        _mint(orig, amount);

        emit Mint(orig, amount);
    }

    // post-fork chainid = 1 burn
    function burnPostForkOnEth(address to, uint256 amount) public isEthereumMainnetPostFork() {
        require(originalOwnerNotes[msg.sender] >= amount, "NO_BAL");

        originalOwnerNotes[msg.sender] -= amount;

        assert(IWETH(WETH).transfer(to, amount));
    }

    // post-fork chainid = 10001 burn
    function burnPostForkOnEthW(address to, uint256 amount) public isEthereumWPostFork() {
        _burn(msg.sender, amount);

        assert(IWETH(WETH).transfer(to, amount));
    }

    // pre-fork chainid = 1 burn
    function burnPreForkOnEth(address to, uint256 amount) public isEthereumMainnetPreFork() {
        require(originalOwnerNotes[msg.sender] >= amount, "NO_NOTE");

        _burn(msg.sender, amount);

        originalOwnerNotes[msg.sender] -= amount;

        assert(IWETH(WETH).transfer(to, amount));
    }
}
