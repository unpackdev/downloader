// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Paradox.sol";

contract ParadoxClaim is Ownable {
    Paradox public paradox;
    bool public claimingStarted;
    mapping(address => uint256) public claimableTokens;

    constructor(address _keyAddress) {
        paradox = Paradox(_keyAddress);
    }

    function claim() external {
        require(claimingStarted, "Claim phase has not started");
        uint256 tokens = claimableTokens[msg.sender];
        require(tokens > 0, "Nothing to claim");
        claimableTokens[msg.sender] = 0;
        require(
            paradox.transfer(msg.sender, tokens),
            "Oops, Something went wrong"
        );
    }

    function updateClaimableTokens(
        address[] memory _recipients,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(_recipients.length == _amounts.length);

        uint256 totalAmount;
        for (uint256 i; i < _amounts.length; ++i) {
            totalAmount += _amounts[i];
            claimableTokens[_recipients[i]] = _amounts[i];
        }

        require(
            paradox.transferFrom(msg.sender, address(this), totalAmount),
            "Oops, Something went wrong"
        );
    }

    function startClaim() external onlyOwner {
        claimingStarted = true;
    }

    function rescueTokens() external onlyOwner {
        paradox.transfer(msg.sender, paradox.balanceOf(address(this)));
    }
}
