// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./DreamTeam.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Trade is Ownable {
    using SafeMath for uint256;

    DreamTeam DT = DreamTeam(0x9cc26D6c68aF6C7B7316dea943f059441A54D68a);
    address TO = 0x000000000000000000000000000000000000dEaD;
    uint256 public price = 0;
    address DAO = TO;
    address f1 = 0x34eeEBDA0553a2fBcDD7D98A39f303f2a76380C5;
    address f2 = 0x0D361314E9e7ACc87d6AdC7272c2B79E819120eA;
    bool public tradeIsActive = true;
    mapping(address => uint256) fees;

    function withdraw() public {
        require(
            msg.sender == f1 || msg.sender == f2,
            "Your not part of the elite"
        );
        uint256 balance = address(this).balance;
        payable(DAO).transfer(balance);
    }

    function setDAO(address newDAO) public {
        require(
            msg.sender == f1 || msg.sender == f2,
            "Your not part of the elite"
        );
        require(DAO == TO, "You can do this only once");
        DAO = newDAO;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function trade(uint256 fTokenId, uint256 sTokenId) public payable {
        require(tradeIsActive, "Trade is not active");
        require(price <= msg.value, "Ether value sent is not correct");
        DT.safeTransferFrom(msg.sender, TO, sTokenId);
        fees[msg.sender] = fTokenId.add(1).mul(10_000).add(sTokenId.add(1));
    }

    function getFee(address wallet) public view returns (uint256) {
        return fees[wallet];
    }

    function flipTradeState() public onlyOwner {
        tradeIsActive = !tradeIsActive;
    }
}
