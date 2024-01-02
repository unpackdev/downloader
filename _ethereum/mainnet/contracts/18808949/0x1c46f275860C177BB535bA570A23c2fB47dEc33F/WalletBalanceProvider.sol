// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./IPoolAddressesProvider.sol";
import "./IPool.sol";
import "./DataTypes.sol";
import "./ReserveConfiguration.sol";

contract WalletBalanceProvider {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    address constant MOCK_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Check the token balance of a wallet in a token contract
     *
     * Returns the balance of the token for user. Avoids possible errors:
     *   - return 0 on non-contract address
     *
     */
    function balanceOf(address user, address token) public view returns (uint256) {
        if (token == MOCK_ETH_ADDRESS) {
            return user.balance; // ETH balance
                // check if token is actually a contract
        } else if (token.code.length > 0) {
            return IERC20(token).balanceOf(user);
        }
        revert("INVALID_TOKEN");
    }

    /**
     * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
     * @param users The list of users
     * @param tokens The list of tokens
     * @return And array with the concatenation of, for each user, his/her balances
     *
     */
    function batchBalanceOf(address[] calldata users, address[] calldata tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](users.length * tokens.length);

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                balances[i * tokens.length + j] = balanceOf(users[i], tokens[j]);
            }
        }

        return balances;
    }

    /**
     * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
     * @param users The list of users
     * @param tokens The list of tokens
     * @param ids the list of ids
     * @return And array with the concatenation of, for each user, his/her balances
     *
     */
    function batchERC1155BalanceOf(address[] calldata users, address[] calldata tokens, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory)
    {
        require(tokens.length == ids.length, "INVALID_INPUT");
        uint256[] memory balances = new uint256[](users.length * tokens.length);

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                balances[i * tokens.length + j] = IERC1155(tokens[j]).balanceOf(users[i], ids[j]);
            }
        }

        return balances;
    }

    /**
     * @dev provides balances of user wallet for all reserves available on the pool
     */
    function getUserWalletBalances(address provider, address user)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());

        address[] memory reserves = pool.getReservesList();
        address[] memory reservesWithEth = new address[](reserves.length + 1);
        for (uint256 i = 0; i < reserves.length; i++) {
            reservesWithEth[i] = reserves[i];
        }
        reservesWithEth[reserves.length] = MOCK_ETH_ADDRESS;

        uint256[] memory balances = new uint256[](reservesWithEth.length);

        for (uint256 j = 0; j < reserves.length; j++) {
            DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(reservesWithEth[j]);

            (bool isActive,,,) = configuration.getFlags();

            if (!isActive) {
                balances[j] = 0;
                continue;
            }
            balances[j] = balanceOf(user, reservesWithEth[j]);
        }
        balances[reserves.length] = balanceOf(user, MOCK_ETH_ADDRESS);

        return (reservesWithEth, balances);
    }
}
