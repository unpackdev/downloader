// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IDAOPermission.sol";

interface IDAOToken is IDAOPermission {
    event CreateLPPoolOrLinkLPPool(
        uint256 _baseTokenAmount,
        address _quoteTokenAddress,
        uint256 _quoteTokenAmount,
        uint24 _fee,
        uint160 _sqrtPriceX96,
        int24 _tickLower,
        int24 _tickUpper,
        address _lpPool
    );

    event UpdateLPPool(uint256 _baseTokenAmount);

    event Mint(
        address[] _mintTokenAddressList,
        uint24[] _mintTokenAmountRatioList,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _mintValue
    );

    event BonusWithdrawByTokenIdList(
        address indexed operator,
        uint256[] tokenIdList,
        uint256 token0TotalAmount,
        uint256 token1TotalAmount
    );

    event AddManager(address _manager);
    event RemoveManager(address _manager);
    event TransferOwnership(address _newOwner);

    function staking() external view returns (address);

    function factory() external view returns (address);

    function lpRatio() external view returns (uint256);

    function temporaryAmount() external view returns (uint256);

    function lpToken0() external view returns (address);

    function lpToken1() external view returns (address);

    function lpPool() external view returns (address);

    function UNISWAP_V3_POSITIONS() external view returns (address);

    function WETH9() external view returns (address);

    function destruct() external;

    function createLPPoolOrLinkLPPool(
        uint256 _baseTokenAmount,
        address _quoteTokenAddress,
        uint256 _quoteTokenAmount,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper,
        uint160 _sqrtPriceX96
    ) external payable;

    function updateLPPool(
        uint256 _baseTokenAmount,
        int24 _tickLower,
        int24 _tickUpper
    ) external;

    function mint(
        address[] memory _mintTokenAddressList,
        uint24[] memory _mintTokenAmountRatioList,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        int24 _tickLower,
        int24 _tickUpper
    ) external;

    function bonusWithdraw() external;

    function bonusWithdrawByTokenIdList(uint256[] memory tokenIdList) external;

    function mintAnchor()
        external
        view
        returns (
            uint128 p,
            uint16 aNumerator,
            uint16 aDenominator,
            uint16 bNumerator,
            uint16 bDenominator,
            uint16 c,
            uint16 d,
            uint256 lastTimestamp,
            uint256 n
        );
}
