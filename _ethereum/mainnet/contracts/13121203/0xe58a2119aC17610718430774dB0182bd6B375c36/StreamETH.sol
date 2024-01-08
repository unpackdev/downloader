// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";

contract StreamETH is Ownable {
    address[] public _recipients;
    uint256[] public _shareBPS;

    event Distributed(uint256 balance);
    event RecipientsUpdated(address[] recipients, uint256[] shareBPS);

    constructor(
        address _owner,
        address[] memory recipients,
        uint256[] memory shareBPS
    ) {
        updateRecipients(recipients, shareBPS);
        Ownable.transferOwnership(_owner);
    }

    receive() external payable {}

    /* user functions */

    function distribute() public {
        // get balance
        uint256 balance = address(this).balance;
        // transfer to recipients
        for (uint256 index = 0; index < _recipients.length; index++) {
            payable(_recipients[index]).transfer((balance * _shareBPS[index]) / 10_000);
        }
        // emit event
        emit Distributed(balance);
    }

    /* admin functions */

    function updateRecipients(address[] memory recipients, uint256[] memory shareBPS)
        public
        onlyOwner
    {
        // clear storage
        delete _recipients;
        delete _shareBPS;
        assert(_recipients.length == 0 && _shareBPS.length == 0);
        // sumBPS distribution
        uint256 sumBPS = 0;
        for (uint256 index = 0; index < recipients.length; index++) {
            sumBPS += shareBPS[index];
        }
        require(sumBPS == 10_000, "invalid sum");
        // update storage
        _recipients = recipients;
        _shareBPS = shareBPS;
        // emit event
        emit RecipientsUpdated(recipients, shareBPS);
    }
}
