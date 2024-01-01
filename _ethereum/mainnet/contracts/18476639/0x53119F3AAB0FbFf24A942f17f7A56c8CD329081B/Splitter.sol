// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;



contract Splitter {
    address owner;
    address public wallet1 =
        payable(0x23b864544862917dE53c858a1CDD657A6dEff965);
    address public wallet2 =
        payable(0x4d2dfE87d913a74088F6970c31F16955383B33F0);

        modifier onlyOwner(){
            require(msg.sender == owner, "You are not auth");
            _;
        }

    receive() external payable {
        split(msg.value);
    }

    fallback() external payable {
        split(msg.value);
    }

    constructor(){
        owner = msg.sender;
    }

    function split(uint256 value) internal {
        uint256 wallet1Value = value / 2;
        uint256 wallet2Value = value - wallet1Value;
        (bool success1, ) = wallet1.call{value: wallet1Value}("");
        (bool success2, ) = wallet2.call{value: wallet2Value}("");
        require(success1 && success2);
    }

    function changeWallets(address _wallet1, address _wallet2) external onlyOwner{
        wallet1 = payable(_wallet1);
        wallet2 = payable (_wallet2);
    }
}