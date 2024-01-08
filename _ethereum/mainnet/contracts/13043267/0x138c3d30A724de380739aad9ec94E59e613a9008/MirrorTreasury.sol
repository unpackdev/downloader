// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IDistributionLogic.sol";
import "./ITributaryRegistry.sol";
import "./ITreasuryConfig.sol";
import "./IMirrorTreasury.sol";
import "./Governable.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract MirrorTreasury is IMirrorTreasury, Governable {
    // ============ Treasury Configuration ============

    // Used to pull the active distribution model.
    address public treasuryConfig;

    // ============ Tributary Registry ============

    // Used to find tributary addresses associated with Economic Producers.
    address public tributaryRegistry;

    // ============ Structs ============

    // Allows governance to execute generic functions.
    struct Call {
        // The target of the transaction.
        address target;
        // The value passed into the transaction.
        uint96 value;
        // Any data passed with the call.
        bytes data;
    }

    // ============ Events ============

    // Emitted when the treasury transfers ETH.
    event Transfer(address indexed from, address indexed to, uint256 value);
    // Emitted when the treasury transfers an ERC20 token.
    event ERC20Transfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    // ============ Constructor ============

    // NOTE: Once deployed, tributaryRegistry and treasuryConfig should be set.
    constructor(address owner_) Governable(owner_) {}

    // ============ Treasury Contributions ============

    /**
     * A safe, public function for making contributions to the treasury.
     * If a tributary is registered for the contributor, then governance
     * tokens will be allocated according to the active distribution model.
     */
    function contribute(uint256 amount) public payable override {
        require(msg.value == amount, "msg.value != amount");
        _allocateGovernance(msg.sender, amount);
    }

    // Allows directly contributing with a specify treasury, but the sender
    // must be registered as a "singleton producer" - e.g. auctions house.
    function contributeWithTributary(address tributary)
        public
        payable
        override
    {
        // Here we don't revert, but instead just don't allocate goverance
        // if the call isn't registered as an economic producer.
        if (
            ITributaryRegistry(tributaryRegistry).singletonProducer(msg.sender)
        ) {
            _allocateGovernanceToTributary(tributary, msg.value);
        }
    }

    /**
     * Allows receiving ETH, and can mint treasury governance tokens in
     * exchange. Uses a registry to specify which addresses are allowed
     * to receive gov tokens in exchange for contributing ETH.
     */
    receive() external payable {
        _allocateGovernance(msg.sender, msg.value);
    }

    // ============ Treasury Configuration ============

    function setTreasuryConfig(address treasuryConfig_) public onlyGovernance {
        treasuryConfig = treasuryConfig_;
    }

    // ============ Tributary Registry Configuration ============

    function setTributaryRegistry(address tributaryRegistry_)
        public
        onlyGovernance
    {
        tributaryRegistry = tributaryRegistry_;
    }

    // ============ Funds Administration ============

    function transferFunds(address payable to, uint256 value)
        external
        override
        onlyGovernance
    {
        _sendFunds(to, value);
        emit Transfer(address(this), to, value);
    }

    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external override onlyGovernance {
        IERC20(token).transfer(to, amount);
        emit ERC20Transfer(token, address(this), to, amount);
    }

    // ============ Generic Call Execution ============

    function executeGeneric(Call memory call) public onlyGovernance {
        (bool ok, ) = call.target.call{value: uint256(call.value)}(call.data);

        require(ok, "execute transaction failed");
    }

    // ============ Private Utils ============

    function _sendFunds(address payable recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "Insufficient balance for send"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value: recipient may have reverted");
    }

    function _allocateGovernance(address producer, uint256 amount) private {
        // Get the tributary that was registered for the given producer.
        address tributary = ITributaryRegistry(tributaryRegistry)
            .producerToTributary(producer);

        _allocateGovernanceToTributary(tributary, amount);
    }

    function _allocateGovernanceToTributary(address tributary, uint256 amount)
        private
    {
        // If there is a registered tributary to mint Mirror tokens for,
        // then, here, we go and mint those tokens! Else, just accept ETH, no sweat.
        if (tributary != address(0)) {
            address distributionModel = ITreasuryConfig(treasuryConfig)
                .distributionModel();

            IDistributionLogic(distributionModel).distribute(tributary, amount);
        }
    }
}
