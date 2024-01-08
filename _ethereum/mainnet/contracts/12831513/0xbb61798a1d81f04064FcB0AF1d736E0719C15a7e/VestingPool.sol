// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";
import "./StringsUpgradeable.sol";
import "./EthAddressLib.sol";
import "./ERC20TransferHelper.sol";
import "./IVestingPool.sol";
import "./IVNFTErc20Container.sol";
import "./VestingLibrary.sol";

interface IERC20Optional {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract VestingPool is IVestingPool {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using VestingLibrary for VestingLibrary.Vesting;
    using StringsUpgradeable for uint256;
    event NewManager(address oldManager, address newManager);

    address internal _underlying;
    bool internal _initialized;

    address public admin;
    address public pendingAdmin;
    address public manager;
    uint256 internal _totalAmount;

    // tokenId => Vault
    mapping(uint256 => VestingLibrary.Vesting) public vestingById;

    // variables added in v2.1
    string internal _baseImageURI;
    string internal _baseExternalURI;

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

    function _setBaseImageURI(string memory uri_) external onlyAdmin {
        _baseImageURI = uri_;
    }

    function _setBaseExternalURI(string memory uri_) external onlyAdmin {
        _baseExternalURI = uri_;
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
        return
            _mint(
                claimType_,
                minter_,
                tokenId_,
                term_,
                amount_,
                maturities_,
                percentages_,
                originalInvestor_
            );
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
        require(
            maturities_.length > 0 && maturities_.length == percentages_.length,
            "invalid maturities/percentages"
        );

        if (claimType_ == VestingLibrary.CLAIM_TYPE_MULTI) {
            vars.term = _sub(
                maturities_[maturities_.length - 1],
                maturities_[0]
            );
            require(vars.term == term_, "term mismatch");
        }

        for (uint256 i = 0; i < percentages_.length; i++) {
            vars.sumPercentages = vars.sumPercentages.add(percentages_[i]);
        }
        require(
            vars.sumPercentages == VestingLibrary.FULL_PERCENTAGE,
            "invalid percentages"
        );

        ERC20TransferHelper.doTransferIn(_underlying, minter_, amount_);
        VestingLibrary.Vesting storage vesting = vestingById[tokenId_];
        (, vars.mintPrincipal) = vesting.mint(
            claimType_,
            term_,
            amount_,
            maturities_,
            percentages_,
            originalInvestor_
        );

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

    function recharge(
        address recharger_,
        address owner_,
        uint256 tokenId_,
        uint256 amount_
    ) external virtual override onlyManager returns (uint256) {
        ERC20TransferHelper.doTransferIn(_underlying, recharger_, amount_);
        VestingLibrary.Vesting storage vesting = vestingById[tokenId_];
        vesting.recharge(amount_);

        emit RechargeVesting(recharger_, owner_, tokenId_, amount_, amount_);

        _totalAmount = _totalAmount.add(amount_);
        uint256 rechargeUnits = amount2units(amount_);
        return rechargeUnits;
    }

    function claim(
        address payable payee,
        uint256 tokenId,
        uint256 amount
    ) external virtual override onlyManager returns (uint256) {
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
        if (!vesting.isValid) {
            return 0;
        }

        if (
            vesting.claimType == VestingLibrary.CLAIM_TYPE_LINEAR ||
            vesting.claimType == VestingLibrary.CLAIM_TYPE_SINGLE
        ) {
            if (block.timestamp >= vesting.maturities[0]) {
                // 到期或过期
                return vesting.principal;
            }
            uint256 timeRemained = vesting.maturities[0] - block.timestamp;
            // 尚未开始解锁
            if (timeRemained >= vesting.term) {
                return 0;
            }

            uint256 lockedAmount = vesting.vestingAmount.mul(timeRemained).div(
                vesting.term
            );
            if (lockedAmount > vesting.principal) {
                return 0;
            }
            return
                vesting.principal.sub(lockedAmount, "claimable amount error");
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

            uint256 lockedAmount = vesting
            .vestingAmount
            .mul(lockedPercentage)
            .div(VestingLibrary.FULL_PERCENTAGE, "locked amount error");
            //避免先claim后再split，可能会因为精度导致locedAmount比principal多一点
            if (lockedAmount > vesting.principal) {
                return 0;
            }
            return
                vesting.principal.sub(lockedAmount, "claimable amount error");
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
        require(claimAmount_ <= claimableAmount(tokenId_), "over claim");

        VestingLibrary.Vesting storage v = vestingById[tokenId_];

        require(claimAmount_ <= v.principal, "insufficient principal");

        v.claim(claimAmount_);

        ERC20TransferHelper.doTransferOut(_underlying, payee_, claimAmount_);

        _totalAmount = _totalAmount.sub(claimAmount_);

        emit ClaimVesting(payee_, tokenId_, claimAmount_);
        return amount2units(claimAmount_);
    }

    function transferVesting(
        address from_,
        uint256 tokenId_,
        address to_,
        uint256 targetTokenId_,
        uint256 transferUnits_
    ) public virtual override onlyManager {
        uint256 transferAmount = units2amount(transferUnits_);
        (
            uint256 transferVestingAmount,
            uint256 transferPrincipal
        ) = vestingById[tokenId_].transfer(
            vestingById[targetTokenId_],
            transferAmount
        );
        emit TransferVesting(
            from_,
            tokenId_,
            to_,
            targetTokenId_,
            transferVestingAmount,
            transferPrincipal
        );
    }

    function splitVesting(
        address owner_,
        uint256 tokenId_,
        uint256 newTokenId_,
        uint256 splitUnits_
    ) public virtual override onlyManager {
        uint256 splitAmount = units2amount(splitUnits_);
        (uint256 splitVestingAmount, uint256 splitPrincipal) = vestingById[
            tokenId_
        ]
        .split(vestingById[newTokenId_], splitAmount);
        emit SplitVesting(
            owner_,
            tokenId_,
            newTokenId_,
            splitVestingAmount,
            splitPrincipal
        );
    }

    function mergeVesting(
        address owner_,
        uint256 tokenId_,
        uint256 targetTokenId_
    ) public virtual override onlyManager {
        (uint256 mergeVestingAmount, uint256 mergePrincipal) = vestingById[
            tokenId_
        ]
        .merge(vestingById[targetTokenId_]);
        delete vestingById[tokenId_];
        emit MergeVesting(
            owner_,
            tokenId_,
            targetTokenId_,
            mergeVestingAmount,
            mergePrincipal
        );
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

    function totalAmount() public view override returns (uint256) {
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

    struct UnderlyingInfo {
        address underlying;
        string symbol;
        uint8 decimals;
    }

    function getInfo(uint256 tokenId, address owner, string memory tokenSymbol) 
        external 
        view 
        override 
        returns (string memory) 
    {
        string memory underlyingSymbol;
        uint8 underlyingDecimals;
        if (_underlying == EthAddressLib.ethAddress()) {
            underlyingSymbol = "ETH";
            underlyingDecimals = 18;
        } else {
            underlyingSymbol = IERC20Optional(_underlying).symbol();
            underlyingDecimals = IERC20Optional(_underlying).decimals();
        }

        UnderlyingInfo memory underlyingInfo = UnderlyingInfo(_underlying, underlyingSymbol, underlyingDecimals);

        return string(
            abi.encodePacked(
                'data:application/json,',
                abi.encodePacked(
                    '{"name":"', name(tokenId, underlyingSymbol, underlyingDecimals),
                    '", "description":"', description(tokenId, underlyingSymbol),
                    '","image": "', _baseImageURI, tokenSymbol, '/', tokenId.toString(),
                    '.png","external_url":"', _baseExternalURI, tokenSymbol, '/', tokenId.toString(),
                    '", "properties": ', properties(tokenId, owner, underlyingInfo),
                    '}'
                )
            )
        );
    }

    function name(uint256 tokenId, string memory underlyingSymbol, uint8 underlyingDecimals) 
        internal 
        view  
        returns (bytes memory) 
    {
        uint8 claimType = vestingById[tokenId].claimType;
        uint256 principal = vestingById[tokenId].principal;

        bytes memory typeName;
        if (claimType == 0) {
            typeName = 'Linear';
        } else if (claimType == 1) {
            typeName = 'OneTime';
        } else if (claimType == 2) {
            typeName = abi.encodePacked(vestingById[tokenId].maturities.length.toString(), ' Stages');
        } else {
            revert("unsupported claimType");
        }

        return 
            abi.encodePacked(
                underlyingSymbol, ' Allocation Voucher #', tokenId.toString(), ' - ', 
                trim(uint2decimal(principal, underlyingDecimals), underlyingDecimals - 2),
                ' - ', typeName
            );
    }

    function description(uint256 tokenId, string memory underlyingSymbol) 
        internal 
        pure 
        returns (bytes memory) 
    {
        return 
            abi.encodePacked(
                "Voucher #", tokenId.toString(), " of ", underlyingSymbol, 
                " allocation. Voucher is used to represent the lock-up allocations of a certain project, which is currently being used to trade in the OTC Market. Now, everyone can trade ",
                underlyingSymbol, "'s allocations on Opensea or Solv Vouchers by trading the Voucher onchain!"
            );
    }

    function properties(uint256 tokenId, address owner, UnderlyingInfo memory underlyingInfo) 
        internal 
        view 
        returns (bytes memory) 
    {
        bytes memory data = abi.encodePacked(
            '{"owner":"', addressToString(owner),
            '","underlying":"', addressToString(underlyingInfo.underlying),
            '","underlyingSymbol":"', underlyingInfo.symbol,
            '","vestingAmount":"', uint2decimal(vestingById[tokenId].vestingAmount, underlyingInfo.decimals),
            '","principal":"', uint2decimal(vestingById[tokenId].principal, underlyingInfo.decimals),
            '","claimType":"', uint2claimType(vestingById[tokenId].claimType),
            '","claimableAmount":"', uint2decimal(claimableAmount(tokenId), underlyingInfo.decimals),
            '","percentages":', percentArray2str(vestingById[tokenId].percentages),
            ',"maturities":', uintArray2str(vestingById[tokenId].maturities)
        );

        if (vestingById[tokenId].term > 0) {
            data = abi.encodePacked(data, ',"term":"', second2day(vestingById[tokenId].term), ' days"');
        }

        bytes memory originalInvestor = bytes(vestingById[tokenId].originalInvestor);
        if (originalInvestor.length > 0) {
            data = abi.encodePacked(data, ',"originalInvestor":"', originalInvestor, '"');
        }

        return abi.encodePacked(data, '}');
    }

    function uintArray2str(uint64[] storage array) 
        private 
        view 
        returns (bytes memory) 
    {
        bytes memory pack = abi.encodePacked('[');
        for (uint256 i = 0; i < array.length; i++) {
            if (i == array.length - 1) {
                pack = abi.encodePacked(pack, uint256(array[i]).toString());
            } else {
                pack = abi.encodePacked(pack, uint256(array[i]).toString(), ',');
            }
        }
        return abi.encodePacked(pack, ']');
    }

    function percentArray2str(uint32[] storage array) 
        private 
        view 
        returns (string memory) 
    {
        bytes memory pack = abi.encodePacked('[');
        for (uint256 i = 0; i < array.length; i++) {
            bytes memory percent = abi.encodePacked('"', uint2decimal(array[i], 2), '%"');

            if (i == array.length - 1) {
                pack = abi.encodePacked(pack, percent);
            } else {
                pack = abi.encodePacked(pack, percent, ',');
            }
        }
        pack = abi.encodePacked(pack, ']');
        return string(pack);
    }

    function uint2claimType(uint8 claimType) 
        private
        pure 
        returns (string memory) 
    {
        return claimType == 0 ? 'Linear' : claimType == 1 ? 'OneTime' : claimType == 2 ? 'Staged' : 'unknown';
    }

    function uint2decimal(uint256 number, uint8 decimals) 
        private
        pure
        returns (bytes memory)
    {
        uint256 base = 10 ** decimals;
        string memory round = number.div(base).toString();
        string memory fraction = number.mod(base).toString();
        uint256 fractionLength = bytes(fraction).length;

        bytes memory fullStr = abi.encodePacked(round, '.');
        if (fractionLength < decimals) {
            for (uint8 i = 0; i < decimals - fractionLength; i++) {
                fullStr = abi.encodePacked(fullStr, '0');
            }
        }

        return abi.encodePacked(fullStr, fraction);
    }

    function second2day(uint256 second)
        private
        pure
        returns (bytes memory)
    {
        return uint2decimal(second.div(864), 2);
    }

    function trim(bytes memory oriString, uint256 cutLength) 
        private 
        pure
        returns (bytes memory)
    {
        bytes memory newString = new bytes(oriString.length - cutLength);
        uint256 index = newString.length;
        while (index-- > 0) {
            newString[index] = oriString[index];
        }
        return newString;
    }

    function addressToString(address _addr) 
        private 
        pure 
        returns (string memory) 
    {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
