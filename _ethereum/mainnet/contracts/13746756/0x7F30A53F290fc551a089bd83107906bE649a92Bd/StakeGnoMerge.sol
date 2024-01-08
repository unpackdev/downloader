// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./SafeERC20.sol";

contract StakeGnoMerge is Ownable {
    using SafeERC20 for IERC20;

    // bytes4(keccak256(bytes("permit(address,address,uint256,uint256,uint8,bytes32,bytes32)")));
    bytes4 constant _PERMIT_SIGNATURE = 0xd505accf;

    // Swap ratio from STAKE to GNO multiplied by 1e10
    uint256 public constant SWAP_RATIO = 326292707;

    // STAKE token address
    IERC20 public immutable stake;

    // GNO token address
    IERC20 public immutable gno;

    // UNIX time in seconds when the owner will be able to withdraw the remaining GNO tokens
    uint256 public withdrawTimeout;

    /**
     * @dev Emitted when someone swap STAKE for GNO
     */
    event StakeToGno(
        uint256 stakeAmount,
        uint256 gnoAmount,
        address indexed grantee
    );

    /**
     * @dev Emitted when the owner increases the timeout
     */
    event NewWithdrawTimeout(uint256 newWithdrawTimeout);

    /**
     * @dev Emitted when the owner withdraw tokens
     */
    event WithdrawTokens(address tokenAddress, uint256 amount);

    /**
     * @dev This contract will receive GNO tokens, the users will be able to swap their STAKE tokens for GNO tokens
     *      as long as this contract holds enough amount. The swapped STAKE tokens will be burned.
     *      Once the withdrawTimeout is reached, the owner will be able to withdraw the remaining GNO tokens.
     * @param _stake STAKE token address
     * @param _gno GNO token address
     * @param duration Time in seconds that the owner will not be able to withdraw the GNO tokens
     */
    constructor(
        IERC20 _stake,
        IERC20 _gno,
        uint256 duration
    ) {
        stake = _stake;
        gno = _gno;
        withdrawTimeout = block.timestamp + duration;
    }

    /**
     * @notice Method that allows swap STAKE for GNO tokens at the ratio of 1 STAKE --> 0.0326292707 GNO
     * Users can either use the permit functionality, or approve previously the tokens and send an empty _permitData
     * @param stakeAmount Amount of STAKE to swap
     * @param _permitData Raw data of the call `permit` of the token
     */
    function stakeToGno(uint256 stakeAmount, bytes calldata _permitData)
        public
    {
        // receive and burn STAKE tokens
        if (_permitData.length > 4) {
            // supported signatures:
            // permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32)
            // permit(address,address,uint256,uint256,uint8,bytes32,bytes32)
            require(
                bytes4(_permitData[0:4]) == bytes4(0x8fcbaf0c) ||
                    bytes4(_permitData[0:4]) == bytes4(0xd505accf),
                "StakeGnoMerge: invalid permit signature"
            );
            (bool status, ) = address(stake).call(_permitData);
            require(status, "StakeGnoMerge: permit failed");
        }

        stake.safeTransferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            stakeAmount
        );

        // transfer GNO tokens
        uint256 gnoAmount = (stakeAmount * SWAP_RATIO) / 1e10;
        gno.safeTransfer(msg.sender, gnoAmount);

        emit StakeToGno(stakeAmount, gnoAmount, msg.sender);
    }

    /**
     * @notice Method that allows the owner to withdraw any token from this contract
     * In order to withdraw GNO tokens the owner must wait until the withdrawTimeout expires
     * @param tokenAddress Token address
     * @param amount Amount of tokens to withdraw
     */
    function withdrawTokens(address tokenAddress, uint256 amount)
        public
        onlyOwner
    {
        if (tokenAddress == address(gno)) {
            require(
                block.timestamp > withdrawTimeout,
                "StakeGnoMerge::withdrawTokens: TIMEOUT_NOT_REACHED"
            );
        }

        IERC20(tokenAddress).safeTransfer(owner(), amount);

        emit WithdrawTokens(tokenAddress, amount);
    }

    /**
     * @notice Method that allows the owner to increase the withdraw timeout
     * @param newWithdrawTimeout new withdraw timeout
     */
    function setWithdrawTimeout(uint256 newWithdrawTimeout) public onlyOwner {
        require(
            newWithdrawTimeout > withdrawTimeout,
            "StakeGnoMerge::setWithdrawTimeout: NEW_TIMEOUT_MUST_BE_HIGHER"
        );

        withdrawTimeout = newWithdrawTimeout;

        emit NewWithdrawTimeout(newWithdrawTimeout);
    }
}
