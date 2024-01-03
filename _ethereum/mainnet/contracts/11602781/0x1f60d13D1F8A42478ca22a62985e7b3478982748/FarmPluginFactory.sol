pragma solidity ^0.4.25;

/**
 *
 * This was a concept plugin for farming BOND with USDC via Stash. Unfortunately Insure deposits require tx.origin == msg.sender, so this plugin will not work in its current form.
 * (Contract was verified just for transparency)
 *
 * For more info checkout: https://squirrel.finance
 *
 */

contract FarmPluginFactory {

    mapping(address => address) public plugins;
    address[] stashes;

    function createPlugin() external returns(address) {
        if (plugins[msg.sender] == 0) {
            FarmPlugin plugin = new FarmPlugin(msg.sender);
            plugins[msg.sender] = plugin;
            stashes.push(msg.sender);
            return plugin;
        } else {
            return plugins[msg.sender];
        }
    }

    function getStashes(uint256 startIndex, uint256 endIndex) public view returns (address[]) {
        uint256 numStashes = (endIndex - startIndex) + 1;
        if (startIndex == 0 && endIndex == 0) {
            numStashes = stashes.length;
        }

        address[] memory list = new address[](numStashes);
        for (uint256 i = 0; i < numStashes; i++) {
            list[i] = stashes[i + startIndex];
        }
        return (list);
    }
}



contract FarmPlugin {

    ERC20 usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 bond = ERC20(0x0391D2021f89DC339F60Fff84546EA23E337750f);

    SquirrelBondFarm bondFarm = SquirrelBondFarm(0x54f84Fb988e2b246150b13b6B5e55a0737D20CdA);
    SquirrelStash stash;

    constructor(address stashAddress) public {
        stash = SquirrelStash(stashAddress);
        usdc.approve(bondFarm, 2 ** 255);
    }

    modifier adminOnly() {
        require(stash.adminAddresses(msg.sender) > 0);
        _;
    }

    function stake(uint256 amount) external adminOnly {
        stash.pluginToken(usdc, amount);
        bondFarm.deposit(amount);
    }

    function claimYield() external adminOnly {
        bondFarm.claimYield();
        bond.transfer(stash, bond.balanceOf(this));
    }

    function cashout(uint256 amount) external adminOnly {
        bondFarm.cashout(amount);
        usdc.transfer(stash, usdc.balanceOf(this));
        uint256 bonds = bond.balanceOf(this);
        if (bonds > 0) {
            bond.transfer(stash, bonds);
        }
    }

}


contract SquirrelBondFarm {
    function deposit(uint256 amount) external;
    function claimYield() public;
    function cashout(uint256 amount) external;
}


contract SquirrelStash {
    mapping(address => uint256) public adminAddresses;
    function pluginToken(address token, uint256 amount) external;
}


contract ERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function balanceOf(address who) external view returns (uint256);

    string public symbol;
    uint8 public decimals;
}