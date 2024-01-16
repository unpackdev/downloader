// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ReentrancyGuardUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./VoucherCore.sol";
import "./ISolver.sol";
import "./BondPool.sol";
import "./IVNFTDescriptor.sol";
import "./IBondVoucher.sol";

contract BondVoucher is IBondVoucher, VoucherCore, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    BondPool public bondPool;

    IVNFTDescriptor public voucherDescriptor;

    ISolver public solver;

    EnumerableSetUpgradeable.AddressSet internal _managers;

    modifier onlyManager {
        require(_managers.contains(_msgSender()), "only manager");
        _;
    }

    function initialize(
        address bondPool_,
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

        bondPool = BondPool(bondPool_);
        voucherDescriptor = IVNFTDescriptor(voucherDescriptor_);
        solver = ISolver(solver_);

        ERC165Upgradeable._registerInterface(type(IBondVoucher).interfaceId);
    }

    function mint(
        address issuer_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint256 mintValue_
    ) 
        external 
        override 
        onlyManager
        nonReentrant
        returns (uint256 slot, uint256 tokenId) 
    {
        uint256 err = solver.operationAllowed(
            "mint", 
            abi.encode(
                _msgSender(),
                issuer_,
                effectiveTime_, 
                maturity_
            )
        );
        require(err == 0, "Solver: not allowed");

        slot = getSlot(issuer_, effectiveTime_, maturity_);
        if (!getSlotDetail(slot).isValid) {
            bondPool.createSlot(issuer_, effectiveTime_, maturity_);
        }

        bondPool.mint(_msgSender(), slot, mintValue_);
        tokenId = VoucherCore._mint(_msgSender(), slot, mintValue_);

        solver.operationVerify(
            "mint", 
            abi.encode(_msgSender(), issuer_, slot, tokenId, mintValue_)
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

        uint256 claimCurrencyAmount = bondPool.claim(voucherSlotMapping[tokenId_], to_, claimUnits_);

        if (claimUnits_ == unitsInToken(tokenId_)) {
            _burnVoucher(tokenId_);
        } else {
            _burnUnits(tokenId_, claimUnits_);
        }

        solver.operationVerify(
            "claim",
            abi.encode(_msgSender(), tokenId_, to_, claimUnits_)
        );

        emit Claim(tokenId_, to_, claimUnits_, claimCurrencyAmount);
    }

    function getSlot(
        address issuer_,
        uint64 effectiveTime_,
        uint64 maturity_
    ) 
        public  
        view 
        override 
        returns (uint256) 
    {
        return bondPool.getSlot(issuer_, effectiveTime_, maturity_);
    }

    function getSlotDetail(uint256 slot_) public view override returns (IBondPool.SlotDetail memory) {
        return bondPool.getSlotDetail(slot_);
    }

    function getIssuerSlots(address issuer_) external view override returns (uint256[] memory slots) {
        return bondPool.getIssuerSlots(issuer_);
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
        returns (BondVoucherSnapshot memory snapshot)
    {
        snapshot.tokenId = tokenId_;
        snapshot.parValue = unitsInToken(tokenId_);
        snapshot.slotDetail = bondPool.getSlotDetail(voucherSlotMapping[tokenId_]);
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

    function setManager(address newManager_, bool enabled_) external onlyAdmin {
        require(newManager_ != address(0), "manager can not be 0 address");
        emit SetManager(newManager_, enabled_);
        if (enabled_) {
            _managers.add(newManager_);
        } else {
            _managers.remove(newManager_);
        }
    }

    function voucherType() external pure override returns (Constants.VoucherType) {
        return Constants.VoucherType.BOUNDING;
    }

    function version() external pure returns (string memory) {
        return "1.0.1";
    }
}
