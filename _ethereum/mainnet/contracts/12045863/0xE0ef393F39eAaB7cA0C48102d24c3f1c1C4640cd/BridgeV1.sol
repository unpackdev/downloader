// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./MintableToken.sol";
import "./console.sol";

/**
 * Tixl - $TXL
 * @title Cross chain token bridge
 */
contract BridgeV1 is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;

    event DepositTokens(
        address indexed sourceNetworkTokenAddress,
        uint256 amount,
        address indexed receiverAddress,
        uint256 sourceChainId,
        uint256 number
    );

    event ReleaseTokens(
        address indexed sourceNetworkTokenAddress,
        uint256 amount,
        address indexed receiverAddress,
        uint256 depositChainId,
        uint256 depositNumber
    );

    /**
     * If the bridge is deployed as source or target network bridge
     */
    bool public isSource;

    /**
     * Counts all deposits
     */
    uint256 public depositCount;

    /**
     * The chain ID of the counter side bridge
     * E.g. if this bridge runs on mainnet (chain ID 1) and should bridge to BSC then `otherChainId` would be 56
     */
    uint256 public otherChainId;

    /**
     * A mapping from deposit counters to booleans whether a deposit has been released or not
     */
    mapping(uint256 => bool) public releasedDeposits;

    /**
     * Individual bridge fees per supported token
     */
    mapping(address => uint256) public bridgeFees;

    /**
     * Persistence for the collected bridging fees per token
     */
    mapping(address => uint256) public collectedBridgeFees;

    /**
     * Mapping which contains information about which address may control certain function of this bridge
     * but only for a certain token. So the high level address key should be a token contract address.
     */
    mapping(address => mapping(address => bool)) public permittedOracleAddresses;

    /**
     * Storage of the outside pegged tokens
     */
    mapping(address => address) public outsidePeggedTokens;

    /**
     * Additional reversed mapping to lookup outside pegged tokens from the other side
     */
    mapping(address => address) public reverseOutsidePeggedTokens;

    /**
     * Only supporting whitelisted tokens!
     */
    mapping(address => bool) public tokenWhitelist;

    /**
     * Initializer instead of constructor to have the contract upgradable
     */
    function initialize(bool _isSource, uint256 _otherChainId) public initializer {
        OwnableUpgradeable.__Ownable_init();
        isSource = _isSource;
        otherChainId = _otherChainId;
    }

    /**
     * @param tokenAddress The token address for which the oracle should be allowed to release
     * @param oracleAddress This address should be permitted to release tokens from the bridge
     */
    function addPermittedOracleAddress(address tokenAddress, address oracleAddress) public onlyOwner {
        permittedOracleAddresses[tokenAddress][oracleAddress] = true;
    }

    /**
     * Only whitelisted tokens are supported by the bridge
     */
    function addTokenToWhitelist(address tokenAddress) public onlyOwner {
        require(isSource == true, "Only the source bridge uses a whitelist");
        tokenWhitelist[tokenAddress] = true;
    }

    /**
     * Adds an outside pegged token
     */
    function addOutsidePeggedToken(
        address sourceNetworkTokenAddress,
        address peggedTokenAddress
    ) public onlyOwner {
        require(isSource == false, "Only the target side of a bridge accepts outside pegged tokens");
        outsidePeggedTokens[sourceNetworkTokenAddress] = peggedTokenAddress;
        reverseOutsidePeggedTokens[peggedTokenAddress] = sourceNetworkTokenAddress;
    }

    /**
     * The core function that accepts token transfers to other networks
     */
    function deposit(address tokenAddress, uint256 amount, address receiverAddress, uint256 targetChainId) public {
        // this is a security check that users don't pass funds to the wrong bridge by mistake
        require(targetChainId == otherChainId, "Wrong chain ID passed");

        uint256 amountAfterFees = amount.sub(bridgeFees[tokenAddress]);
        require(amountAfterFees > 0, "Amount too low to cover bridge fee");
        collectedBridgeFees[tokenAddress] = collectedBridgeFees[tokenAddress].add(bridgeFees[tokenAddress]);

        if (isSource) {
            require(tokenWhitelist[tokenAddress] == true, "Token not whitelisted");

            // transfer the token into the bridge
            require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount) == true, "Could not deposit token");
        } else {
            // on the target bridge side tokens are burned again after they've been minted before
            ERC20Burnable(tokenAddress).burnFrom(msg.sender, amountAfterFees);
            // keeping the bridge fees in this contract
            require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), bridgeFees[tokenAddress]) == true, "Could not take bridge fees");
        }

        // For every deposit we increase the counter, this can be used on the target side bridge to avoid double releases
        depositCount = depositCount.add(1);

        // We always dispatch the deposit event with the "true" token address in the source network
        emit DepositTokens(
            isSource ? tokenAddress : reverseOutsidePeggedTokens[tokenAddress],
            amountAfterFees,
            receiverAddress,
            getChainID(),
            depositCount
        );
    }

    /**
     * Releases tokens to a certain user
     *
     * @param receiverAddress The account to receive the tokens
     * @param sourceNetworkTokenAddress We always use the source network token address and not the outside pegged
     *        token address for releasing. That means that on the target network side the bridge will look up the
     *        corresponding outside pegged token.
     * @param amount The amount to be sent
     * @param depositChainId The chain ID where the deposit comes from
     * @param depositNumber The number of the corresponding deposit
     */
    function release(
        address receiverAddress,
        address sourceNetworkTokenAddress,
        uint256 amount,
        uint256 depositChainId,
        uint256 depositNumber
    ) public {
        require(permittedOracleAddresses[sourceNetworkTokenAddress][msg.sender] == true, "Release not permitted");
        // only if the deposit is from the correct bridge, it should be processed
        require(depositChainId == otherChainId, "Wrong chain ID");
        // we don't want to double process deposits
        require(releasedDeposits[depositNumber] == false, "Deposit was already processed");

        if (isSource) {
            IERC20 token = IERC20(sourceNetworkTokenAddress);
            // on the source side the tokens are transferred from the bridge to the receiver
            require(token.transfer(receiverAddress, amount) == true, "Could not release tokens");
        } else {
            require(outsidePeggedTokens[sourceNetworkTokenAddress] != address(0), "No outside pegged token exists");
            MintableToken(outsidePeggedTokens[sourceNetworkTokenAddress]).mint(receiverAddress, amount);
        }

        releasedDeposits[depositNumber] = true;
        emit ReleaseTokens(sourceNetworkTokenAddress, amount, receiverAddress, depositChainId, depositNumber);
    }

    /**
     * Removes an outside pegged token
     */
    function removeOutsidePeggedToken(address sourceNetworkTokenAddress) public onlyOwner {
        address peggedTokenAddress = outsidePeggedTokens[sourceNetworkTokenAddress];
        outsidePeggedTokens[sourceNetworkTokenAddress] = address(0);
        reverseOutsidePeggedTokens[peggedTokenAddress] = address(0);
    }

    /**
     * Removes an oracle address for a token
     */
    function removePermittedOracleAddress(address oracleAddress, address tokenAddress) public onlyOwner {
        permittedOracleAddresses[tokenAddress][oracleAddress] = false;
    }

    /**
     * Removes a token from the whitelist (stops bridging)
     */
    function removeTokenFromWhitelist(address tokenAddress) public onlyOwner {
        require(isSource == true, "Only the source bridge uses a whitelist");
        tokenWhitelist[tokenAddress] = false;
    }

    /**
     * Sets the individual bridge fee for a token
     */
    function setBridgeFee(address tokenAddress, uint256 fee) public onlyOwner {
        require(fee >= 0, "Fee must be at least 0");
        bridgeFees[tokenAddress] = fee;
    }

    /**
     * Allows a permitted oracle address to withdraw the bridge fees from the bridge
     */
    function withdrawBridgeFees(address tokenAddress, uint256 amount) public onlyOwner returns (bool) {
        collectedBridgeFees[tokenAddress] = collectedBridgeFees[tokenAddress].sub(amount);
        return IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    function getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
