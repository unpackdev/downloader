pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./interfaces.sol";
import "./interfaces.sol";
import "./math.sol";
import "./stores.sol";
import "./variables.sol";
import "./events.sol";

contract LiquidityResolver is DSMath, Stores, Variables, Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Borrow Flashloan and Cast spells.
     * @param token Token Address.
     * @param amt Token Amount.
     * @param data targets & data for cast.
     */
    function flashBorrowAndCast(
        address token,
        uint amt,
        uint /* route */,
        bytes memory data
    ) external payable {
        AccountInterface(address(this)).enable(address(instaPool));
        (string[] memory _targets, bytes[] memory callDatas) = abi.decode(data, (string[], bytes[]));

        bytes memory callData = abi.encodeWithSignature("cast(string[],bytes[],address)", _targets, callDatas, address(instaPool));

        instaPool.initiateFlashLoan(token, amt, callData);

        emit LogFlashBorrow(token, amt);
        AccountInterface(address(this)).disable(address(instaPool));
    }

    /**
     * @dev Return token to InstaPool.
     * @param token Token Address.
     * @param amt Token Amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPayback(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable {
        uint _amt = getUint(getId, amt);
        
        IERC20 tokenContract = IERC20(token);

        tokenContract.safeTransfer(address(instaPool), _amt);

        setUint(setId, _amt);

        emit LogFlashPayback(token, _amt);
    }
}

contract ConnectV2InstaPool is LiquidityResolver {
    string public name = "Instapool-v1";
}