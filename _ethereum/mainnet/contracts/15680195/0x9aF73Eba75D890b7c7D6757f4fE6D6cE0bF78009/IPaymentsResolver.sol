// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title IPaymentsResolver
 * @author NeatFi
 * @notice Interface to the {PaymentsResolver} contract of NeatFi.
 */
interface IPaymentsResolver {
    /**
     * @notice Calculates the earnings of an English Auction maker based on the
     *         Order purchase value.
     * @dev Called only from the NeatFi contract.
     * @param value - The purchase value of the English Auction Order.
     * @return makerEarnings - The value in native tokens (i.e Eth for Ethereum) that
     *                         the Order maker will receive.
     */
    function englishAuctionFeeResolver(uint256 value)
        external
        view
        returns (uint256 makerEarnings);

    /**
     * @notice Calculates the earnings of a Dutch Auction maker based on the
     *         Order purchase value.
     * @dev Called only from the NeatFi contract.
     * @param value - The purchase value of the Dutch Auction Order.
     * @return makerEarnings - The value in native tokens (i.e Eth for Ethereum) that
     *                         the Order maker will receive.
     */
    function dutchAuctionFeeResolver(uint256 value)
        external
        view
        returns (uint256 makerEarnings);

    /**
     * @notice Calculates the earnings of a Sell Auction maker based on the
     *         Order purchase value.
     * @dev Called only from the NeatFi contract.
     * @param value - The purchase value of the Sell Auction Order.
     * @return makerEarnings - The value in native tokens (i.e Eth for Ethereum) that
     *                         the Order maker will receive.
     */
    function sellFeeResolver(uint256 value)
        external
        view
        returns (uint256 makerEarnings);

    /**
     * @notice Returns the protocol fee for Swap Order creation. Bid type Orders
     *         do not require a protocol fee payment.
     * @dev Called only from the NeatFi contract.
     * @return feeToBePaid - The value in native tokens (i.e Eth for Ethereum) that
     *                       the Order maker must pay for the Order creation.
     */
    function swapFeeResolver() external view returns (uint256 feeToBePaid);
}
