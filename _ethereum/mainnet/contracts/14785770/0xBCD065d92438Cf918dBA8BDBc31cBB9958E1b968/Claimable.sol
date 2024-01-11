// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";

/**
 * @title Claimable Methods
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 * @custom:a Alfredo Lopez / Marketingcycle / ValiFI
 */
contract Claimable is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // Event when the Smart Contract receive Amount of Native or ERC20 tokens
    /**
     * @dev Event when the Smart Contract receive Amount of Native or ERC20 tokens
     * @param sender The address of the sender
     * @param value The amount of tokens
     */
    event ValueReceived(address indexed sender, uint256 indexed value);
    /**
     * @dev Event when the Smart Contract Send Amount of Native or ERC20 tokens
     * @param receiver The address of the receiver
     * @param value The amount of tokens
     */
    event ValueSent(address indexed receiver, uint256 indexed value);

    /// @notice Handle receive ether
    receive() external payable {
        emit ValueReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Throws if a given address is equal to address(0)
     * @param to The address to check
     */
    modifier validAddress(address to) {
        require(to != address(0), "VoxoDeus: Not Add Zero Address");
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param token address of the claimed token or address(0) for native coins.
     * @param to address of the tokens/coins receiver.
     */
    function claimValues(address token, address to)
        public
        validAddress(to)
        onlyOwner
    {
        if (token == address(0)) {
            _claimNativeCoins(to);
        } else {
            _claimErc20Tokens(token, to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param to address of the coins receiver.
     */
    function _claimNativeCoins(address to) private {
        uint256 amount = address(this).balance;

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = to.call{value: amount}("");
        require(
            success,
            "VoxoDeus: Address: unable to send value, recipient may have reverted"
        );
        // Event when the Smart Contract Send Amount of Native or ERC20 tokens
        emit ValueSent(to, amount);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param to address of the tokens receiver.
     */
    function _claimErc20Tokens(address _token, address to) private {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(to, balance);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC721 contract from this contract.
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc721Tokens(address _token, address _to)
        public
        validAddress(_to)
        onlyOwner
    {
        IERC721Upgradeable token = IERC721Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(address(this), _to, balance);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC721 contract from this contract.
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc1155Tokens(
        address _token,
        address _to,
        uint256 _id
    ) public validAddress(_to) onlyOwner {
        IERC1155Upgradeable token = IERC1155Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this), _id);
        bytes memory data = "0x00";
        token.safeTransferFrom(address(this), _to, _id, balance, data);
    }
}
