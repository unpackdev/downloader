// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

/*
    ██████╗░░░██╗██╗███████╗░░░░░░░█████╗░░█████╗░███╗░░░███╗██╗░█████╗░░██████╗
    ╚════██╗░██╔╝██║╚════██║░░░░░░██╔══██╗██╔══██╗████╗░████║██║██╔══██╗██╔════╝
    ░░███╔═╝██╔╝░██║░░░░██╔╝█████╗██║░░╚═╝██║░░██║██╔████╔██║██║██║░░╚═╝╚█████╗░
    ██╔══╝░░███████║░░░██╔╝░╚════╝██║░░██╗██║░░██║██║╚██╔╝██║██║██║░░██╗░╚═══██╗
    ███████╗╚════██║░░██╔╝░░░░░░░░╚█████╔╝╚█████╔╝██║░╚═╝░██║██║╚█████╔╝██████╔╝
    ╚══════╝░░░░░╚═╝░░╚═╝░░░░░░░░░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░╚════╝░╚═════╝░
*/

contract StudioBadgePayment is Ownable {
    // @dev Using errors instead of requires with strings saves gas at deploy time and during reverts
    error SaleNotActive();
    error MaxSupplyReached();
    error NotWhiteListed();
    error PurchasedAlready();
    error NotEnoughETHSent();
    error ReferralNotAvailable();
    error CantReferSelf();

    uint256 public constant MAX_SUPPLY = 200;
    uint256 public salePrice = 2.47 ether;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public purchased;
    address[] public purchaseList;
    mapping(address => bool) public referralAvailable;
    uint256 public amtSold = 0;
    // 247 Multisig
    address public withdrawAddress = 0x0A59AF20E12168a6f12859a844771B25Cae05Ae9;

    // @dev OFF and COMPLETE are both sale-off states. Distinction is required/used for ease of frontend sale progression context.
    enum SaleState {
        OFF,
        WHITELISTSALE,
        PUBLIC,
        COMPLETE
    }
    SaleState public saleState = SaleState.OFF;

    // Owner functionality ------------------------------------------------------------------------
    /**
     * @notice Sets the address that is allowed to withdraw eth from contract.
     * @param addr The address to set.
     */
    function setWithdrawalAddress(address addr) external onlyOwner {
        withdrawAddress = addr;
    }

    /**
     * @notice Sets mint list sale active. Only one sale state can be active at a time.
     */
    function setWhiteListSaleActive() external onlyOwner {
        saleState = SaleState.WHITELISTSALE;
    }

    /**
     * @notice Sets public sale active. Only one sale state can be active at a time.
     */
    function setPublicSaleActive() external onlyOwner {
        saleState = SaleState.PUBLIC;
    }

    /**
     * @notice Turns off sale. Only one sale state can be active at a time.
     */
    function setSaleInactive() external onlyOwner {
        saleState = SaleState.OFF;
    }

    /**
     * @notice Sets sale complete. Only one sale state can be active at a time.
     */
    function setSaleComplete() external onlyOwner {
        saleState = SaleState.COMPLETE;
    }

    /**
     * @notice Sets the price in wei
     */
    function setSalePriceINWEI(uint256 newSalePrice) external onlyOwner {
        salePrice = newSalePrice;
    }

    /**
     * @notice Withdraw balance to treasury
     */
    function withdraw() external onlyOwner {
        (bool sent, ) = withdrawAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice Adds a list of addresses to the whitelist
     */
    function addAddresses(address[] calldata addrs) external onlyOwner {
        for (uint16 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }

    /**
     * @notice Adds a single address to the whitelist
     */
    function addAddress(address addr) external onlyOwner {
        whitelist[addr] = true;
    }

    // Purchase functionality ------------------------------------------------------------------------
    /**
     * @notice Function to purchase a reservation for a studio badge.
     */
    function purchaseBadgeWhiteList() public payable {
        if (saleState != SaleState.WHITELISTSALE) revert SaleNotActive();
        if (purchased[msg.sender]) revert PurchasedAlready();
        if (!whitelist[msg.sender]) revert NotWhiteListed();
        if (amtSold + 1 > MAX_SUPPLY) revert MaxSupplyReached();
        if (msg.value < salePrice) revert NotEnoughETHSent();
        purchased[msg.sender] = true;
        purchaseList.push(msg.sender);
        whitelist[msg.sender] = false;
        referralAvailable[msg.sender] = true;
        amtSold += 1;
    }

    /**
     * @notice Function to purchase a reservation for a studio badge.
     */
    function purchaseBadgePublic() public payable {
        if (saleState != SaleState.PUBLIC) revert SaleNotActive();
        if (purchased[msg.sender]) revert PurchasedAlready();
        if (amtSold + 1 > MAX_SUPPLY) revert MaxSupplyReached();
        if (msg.value < salePrice) revert NotEnoughETHSent();
        purchased[msg.sender] = true;
        purchaseList.push(msg.sender);
        amtSold += 1;
    }

    /**
     * @notice Function to refer another user to the whitelist if available.
     */
    function refer(address toRefer) public {
        if (!referralAvailable[msg.sender]) revert ReferralNotAvailable();
        if (toRefer == msg.sender) revert CantReferSelf();
        whitelist[toRefer] = true;
        referralAvailable[msg.sender] = false;
    }
}
