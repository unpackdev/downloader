// License-Identifier: MIT
pragma solidity 0.8.7;
import "./IOracle.sol";

interface IwOHM {
    function sOHMTowOHM( uint256 amountSOHM ) external view returns ( uint256 amountWOHM);
}

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

contract wOHMOracle is IAggregator {
    IAggregator private constant ohmOracle = IAggregator(0x90c2098473852E2F07678Fe1B6d595b1bd9b16Ed);
    IwOHM public constant wOHM = IwOHM(0xCa76543Cf381ebBB277bE79574059e32108e3E65);

    // Calculates the lastest exchange rate
    // Uses ohm rate and wOHM conversion
    function latestAnswer() external view override returns (int256) {
        return int256(uint256(ohmOracle.latestAnswer()) * uint256(1e18) /  wOHM.sOHMTowOHM(1e9));
    }
}