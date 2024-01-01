// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BaseContract.sol";
import "./ERC20Template.sol";

struct TokenInfo {
    string name;
    string symbol;
}

struct DeployedToken {
    TokenInfo tokenInfo;
    address contractAddress;
}

contract ERC20Factory is BaseContract {
    /**
     * Role definintions
     * /
    /**
     * @notice Only accounts with this role can call the `deployTokens` function
     */
    bytes32 public constant TOKEN_DEPLOYER_ROLE =
        keccak256("TOKEN_DEPLOYER_ROLE");

    address[] public s_deployedTokenAddresses;
    mapping(address => TokenInfo) public s_deployedTokenInfo;

    // reserved for possible future storages
    uint256[50] private __gap;

    event TokensDeployed(DeployedToken[] deployedTokens);

    constructor() {}

    function initialize() public initializer {
        __BaseContract_init(_msgSender());
        __ERC20Factory_init();
    }

    function __ERC20Factory_init() internal onlyInitializing {
        __ERC20Factory_init_unchained();
    }

    function __ERC20Factory_init_unchained() internal onlyInitializing {
        _grantRole(TOKEN_DEPLOYER_ROLE, _msgSender());
    }

    /**
     * Deploy a batch of token contract with their names and symbols provided in the `tokenInfos` array
     * @param tokenInfos a list of `TokenInfo` that is going to be deployed
     */
    function deployTokens(
        TokenInfo[] memory tokenInfos
    ) external onlyRole(TOKEN_DEPLOYER_ROLE) whenNotPaused {
        DeployedToken[] memory t_deployedTokens = new DeployedToken[](
            tokenInfos.length
        );

        for (uint256 i = 0; i < tokenInfos.length; i++) {
            DeployedToken memory t_deployedToken = _deployToken(tokenInfos[i]);
            t_deployedTokens[i] = t_deployedToken;
        }

        emit TokensDeployed(t_deployedTokens);
    }

    /**
     * Get the details of all token contracts that was deployed from this Factory contract
     */
    function getDeployedTokens()
        external
        view
        returns (DeployedToken[] memory)
    {
        DeployedToken[] memory t_deployedTokens = new DeployedToken[](
            s_deployedTokenAddresses.length
        );

        TokenInfo memory t_tokenInfo;

        for (uint256 i = 0; i < s_deployedTokenAddresses.length; i++) {
            address t_tokenAddress = s_deployedTokenAddresses[i];
            t_tokenInfo = s_deployedTokenInfo[t_tokenAddress];
            t_deployedTokens[i].tokenInfo = t_tokenInfo;
            t_deployedTokens[i].contractAddress = t_tokenAddress;
        }

        return t_deployedTokens;
    }

    /**
     * Internal function to deploy a single token.
     * @param tokenInfo name and symbol of the token contract being deployed
     */
    function _deployToken(
        TokenInfo memory tokenInfo
    ) internal returns (DeployedToken memory) {
        // deploy new token contract
        ERC20Template t_newToken = new ERC20Template(
            tokenInfo.name,
            tokenInfo.symbol,
            _msgSender()
        );

        address t_newTokenAddress = address(t_newToken);

        // save to mapping storage
        s_deployedTokenAddresses.push(t_newTokenAddress);
        s_deployedTokenInfo[t_newTokenAddress] = tokenInfo;

        return DeployedToken(tokenInfo, t_newTokenAddress);
    }
}
