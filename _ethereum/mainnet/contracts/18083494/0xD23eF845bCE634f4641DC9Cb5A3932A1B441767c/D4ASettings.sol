// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AccessControl.sol";
import "./AccessControlStorage.sol";
import "./Initializable.sol";

import "./D4AConstants.sol";
import "./D4AEnums.sol";
import "./SettingsStorage.sol";
import "./ID4ASettings.sol";
import "./ID4ADrb.sol";
import "./ID4AProtocolReadable.sol";
import "./IPermissionControl.sol";
import "./ID4AFeePoolFactory.sol";
import "./ID4AERC20Factory.sol";
import "./ID4AOwnerProxy.sol";
import "./ID4AERC721Factory.sol";
import "./D4ASettingsReadable.sol";

contract D4ASettings is ID4ASettings, Initializable, AccessControl, D4ASettingsReadable {
    function initializeD4ASettings(uint256 reservedDaoAmount) public initializer {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DAO_ROLE, OPERATION_ROLE);
        _setRoleAdmin(SIGNER_ROLE, OPERATION_ROLE);
        //some default value here
        l.createDaoFeeAmount = 0.1 ether;
        l.createCanvasFeeAmount = 0.01 ether;
        l.protocolMintFeeRatioInBps = 250;
        l.protocolRoyaltyFeeRatioInBps = 250;
        l.daoFeePoolMintFeeRatioInBps = 3000;
        l.daoFeePoolMintFeeRatioInBpsFlatPrice = 3500;
        l.minRoyaltyFeeRatioInBps = 500;
        l.maxRoyaltyFeeRatioInBps = 1000;

        l.daoCreatorERC20RatioInBps = 300;
        l.protocolERC20RatioInBps = 200;
        l.canvasCreatorERC20RatioInBps = 9500;
        l.maxMintableRound = 366;
        l.reservedDaoAmount = reservedDaoAmount;
    }

    function changeCreateFee(
        uint256 createDaoFeeAmount,
        uint256 createCanvasFeeAmount
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.createDaoFeeAmount = createDaoFeeAmount;
        l.createCanvasFeeAmount = createCanvasFeeAmount;
        emit ChangeCreateFee(createDaoFeeAmount, createCanvasFeeAmount);
    }

    function changeProtocolFeePool(address protocolFeePool) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolFeePool = protocolFeePool;
        emit ChangeProtocolFeePool(protocolFeePool);
    }

    function changeMintFeeRatio(
        uint256 protocolFeeRatioInBps,
        uint256 daoFeePoolMintFeeRatioInBps,
        uint256 daoFeePoolMintFeeRatioInBpsFlatPrice
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolMintFeeRatioInBps = protocolFeeRatioInBps;
        l.daoFeePoolMintFeeRatioInBps = daoFeePoolMintFeeRatioInBps;
        l.daoFeePoolMintFeeRatioInBpsFlatPrice = daoFeePoolMintFeeRatioInBpsFlatPrice;
        emit ChangeMintFeeRatio(
            protocolFeeRatioInBps, daoFeePoolMintFeeRatioInBps, daoFeePoolMintFeeRatioInBpsFlatPrice
        );
    }

    function changeTradeFeeRatio(uint256 protocolRoyaltyFeeRatioInBps) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolRoyaltyFeeRatioInBps = protocolRoyaltyFeeRatioInBps;
        emit ChangeTradeFeeRatio(protocolRoyaltyFeeRatioInBps);
    }

    function changeERC20TotalSupply(uint256 tokenMaxSupply) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.tokenMaxSupply = tokenMaxSupply;
        emit ChangeERC20TotalSupply(tokenMaxSupply);
    }

    function changeERC20Ratio(
        uint256 protocolERC20RatioInBps,
        uint256 daoCreatorERC20RatioInBps,
        uint256 canvasCreatorERC20RatioInBps
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.protocolERC20RatioInBps = protocolERC20RatioInBps;
        l.daoCreatorERC20RatioInBps = daoCreatorERC20RatioInBps;
        l.canvasCreatorERC20RatioInBps = canvasCreatorERC20RatioInBps;
        require(
            protocolERC20RatioInBps + daoCreatorERC20RatioInBps + canvasCreatorERC20RatioInBps == BASIS_POINT,
            "invalid ratio"
        );

        emit ChangeERC20Ratio(protocolERC20RatioInBps, daoCreatorERC20RatioInBps, canvasCreatorERC20RatioInBps);
    }

    function changeMaxMintableRounds(uint256 maxMintableRound) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        emit ChangeMaxMintableRounds(l.maxMintableRound, maxMintableRound);
        l.maxMintableRound = maxMintableRound;
    }

    function setMintableRounds(uint256[] calldata mintableRounds) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.layout().mintableRounds = mintableRounds;

        emit MintableRoundsSet(mintableRounds);
    }

    function changeAddress(
        address drb,
        address erc20Factory,
        address erc721Factory,
        address feePoolFactory,
        address ownerProxy,
        address createProjectProxy,
        address permissionControl
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.drb = ID4ADrb(drb);
        l.erc20Factory = ID4AERC20Factory(erc20Factory);
        l.erc721Factory = ID4AERC721Factory(erc721Factory);
        l.feePoolFactory = ID4AFeePoolFactory(feePoolFactory);
        l.ownerProxy = ID4AOwnerProxy(ownerProxy);
        l.createProjectProxy = createProjectProxy;
        l.permissionControl = IPermissionControl(permissionControl);
        emit ChangeAddress(
            drb, erc20Factory, erc721Factory, feePoolFactory, ownerProxy, createProjectProxy, permissionControl
        );
    }

    function changeAssetPoolOwner(address assetOwner) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.assetOwner = assetOwner;
        emit ChangeAssetPoolOwner(assetOwner);
    }

    function changeFloorPrices(uint256[] memory daoFloorPrices) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        delete l.daoFloorPrices; // TODO: check if this is necessary
        l.daoFloorPrices = daoFloorPrices;
        emit ChangeFloorPrices(daoFloorPrices);
    }

    function changeMaxNFTAmounts(uint256[] memory nftMaxSupplies) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        delete l.nftMaxSupplies; // TODO: check if this is necessary
        l.nftMaxSupplies = nftMaxSupplies;
        emit ChangeMaxNFTAmounts(nftMaxSupplies);
    }

    function changeD4APause(bool isPaused) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        l.isProtocolPaused = isPaused;
        emit ChangeD4APause(isPaused);
    }

    function setProjectPause(bytes32 daoId, bool isPaused) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        require(
            (_hasRole(DAO_ROLE, msg.sender) && l.ownerProxy.ownerOf(daoId) == msg.sender)
                || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pauseStatuses[daoId] = isPaused;
        emit D4ASetProjectPaused(daoId, isPaused);
    }

    function setCanvasPause(bytes32 canvasId, bool isPaused) public {
        SettingsStorage.Layout storage l = SettingsStorage.layout();

        require(
            (
                _hasRole(DAO_ROLE, msg.sender)
                    && l.ownerProxy.ownerOf(ID4AProtocolReadable(address(this)).getCanvasDaoId(canvasId)) == msg.sender
            ) || _hasRole(OPERATION_ROLE, msg.sender) || _hasRole(PROTOCOL_ROLE, msg.sender),
            "only project owner or admin can call"
        );
        l.pauseStatuses[canvasId] = isPaused;
        emit D4ASetCanvasPaused(canvasId, isPaused);
    }

    function transferMembership(bytes32 role, address previousMember, address newMember) public {
        require(!_hasRole(role, newMember), "new member already has the role");
        require(_hasRole(role, previousMember), "previous member does not have the role");
        require(newMember != address(0x0) && previousMember != address(0x0), "invalid address");
        _grantRole(role, newMember);
        _revokeRole(role, previousMember);

        emit MembershipTransferred(role, previousMember, newMember);
    }

    function setTemplateAddress(
        TemplateChoice templateChoice,
        uint8 index,
        address template
    )
        public
        onlyRole(PROTOCOL_ROLE)
    {
        SettingsStorage.Layout storage l = SettingsStorage.layout();
        if (templateChoice == TemplateChoice.PRICE) {
            l.priceTemplates[index] = template;
        } else {
            l.rewardTemplates[index] = template;
        }
    }

    function setReservedDaoAmount(uint256 reservedDaoAmount) public onlyRole(PROTOCOL_ROLE) {
        SettingsStorage.layout().reservedDaoAmount = reservedDaoAmount;
    }
}
