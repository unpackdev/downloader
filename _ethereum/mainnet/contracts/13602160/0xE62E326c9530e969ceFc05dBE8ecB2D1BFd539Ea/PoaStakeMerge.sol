// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20Burnable.sol";

contract PoaStakeMerge is Ownable {
    using SafeERC20 for IERC20;

    // bytes4(keccak256(bytes("permit(address,address,uint256,uint256,uint8,bytes32,bytes32)")));
    bytes4 constant _PERMIT_SIGNATURE = 0xd505accf;

    // Swap ratio from POA20 to STAKE multiplied by 1e11
    uint256 public constant SWAP_RATIO = 214308824;

    // POA20 token address
    IERC20 public immutable poa;

    // STAKE token address
    IERC20 public immutable stake;

    // UNIX time in seconds when the owner will be able to withdraw the remaining STAKE tokens
    uint256 public withdrawTimeout;

    /**
     * @dev Emitted when someone swap POA20 for STAKE
     */
    event PoaToStake(
        uint256 poaAmount,
        uint256 stakeAmount,
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
     * @dev This contract will receive STAKE tokens, the users will be able to swap their POA20 tokens for STAKE tokens
     *      as long as this contract holds enough amount. The swapped POA20 tokens will be burned.
     *      Once the withdrawTimeout is reached, the owner will be able to withdraw the remaining STAKE tokens.
     * @param _poa POA20 token address
     * @param _stake STAKE token address
     * @param duration Time in seconds that the owner will not be able to withdraw the STAKE tokens
     */
    constructor(
        IERC20 _poa,
        IERC20 _stake,
        uint256 duration
    ) {
        poa = _poa;
        stake = _stake;
        withdrawTimeout = block.timestamp + duration;
    }

    /**
     * @notice Method that allows swap POA20 for STAKE tokens at the ratio of 1 POA20 --> 0.00214308824 STAKE
     * Users can either use the permit functionality, or approve previously the tokens and send an empty _permitData
     * @param poaAmount Amount of POA20 to swap
     * @param _permitData Raw data of the call `permit` of the token
     */
    function poaToStake(uint256 poaAmount, bytes calldata _permitData) public {
        // receive and burn POA20 tokens
        if (_permitData.length != 0) {
            _permit(address(poa), poaAmount, _permitData);
        }

        poa.safeTransferFrom(msg.sender, address(this), poaAmount);
        ERC20Burnable(address(poa)).burn(poaAmount);

        // transfer STAKE tokens
        uint256 stakeAmount = (poaAmount * SWAP_RATIO) / 1e11;
        stake.safeTransfer(msg.sender, stakeAmount);

        emit PoaToStake(poaAmount, stakeAmount, msg.sender);
    }

    /**
     * @notice Method that allows the owner to withdraw any token from this contract
     * In order to withdraw STAKE tokens the owner must wait until the withdrawTimeout expires
     * @param tokenAddress Token address
     * @param amount Amount of tokens to withdraw
     */
    function withdrawTokens(address tokenAddress, uint256 amount)
        public
        onlyOwner
    {
        if (tokenAddress == address(stake)) {
            require(
                block.timestamp > withdrawTimeout,
                "PoaStakeMerge::withdrawTokens: TIMEOUT_NOT_REACHED"
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
            "PoaStakeMerge::setWithdrawTimeout: NEW_TIMEOUT_MUST_BE_HIGHER"
        );

        withdrawTimeout = newWithdrawTimeout;

        emit NewWithdrawTimeout(newWithdrawTimeout);
    }

    /**
     * @notice Function to extract the selector of a bytes calldata
     * @param _data The calldata bytes
     */
    function _getSelector(bytes memory _data)
        private
        pure
        returns (bytes4 sig)
    {
        assembly {
            sig := mload(add(_data, 32))
        }
    }

    /**
     * @notice Function to call token permit method of extended ERC20
     + @param token ERC20 token address
     * @param _amount Quantity that is expected to be allowed
     * @param _permitData Raw data of the call `permit` of the token
     */
    function _permit(
        address token,
        uint256 _amount,
        bytes calldata _permitData
    ) internal {
        bytes4 sig = _getSelector(_permitData);
        require(
            sig == _PERMIT_SIGNATURE,
            "PoaStakeMerge::_permit: NOT_VALID_CALL"
        );
        (
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(
                _permitData[4:],
                (address, address, uint256, uint256, uint8, bytes32, bytes32)
            );
        require(
            owner == msg.sender,
            "PoaStakeMerge::_permit: PERMIT_OWNER_MUST_BE_THE_SENDER"
        );
        require(
            spender == address(this),
            "PoaStakeMerge::_permit: SPENDER_MUST_BE_THIS"
        );
        require(
            value == _amount,
            "PoaStakeMerge::_permit: PERMIT_AMOUNT_DOES_NOT_MATCH"
        );

        // we call without checking the result, in case it fails and he doesn't have enough balance
        // the following transferFrom should be fail. This prevents DoS attacks from using a signature
        // before the smartcontract call
        /* solhint-disable avoid-low-level-calls */
        address(token).call(
            abi.encodeWithSelector(
                _PERMIT_SIGNATURE,
                owner,
                spender,
                value,
                deadline,
                v,
                r,
                s
            )
        );
    }
}
