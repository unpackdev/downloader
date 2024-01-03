pragma solidity ^0.4.25;

/**
 * 
 * "Stash" (v0.2 beta)
 * A simple tool for a personal smart contract wallet to help protect your assets.
 * 
 * For more info checkout: https://squirrel.finance
 * 
 */


contract StashFactory {
    
    mapping(address => address) public stashes;
    address[] squirrels;
    
    
    function createStash(address squirrel) external {
        require(stashes[squirrel] == 0 && squirrel != 0);
        SquirrelStash stash = new SquirrelStash(squirrel);
        stashes[squirrel] = address(stash);
        squirrels.push(squirrel);
    }
    
    
    function getWhitelisted(address stashAddress, uint256 startIndex, uint256 endIndex) public view returns (address[], bool[2][]) {
        SquirrelStash stash = SquirrelStash(stashAddress);
        
        uint256 numWhitelists = (endIndex - startIndex) + 1;
        if (startIndex == 0 && endIndex == 0) {
            numWhitelists = stash.whitelistLength();
        }

        address[] memory list = new address[](numWhitelists);
        bool[2][] memory approved = new bool[2][](numWhitelists);
        for (uint256 i = 0; i < numWhitelists; i++) {
            address recipient = stash.whitelist(i + startIndex);
            list[i] = recipient;
            (, approved[i][0], approved[i][1]) = stash.whitelistedAddress(recipient);
        }
        return (list, approved);
    }
    
    
    function getAdmins(address stashAddress, uint256 startIndex, uint256 endIndex) public view returns (address[]) {
        SquirrelStash stash = SquirrelStash(stashAddress);
        
        uint256 numAdmins = (endIndex - startIndex) + 1;
        if (startIndex == 0 && endIndex == 0) {
            numAdmins = stash.adminsLength();
        }

        address[] memory list = new address[](numAdmins);
        for (uint256 i = 0; i < numAdmins; i++) {
            list[i] = stash.admins(i + startIndex);
        }
        return (list);
    }
    
    function getSquirrels(uint256 startIndex, uint256 endIndex) public view returns (address[]) {
        uint256 numSquirrels = (endIndex - startIndex) + 1;
        if (startIndex == 0 && endIndex == 0) {
            numSquirrels = squirrels.length;
        }

        address[] memory list = new address[](numSquirrels);
        for (uint256 i = 0; i < numSquirrels; i++) {
            list[i] = squirrels[i + startIndex];
        }
        return (list);
    }
    
    
    function getLatestHistory(address stashAddress, uint256 startIndex, uint256 amount) external view returns (address[], address[], uint256[8][], uint256) {
        SquirrelStash stash = SquirrelStash(stashAddress);
        
        uint256 toFetch = amount;
        if (stash.historyLength() < amount) {
            toFetch = stash.historyLength();
        }
        if (stash.historyLength() < startIndex + amount) {
            toFetch = stash.historyLength() - startIndex;
        }

        address[] memory recipients = new address[](toFetch);
        address[] memory tokens = new address[](toFetch);
        uint256[8][] memory extraData = new uint256[8][](toFetch);
        uint256 index = (stash.historyLength() - 1) - startIndex;
        for (uint256 i = 0; i < toFetch; i++) {
            setData1(recipients, tokens, index, i, stash);
            setData2(extraData, index, i, stash);
            setData3(extraData, index, i, stash);
        }

        return (recipients, tokens, extraData, stash.historyLength());
    }
    
    
    function setData1(address[] recipients, address[] tokens, uint256 index, uint256 i, SquirrelStash stash) internal view {
        (recipients[i], tokens[i], , , , , , , ) = stash.history(index - i);
    }
    
    function setData2(uint256[8][] extraData, uint256 index, uint256 i, SquirrelStash stash) internal view {
        (, , extraData[i][0], extraData[i][1], extraData[i][2], extraData[i][3], extraData[i][4], , ) = stash.history(index - i);
    }
    
    function setData3(uint256[8][] extraData, uint256 index, uint256 i, SquirrelStash stash) internal view {
        (, , , , , , , bool ethApproved, bool tokenApproved) = stash.history(index - i);
        extraData[i][5] = ethApproved ? 1 : 0;
        extraData[i][6] = tokenApproved ? 1 : 0;
        extraData[i][7] = index - i;
    }
    
}


