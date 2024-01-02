// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SafeERC20.sol";
import "./ERC20Burnable.sol";
import "./ReentrancyGuard.sol";
import "./FxBaseRootTunnel.sol";
import "./Ownable.sol";

error InsufficentFunds();

contract Claim51Root is FxBaseRootTunnel, ReentrancyGuard, Ownable {
    event Burned(address indexed user, uint256 amount);

    struct ClaimDetails {
        uint256 totalBurned;
        uint256 tokenAmount;
    }

    address public immutable PILOT_TOKEN;

    uint256 public totalBurnedTokens;

    mapping(address => ClaimDetails) public userDetails;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _pilotToken
    )
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
        Ownable(msg.sender)
    {
        PILOT_TOKEN = _pilotToken;
    }

    function claimToken() external nonReentrant {
        address sender = msg.sender;
        uint256 senderBalance = IERC20(PILOT_TOKEN).balanceOf(sender);
        if (senderBalance == 0) revert InsufficentFunds();

        SafeERC20.safeTransferFrom(IERC20(PILOT_TOKEN), sender, address(this), senderBalance);
        ERC20Burnable(PILOT_TOKEN).burn(senderBalance);
        totalBurnedTokens += senderBalance;

        ClaimDetails storage claimDetails = userDetails[sender];
        claimDetails.tokenAmount = senderBalance;
        claimDetails.totalBurned += senderBalance;

        _sendMessageToChild(abi.encode(sender, claimDetails, totalBurnedTokens));

        emit Burned(sender, senderBalance);
    }

    function _processMessageFromChild(bytes memory data) internal override { }

    function recoverERC20(address _to, address _token) external onlyOwner {
        SafeERC20.safeTransfer(IERC20(_token), _to, IERC20(_token).balanceOf(address(this)));
    }
}
