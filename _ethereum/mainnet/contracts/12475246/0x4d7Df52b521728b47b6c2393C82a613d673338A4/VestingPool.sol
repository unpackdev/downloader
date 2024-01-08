// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";
import "./IVestingPool.sol";
import "./IVNFTErc20Container.sol";
import "./VestingLibrary.sol";
import "./EthAddressLib.sol";
import "./ERC20TransferHelper.sol";

contract VestingPool is IVestingPool {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using VestingLibrary for VestingLibrary.Vesting;
    event NewManager(address oldManager, address newManager);

    address internal _underlying;
    bool internal _initialized;

    address public admin;
    address public pendingAdmin;
    address public manager;
    uint256 internal _totalAmount;

    //tokenId => Vault
    mapping(uint256 => VestingLibrary.Vesting) public vestingById;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager");
        _;
    }

    function initialize(address underlying_) public {
        require(_initialized == false, "already initialized");
        admin = msg.sender;

        if (underlying_ != EthAddressLib.ethAddress()) {
            IERC20(underlying_).totalSupply();
        }

        _underlying = underlying_;
        _initialized = true;
    }

    function isVestingPool() external pure override returns (bool) {
        return true;
    }

    function _setManager(address newManager_) public onlyAdmin {
        address oldManager = manager;
        manager = newManager_;
        emit NewManager(oldManager, newManager_);
    }

    function mint(
        uint8 claimType_,
        address minter_,
        uint256 tokenId_,
        uint64 term_,
        uint256 amount_,
        uint64[] calldata maturities_,
        uint32[] calldata percentages_,
        string memory originalInvestor_
    ) external virtual override onlyManager returns (uint256) {
        return _mint(claimType_, minter_, tokenId_, term_, amount_, maturities_, percentages_, originalInvestor_);
    }

    struct MintLocalVar {
        uint64 term;
        uint256 sumPercentages;
        uint256 mintPrincipal;
        uint256 mintUnits;
    }
    function _mint(
        uint8 claimType_,
        address minter_,
        uint256 tokenId_,
        uint64 term_,
        uint256 amount_,
        uint64[] memory maturities_,
        uint32[] memory percentages_,
        string memory originalInvestor_
    ) internal virtual returns (uint256) {
        MintLocalVar memory vars;
        require(maturities_.length > 0 && maturities_.length == percentages_.length, "invalid maturities/percentages");

        if (claimType_ == VestingLibrary.CLAIM_TYPE_MULTI) {
            vars.term = _sub(maturities_[maturities_.length - 1], maturities_[0]);
            require(vars.term == term_, "term mismatch");
        }

        for (uint256 i = 0; i < percentages_.length; i++) {
            vars.sumPercentages = vars.sumPercentages.add(percentages_[i]);
        }
        require(vars.sumPercentages == VestingLibrary.FULL_PERCENTAGE, "invalid percentages");

        ERC20TransferHelper.doTransferIn(_underlying, minter_, amount_);
        VestingLibrary.Vesting storage vesting = vestingById[tokenId_];
        (, vars.mintPrincipal) = vesting.mint(claimType_, term_, amount_, maturities_, percentages_, originalInvestor_);

        vars.mintUnits = amount2units(vars.mintPrincipal);

        emit MintVesting(
            claimType_,
            minter_,
            tokenId_,
            term_,
            maturities_,
            percentages_,
            amount_,
            amount_
        );

        _totalAmount = _totalAmount.add(amount_);

        return vars.mintUnits;
    }

    function claim(address payable payee, uint256 tokenId, uint256 amount)
        external
        virtual
        override
        onlyManager
        returns (uint256)
    {
        return _claim(payee, tokenId, amount);
    }

    function claimableAmount(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        VestingLibrary.Vesting memory vesting = vestingById[tokenId_];

        if (vesting.claimType == VestingLibrary.CLAIM_TYPE_LINEAR 
            || vesting.claimType == VestingLibrary.CLAIM_TYPE_SINGLE) {
            if (block.timestamp >= vesting.maturities[0]) {
                // 到期或过期
                return vesting.principal;
            } 
            uint256 timeRemained = vesting.maturities[0] - block.timestamp;
            // 尚未开始解锁
            if (timeRemained >= vesting.term) {
                return 0;
            }

            uint256 lockedAmount = vesting.vestingAmount.mul(timeRemained).div(vesting.term);
            return vesting.principal.sub(lockedAmount, "claimable amount error");

        } else if (vesting.claimType == VestingLibrary.CLAIM_TYPE_MULTI) {  
            //尚未开始解锁
            if (block.timestamp < vesting.maturities[0]) {
                return 0;
            }

            uint256 lockedPercentage;
            for (uint256 i = vesting.maturities.length - 1; i >= 0; i--) {
                if (vesting.maturities[i] <= block.timestamp) {
                    break;
                }
                lockedPercentage = lockedPercentage.add(vesting.percentages[i]);
            }

            uint256 lockedAmount = 
                    vesting.vestingAmount.mul(lockedPercentage)
                    .div(VestingLibrary.FULL_PERCENTAGE, "locked amount error");
            return vesting.principal.sub(lockedAmount, "claimable amount error");
        } else {
            revert("unsupported claimType");
        }
    }

    function _claim(
        address payable payee_,
        uint256 tokenId_,
        uint256 claimAmount_
    ) internal virtual returns (uint256) {
        require(claimAmount_ > 0, "cannot claim 0");
        require(
            claimAmount_ <= claimableAmount(tokenId_),
            "over claim"
        );

        VestingLibrary.Vesting storage v = vestingById[tokenId_];

        require(
            claimAmount_ <= v.principal,
            "insufficient principal"
        );

        v.claim(claimAmount_);

        ERC20TransferHelper.doTransferOut(_underlying, payee_, claimAmount_);

        _totalAmount = _totalAmount.sub(claimAmount_);

        emit ClaimVesting(
            payee_,
            tokenId_,
            claimAmount_
        );
        return amount2units(claimAmount_);
    }

    function transferVesting( address from_, uint256 tokenId_,
        address to_,
        uint256 targetTokenId_,
        uint256 transferUnits_) public override virtual onlyManager {
        uint256 transferAmount = units2amount(transferUnits_);
        (uint256 transferVestingAmount, uint256 transferPrincipal) =
            vestingById[tokenId_].transfer(vestingById[targetTokenId_], transferAmount);
        emit TransferVesting(
            from_,
            tokenId_,
            to_,
            targetTokenId_,
            transferVestingAmount,
            transferPrincipal
        );
    }

    function splitVesting(address owner_, uint256 tokenId_, uint256 newTokenId_,
        uint256 splitUnits_) public  virtual override onlyManager {
        uint256 splitAmount = units2amount(splitUnits_);
        (uint256 splitVestingAmount, uint256 splitPrincipal) = vestingById[tokenId_].split(vestingById[newTokenId_], splitAmount);
        emit SplitVesting(owner_, tokenId_, newTokenId_, splitVestingAmount, splitPrincipal);
    }

    function mergeVesting(address owner_, uint256 tokenId_,
        uint256 targetTokenId_) public  virtual override onlyManager {
        (uint256 mergeVestingAmount, uint256 mergePrincipal) = vestingById[tokenId_].merge(vestingById[targetTokenId_]);
        delete vestingById[tokenId_];
        emit MergeVesting(owner_, tokenId_, targetTokenId_, mergeVestingAmount, mergePrincipal);
    }

    function units2amount(uint256 units_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return units_ * 1;
    }

    function amount2units(uint256 amount_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return amount_ / 1;
    }

    function totalAmount() public view override returns(uint256) {
        return _totalAmount;
    }

    struct VestingSnapShot {
        uint256 vestingAmount_;
        uint256 principal_;
        uint64[] maturities_;
        uint32[] percentages_;
        uint64 term_;
        uint8 claimType_;
        uint256 claimableAmount;
        bool isValid_;
        string originalInvestor_;
    }

    function getVestingSnapshot(uint256 tokenId_)
    public
    view
    override
    returns (
        uint8,
        uint64,
        uint256,
        uint256,
        uint64[] memory,
        uint32[] memory,
        uint256,
        string memory,
        bool
    )
    {
        VestingSnapShot memory vars;
        vars.vestingAmount_ = vestingById[tokenId_].vestingAmount;
        vars.principal_ = vestingById[tokenId_].principal;
        vars.maturities_ = vestingById[tokenId_].maturities;
        vars.percentages_ = vestingById[tokenId_].percentages;
        vars.term_ = vestingById[tokenId_].term;
        vars.claimType_ = vestingById[tokenId_].claimType;
        vars.claimableAmount = claimableAmount(tokenId_);
        vars.isValid_ = vestingById[tokenId_].isValid;
        vars.originalInvestor_ = vestingById[tokenId_].originalInvestor;
        return (
            vars.claimType_,
            vars.term_,
            vars.vestingAmount_,
            vars.principal_,
            vars.maturities_,
            vars.percentages_,
            vars.claimableAmount,
            vars.originalInvestor_,
            vars.isValid_
        );
    }

    function underlying() public view override returns (address) {
        return _underlying;
    }

    function _setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() public {
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

    function _add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "add-overflow");
        return c;
    }

    function _sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a, "sub-overflow");
        return a - b;
    }
}
