// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";

import "./FoundationLib.sol";
import "./EtherReceiver.sol";

contract Foundation is EtherReceiver, Ownable {
    uint256 m_rake_bps;

    constructor() {
        m_rake_bps = FoundationLib.RAKE_BPS_V0;
    }

    function getOurRakeBps() public view returns (uint256) {
        return m_rake_bps;
    }

    function setRakeBps(uint256 _val) public onlyOwner {
        m_rake_bps = _val;
    }

    function calculateFoundationRakeForSalePrice(uint256 _sale_price)
        public
        view
        returns (uint256)
    {
        return (_sale_price * m_rake_bps) / 10000;
    }

    event FundsWithdrawn(address indexed caller, uint256 amount);

    function withdrawFunds() external payable onlyOwner {
        uint256 amount = getBalance();
        console.log("In[withdrawFunds] amount[%d]", amount);
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "failed withdraw eth");

        emit FundsWithdrawn(msg.sender, amount);
    }
}
