// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IBridge.sol";
import "./IDex.sol";

/**
// @title Wagpay bridge aggregator main contract.
// @notice This contract is responsible for calling bridge and dex implementation contracts
// and for adding/removing/storing bridge and dex ids.
*/
contract WagPayBridge is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _bridgeIds;
    Counters.Counter private _dexIds;
	address private constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // mapping to get bridge address from bridge id
    mapping(uint => address) bridges;

    // mapping to get dex address from dex id
    mapping(uint => address) dexes;

    event transferComplete(uint toChainId, uint bridgeId, bool dexRequired, uint dexId, address tokenAddress);

    /**
    // @param dexId Id of dex
    // @param amountIn amount of input tokens
    // @param amountOut amount of output tokens
    // @param fromToken address of input token
    // @param toToken address of output token
    // @param extraData extra data if required
     */
    struct DexData {
        uint dexId;
        uint amountIn;
        uint amountOut;
        address fromToken;
        address toToken;
        bytes extraData;
    }

    /** 
    // @param receiver address of receiver
    // @param bridgeId Id of bridge
    // @param toChain Id of destination chain
    // @param fromToken address of input token
    // @param amount amount of tokens to bridge
    // @param extraData extra data if required
    // @param dexRequired boolean to check if dex is required
    // @param dex Dex data to perform swap
     */
    struct RouteData {
        address receiver;
        uint bridgeId;
        uint64 toChain;
        address fromToken;
        uint amount;
        bytes extraData;
        bool dexRequired;
        DexData dex;
    }

    /**
    // @notice function responsible to call required bridge and dex
    // @param route data required to perform execution
     */
    function transfer(RouteData memory route) external payable nonReentrant {

        require(bridges[route.bridgeId] != address(0), "WagPay: Bridge doesn't exist");        

        IDex idex = IDex(dexes[route.dex.dexId]);
        IBridge bridge = IBridge(bridges[route.bridgeId]);

        // Check if swapping is required
        if(route.dexRequired) {
            if(route.dex.fromToken == NATIVE_TOKEN_ADDRESS) {
                // swap Native -> ERC20
                idex.swapNative{value: route.amount}(route.dex.toToken, route.dex.extraData);
            } else {
                // swap ERC20 -> ERC20 / ERC20 -> Native
                IERC20(route.fromToken).transferFrom(msg.sender, address(this), route.amount);
                IERC20(route.fromToken).approve(dexes[route.dex.dexId], route.amount);
                idex.swapERC20(route.dex.fromToken, route.dex.toToken, route.dex.amountIn,  route.dex.extraData);
            }

            // Bridge
            if(route.dex.toToken == NATIVE_TOKEN_ADDRESS) {
                bridge.transferNative{value: route.dex.amountOut}(route.dex.amountOut, route.receiver, route.toChain, route.extraData);
            } else {
                IERC20(route.dex.toToken).approve(bridges[route.bridgeId], route.dex.amountOut);
                bridge.transferERC20(route.toChain, route.dex.toToken, route.receiver, route.dex.amountOut, route.extraData);
            }

        } else {
            // Bridge
            if(route.fromToken == NATIVE_TOKEN_ADDRESS) {
                bridge.transferNative{value: route.amount}(route.amount, route.receiver, route.toChain, route.extraData);
            } else {
                IERC20(route.fromToken).transferFrom(msg.sender, address(this), route.amount);
                IERC20(route.fromToken).approve(bridges[route.bridgeId], route.amount);
                bridge.transferERC20(route.toChain, route.fromToken, route.receiver, route.amount, route.extraData);
            }
        }

        emit transferComplete(route.toChain, route.bridgeId, route.dexRequired, route.dex.dexId, route.fromToken);
    }

    /**
    // @notice function responsible to add new bridge
    // @param _newBridge address of bridge 
     */
    function addBridge(address _newBridge) external onlyOwner returns (uint) {
        require(_newBridge != address(0), "WagPay: Cannot be a address(0)");
        _bridgeIds.increment();
        uint bridgeId = _bridgeIds.current();
        bridges[bridgeId] = _newBridge;
        return bridgeId;
    }

    /**
    // @notice function responsible to remove bridge
    // @param _bridgeId Id of bridge 
     */
    function removeBridge(uint _bridgeId) external onlyOwner {
        require(bridges[_bridgeId] != address(0), "WagPay: Bridge doesn't exist");
        bridges[_bridgeId] = address(0);
    }

    /**
    // @notice function to get address of bridge
    // @param _bridgeId Id of bridge 
     */
    function getBridge(uint _bridgeId) external view returns (address) {
        return bridges[_bridgeId];
    }

    /**
    // @notice function responsible to add new dex
    // @param _newDex address of dex 
     */
    function addDex(address _newDex) external onlyOwner returns (uint) {
        require(_newDex != address(0), "WagPay: Cannot be a address(0)");
        _dexIds.increment();
        uint dexId = _dexIds.current();
        dexes[dexId] = _newDex;
        return dexId;
    }

    /**
    // @notice function responsible to remove bridge
    // @param _dexId Id of bridge 
     */
    function removeDex(uint _dexId) external onlyOwner {
        require(dexes[_dexId] != address(0), "WagPay: Dex doesn't exist");
        dexes[_dexId] = address(0);
    }

    /**
    // @notice function to get address of dex
    // @param _dexId Id of dex 
     */
    function getDex(uint _dexId) external view returns (address) {
        return dexes[_dexId];
    }

    /**
	// @notice function responsible to rescue funds if any
	// @param  tokenAddr address of token
	 */
    function rescueFunds(address tokenAddr) external onlyOwner nonReentrant {
        if (tokenAddr == NATIVE_TOKEN_ADDRESS) {
            uint balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            uint balance = IERC20(tokenAddr).balanceOf(address(this));
            IERC20(tokenAddr).transferFrom(address(this), msg.sender, balance);
        }
    }
}
