// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IPriceConsumer {

    /**
     * Network: Ethereum Mainnet
     * Feed Registry: 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
     */

    // function setFeedRegistry(address _registry) external;

    function getFeedRegistryAddress() external view returns (address);

    function decimals(address quote) external view returns (uint8);

    function getCentPriceInWei(uint seqOfCurrency) external view returns (uint);

}
