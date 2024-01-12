// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
import "./ILendPoolAddressesProvider.sol";

interface IFeeDistributor {
    event Distributed(uint256 time, uint256 tokenAmount);

    event Claimed(
        address indexed recipient,
        uint256 amount,
        uint256 claimEpoch,
        uint256 maxEpoch
    );

    function lastDistributeTime() external view returns (uint256);

    function distribute() external;

    function claim(bool weth) external returns (uint256);

    function claimable(address _addr) external view returns (uint256);

    function addressesProvider()
        external
        view
        returns (ILendPoolAddressesProvider);

    function bendCollector() external view returns (address);
}
