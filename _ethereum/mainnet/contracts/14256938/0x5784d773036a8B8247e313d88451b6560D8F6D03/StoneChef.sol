import "./StonesUtils.sol";

pragma solidity ^0.6.12;


contract StoneChef is Ownable {

    uint public maxId = 6;

    function calcPrice(uint _Id) public view returns (uint256) {
        // LINK Stone (Chainlink capabilities)
        if (_Id == 5) {
            return (20 ether);
        }

        // UNI Stone (Uniswap capabilities)
        if (_Id == 4) {
            return (20 ether);
        }

        // COMP Stone (Compound capabilities)
        if (_Id == 3) {
            return (20 ether);
        }

        // AAVE Stone (AAVE capabilities)
        if (_Id == 2) {
            return (20 ether);
        }

        // DAI Stone (Maker SAI/DAI capabilities)
        if (_Id == 1) {
            return (30 ether);
        }

        // YFI Stone (Yearn capabilities)

        // PROMINT Stone (DeFi Mint capabilities)

        // HUT (full access to DeWorld)
        if (_Id == 0) {
            return (30 ether);
        }

    }

}
