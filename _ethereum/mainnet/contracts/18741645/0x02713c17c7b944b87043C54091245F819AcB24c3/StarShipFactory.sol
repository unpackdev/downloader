// SPDX-License-Identifier: UNLICENSED
// Starship Contract Factory
// Powered by Agora

pragma solidity 0.8.21;

import "./IAgoraERC20.sol";
import "./Context.sol";
import "./IStarShipDeployer.sol";
import "./IAgoraERC20Config.sol";
import "./IFactoryErrors.sol";
import "./Nukable.sol";
import "./Authoritative.sol";

/**
 * @dev Starship contract factory
 */
contract StarShipFactory is
    Context,
    Nukable,
    Authoritative,
    IAgoraERC20Config,
    IFactoryErrors
{
    uint256 internal constant CALL_GAS_LIMIT = 50000;

    // The contract implementing UniswapV2 protocol
    address public immutable uniswapRouterV2InterfaceAddress;

    mapping(address => address) _lastTokens;

    // Contract to deploy tokens
    address payable public deployerAddress;

    // The address where all the eth collected by the service will end up in.
    address public treasuryAddress;

    // LP locker
    address public locker;

    // The cost in ether to deploy a token
    uint256 public deploymentFee = 0.1 ether;

    uint256 public lockFee = 0.1 ether;

    /**
     *
     * @param superAdmin The supreme ruler of the factory, can do everything
     * @param admins The list of wallets that can perofrm operations with elevated privileges
     * @param treasury Where the collection of taxes will go
     */
    constructor(
        address superAdmin,
        address[] memory admins,
        address treasury,
        address tokenLocker,
        address uniswapRouter
    ) {
        SuperAdmin = superAdmin;
        GrantPlatformAdmin(superAdmin);
        for (uint256 i = 0; i < admins.length; ) {
            GrantPlatformAdmin(admins[i]);
            unchecked {
                i++;
            }
        }

        if (treasury == address(0)) {
            Revert(TreasuryAddressCanNotBeNull.selector);
        }

        if (uniswapRouter == address(0)) {
            Revert(RouterAddressCanNotBeNull.selector);
        }
        uniswapRouterV2InterfaceAddress = uniswapRouter;
        treasuryAddress = treasury;
        locker = tokenLocker;
    }

    function setTreasury(address newAddress) external onlySuperAdmin{
        treasuryAddress = newAddress;
    }

    function withdrawEth() external onlySuperAdmin {
        uint256 gas = (CALL_GAS_LIMIT == 0 || CALL_GAS_LIMIT > gasleft())
            ? gasleft()
            : CALL_GAS_LIMIT;

        bool success;
        // We limit the gas passed so that a called address cannot cause a block out of gas error:
        (success, ) = SuperAdmin.call{value: address(this).balance, gas: gas}(
            ""
        );
    }

    function SetDeployerAddress(
        address newDeployerAddress
    ) external onlySuperAdmin {
        deployerAddress = payable(newDeployerAddress);
    }

    function GetLastCreatedToken() public view returns (address) {
        return _lastTokens[_msgSender()];
    }

    function NukeFactory() external onlySuperAdmin {
        Nuke();
    }

    function CreateNewERC20(
        bytes32 salt,
        string calldata deploymentID,
        TokenConstructorParameters calldata tokenConfig
    ) external payable IfNotNuked returns (address erc20Address) {
        address[5] memory integrationAddresses = [
            _msgSender(),
            uniswapRouterV2InterfaceAddress,
            locker,
            address(this),
            treasuryAddress
        ];

        TokenLpInfo memory tokenLpInfo = abi.decode(
            tokenConfig.tokenLPInfo,
            (TokenLpInfo)
        );
        tokenLpInfo.lockFee = lockFee;

        bytes memory args = abi.encode(
            integrationAddresses,
            tokenConfig.baseParameters,
            tokenConfig.taxParameters,
            abi.encode(tokenLpInfo)
        );

        address tokenAddress = IStarShipDeployer(deployerAddress)
            .DeployNewToken(
                salt,
                keccak256(abi.encodePacked(deploymentID)),
                args
            );
        _lastTokens[_msgSender()] = tokenAddress;

        // Decoding paramets
        TokenInfoParameters memory tokenInfo = abi.decode(
            tokenConfig.baseParameters,
            (TokenInfoParameters)
        );

        if (tokenInfo.autoCreateLiquidity) {
            TokenLpInfo memory lpInfo = abi.decode(
                tokenConfig.tokenLPInfo,
                (TokenLpInfo)
            );
            _processLiquidityParams(tokenAddress, lpInfo, tokenInfo);
        }

        return tokenAddress;
    }

    function _processLiquidityParams(
        address tokenAddress,
        TokenLpInfo memory params,
        TokenInfoParameters memory configParams
    ) internal {
        uint256 totalFee = params.ethForSupply;
        uint256 totalLiquidityFee = totalFee;
        if (!configParams.payInTax) {
            totalFee += deploymentFee;
        }

        if (!params.burnLP) {
            totalFee += lockFee;
            totalLiquidityFee += lockFee;
        }

        if (msg.value < totalFee) {
            Revert(TransactionUnderpriced.selector);
        }

        IAgoraERC20(tokenAddress).addLiquidity{value: totalLiquidityFee}();
    }
}
