// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20Upgradeable.sol";

interface IveDF is IERC20Upgradeable {
    function create(
        address _recipient,
        uint256 _amount,
        uint256 _duration
    ) external returns (uint96);

    function refresh(
        address _recipient,
        uint256 _amount,
        uint256 _duration
    ) external returns (uint96, uint256);

    function refresh2(
        address _recipient,
        uint256 _amount,
        uint256 _duration
    ) external returns (uint96);

    function refill(address _recipient, uint256 _amount)
        external
        returns (uint96);

    function extend(address _recipient, uint256 _duration)
        external
        returns (uint96);

    function withdraw(address _from) external returns (uint96);

    function withdraw2(address _from) external returns (uint96);

    /**
     * @dev Used to query the information of the locker.
     * @param _lockerAddress veDF locker address.
     * @return Information of the locker.
     *         due time;
     *         Lock up duration;
     *         Lock up sDF amount;
     */
    function getLocker(address _lockerAddress)
        external
        view
        returns (
            uint32,
            uint32,
            uint96
        );

    /**
     * @dev Calculate the expected amount of users.
     * @param _lockerAddress veDF locker address.
     * @param _amount Staked DF token amount.
     * @param _duration Duration, in seconds.
     * @return veDF amount.
     */
    function calcBalanceReceived(
        address _lockerAddress,
        uint256 _amount,
        uint256 _duration
    ) external view returns (uint256);

    function getAnnualInterestRate(
        address _lockerAddress,
        uint256 _amount,
        uint256 _duration
    ) external view returns (uint256);
}