contract SquirrelStash {

    mapping(address => uint256) public adminAddresses; // Can withdraw to whitelisted addresses only
    address[] public admins;
    
    address[] public whitelist;
    mapping(address => Whitelisted) public whitelistedAddress;
    mapping(address => bytes32) private addressPasswords; // Hashed
    mapping(uint256 => bytes32) private pendingPasswords;
    
    mapping(address => mapping(address => uint256)) private addressLimits;
    mapping(address => mapping(address => LimitUpdate)) private pendingLimitUpdate;
    
    mapping(address => mapping(address => uint256)) private limitEpochEnds;
    mapping(address => mapping(address => uint256)) private limitEpochSpent;
    
    uint8 constant public ACTION_EDIT_PASSWORD = 1;
    uint8 constant public ACTION_EDIT_ADMIN = 2;
    uint8 constant public ACTION_WITHDRAW_TOKEN = 3;
    uint8 constant public ACTION_WITHDRAW_ETH = 4;
    uint8 constant public ACTION_ADD_RECIPIENT = 5;
    uint8 constant public ACTION_EDIT_DELAY = 6;
    uint8 constant public ACTION_EDIT_LIMIT = 7;
    uint8 constant public ACTION_ADD_PLUGIN = 8;
    
    uint8 constant public STATE_PENDING = 0;
    uint8 constant public STATE_COMPLETED = 1;
    uint8 constant public STATE_CANCELLED = 2;
    
    History[] public history;
    uint256 public DELAY_TIMER = 3 days;
    uint128 constant public STASH_VERSION = 2;
    
    struct Whitelisted {
        uint128 index;
        bool ethApproved;
        bool tokenApproved;
    }
    
    struct LimitUpdate {
        uint128 etaTimestamp;
        uint128 limit;
    }
    
    struct History {
        address recipient;
        address token;
        uint8 action;
        uint8 state;
        uint128 amount;
        uint48 epoch;
        uint48 eta;
        bool ethApproved;
        bool tokenApproved;
    }

    modifier adminOnly() {
        require(adminAddresses[msg.sender] > 0);
        _;
    }
    
    constructor(address squirrel) public {
        admins.push(squirrel);
        adminAddresses[squirrel] = 1;
    }
    
    function() external payable { /** Accepts eth **/ }
    
    
    function whitelistAddress(address candidate, bool tokenApproved, bool ethApproved) external adminOnly {
        uint48 eta = uint48(now + DELAY_TIMER);
        history.push(History(candidate, msg.sender, ACTION_ADD_RECIPIENT, STATE_PENDING, 0, uint48(now), eta, tokenApproved, ethApproved));
    }


    function triggerWhiteListApproval(uint256 index, bool cancel) external adminOnly {
        History storage pending = history[index];
        require(pending.action == ACTION_ADD_RECIPIENT);
        require(pending.state == STATE_PENDING);
        if (cancel) {
            pending.state = STATE_CANCELLED;
        } else {
            if (pending.eta > 0 && pending.eta < now) {
                updateCandidate(pending);
                pending.state = STATE_COMPLETED;
            }
        }
    }
    
    function updateCandidate(History action) internal {
        address candidate = action.recipient;
        uint128 index = whitelistedAddress[candidate].index;
        bool approving = (action.ethApproved || action.tokenApproved);
        if (index == 0 && approving) {
            whitelist.push(candidate); // Add new recipient
            whitelistedAddress[candidate] = Whitelisted(uint128(whitelist.length), action.ethApproved, action.tokenApproved);
        } else if (index > 0) {
            if (approving) {
                Whitelisted memory data = whitelistedAddress[candidate];
                data.ethApproved = action.ethApproved;
                data.tokenApproved = action.tokenApproved;
                whitelistedAddress[candidate] = data;
            } else { // Removing from whitelist
                uint256 numWhitelisted = whitelist.length;
                delete whitelistedAddress[candidate];
                if (numWhitelisted > 1) {
                    whitelist[index - 1] = whitelist[numWhitelisted - 1];
                }
                delete whitelist[numWhitelisted - 1];
                whitelist.length--;
            }
        }
    }


    function editPassword(address candidate, bytes32 hash) external adminOnly {
        uint48 eta = uint48(now + DELAY_TIMER);
        pendingPasswords[history.length] = hash;
        history.push(History(candidate, msg.sender, ACTION_EDIT_PASSWORD, STATE_PENDING, 0, uint48(now), eta, hash != 0, false));
    }
    
    function triggerPasswordUpdate(uint256 index, bool cancel) external adminOnly {
        History storage pending = history[index];
        require(pending.action == ACTION_EDIT_PASSWORD);
        require(pending.state == STATE_PENDING);
        
        if (cancel) {
            pending.state = STATE_CANCELLED;
        } else {
            require(pending.eta > 0 && pending.eta < now);
            bytes32 newPassword = pendingPasswords[index];
            if (newPassword == keccak256("")) {
                delete addressPasswords[pending.recipient];
            } else {
                addressPasswords[pending.recipient] = newPassword;
            }
            delete pendingPasswords[index];
            pending.state = STATE_COMPLETED;
        }
    }
    

    function editAdmin(address candidate, bool isAdmin) external adminOnly {
        require(candidate != msg.sender); // Don't edit yourself
        
        if (isAdmin && adminAddresses[candidate] == 0) {
            admins.push(candidate); // Add new admin
            adminAddresses[candidate] = admins.length;
            history.push(History(candidate, msg.sender, ACTION_EDIT_ADMIN, STATE_COMPLETED, 0, uint48(now), 0, isAdmin, false));
        } else if (!isAdmin && adminAddresses[candidate] > 0) {
            uint48 eta = uint48(now + DELAY_TIMER); // Removing admin
            history.push(History(candidate, msg.sender, ACTION_EDIT_ADMIN, STATE_PENDING, 0, uint48(now), eta, false, false));
        }
    }
    
    function triggerAdminRemoval(uint256 index, bool cancel) external adminOnly {
        History storage pending = history[index];
        require(pending.action == ACTION_EDIT_ADMIN);
        require(pending.state == STATE_PENDING);
        
         if (cancel) {
            pending.state = STATE_CANCELLED;
        } else {
            require(pending.recipient != msg.sender); // Don't remove yourself
            require(pending.eta > 0 && pending.eta < now);
            uint256 numAdmins = admins.length;
            uint256 adminIndex = adminAddresses[pending.recipient] - 1;
            delete adminAddresses[pending.recipient]; // Remove old admin
            if (numAdmins > 1) {
                admins[adminIndex] = admins[numAdmins - 1];
            }
            delete admins[numAdmins - 1];
            admins.length--;
            pending.state = STATE_COMPLETED;
        }
    }
    
    
    function editWithdrawLimit(address candidate, address token, uint128 limit) external adminOnly {
        uint48 eta = uint48(now + DELAY_TIMER);
        pendingLimitUpdate[candidate][token] = LimitUpdate(eta, limit);
        history.push(History(candidate, token, ACTION_EDIT_LIMIT, STATE_PENDING, limit, uint48(now), eta, false, false));
    }
    
    function triggerLimitUpdate(uint256 index, bool cancel) external adminOnly {
        History storage pending = history[index];
        require(pending.action == ACTION_EDIT_LIMIT);
        require(pending.state == STATE_PENDING);
        
        if (cancel) {
            pending.state = STATE_CANCELLED;
        } else {
            require(pending.eta > 0 && pending.eta < now);
            if (pending.amount > 0) {
                addressLimits[pending.recipient][pending.token] = pending.amount;
            } else {
                delete addressLimits[pending.recipient][pending.token];
            }
            pending.state = STATE_COMPLETED;
        }
    }
    
    
    function editDelay(uint128 newDelay) external adminOnly {
        require(newDelay >= 24 hours && newDelay <= 30 days);
        uint48 eta = uint48(now + DELAY_TIMER);
        history.push(History(0, msg.sender, ACTION_EDIT_DELAY, STATE_PENDING, newDelay, uint48(now), eta, false, false));
    }
    
    function triggerDelayUpdate(uint256 index, bool cancel) external adminOnly {
        History storage pending = history[index];
        require(pending.action == ACTION_EDIT_DELAY);
        require(pending.state == STATE_PENDING);
        if (cancel) {
            pending.state = STATE_CANCELLED;
        } else {
            require(pending.eta > 0 && pending.eta < now);
            DELAY_TIMER = pending.amount;
            pending.state = STATE_COMPLETED;
        }
    }


    function withdrawToken(address recipient, address token, uint256 amount) external adminOnly {
        withdrawTokenInternal(recipient, token, amount);
    }
    
    function withdrawToken(address recipient, address token, uint256 amount, string password) external {
        validatePassword(recipient, password);
        withdrawTokenInternal(recipient, token, amount);
    }
    
    function withdrawTokenInternal(address recipient, address token, uint256 amount) internal {
        require(whitelistedAddress[recipient].tokenApproved);
        validateLimits(recipient, token, amount);
        history.push(History(recipient, token, ACTION_WITHDRAW_TOKEN, STATE_COMPLETED, uint128(amount), uint48(now), 0, false, false));
        ERC20(token).transfer(recipient, amount);
    }
    
    function withdrawEth(address recipient, uint256 amount) external adminOnly {
        withdrawEthInternal(recipient, amount);
    }
    
    function withdrawEth(address recipient, uint256 amount, string password) external {
        validatePassword(recipient, password);
        withdrawEthInternal(recipient, amount);
    }
    
    function withdrawEthInternal(address recipient, uint256 amount) internal {
        require(whitelistedAddress[recipient].ethApproved);
        validateLimits(recipient, 0, amount);
        history.push(History(recipient, 0, ACTION_WITHDRAW_ETH, STATE_COMPLETED, uint128(amount), uint48(now), 0, false, false));
        recipient.transfer(amount);
    }
    
    
    function validatePassword(address recipient, string password) view internal {
        bytes32 key = addressPasswords[recipient];
        require(key != 0);
        require(keccak256(password) == key);
    }
    
    function validateLimits(address recipient, address token, uint256 amount) internal {
        require(uint256(amount) == uint128(amount));
        uint256 limit = addressLimits[recipient][token];
        if (limit > 0) {
            if (limitEpochEnds[recipient][token] < now) {
                require(amount <= limit);
                limitEpochEnds[recipient][token] = now + 24 hours; // Daily withdrawal limit
                limitEpochSpent[recipient][token] = amount;
            } else {
                uint256 totalToday = amount + limitEpochSpent[recipient][token];
                require(totalToday <= limit);
                limitEpochSpent[recipient][token] = totalToday;
            }
        }
    }
    
    
    function hashed(address recipient) external view returns (bool) {
        return addressPasswords[recipient] != 0;
    }
    
    function adminsLength() public view returns (uint256) {
        return admins.length;
    }
    
    function whitelistLength() public view returns (uint256) {
        return whitelist.length;
    }
    
    function historyLength() public view returns (uint256) {
        return history.length;
    }
    
    
    /**
     * v0.2 DeFi Plugin stuff
     */
    
    mapping(address => bool) public whiteListedPlugins;
    PluginList constant plugins = PluginList(0x2459D608A7B7Eb695C78D4a40137bDeaD85D91c2);
    
    function whitelistPlugin(address candidateFactory) external adminOnly {
        require(plugins.isValid(candidateFactory));
        PluginFactory factory = PluginFactory(candidateFactory);
        address plugin = factory.createPlugin();
        uint48 eta = uint48(now + DELAY_TIMER);
        history.push(History(plugin, msg.sender, ACTION_ADD_PLUGIN, STATE_PENDING, 0, uint48(now), eta, false, false));
    }
    
    function triggerPluginApproval(uint256 index, bool cancel) external adminOnly {
        History storage pending = history[index];
        require(pending.action == ACTION_ADD_PLUGIN);
        require(pending.state == STATE_PENDING);
        if (cancel) {
            pending.state = STATE_CANCELLED;
        } else {
            if (pending.eta > 0 && pending.eta < now) {
                whiteListedPlugins[pending.recipient] = true;
                pending.state = STATE_COMPLETED;
            }
        }
    }
    
    function pluginEth(uint256 amount) external {
        require(whiteListedPlugins[msg.sender]);
        msg.sender.transfer(amount);
    }
    
    function pluginToken(address token, uint256 amount) external {
        require(whiteListedPlugins[msg.sender]);
        require(ERC20(token).transfer(msg.sender, amount));
    }
    
    
    
}


contract PluginList {
    function isValid(address candidate) external view returns (bool);
}




contract PluginFactory {
    function createPlugin() external returns(address);
}

contract ERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function balanceOf(address who) external view returns (uint256);
    
    string public symbol;
    uint8 public decimals;
}