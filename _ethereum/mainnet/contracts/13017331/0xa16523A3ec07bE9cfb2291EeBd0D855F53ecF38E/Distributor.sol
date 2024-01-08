// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";


interface Mintable {
    function mint(address to, uint256 amount) external;
}

/**
 * @title Ethair Token Distribution Contract
 * @dev This contract is responsible for distributing tokens to marketplace participants. Controls are in place to rate limit distribution daily and to distribute the correct amount of tokens to each of the recipients and the Dev Fund address. No methods are open to the general public. Methods are split into Admin Role Methods and Worker Methods.
 */
contract Distributor is AccessControlUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /*----------  Constants  ----------*/

    uint256 internal constant SECONDS_PER_DAY = 86400;
    uint256 internal constant GRAINS = 10 ** 18;
    uint256 internal constant TWO_DECIMAL_PLACES = 10 ** 16;
    uint256 internal constant PERCENT_75 = 75 * TWO_DECIMAL_PLACES;
    uint256 internal constant PERCENT_25 = 25 * TWO_DECIMAL_PLACES;


    /*----------  Globals  ----------*/

    bytes32 public constant WORKER_ROLE = keccak256("WORKER_ROLE");

    mapping (bytes32 => bool) public nonces;  // Marked as true once nonce is consumed.

    uint256 public maximumDailyTransferLimit; // Rate limit on daily transfers. May be adjusted up or down by Admin Role.
    uint256 public sentWithin24Hours;         // Cumulative tokens sent within 24 hours.
    uint256 public maximumDailyMintLimit;     // Rate limit on daily minting. May be adjusted up or down by Admin Role.
    uint256 public mintedWithin24Hours;       // Cumulative tokens minted within 24 hours.

    uint256 public currentDay;                // Daily counter.
    address public devFund;                   // Updatable address, recipient of dev fund tokens.


    /*----------  Modifiers  ----------*/

    /**
     * @dev CAUTION: updates state: nonceMapping.
     * @param uuid number of tokens to send.
     */
    modifier nonceCheck(bytes32 uuid) {
        require(!nonces[uuid], "nonceCheck:: uuid already used");
        nonces[uuid] = true;

        _;
    }

    /**
     * @dev CAUTION: updates state: currentDay, and sentWithin24Hours.
     * @param amount number of tokens to send.
     */
    modifier withinDailyTransferLimit(uint256 amount) {

        (bool newDay, uint256 actualDay) = isNewDay();

        if (newDay) {
            sentWithin24Hours = amount;
            currentDay = actualDay;
            require(
                amount <= maximumDailyTransferLimit,
                "withinDailyTransferLimit::Daily transfer limit reached."
            );
        } else {
            sentWithin24Hours = sentWithin24Hours + amount;
            require(
                sentWithin24Hours <= maximumDailyTransferLimit,
                "withinDailyTransferLimit::Daily transfer limit reached."
            );
        }

        _;

    }

    /**
     * @dev CAUTION: updates state: currentDay, and mintedWithin24Hours.
     * @param amount number of tokens to send.
     */
    modifier withinDailyMintLimit(uint256 amount) {

        (bool newDay, uint256 actualDay) = isNewDay();

        if (newDay) {
            mintedWithin24Hours = amount;
            currentDay = actualDay;
            require(
                amount <= maximumDailyMintLimit,
                "withinDailyMintLimit::Daily transfer limit reached."
            );
        } else {
            mintedWithin24Hours = mintedWithin24Hours + amount;
            require(
                mintedWithin24Hours <= maximumDailyMintLimit,
                "withinDailyMintLimit::Daily transfer limit reached."
            );
        }

        _;

    }

    /*----------  Initializer  ----------*/

    function initialize()
        initializer
        public
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WORKER_ROLE, _msgSender());
    }


    /*----------  Internal Methods  ----------*/

    function isNewDay()
        internal
        view
        returns (bool, uint256)
    {
        // solium-disable-next-line security/no-block-members
        uint256 actualDay = (block.timestamp / SECONDS_PER_DAY);
        return (actualDay != currentDay, actualDay);
    } 


    /*----------  Admin Role Methods  ----------*/

    /**
     * @dev Admin Role Method: Permits the Admin Role address to update the Dev Fund address
     * @param _devFund Dev Fund Address
     */
    function setAddresses(address _devFund)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        devFund = _devFund;
    }

    /**
     * @dev Admin Role Method: Permits the Admin Role address to update the `maximumDailyTransferLimit`. This limit may be increased or decreased as needed.
     * @param amount New daily transfer limit amount, denominated in GRAINS.
     */
    function setMaximumDailyTransferLimit(uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maximumDailyTransferLimit = amount;
    }

    /**
     * @dev Admin Role Method: Permits the Admin Role address to update the `maximumDailyMintLimit`. This limit may be increased or decreased as needed.
     * @param amount New daily transfer limit amount, denominated in GRAINS.
     */
    function setMaximumDailyMintLimit(uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maximumDailyMintLimit = amount;
    }


    /*----------  Worker Methods  ----------*/

    /**
     * @dev Worker Method Pull method to accept approved tokens into the contract.
     * @param token The token to transfer to this contract.
     * @param from Address tokens are being transferred from.
     * @param value Number of tokens to transfer, denoted in GRAINS.
     */
    function receiveTokens(IERC20Upgradeable token, address from, uint256 value)
        public
        onlyRole(WORKER_ROLE)
    {
        token.safeTransferFrom(from, address(this), value);
    }

    /**
     * @dev Worker Method token distribution method. 
     * @param token The token to transfer.
     * @param to Primary recipient.
     * @param value Number of tokens to transfer, denoted in GRAINS.
     * @param uuid Nonce to ensure request is only completed once.
     */
    function sendTokens(IERC20Upgradeable token, address to, uint256 value, bytes32 uuid)
        public
        onlyRole(WORKER_ROLE)
        nonceCheck(uuid)
        withinDailyTransferLimit(value)
    {
        token.safeTransfer(to, value);
    }

    /**
     * @dev Worker Method token minting. Mint tokens to distributor as well as the Dev Fund.
     * @param token The token to mint.
     * @param value Number of tokens to mint, denoted in GRAINS.
     * @param uuid Nonce to ensure request is only completed once.
     */
    function mintTokens(Mintable token, uint256 value, bytes32 uuid)
        public
        onlyRole(WORKER_ROLE)
        nonceCheck(uuid)
        withinDailyMintLimit(value)
    {
        token.mint(address(this), (value * PERCENT_75) / GRAINS);
        token.mint(devFund, (value * PERCENT_25) / GRAINS);
    }
}
