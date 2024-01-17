// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./UUPSUpgradeable.sol";

import "./AccessControlUpgradeable.sol";

import "./VRFConsumerBaseV2Upgradeable.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./IUniswapV2Router02.sol";

import "./APMorgan.sol";
import "./APMorganRoles.sol";

import "./IAPMorgan.types.sol";

contract APMorganMinter is
    UUPSUpgradeable,
    APMorganRoles,
    IAPMorganTypes,
    VRFConsumerBaseV2Upgradeable
{
    /// Link Token for subscription payment to VRF
    LinkTokenInterface immutable LINKTOKEN;

    /// Gas value KeyHash for VRF requests
    bytes32 immutable keyHash;

    /// vrf callback gas limit
    uint32 public callbackGasLimit;

    /// Number of requested confirmations for randomness (minimum 3)
    uint16 public constant requestConfirmations = 3;

    /// vrf params
    uint64 public s_subscriptionId;

    APMorgan apMorgan;

    // auto initialize implementation for production environment - require explicitly stating if contract is for testing.
    constructor(
        bool isTestingContract,
        address _vrfCoordinator,
        address linkTokenContract,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Upgradeable(_vrfCoordinator) {
        LINKTOKEN = LinkTokenInterface(linkTokenContract);
        keyHash = _keyHash;

        if (!isTestingContract) {
            //// @custom:oz-upgrades-unsafe-allow constructor
            _disableInitializers();
        }
    }

    function initialize(address admin, address _apMorgan) public initializer {
        callbackGasLimit = 1_000_000; // sufficiently high
        __roles_init(admin, _apMorgan);

        apMorgan = APMorgan(_apMorgan);

        //Create a new VRF subscription when you initialize the contract.
        createNewSubscription();
    }

    function sendVrfRequest()
        external
        payable
        onlyRole(APMORGAN_ROLE)
        returns (uint256 s_requestId)
    {
        s_requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                1 // num of random numbers to request
            );
    }

    /// @notice VRF callback function to provide random numbers and mint the associated token
    /// @param requestId - VRF request id
    /// @param randomWords - random numbers
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        (uint8 randomLayer0, uint8 randomLayer1) = getTwoRandomLayers(
            randomWords[0]
        );

        apMorgan.mintAPMorgan(requestId, randomLayer0, randomLayer1);
    }

    /// @notice get two random layers from a single uint256 returned from vrf
    /// @param randomWord - random number
    function getTwoRandomLayers(uint256 randomWord)
        internal
        pure
        returns (uint8, uint8)
    {
        return (
            determineRandomLayer(randomWord % 100), // Only looks at the first 7 bits (ie 2^7)
            determineRandomLayer((randomWord >> 7) % 100) // Looks at the next 7 bits of the number
        );
    }

    /// @notice Probabilistic Randomness for layer assets
    /// 50% probability of asset 0
    /// 30% probability of asset 1
    /// 15% probability of asset 2
    /// 5% probability of asset 3
    /// @param randomValue - random value between 0 and 99
    /// @return randomAsset - random asset of value [0:3]
    function determineRandomLayer(uint256 randomValue)
        internal
        pure
        returns (uint8 randomAsset)
    {
        if (randomValue < 50) {
            randomAsset = 0;
        } else if (randomValue < 80) {
            randomAsset = 1;
        } else if (randomValue < 95) {
            randomAsset = 2;
        } else {
            randomAsset = 3;
        }
    }

    // ////////////// VRF functions //////////////

    /// @notice Adds this contract as a consumer of VRF random words (numbers)
    function createNewSubscription() internal virtual {
        s_subscriptionId = VRFCoordinatorV2Interface(vrfCoordinator)
            .createSubscription();
        // Add this contract as a consumer of its own subscription.
        VRFCoordinatorV2Interface(vrfCoordinator).addConsumer(
            s_subscriptionId,
            address(this)
        );
    }

    /// @notice Adds this contract as a consumer of VRF random words (numbers)
    /// @param amount - id of token to set as pfp
    /// @dev assumes this contract holds link (decimals: 18)
    function topUpSubscription(uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        LINKTOKEN.transferAndCall(
            address(VRFCoordinatorV2Interface(vrfCoordinator)),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    /// @notice Removes the vrf subscription
    /// @param receivingWallet - wallet that will receive outstanding link balance in subscription
    function cancelSubscription(address receivingWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        VRFCoordinatorV2Interface(vrfCoordinator).cancelSubscription(
            s_subscriptionId,
            receivingWallet
        );
        s_subscriptionId = 0;
    }

    /// @notice Withdraw subscriptions link to wallet
    /// @param amount - amount of link to withdraw
    /// @param to - receiver
    /// @dev check the vrfCoordinator contract to get the balance of link related to this contracts subscriptionId
    function withdraw(uint256 amount, address to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        LINKTOKEN.transfer(to, amount);
    }

    /// @notice used for upgrading
    /// @param newImplementation - Address of new implementation contract
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /// @notice used for upgrading
    /// @param interfaceId - interface identifier for contract
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Univ2 interface for swapping native token for link to mint subsidy
    /// @param router - address of router contract
    /// @param amountOutMin - min amount required to return for swap
    /// @param path - array of addresses for swap
    function swapToLinkForRandomness(
        address router,
        uint256 amountOutMin,
        address[] calldata path
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // uint amountOutMin, address[] calldata path, address to, uint deadline)
        IUniswapV2Router02(router).swapExactETHForTokens{
            value: address(this).balance
        }(amountOutMin, path, address(this), block.timestamp);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}
