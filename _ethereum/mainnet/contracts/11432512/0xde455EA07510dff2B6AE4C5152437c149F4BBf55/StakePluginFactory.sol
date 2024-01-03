pragma solidity ^0.4.25;

/**
 * 
 * "Stash" (v0.2 beta)
 * A simple tool for a personal smart contract wallet to help protect your assets.
 * 
 * For more info checkout: https://squirrel.finance
 * 
 */

contract StakePluginFactory {
    
    mapping(address => address) public plugins;
    address[] stashes;
    
    function createPlugin() external returns(address) {
        if (plugins[msg.sender] == 0) {
            StakePlugin plugin = new StakePlugin(msg.sender);
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



contract StakePlugin {
    
    ERC20 nuts = ERC20(0x84294FC9710e1252d407d3D80A84bC39001bd4A8);
    ERC20 bond = ERC20(0x0391D2021f89DC339F60Fff84546EA23E337750f);
    
    NutsStaking nutsStaking = NutsStaking(0x07f2479b209461A8b624A536902F396F631007e9);
    SquirrelStash stash;
    
    constructor(address stashAddress) public {
        stash = SquirrelStash(stashAddress);
    }
    
    modifier adminOnly() {
        require(stash.adminAddresses(msg.sender) > 0);
        _;
    }
    
    function stake(uint256 amount) external adminOnly {
        stash.pluginToken(nuts, amount);
        bytes memory empty;
        nuts.approveAndCall(nutsStaking, amount, empty);
    }
    
    function claimYield() external adminOnly {
        nutsStaking.claimYield();
        bond.transfer(stash, bond.balanceOf(this));
    }
    
    function cashout(uint256 amount) external adminOnly {
        nutsStaking.cashout(amount);
        nuts.transfer(stash, nuts.balanceOf(this));
        uint256 bonds = bond.balanceOf(this);
        if (bonds > 0) {
            bond.transfer(stash, bonds);
        }
    }
    
}




contract NutsStaking {
    function receiveApproval(address player, uint256 amount, address, bytes) external;
    function cashout(uint256 amount) external;
    function claimYield() public;
    function dividendsOf(address farmer) view public returns (uint256);
    mapping(address => uint256) public balances;
}



contract PluginFactory {
    function createPlugin(address stash) external returns(address);
}

contract ERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function balanceOf(address who) external view returns (uint256);
    
    string public symbol;
    uint8 public decimals;
}

contract SquirrelStash {
    mapping(address => uint256) public adminAddresses; // Can withdraw to whitelisted addresses only
    function pluginToken(address token, uint256 amount) external;
}