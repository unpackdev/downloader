// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// Libraries
import "./ProxyFactory.sol";

// Internal Interfaces
import "./TokenDropFactory.sol";

// Clone Contracts
import "./Pod.sol";
import "./TokenDrop.sol";

/**
 * @title PodFactory (ProxyFactory) - Clones a Pod Instance
 * @notice Reduces gas costs and collectively increases that chances winning for PoolTogether users, while keeping user POOL distributions to users.
 * @dev The PodFactory creates/initializes connected Pod and TokenDrop smart contracts. Pods stores tokens, tickets, prizePool and other essential references.
 * @author Kames Geraghty
 */
contract PodFactory is ProxyFactory {
    /**
     * @notice TokenDropFactory reference
     */
    TokenDropFactory public tokenDropFactory;

    /**
     * @notice Contract template for deploying proxied Pods
     */
    Pod public podInstance;

    /***********************************|
    |   Events                          |
    |__________________________________*/
    /**
     * @dev Emitted when a new Pod and TokenDrop pair is created.
     */
    event LogCreatedPodAndTokenDrop(Pod indexed pod, TokenDrop indexed drop);

    /***********************************|
    |   Constructor                     |
    |__________________________________*/
    /**
     * @notice Initializes the Pod Factory with an instance of the Pod and TokenDropFactory reference.
     * @dev Initializes the Pod Factory with an instance of the Pod and TokenDropFactory reference.
     * @param _tokenDropFactory Target PrizePool for deposits and withdraws
     */
    constructor(TokenDropFactory _tokenDropFactory) {
        require(
            address(_tokenDropFactory) != address(0),
            "PodFactory:invalid-token-drop-factory"
        );
        // Pod Instance
        podInstance = new Pod();

        // Reference TokenDropFactory
        tokenDropFactory = _tokenDropFactory;
    }

    /**
     * @notice Create a new Pod Clone using the Pod instance.
     * @dev The Pod Smart Contact is created and initialized using the PodFactory.
     * @param _prizePool Target PrizePool for deposits and withdraws.
     * @param _ticket Non-sponsored PrizePool ticket - is verified during initialization.
     * @param _faucet  TokenFaucet address that distributes reward token for PrizePool deposits.
     * @param _manager Manages the Pod's non-core assets (ERC20 and ERC721 tokens).
     * @param _decimals Set the Pod decimals to match the underlying asset.
     * @return pod Pod address
     */
    function create(
        address _prizePool,
        address _ticket,
        address _faucet,
        address _manager,
        uint8 _decimals
    ) external returns (address pod) {
        // Pod Deploy
        Pod _pod = Pod(deployMinimal(address(podInstance), ""));

        // Pod Initialize
        _pod.initialize(_prizePool, _ticket, _decimals);

        // Pod Set Manager
        _pod.setManager(_manager);

        // Governance managed PrizePools include TokenFaucets, which "drip" an asset token.
        // Community managed PrizePools might NOT have a TokenFaucet, and thus don't require a TokenDrop.
        TokenDrop _drop;
        if (address(_faucet) != address(0)) {
            TokenFaucet faucet = TokenFaucet(_faucet);

            // Create TokenDrop instance
            _drop = tokenDropFactory.create(
                IERC20Upgradeable(_pod),
                IERC20Upgradeable(faucet.asset())
            );

            // Set Pod TokenFacuet
            _pod.setTokenFaucet(faucet);

            // Set Pod TokenDrop
            _pod.setTokenDrop(_drop);
        }

        // Update Pod owner from factory to msg.sender
        _pod.transferOwnership(msg.sender);

        // Emit LogCreatedPodAndTokenDrop
        emit LogCreatedPodAndTokenDrop(_pod, _drop);

        // Return Pod/TokenDrop addresses
        return (address(_pod));
    }
}
