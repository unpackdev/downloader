import "./StoneUtils.sol";

pragma solidity ^0.6.12;

contract StoneChef is Ownable {

    uint public maxId = 20;

    function calcPrice(uint _Id) public view returns (uint256) {

        // DAI Stone - Maker SAI/DAI capabilities
        if (_Id >= 16 && _Id <=  20) {
            return (5 ether / 10);
        }

        // YFI Stone (Yearn capabilities)

        // PROMINT Stone (DeFi Mint capabilities)

        // HUT - early VIP founder access to DeWorld
        if (_Id >= 0 && _Id <=  15) {
            return (3 ether);
        }

    }

}
