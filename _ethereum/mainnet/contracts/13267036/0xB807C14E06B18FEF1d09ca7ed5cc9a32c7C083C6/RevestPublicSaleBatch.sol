// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

/**
 * Batch sale means that all tokens will be divided proportionally among all contributors.
 * Price is determined by the amount of ETH sent, therefore no need to set price variable here
 */
contract RevestPublicSaleBatch is Ownable {

    address public token; // RVST
    uint public tokenAmount; // How much is being sold
    uint public startTimestamp; // When to open the public sale
    uint public earlybirdTimestamp; // When the early bird discount ends
    uint public endTimestamp; // When to close it
    uint public earlybirdBonus; // How much of a premium to apply to early bird contributions
    uint public earlybirdDenominator = 100;

    mapping(address => uint) public allocs; // Maps addresses to contribution amounts
    uint public totalAlloc;

    constructor(uint _startTimestamp, uint _endTimestamp, uint _earlybirdTimestamp, uint _earlybirdBonus) Ownable() {
        require(
            block.timestamp < _startTimestamp
            && _startTimestamp < _earlybirdTimestamp
            && _earlybirdTimestamp < _endTimestamp,
            "E061"
        );
        require(_earlybirdBonus > earlybirdDenominator, "E062");

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        earlybirdTimestamp = _earlybirdTimestamp;
        earlybirdBonus = _earlybirdBonus;
    }

    receive() external payable {
        require(startTimestamp <= block.timestamp && block.timestamp <= endTimestamp, "E063");

        uint amount = msg.value;
        uint effective = block.timestamp <= earlybirdTimestamp ? amount * earlybirdBonus / earlybirdDenominator : amount;
        allocs[msg.sender] += effective;
        totalAlloc += effective;
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claimOnBehalf(address user) external onlyOwner {
        _claim(user);
    }

    function _claim(address user) internal claimable {
        require(allocs[user] > 0, "E064");

        // Calculate amount claimable - this changes based on batch auction, Dutch auction, or crowdsale
        uint amount = claimableTokens(user);
        allocs[user] = 0; // Prevent re-entrancy by updating balances before any external calls

        // Simple implementation: send tokens to users directly
        IERC20(token).transfer(user, amount);

        // Advanced implementation: wrap tokens in FNFTs before sending to users. We need to handle staking cases, not sure that logic belongs here
    }

    function claimableTokens(address user) public view claimable returns (uint) {
        return allocs[user] * tokenAmount / totalAlloc;
    }

    modifier claimable() {
        require(block.timestamp > endTimestamp, "E065");
        require(token != address(0x0), "E066");
        _;
    }

    /**
    * ADMIN FUNCTIONS
    */

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = _tokenAddress;
    }

    function setTokenAmount(uint _tokenAmount) external onlyOwner {
        // Add some checks here to ensure the contract has the proper amount
        tokenAmount = _tokenAmount;
    }

    //Manual function to map seed round allocations
    function manualMapAllocation(address[] memory users, uint[] memory etherAlloc) external onlyOwner {
        uint len = users.length;
        require(len == etherAlloc.length, "E067");
        for(uint iter = 0; iter < len; iter++) {
            uint ethAll = etherAlloc[iter];

            allocs[users[iter]] += ethAll;
            totalAlloc += ethAll;
        }
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success,) = owner().call{value: amount}("");
        require(success, "E068");
    }
}
