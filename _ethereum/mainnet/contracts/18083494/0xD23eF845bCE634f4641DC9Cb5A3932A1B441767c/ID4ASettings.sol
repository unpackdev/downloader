// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./D4AEnums.sol";

interface ID4ASettings {
    event ChangeCreateFee(uint256 createDaoFeeAmount, uint256 createCanvasFeeAmount);

    event ChangeProtocolFeePool(address protocolFeePool);

    event ChangeMintFeeRatio(
        uint256 protocolFeeRatioInBps, uint256 daoFeePoolMintFeeRatioInBps, uint256 daoFeePoolMintFeeRatioInBpsFlatPrice
    );

    event ChangeTradeFeeRatio(uint256 protocolRoyaltyFeeRatioInBps);

    event ChangeERC20TotalSupply(uint256 tokenMaxSupply);

    event ChangeERC20Ratio(
        uint256 protocolERC20RatioInBps, uint256 daoCreatorERC20RatioInBps, uint256 canvasCreatorERC20RatioInBps
    );

    event ChangeMaxMintableRounds(uint256 oldMaxMintableRound, uint256 newMaxMintableRound);

    event MintableRoundsSet(uint256[] mintableRounds);

    event ChangeAddress(
        address drb,
        address erc20Factory,
        address erc721Factory,
        address feePoolFactory,
        address ownerProxy,
        address createProjectProxy,
        address permissionControl
    );

    event ChangeAssetPoolOwner(address assetOwner);

    event ChangeFloorPrices(uint256[] daoFloorPrices);

    event ChangeMaxNFTAmounts(uint256[] nftMaxSupplies);

    event ChangeD4APause(bool isPaused);

    event D4ASetProjectPaused(bytes32 daoId, bool isPaused);

    event D4ASetCanvasPaused(bytes32 canvasId, bool isPaused);

    event MembershipTransferred(bytes32 indexed role, address indexed previousMember, address indexed newMember);

    function changeCreateFee(uint256 createDaoFeeAmount, uint256 createCanvasFeeAmount) external;

    function changeProtocolFeePool(address protocolFeePool) external;

    function changeMintFeeRatio(
        uint256 protocolFeeRatioInBps,
        uint256 daoFeePoolMintFeeRatioInBps,
        uint256 daoFeePoolMintFeeRatioInBpsFlatPrice
    )
        external;

    function changeTradeFeeRatio(uint256 protocolRoyaltyFeeRatioInBps) external;

    function changeERC20TotalSupply(uint256 tokenMaxSupply) external;

    function changeERC20Ratio(
        uint256 protocolERC20RatioInBps,
        uint256 daoCreatorERC20RatioInBps,
        uint256 canvasCreatorERC20RatioInBps
    )
        external;

    function changeMaxMintableRounds(uint256 maxMintableRound) external;

    function setMintableRounds(uint256[] calldata mintableRounds) external;

    function changeAddress(
        address drb,
        address erc20Factory,
        address erc721Factory,
        address feePoolFactory,
        address ownerProxy,
        address createProjectProxy,
        address permissionControl
    )
        external;

    function changeAssetPoolOwner(address assetOwner) external;

    function changeFloorPrices(uint256[] memory daoFloorPrices) external;

    function changeMaxNFTAmounts(uint256[] memory nftMaxSupplies) external;

    function changeD4APause(bool isPaused) external;

    function setProjectPause(bytes32 daoId, bool isPaused) external;

    function setCanvasPause(bytes32 canvasId, bool isPaused) external;

    function transferMembership(bytes32 role, address previousMember, address newMember) external;

    function setTemplateAddress(TemplateChoice templateChoice, uint8 index, address template) external;

    function setReservedDaoAmount(uint256 reservedDaoAmount) external;
}
