// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./EthereumConstants.sol";
import "./IEthereumPortal.sol";

/// @title Main entry point on ethereum network. Sends messages to its counterpart on polygon
/// @dev the main mechanism is polygon's state sync, see https://docs.polygon.technology/docs/contribute/state-sync/state-sync
contract EthereumPortal is EthereumConstants, IEthereumPortal, Ownable {
    address public polygonContract;

    constructor() Ownable() {}

    /** @param _polygonContract address of the polygon contract */
    function initialize(address _polygonContract) external onlyOwner {
        polygonContract = _polygonContract;
    }

    /**
     *  @param tokenIn The ERC20 token to deposit
     *  @param amountIn The amount of tokens to deposit
     *  @param routerAddress The address of the router contract on L2
     *  @param routerArguments Calldata to execute the desired swap on L2
     *  @param calls Calldata to purchase NFT on L2
     *  @dev The L1 function to execute a cross chain purchase with an ERC20 on L2
     */
    function depositERC20(
        IERC20 tokenIn,
        uint256 amountIn,
        address routerAddress,
        bytes calldata routerArguments,
        bytes calldata calls
    ) external {
        require(
            CHAIN_MANAGER.rootToChildToken(address(tokenIn)) != address(0x0),
            "EthereumPortal: TOKEN MUST BE MAPPED"
        );

        bool success = tokenIn.transferFrom(msg.sender, address(this), amountIn);
        require(success, "funds transfer failed");
        tokenIn.approve(ERC20_PREDICATE, amountIn);

        CHAIN_MANAGER.depositFor(polygonContract, address(tokenIn), abi.encode(amountIn));

        FX_ROOT.sendMessageToChild(
            polygonContract,
            abi.encode(
                CHAIN_MANAGER.rootToChildToken(address(tokenIn)),
                amountIn,
                msg.sender,
                routerAddress,
                routerArguments,
                calls
            )
        );
    }

    /**
     *  @param routerAddress The address of the router contract on L2
     *  @param routerArguments Calldata to execute the desired swap on L2
     *  @param calls Calldata to purchase NFT on L2
     *  @dev The L1 function to execute a cross chain purchase with ETH on L2
     */
    function depositEther(
        address routerAddress,
        bytes calldata routerArguments,
        bytes calldata calls
    ) external payable {
        CHAIN_MANAGER.depositEtherFor{value: msg.value}(polygonContract);

        FX_ROOT.sendMessageToChild(
            polygonContract,
            abi.encode(WETH, msg.value, msg.sender, routerAddress, routerArguments, calls)
        );
    }
}
