// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.0;

interface IVesting {

    struct Investor {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 lastClaimedBlock;
        uint256 rewardPerBlock;
        uint256 personalBlockStart;
        uint256 personalBlockEnd;
    }

    /// @notice Get amount of tokens were released for investor (msg.sender) at this moment
    /// @return amount The amount were released
    function getReleasedAmount(address investor) external view returns (uint256 amount);

    /// @notice Get amount of tokens were locked for investor (msg.sender)
    /// @return amount The amount for distribution
    function getLockedAmount(address investor) external view returns (uint256 amount);

    /// @notice Get total amount, locked up tokens
    /// @return amount The total amount for distribution
    function getTotalLockedAmount() external view returns (uint256 amount);

    /// @notice Get total amount, released tokens
    /// @return amount The total amount of released tokens
    function getTotalReleasableAmount() external view returns (uint256 amount);

    /// @notice Get amount of current released tokens of investor
    /// @return amount The amount of released tokens
    function getReleasableAmount(address investor) external view returns (uint256 amount, uint256 currentBlock);

    /// @notice Claim current released amount by investor
    function claim() external;

    /// @notice Owner has the possibility to specify investors.
    /// @param addresses The addresses for distribution
    /// @param amounts The amounts for distribution
    /// addresses and amounts length must be equal
    /// onlyOwner modifier must be provided
    function specifyInvestors(address[] calldata addresses, uint256[] calldata amounts, uint8[] calldata periods) external;

    /// @notice Owner has the possibility to add new investor.
    /// @param investor The address of new investor
    /// @param amount The amount for distribution
    /// onlyOwner modifier must be provided
    function addInvestor(address investor, uint256 amount, uint8 period) external;

    /// @notice Owner has the possibility to change address of existing investor.
    /// @param oldAddress The old address of investor
    /// @param newAddress The new address of investor
    /// onlyOwner modifier must be provided
    function changeInvestorAddress(address oldAddress, address newAddress) external;



    //Events
    /// @notice Emitted when tokens was claimed
    /// @param investor The address of investor who received tokens
    /// @param amount The number of claimed tokens
    event Claimed(address investor, uint256 amount);

    /// @notice Emitted when one investor was added
    /// @param investor The address of investor which was added
    /// @param amount The number of tokens for added investor
    event InvestorAdded(address investor, uint256 amount, uint8 period);

    /// @notice Emitted when owner change investor address
    /// @param oldAddress The old address of investor
    /// @param newAddress The new address of investor
    event InvestorChanged(address oldAddress, address newAddress);
}
