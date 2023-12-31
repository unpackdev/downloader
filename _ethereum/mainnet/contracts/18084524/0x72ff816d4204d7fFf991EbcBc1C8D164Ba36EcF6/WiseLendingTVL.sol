// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

/**
 * @author Christoph Krpoun
 */

interface IWiseLending {

    function getPseudoTotalPool(
        address _token
    )
        external
        view
        returns (uint256);
}

interface IWiseOracleHub {

    function getTokensInUSD(
        address _tokenAddress,
        uint256 _amount
    )
        external
        view
        returns (uint256);
}

interface IFeeManager {

    function getPoolTokenAdressesByIndex(
        uint256 _index
    )
        external
        view
        returns (address);

    function getPoolTokenAddressesLength()
        external
        view
        returns (uint256);
}

/**
 * @dev Smart contract to querry the TVL [total value locked] for wise lending on-chain.
 * To take into account the borrowed amounts it computest the usd value of all pseudo token
 * amounts from each pool and sums them up.
 *
 * For more infos see {https://wisesoft.gitbook.io/wise/}
 */

contract WiseLendingTVL {

    IFeeManager constant FEE_MANAGER = IFeeManager(
        0x0bC24E61DAAd6293A1b3b53a7D01086BfF0Ea6e5
    );

    IWiseLending constant WISE_LENDING = IWiseLending(
        0x84524bAa1951247b3A2617A843e6eCe915Bb9674
    );

    IWiseOracleHub constant ORACLE_HUB = IWiseOracleHub(
        0xD2cAa748B66768aC9c53A5443225Bdf1365dd4B6
    );

    constructor() {}

    /**
     * @dev External view function returing the TVL of wise lending.
     * Note that the order is 1E18, meaning that 1 USD corresponds
     * to 1E18.
     */
    function getTVL()
        external
        view
        returns (uint256)
    {
        uint8 i;
        uint256 tvl;
        address poolToken;

        while (i < FEE_MANAGER.getPoolTokenAddressesLength()) {

            poolToken = FEE_MANAGER.getPoolTokenAdressesByIndex(
                i
            );

            tvl += ORACLE_HUB.getTokensInUSD(
                poolToken,
                WISE_LENDING.getPseudoTotalPool(
                    poolToken
                )
            );

            i++;
        }

        return tvl;
    }
}
