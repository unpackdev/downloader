pragma solidity ^0.4.25;

/**
 *
 * "Stash" (v0.2 beta)
 * A simple tool for a personal smart contract wallet to help protect your assets.
 *
 * For more info checkout: https://squirrel.finance
 *
 */

contract InsurePluginFactory {

    mapping(address => address) public plugins;
    address[] stashes;

    function createPlugin() external returns(address) {
        if (plugins[msg.sender] == 0) {
            InsurePlugin plugin = new InsurePlugin(msg.sender);
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



contract InsurePlugin {

    ERC20 bond = ERC20(0x0391D2021f89DC339F60Fff84546EA23E337750f);

    SquirrelBondInsure bondInsure = SquirrelBondInsure(0x4b70388eAbb6b7596dcF78e9C8DFb6328B5442a1);
    SquirrelStash stash;

    constructor(address stashAddress) public {
        stash = SquirrelStash(stashAddress);
    }

    modifier adminOnly() {
        require(stash.adminAddresses(msg.sender) > 0);
        _;
    }
    
    function() external payable { /** Accepts eth **/ }

    function stake(uint256 amount) external adminOnly {
        stash.pluginEth(amount);
        bondInsure.deposit.value(amount)(this);
    }

    function claimYield() external adminOnly {
        bondInsure.claimYield();
        bond.transfer(stash, bond.balanceOf(this));
    }

    function beginCashout(uint256 amount) external adminOnly {
        bondInsure.beginCashout(amount);
        uint256 bonds = bond.balanceOf(this);
        if (bonds > 0) {
            bond.transfer(stash, bonds);
        }
    }
    
    function doCashout() external adminOnly {
        bondInsure.doCashout();
        address(stash).transfer(address(this).balance);
    }

}


contract SquirrelBondInsure {
    function deposit(address recipient) payable external;
    function claimYield() public;
    function beginCashout(uint256 amount) external;
    function doCashout() external;
}


contract SquirrelStash {
    mapping(address => uint256) public adminAddresses;
    function() external payable { /** Accepts eth **/ }
    function pluginEth(uint256 amount) external;
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