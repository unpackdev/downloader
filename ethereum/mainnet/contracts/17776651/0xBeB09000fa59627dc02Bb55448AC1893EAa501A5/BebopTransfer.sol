// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDaiLikePermit.sol";
import "./IPermit2.sol";
import "./Order.sol";
import "./Signature.sol";
import "./Transfer.sol";
import "./Commands.sol";
import "./SafeCast160.sol";
import "./BebopSigning.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

abstract contract BebopTransfer {

    using SafeERC20 for IERC20;

    address public immutable WRAPPED_NATIVE_TOKEN;
    address public immutable DAI_TOKEN;

    IPermit2 public immutable PERMIT2;

    uint private immutable _chainId;

    function getChainId() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    constructor(address _wrapped_native_token_address, address _permit, address _dai_address) {
        WRAPPED_NATIVE_TOKEN = _wrapped_native_token_address;
        DAI_TOKEN = _dai_address;
        PERMIT2 = IPermit2(_permit);
        _chainId = getChainId();
    }

    function makerTransferFunds(
        address from,
        address to,
        address[] memory maker_tokens,
        uint256[] memory maker_amounts,
        bool usingPermit2,
        bytes memory makerCommands
    ) internal returns (uint256) {
        uint256 nativeToTaker;
        uint256 tokensNum = maker_tokens.length;
        IPermit2.AllowanceTransferDetails[] memory batchTransferDetails = new IPermit2.AllowanceTransferDetails[](tokensNum);
        for (uint j; j < tokensNum; ++j) {
            uint256 amount = maker_amounts[j];
            address receiver = to;
            if (makerCommands[j] != Commands.SIMPLE_TRANSFER){
                if (makerCommands[j] == Commands.TRANSFER_TO_CONTRACT) {
                    receiver = address(this);
                } else if (makerCommands[j] == Commands.NATIVE_TRANSFER) {
                    require(maker_tokens[j] == WRAPPED_NATIVE_TOKEN, "Invalid maker's native transfer");
                    nativeToTaker += amount;
                    receiver = address(this);
                } else {
                    revert("Unknown maker command");
                }
            }
            if (usingPermit2) {
                batchTransferDetails[j] = IPermit2.AllowanceTransferDetails({
                    from: from,
                    to: receiver,
                    amount: SafeCast160.toUint160(amount),
                    token: maker_tokens[j]
                });
            } else {
                IERC20(maker_tokens[j]).safeTransferFrom(from, receiver, amount);
            }
        }
        if (usingPermit2){
            PERMIT2.transferFrom(batchTransferDetails);
        }

        return nativeToTaker;
    }

    function permitToken(
        address takerAddress,
        address tokenAddress,
        uint deadline,
        bytes memory permitSignature
    ) internal {
        (bytes32 r, bytes32 s, uint8 v) = Signature.getRsv(permitSignature);

        if (tokenAddress == DAI_TOKEN){
            if (_chainId == 137){
                IDaiLikePermit(tokenAddress).permit(
                    takerAddress, address(this), IDaiLikePermit(tokenAddress).getNonce(takerAddress), deadline, true, v, r, s
                );
            } else {
                IDaiLikePermit(tokenAddress).permit(
                    takerAddress, address(this), IERC20Permit(tokenAddress).nonces(takerAddress), deadline, true, v, r, s
                );
            }
        } else {
            IERC20Permit(tokenAddress).permit(takerAddress, address(this), type(uint).max, deadline, v, r, s);
        }

    }

}
