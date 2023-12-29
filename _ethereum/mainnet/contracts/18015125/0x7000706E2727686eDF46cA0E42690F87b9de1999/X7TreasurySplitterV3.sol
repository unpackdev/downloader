// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract representing the treasury (v3)

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function freezeOutlet(Outlet outlet) external onlyOwner {
        require(outlet != Outlet.OTHER_SLOT1 && outlet != Outlet.OTHER_SLOT2 && outlet != Outlet.NONE);
        require(!outletFrozen[outlet]);
        outletFrozen[outlet] = true;
        emit OutletFrozen(outlet);
    }

    function setOutletRecipient(Outlet outlet, address recipient) external onlyOwner {
        // Check that outlet is not frozen
        require(!outletFrozen[outlet]);

        // Check that the recipient is not already in use
        require(outletLookup[recipient] == Outlet.NONE);

        address oldRecipient = outletRecipient[outlet];
        outletLookup[recipient] = outlet;
        outletRecipient[outlet] = recipient;

        emit OutletRecipientSet(outlet, oldRecipient, recipient);
    }

    function setSlotShares(uint256 slot1Share, uint256 slot2Share, uint256 rewardPoolShare) external onlyOwner {
        require(slot1Share + slot2Share + rewardPoolShare == 51000);
        divvyUp();

        uint256 oldOtherSlot1Share = outletShare[Outlet.OTHER_SLOT1];
        uint256 oldOtherSlot2Share = outletShare[Outlet.OTHER_SLOT2];
        uint256 oldRewardPoolShare = outletShare[Outlet.REWARD_POOL];
        outletShare[Outlet.OTHER_SLOT1] = slot1Share;
        outletShare[Outlet.OTHER_SLOT2] = slot2Share;
        outletShare[Outlet.REWARD_POOL] = rewardPoolShare;

        emit SharesSet(oldOtherSlot1Share, oldOtherSlot2Share, oldRewardPoolShare, slot1Share, slot2Share, rewardPoolShare);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IWETH {
    function withdraw(uint) external;
}

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract X7TreasurySplitterV3 is Ownable {

    enum Outlet {
        NONE,
        PROFITSHARE,
        REWARD_POOL,
        OTHER_SLOT1,
        OTHER_SLOT2
    }

    uint256 public reservedETH;
    address public WETH;

    mapping(Outlet => uint256) public outletBalance;
    mapping(Outlet => address) public outletRecipient;
    mapping(Outlet => uint256) public outletShare;
    mapping(address => Outlet) public outletLookup;
    mapping(Outlet => bool) public outletFrozen;

    event OutletRecipientSet(Outlet indexed outlet, address indexed oldRecipient, address indexed newRecipient);
    event SharesSet(uint256 oldOtherSlot1Share, uint256 oldOtherSlot2Share, uint256 oldRewardPoolShare, uint256 newOtherSlot1Share, uint256 newOtherSlot2Share, uint256 newRewardPoolShare);
    event OutletFrozen(Outlet indexed outlet);

    constructor (address weth) Ownable(msg.sender) {
        WETH = weth;

        outletShare[Outlet.PROFITSHARE] = 49000;
        outletShare[Outlet.REWARD_POOL] = 6000;
        outletShare[Outlet.OTHER_SLOT1] = 15000;
        outletShare[Outlet.OTHER_SLOT2] = 30000;

        // Profit Share
        outletRecipient[Outlet.PROFITSHARE] = address(0x0000000000000000000000000000000000000000);

        // Reward Pool
        outletRecipient[Outlet.REWARD_POOL] = address(0x0000000000000000000000000000000000000000);

        // Initial Community Gnosis Wallet
        outletRecipient[Outlet.OTHER_SLOT1] = address(0x0000000000000000000000000000000000000000);

        // Initial Project Gnosis Wallet
        outletRecipient[Outlet.OTHER_SLOT2] = address(0x0000000000000000000000000000000000000000);
    }

    receive () external payable {}

    function divvyUp() public {
        uint256 newETH = address(this).balance - reservedETH;

        if (newETH > 0) {
            outletBalance[Outlet.PROFITSHARE] += newETH * outletShare[Outlet.PROFITSHARE] / 100000;
            outletBalance[Outlet.REWARD_POOL] += newETH * outletShare[Outlet.REWARD_POOL] / 100000;
            outletBalance[Outlet.OTHER_SLOT1] += newETH * outletShare[Outlet.OTHER_SLOT1] / 100000;

            outletBalance[Outlet.OTHER_SLOT2] = address(this).balance -
            outletBalance[Outlet.PROFITSHARE] -
            outletBalance[Outlet.OTHER_SLOT1] -
            outletBalance[Outlet.REWARD_POOL];

            reservedETH = address(this).balance;
        }
    }

    function freezeOutlet(Outlet outlet) external onlyOwner {
        require(outlet != Outlet.OTHER_SLOT1 && outlet != Outlet.OTHER_SLOT2 && outlet != Outlet.NONE);
        require(!outletFrozen[outlet]);
        outletFrozen[outlet] = true;
        emit OutletFrozen(outlet);
    }

    function setOutletRecipient(Outlet outlet, address recipient) external onlyOwner {
        // Check that outlet is not frozen
        require(!outletFrozen[outlet]);

        // Check that the recipient is not already in use
        require(outletLookup[recipient] == Outlet.NONE);

        address oldRecipient = outletRecipient[outlet];
        outletLookup[recipient] = outlet;
        outletRecipient[outlet] = recipient;

        emit OutletRecipientSet(outlet, oldRecipient, recipient);
    }

    function setSlotShares(uint256 slot1Share, uint256 slot2Share, uint256 rewardPoolShare) external onlyOwner {
        require(slot1Share + slot2Share + rewardPoolShare == 51000);
        divvyUp();

        uint256 oldOtherSlot1Share = outletShare[Outlet.OTHER_SLOT1];
        uint256 oldOtherSlot2Share = outletShare[Outlet.OTHER_SLOT2];
        uint256 oldRewardPoolShare = outletShare[Outlet.REWARD_POOL];
        outletShare[Outlet.OTHER_SLOT1] = slot1Share;
        outletShare[Outlet.OTHER_SLOT2] = slot2Share;
        outletShare[Outlet.REWARD_POOL] = rewardPoolShare;

        emit SharesSet(oldOtherSlot1Share, oldOtherSlot2Share, oldRewardPoolShare, slot1Share, slot2Share, rewardPoolShare);
    }

    function takeBalance() external {
        Outlet outlet = outletLookup[msg.sender];
        require(outlet != Outlet.NONE);
        divvyUp();
        _sendBalance(outlet);
    }

    function takeCurrentBalance() external {
        Outlet outlet = outletLookup[msg.sender];
        require(outlet != Outlet.NONE);
        _sendBalance(outlet);
    }

    function pushAll() public {
        divvyUp();
        _sendBalance(Outlet.PROFITSHARE);
        _sendBalance(Outlet.REWARD_POOL);
        _sendBalance(Outlet.OTHER_SLOT1);
        _sendBalance(Outlet.OTHER_SLOT2);
    }

    function rescueWETH() public {
        IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        pushAll();
    }

    function rescueTokens(address tokenAddress) external {
        if (tokenAddress == WETH) {
            rescueWETH();
        } else {
            IERC20(tokenAddress).transfer(outletRecipient[Outlet.OTHER_SLOT2], IERC20(tokenAddress).balanceOf(address(this)));
        }
    }

    function _sendBalance(Outlet outlet) internal {
        bool success;
        address recipient = outletRecipient[outlet];

        if (recipient == address(0)) {
            return;
        }

        uint256 ethToSend = outletBalance[outlet];

        if (ethToSend > 0) {
            outletBalance[outlet] = 0;
            reservedETH -= ethToSend;

            (success,) = recipient.call{value: ethToSend}("");
            if (!success) {
                outletBalance[outlet] += ethToSend;
                reservedETH += ethToSend;
            }
        }
    }
}