// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ISolver.sol";
import "./VNFTCore.sol";
import "./IICToken.sol";
import "./IVestingPool.sol";
import "./IVNFTErc20Container.sol";
import "./EthAddressLib.sol";

contract ICToken is IICToken, IVNFTErc20Container, VNFTCore {
    event NewSolver(ISolver oldSolver, ISolver newSolver);
    event NewVestingPool(
        IVestingPool oldVestingPool,
        IVestingPool newVestingPool
    );

    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;

    address public admin;
    address public pendingAdmin;

    bool internal _notEntered;
    uint256 public nextTokenId;

    ISolver public solver;
    IVestingPool public vestingPool;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
        // get a gas-refund post-Istanbul
    }

    function initialize(
        ISolver solver_,
        IVestingPool vestingPool_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        string calldata contractURI_
    ) external {
        admin = msg.sender;
        VNFTCore._initialize(name_, symbol_, baseURI_, contractURI_);

        _setVestingPool(vestingPool_);
        _setSolver(solver_);

        nextTokenId = 1;
        _notEntered = true;
    }

    function owner() external view virtual returns (address) {
        return admin;
    }

    function setContractURI(string memory uri_) external virtual onlyAdmin {
        VNFTCore._setContractURI(uri_);
    }

    function setBaseURI(string memory uri_) external virtual onlyAdmin {
        ERC721Upgradeable._setBaseURI(uri_);
    }

    function mint(
        uint64 term_, /*seconds*/
        uint256 amount_,
        uint64[] calldata maturities_,
        uint32[] calldata percentages_,
        string memory originalInvestor_
    ) external virtual override returns (uint256, uint256) {
        (uint256 slot, uint256 tokenId) =
        _mint(msg.sender, term_, amount_, maturities_, percentages_, originalInvestor_);
        return (slot, tokenId);
    }

    struct MintLocalVar {
        uint256 tokenId;
        uint256 slot;
        uint256 mintUnits;
        uint64 term;
        uint8 claimType;
    }
    function _mint(
        address minter_,
        uint64 term_,
        uint256 amount_,
        uint64[] memory maturities_, /*seconds*/
        uint32[] memory percentages_,
        string memory originalInvestor_
    ) internal virtual nonReentrant returns (uint256, uint256) {
        MintLocalVar memory vars;
        vars.tokenId = generateTokenId();
        vars.claimType = maturities_.length > 1 ? 2 : term_ == 0 ? 1 : 0;

        uint256 err =
        solver.depositAllowed(
            address(this),
            minter_,
            term_,
            amount_,
            maturities_
        );
        require(err == 0, "solver not allowed");
      
        vars.mintUnits =
            vestingPool.mint(
                vars.claimType,
                minter_,
                vars.tokenId,
                term_,
                amount_,
                maturities_,
                percentages_,
                originalInvestor_
            );


        vars.slot = getSlot(vars.claimType, maturities_, percentages_, term_);

        VNFTCore._mintUnits(minter_, vars.tokenId, vars.slot, vars.mintUnits);

        solver.depositVerify(
            address(this),
            minter_,
            amount_,
            vars.tokenId,
            term_,
            maturities_
        );

        return (vars.slot, vars.tokenId);
    }

    function claim(uint256 tokenId, uint256 amount) external virtual override {
        _claim(msg.sender, tokenId, amount);
    }

    function claimAll(uint256 tokenId) external virtual override {
        _claim(msg.sender, tokenId, claimableAmount(tokenId));
    }

    function claimableAmount(uint256 tokenId_)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return vestingPool.claimableAmount(tokenId_);
    }

    function _claim(
        address payable payee_,
        uint256 tokenId_,
        uint256 claimAmount_
    ) internal virtual nonReentrant {
        require(ownerOf(tokenId_) == payee_, "only owner");

        (, uint64 term_,,, uint64[] memory maturities_, , , , ) =
        vestingPool.getVestingSnapshot(tokenId_);

        uint256 err =
        solver.withdrawAllowed(
            address(this),
            payee_,
            claimAmount_,
            tokenId_,
            term_,
            maturities_[0]
        );
        require(err == 0, "solver not allowed");

        uint256 claimUnits = vestingPool.claim(payee_, tokenId_, claimAmount_);
        VNFTCore._burnUnits(tokenId_, claimUnits);
    }

    function split(
        uint256 tokenId_,
        uint256[] calldata splitUnits_
    ) external override returns (uint256[] memory newTokenIds) {
        require(splitUnits_.length > 0, "splitUnits is empty");
        newTokenIds = new uint256[](splitUnits_.length);
        for (uint256 i = 0; i < splitUnits_.length; i++) {
            newTokenIds[i] = _splitUnits(tokenId_, splitUnits_[i]);
        }

        return newTokenIds;
    }

    function _splitUnits(uint256 tokenId_, uint256 splitUnits_)
    internal
    virtual
    returns (uint256 newTokenId)
    {
        newTokenId = generateTokenId();
        vestingPool.splitVesting(ownerOf(tokenId_), tokenId_, newTokenId, splitUnits_);
        VNFTCore._splitUnits(tokenId_, newTokenId, splitUnits_);

        return newTokenId;
    }

    function merge(uint256[] calldata tokenIds_, uint256 targetTokenId_)
    external
    override
    {
        require(tokenIds_.length > 0, "tokenIds is empty");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _merge(tokenIds_[i], targetTokenId_);
        }
    }

    function _merge(uint256 tokenId_, uint256 targetTokenId_)
    internal
    virtual
    override
    {
        vestingPool.mergeVesting(ownerOf(tokenId_), tokenId_, targetTokenId_);
        VNFTCore._merge(tokenId_, targetTokenId_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 transferUnits_
    ) public virtual override returns (uint256 newTokenId) {
        newTokenId = generateTokenId();
        _transferUnitsFrom(
            from_,
            to_,
            tokenId_,
            newTokenId,
            transferUnits_
        );
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 targetTokenId_,
        uint256 transferUnits_
    ) public virtual override {
        require(_exists(targetTokenId_), "target token not exists");
        _transferUnitsFrom(
            from_,
            to_,
            tokenId_,
            targetTokenId_,
            transferUnits_
        );
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 targetTokenId_,
        uint256 transferUnits_,
        bytes memory data_
    ) external virtual override {
        transferFrom(from_, to_, tokenId_, targetTokenId_, transferUnits_);
        require(_checkOnVNFTReceived(from_, to_, targetTokenId_, transferUnits_, data_),
            "to non VNFTReceiver");
    }
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 transferUnits_,
        bytes memory data_
    ) external virtual override returns (uint256 newTokenId) {
        newTokenId = transferFrom(from_, to_, tokenId_, transferUnits_);
        require(_checkOnVNFTReceived(from_, to_, newTokenId, transferUnits_, data_),
            "to non VNFTReceiver");
        return newTokenId;
    }

    function _transferUnitsFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 targetTokenId_,
        uint256 transferUnits_
    ) internal virtual override {
        uint256 err =
        solver.transferFromAllowed(
            address(this),
            from_,
            to_,
            tokenId_,
            targetTokenId_,
            transferUnits_
        );
        require(err == 0, "solver not allow");
        vestingPool.transferVesting(from_, tokenId_, to_, targetTokenId_, transferUnits_);
        VNFTCore._transferUnitsFrom(
            from_,
            to_,
            tokenId_,
            targetTokenId_,
            transferUnits_
        );
    }

    function generateTokenId() internal virtual returns (uint256) {
        return nextTokenId++;
    }

    function getSlot(uint8 claimType_, uint64[] memory maturities_, uint32[] memory percentages_, uint64 term_)
    internal
    pure
    virtual
    returns (uint256)
    {
        uint256 first = uint256(keccak256(abi.encodePacked(claimType_, term_, maturities_[0], percentages_[0])));
        if (maturities_.length == 1) {
            return first;
        }

        uint256 second;
        for (uint256 i = 1; i < maturities_.length; i++) {
            second = uint256(keccak256(abi.encodePacked(second, maturities_[i], percentages_[i])));
        }
        return uint256(keccak256(abi.encodePacked(first, second)));
    }

    function getSnapshot(uint256 tokenId_)
    public
    view
    returns (
        uint8 claimType_,
        uint64 term_,
        uint256 vestingAmount_,
        uint256 principal_,
        uint64[] memory maturities_,
        uint32[] memory percentages_,
        uint256 availableWithdrawAmount_,
        string memory originalInvestor_,
        bool isValid_
    )
    {
        return vestingPool.getVestingSnapshot(tokenId_);
    }

    function getUnderlyingAmount(uint256 units_)
    external
    view
    virtual
    override
    returns (uint256)
    {
        return vestingPool.units2amount(units_);
    }

    function getUnits(uint256 underlyingAmount_)
    external
    view
    virtual
    override
    returns (uint256)
    {
        return vestingPool.amount2units(underlyingAmount_);
    }

    function underlying() external view virtual override returns (address) {
        return vestingPool.underlying();
    }

    function totalUnderlyingAmount() external view override returns (uint256) {
        return vestingPool.totalAmount();
    }

    function _setSolver(ISolver newSolver_) public virtual onlyAdmin {
        ISolver oldSolver = solver;
        require(newSolver_.isSolver(), "solver is invalid");
        solver = newSolver_;

        emit NewSolver(oldSolver, newSolver_);
    }

    function _setVestingPool(IVestingPool newVestingPool_)
    public
    virtual
    onlyAdmin
    {
        IVestingPool oldVestingPool = vestingPool;
        require(newVestingPool_.isVestingPool(), "vestingPool is invalid");
        vestingPool = newVestingPool_;
        emit NewVestingPool(oldVestingPool, newVestingPool_);
    }

    function _setPendingAdmin(address newPendingAdmin) external {
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() external {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "only pending admin"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function _sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a, "overflow");
        return a - b;
    }
}
