// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./ERC20TransferHelper.sol";
import "./VNFTTransferHelper.sol";
import "./VoucherCore.sol";
import "./ISolver.sol";
import "./ConvertiblePool.sol";
import "./IVNFTDescriptor.sol";
import "./IConvertibleVoucher.sol";
import "./IICToken.sol";

contract ConvertibleVoucher is IConvertibleVoucher, VoucherCore, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    ConvertiblePool public convertiblePool;

    IVNFTDescriptor public voucherDescriptor;

    ISolver public solver;

    function initialize(
        address convertiblePool_,
        address voucherDescriptor_,
        address solver_,
        uint8 unitDecimals_,
        string calldata name_,
        string calldata symbol_
    )
        external
        initializer
    {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        VoucherCore._initialize(name_, symbol_, unitDecimals_);

        convertiblePool = ConvertiblePool(convertiblePool_);
        voucherDescriptor = IVNFTDescriptor(voucherDescriptor_);
        solver = ISolver(solver_);

        ERC165Upgradeable._registerInterface(type(IConvertibleVoucher).interfaceId);
    }

    function mint(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint256 tokenInAmount_ // 最大偿付token数量 (at lowestPrice)
    ) 
        external 
        override
        nonReentrant
        returns (uint256 slot, uint256 tokenId) 
    {
        uint256 err = solver.operationAllowed(
            "mint", 
            abi.encode(
                _msgSender(),
                issuer_,
                fundCurrency_,
                lowestPrice_,
                highestPrice_,
                effectiveTime_, 
                maturity_,
                tokenInAmount_
            )
        );
        require(err == 0, "Solver: not allowed");

        slot = getSlot(
            issuer_, fundCurrency_, lowestPrice_, highestPrice_, 
            effectiveTime_, maturity_, 0
        );
        if (!getSlotDetail(slot).isValid) {
            convertiblePool.createSlot(
                issuer_, fundCurrency_, lowestPrice_, highestPrice_, 
                effectiveTime_, maturity_, 0
            );
        }

        uint256 units = convertiblePool.mintWithUnderlyingToken(_msgSender(), slot, tokenInAmount_);
        tokenId = VoucherCore._mint(_msgSender(), slot, units);

        solver.operationVerify(
            "mint", 
            abi.encode(_msgSender(), issuer_, slot, tokenId, units)
        );
    }

    function claimAll(uint256 tokenId_) external override {
        claim(tokenId_, unitsInToken(tokenId_));
    }
    
    function claim(uint256 tokenId_, uint256 claimUnits_) public override {
        claimTo(tokenId_, _msgSender(), claimUnits_);
    }

    function claimTo(uint256 tokenId_, address to_, uint256 claimUnits_) public override nonReentrant {
        require(_msgSender() == ownerOf(tokenId_), "only owner");
        require(claimUnits_ <= unitsInToken(tokenId_), "over claim");

        uint256 err = solver.operationAllowed(
            "claim",
            abi.encode(_msgSender(), tokenId_, to_, claimUnits_)
        );
        require(err == 0, "Solver: not allowed");

        (uint256 claimCurrencyAmount, uint256 claimTokenAmount) 
            = convertiblePool.claim(voucherSlotMapping[tokenId_], to_, claimUnits_);

        if (claimUnits_ == unitsInToken(tokenId_)) {
            _burnVoucher(tokenId_);
        } else {
            _burnUnits(tokenId_, claimUnits_);
        }

        solver.operationVerify(
            "claim",
            abi.encode(_msgSender(), tokenId_, to_, claimUnits_)
        );

        emit Claim(tokenId_, to_, claimUnits_, claimCurrencyAmount, claimTokenAmount);
    }

    function getSlot(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint8 collateralType_
    ) 
        public  
        view 
        override
        returns (uint256) 
    {
        return convertiblePool.getSlot(
            issuer_, fundCurrency_, lowestPrice_, highestPrice_, 
            effectiveTime_, maturity_, collateralType_
        );
    }

    function getSlotDetail(uint256 slot_) public view override returns (IConvertiblePool.SlotDetail memory) {
        return convertiblePool.getSlotDetail(slot_);
    }

    function getIssuerSlots(address issuer_) external view override returns (uint256[] memory slots) {
        return convertiblePool.getIssuerSlots(issuer_);
    }
    
    function contractURI() external view override returns (string memory) {
        return voucherDescriptor.contractURI();
    }

    function slotURI(uint256 slot_) external view override returns (string memory) {
        return voucherDescriptor.slotURI(slot_);
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "token not exists");
        return voucherDescriptor.tokenURI(tokenId_);
    }

    function getSnapshot(uint256 tokenId_)
        public
        override
        view
        returns (ConvertibleVoucherSnapshot memory snapshot)
    {
        snapshot.tokenId = tokenId_;
        snapshot.parValue = unitsInToken(tokenId_);
        snapshot.slotDetail = convertiblePool.getSlotDetail(voucherSlotMapping[tokenId_]);
    }

    function underlying() external view override returns (address) {
        return convertiblePool.underlyingToken();
    }

    function underlyingVestingVoucher() external view override returns (address) {
        return convertiblePool.underlyingVestingVoucher();
    }

    function setVoucherDescriptor(address newDescriptor_) external onlyAdmin {
        require(newDescriptor_ != address(0), "newDescriptor can not be 0 address");
        emit SetDescriptor(address(voucherDescriptor), newDescriptor_);
        voucherDescriptor = IVNFTDescriptor(newDescriptor_);
    }

    function setSolver(ISolver newSolver_) external onlyAdmin {
        require(newSolver_.isSolver(), "invalid solver");
        emit SetSolver(address(solver), address(newSolver_));
        solver = newSolver_;
    }

    function voucherType() external pure override returns (Constants.VoucherType) {
        return Constants.VoucherType.BOUNDING;
    }

    function version() external pure returns (string memory) {
        return "1.0.1";
    }
}
