// SPDX-License-Identifier: BSD-3-Clause AND MIT
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC777Recipient.sol";
import "./IERC1820Registry.sol";
import "./AccessControl.sol";
import "./DelegateRegistry.sol";

/**
* @title Vester factory
* @notice Creates Vester contracts when sent ERC777 tokens to distribute
*/
contract VesterFactory is IERC777Recipient {
    using SafeERC20 for IERC20;

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER");
    address immutable DomToken;

    address immutable Delegator;

    constructor(address DomToken_, address DelegateRegistry_) {
        DomToken = DomToken_;
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        Delegator = DelegateRegistry_;
    }

    event VesterCreated(address childAddress);

    /**
    * @notice ERC777 send() receive hook. Create a Vester contract
    * @param vestingAmount received amount / amount for new Vester
    * @param userData ABI encoded parameters for Vester (except for $DOM address, registry address, and vesting amount)
    */
    function tokensReceived(
        address /* operator */,
        address /* from */,
        address /* to */,
        uint256 vestingAmount,
        bytes calldata userData,
        bytes calldata /* operatorData */
    ) external override {
        require(msg.sender == DomToken, "WRONG_TOKEN");

        (address recipient,
        uint vestingBegin,
        uint vestingCliff,
        uint vestingEnd,
        uint timeout) = abi.decode(
            userData,
            (address, uint, uint, uint, uint)
        );

        Vester vester = new Vester(
            DomToken,
            Delegator,
            recipient,
            vestingAmount,
            vestingBegin,
            vestingCliff,
            vestingEnd,
            timeout
        );

        AccessControl(DomToken).grantRole(TRANSFER_ROLE, address(vester));
        IERC20(DomToken).safeTransfer(address(vester), vestingAmount);

        emit VesterCreated(address(vester));
     }
}

/**
 * Based on Uniswap's TreasuryVester: https://github.com/Uniswap/governance/blob/master/contracts/TreasuryVester.sol
 * @title $DOM vesting contract
 * @notice distributes a token to a single recipient over a linear vesting schedule
 */
contract Vester {
    using SafeERC20 for IERC20;

    IERC20 public dom;
    address public recipient;
    address public delegateRegistry;

    uint public immutable vestingAmount;
    uint public immutable vestingBegin;
    uint public immutable vestingCliff;
    uint public immutable vestingEnd;
    uint public immutable timeout;

    uint public lastUpdate;

    /**
    * @param dom_ address of token to be disbursed
    * @param delegateRegistry_ address of the deployed Gnosis delegateRegistry
    * @param recipient_ recipient of token
    * @param vestingAmount_ total amount to be disbursed
    * @param vestingBegin_ timestamp to start vesting
    * @param vestingCliff_ timestamp at which first withdrawal can be made
    * @param vestingEnd_ timestamp at which all tokens can be withdrawn
    * @param timeout_ minimum seconds between withdrawals (commonly: 0, 1 day, 1 month)
    */
    constructor(
        address dom_,
        address delegateRegistry_,
        address recipient_,
        uint vestingAmount_,
        uint vestingBegin_,
        uint vestingCliff_,
        uint vestingEnd_,
        uint timeout_
    ) {
        require(vestingBegin_ >= block.timestamp, 'BEGIN_TOO_EARLY');
        require(vestingCliff_ >= vestingBegin_, 'CLIFF_TOO_EARLY');
        require(vestingEnd_ > vestingCliff_, 'END_TOO_EARLY');

        dom = IERC20(dom_);
        delegateRegistry = delegateRegistry_;
        recipient = recipient_;
        DelegateRegistry(delegateRegistry).setDelegate('', recipient);

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;
        timeout = timeout_;

        lastUpdate = vestingBegin_;
    }

    /**
     * @notice Transfer ownership of vested tokens
     * @param recipient_ new beneficiary
     */
    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'UNAUTHORIZED');
        require(recipient_ != address(0), "ZERO_ADDRESS");
        recipient = recipient_;
        DelegateRegistry(delegateRegistry).setDelegate('', recipient);
    }

    /**
    * @notice claim pending tokens
    */
    function claim() public {
        require(block.timestamp >= vestingCliff, 'BEFORE_CLIFF');
        require(block.timestamp >= lastUpdate + timeout || lastUpdate == vestingBegin, 'COOLDOWN');
        uint amount;
        if (block.timestamp >= vestingEnd) {
            amount = dom.balanceOf(address(this));
        } else {
            amount = vestingAmount * (block.timestamp - lastUpdate) / (vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        dom.safeTransfer(recipient, amount);
    }
}