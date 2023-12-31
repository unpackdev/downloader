pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IT2BRouter.sol";
import "./SafeTransferLib.sol";
import "./ERC20.sol";

contract T2BApproval {
    using SafeTransferLib for ERC20;

    error ZeroAddress();
    error InvalidTokenAddress();


    // Constructor
    constructor(address _t2bRouter) {
        // Set T2b Router.
        IT2BRouter t2bRouter = IT2BRouter(_t2bRouter);

        // Set Max Approvals for supported tokens.
        uint256 tokenIndex = 0;
        while (t2bRouter.supportedTokens(tokenIndex) != address(0)) {
            ERC20(t2bRouter.supportedTokens(tokenIndex)).approve(
                address(t2bRouter),
                type(uint256).max
            );
            unchecked {
                ++tokenIndex;
            }
        }

        selfdestruct(payable(msg.sender));
    }
}
