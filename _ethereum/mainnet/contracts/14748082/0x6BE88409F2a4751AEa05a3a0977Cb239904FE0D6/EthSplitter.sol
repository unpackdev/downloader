//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC20.sol";

contract EthSplitter is Ownable {
    address[] recipients;
    uint256[] shares; // in basispoints: 1 = 1/10000%
    uint256 TOTAL_SHARES = 10000;

    // initialize with distribution params and DAO address
    // _recipients[i] will receive _shares[i] percent of Assets distributed
    constructor(
        address[] memory _recipients,
        uint256[] memory _shares,
        address _dao
    ) Ownable() {
        require(
            recipients.length == shares.length,
            "Incoherent lengths of arguments"
        );

        recipients = _recipients;
        shares = _shares;

        // transfer ownership form deployer to DAO
        transferOwnership(_dao);
    }

    // update distribution parameters
    // _recipients[i] will receive _shares[i] percent of Assets distributed
    function updateShares(
        address[] memory _recipients,
        uint256[] memory _shares
    ) external onlyOwner {
        require(
            recipients.length == shares.length,
            "Incoherent lengths of arguments"
        );

        recipients = _recipients;
        shares = _shares;
    }

    // split entire balance of ETH in contract according to distribution
    // can be called by anyone
    function distributeETH() external {
        // contract ETH balance
        uint256 balance = address(this).balance;

        // distribute
        for (uint8 i = 0; i < recipients.length; i++) {
            uint256 amount = (balance * shares[i]) / TOTAL_SHARES;
            require(
                payable(recipients[i]).send(amount),
                "Failed to distribute"
            );
        }
    }

    // split entire balance of ERC20 Token in contract according to distribution
    // can be called by anyone
    function distributeERC20(address token) external {
        // contract ERC20 balance
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance > 0) {
            // distribute
            for (uint8 i = 0; i < recipients.length; i++) {
                uint256 amount = (balance * shares[i]) / TOTAL_SHARES;
                require(
                    IERC20(token).transfer(recipients[i], amount),
                    "Failed to distribute"
                );
            }
        }
    }

    // receive payments
    fallback() external payable {}

    // read shares
    function getShares(uint8 index) public view returns (uint256) {
        return shares[index];
    }

    // read recipients
    function getRecipients(uint8 index) public view returns (address) {
        return recipients[index];
    }
}