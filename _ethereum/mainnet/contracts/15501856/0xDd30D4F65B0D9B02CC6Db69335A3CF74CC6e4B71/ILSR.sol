//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILSRFactory {
    function getAllLSRs()
        external
        view
        returns (
            address[] memory _allLsrs,
            address[] memory _msds,
            address[] memory _mprs
        );
}

interface ILSR {
    function mpr() external view returns (address);

    //可以购买usx数量
    function msdQuota() external view returns (uint256);

    //可以卖出usx数量
    function mprOutstanding() external returns (uint256);

    function getAmountToBuy(uint256 _amountIn) external view returns (uint256);

    function getAmountToSell(uint256 _amountIn) external view returns (uint256);

    function buyMsd(uint256 _amountIn) external;

    function sellMsd(uint256 _amountIn) external;

    function strategy() external view returns (address);
}

interface ILSRStrategy {
    //付出代币的最多数量
    function limitOfDeposit() external returns (uint256);

    //买的时候 true暂停，false可以
    function depositStatus() external returns (bool);

    //卖，true是暂停
    function withdrawStatus() external returns (bool);
}
