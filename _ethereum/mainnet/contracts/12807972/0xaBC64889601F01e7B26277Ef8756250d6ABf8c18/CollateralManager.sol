// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Governed.sol";
import "./IMakerDAO.sol";
import "./ICollateralManager.sol";

contract DSMath {
    uint256 internal constant RAY = 10**27;
    uint256 internal constant WAD = 10**18;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * y) + (WAD / 2)) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * WAD) + (y / 2)) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * y) + (RAY / 2)) / RAY;
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = wad * RAY;
    }

    /// @notice It will work only if _dec < 18
    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = _amt * 10**(18 - _dec);
    }
}

contract CollateralManager is ICollateralManager, DSMath, ReentrancyGuard, Governed {
    using SafeERC20 for IERC20;

    // Vault number to collateral type
    mapping(uint256 => bytes32) public collateralType;
    // Vault owner to vault num mapping
    mapping(address => uint256) public override vaultNum;
    // Collateral type to Gem join address of that type
    mapping(bytes32 => address) public mcdGemJoin;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public override mcdManager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public mcdDaiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public mcdSpot = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public mcdJug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public treasury;
    uint256 internal constant MAX_UINT_VALUE = type(uint256).max;

    event AddedGemJoin(address indexed gemJoin, bytes32 ilk);
    event CreatedVault(address indexed owner, uint256 indexed vaultNum, bytes32 indexed collateralType);
    event TransferredVaultOwnership(uint256 indexed vaultNum, address indexed previousOwner, address indexed newOwner);
    event UpdatedMCDAddresses(address mcdManager, address mcdDaiJoin, address mcdSpot, address mcdJug);
    event UpdatedTreasury(address indexed previousTreasury, address indexed newTreasury);

    modifier onlyVaultOwner() {
        require(vaultNum[msg.sender] != 0, "caller-doesn't-own-any-vault");
        _;
    }

    /**
     * @dev Add gemJoin adapter address from Maker in mapping
     * @param _gemJoins Array of gem join addresses
     */
    function addGemJoin(address[] calldata _gemJoins) external override onlyGovernor {
        require(_gemJoins.length != 0, "no-gemJoin-address");
        for (uint256 i; i < _gemJoins.length; i++) {
            address gemJoin = _gemJoins[i];
            bytes32 ilk = GemJoinLike(gemJoin).ilk();
            mcdGemJoin[ilk] = gemJoin;
            emit AddedGemJoin(gemJoin, ilk);
        }
    }

    /**
     * @notice Create new Maker vault
     * @dev Store caller of this function as vault owner.
     * @param _collateralType Collateral type for Maker vault
     * @return _vaultNum Newly created vault number
     */
    function createVault(bytes32 _collateralType) external override returns (uint256 _vaultNum) {
        require(vaultNum[msg.sender] == 0, "caller-owns-another-vault");
        ManagerLike manager = ManagerLike(mcdManager);
        _vaultNum = manager.open(_collateralType, address(this));
        manager.cdpAllow(_vaultNum, address(this), 1);

        vaultNum[msg.sender] = _vaultNum;
        collateralType[_vaultNum] = _collateralType;
        emit CreatedVault(msg.sender, _vaultNum, _collateralType);
    }

    /**
     * @notice Transfer vault ownership to another address/strategy
     * @param _newOwner Address of new owner of vault
     */
    function transferVaultOwnership(address _newOwner) external override onlyVaultOwner {
        _transferVaultOwnership(vaultNum[msg.sender], msg.sender, _newOwner);
    }

    /**
     * @notice Transfer vault ownership to another address/strategy
     * @param _vaultNum Number of vault being transferred
     * @param _owner Address of owner of vault
     * @param _newOwner Address of new owner of vault
     */
    function transferVaultOwnership(
        uint256 _vaultNum,
        address _owner,
        address _newOwner
    ) external onlyGovernor {
        require(_vaultNum != 0, "vault-number-is-zero");
        require(_owner != address(0), "owner-address-zero");
        _transferVaultOwnership(_vaultNum, _owner, _newOwner);
    }

    /**
     * @dev Update MCD addresses.
     */
    function updateMCDAddresses(
        address _mcdManager,
        address _mcdDaiJoin,
        address _mcdSpot,
        address _mcdJug
    ) external onlyGovernor {
        require(_mcdManager != address(0), "mcdManager-address-is-zero");
        require(_mcdDaiJoin != address(0), "mcdDaiJoin-address-is-zero");
        require(_mcdSpot != address(0), "mcdSpot-address-is-zero");
        require(_mcdJug != address(0), "mcdJug-address-is-zero");
        mcdManager = _mcdManager;
        mcdDaiJoin = _mcdDaiJoin;
        mcdSpot = _mcdSpot;
        mcdJug = _mcdJug;
        emit UpdatedMCDAddresses(_mcdManager, _mcdDaiJoin, _mcdSpot, _mcdJug);
    }

    /**
     * @notice Update treasure address
     */
    function updateTreasury(address _treasury) external onlyGovernor {
        require(_treasury != address(0), "treasury-address-is-zero");
        emit UpdatedTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    /**
     * @dev Deposit ERC20 collateral.
     * @param _amount ERC20 amount to deposit.
     */
    function depositCollateral(uint256 _amount) external override nonReentrant onlyVaultOwner {
        uint256 _vaultNum = vaultNum[msg.sender];
        // Receives Gem amount, approve and joins it into the vat.
        // Also convert amount to 18 decimal
        _amount = _joinGem(mcdGemJoin[collateralType[_vaultNum]], _amount);

        ManagerLike manager = ManagerLike(mcdManager);
        // Locks Gem amount into the CDP
        VatLike(manager.vat()).frob(
            collateralType[_vaultNum],
            manager.urns(_vaultNum),
            address(this),
            address(this),
            int256(_amount),
            0
        );
    }

    /**
     * @dev Withdraw collateral.
     * @param _amount Collateral amount to withdraw.
     */
    function withdrawCollateral(uint256 _amount) external override nonReentrant onlyVaultOwner {
        uint256 _vaultNum = vaultNum[msg.sender];
        ManagerLike manager = ManagerLike(mcdManager);
        GemJoinLike gemJoin = GemJoinLike(mcdGemJoin[collateralType[_vaultNum]]);
        uint256 amount18 = convertTo18(gemJoin.dec(), _amount);
        // Unlocks Gem amount18 from the CDP
        manager.frob(_vaultNum, -int256(amount18), 0);
        // Moves Gem amount18 from the CDP urn to this address
        manager.flux(_vaultNum, address(this), amount18);
        // Exits Gem amount to this address as a token
        gemJoin.exit(address(this), _amount);
        // Send Gem to pool's address
        IERC20(gemJoin.gem()).safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Payback borrowed DAI.
     * @param _amount Dai amount to payback.
     */
    function payback(uint256 _amount) external override onlyVaultOwner {
        uint256 _vaultNum = vaultNum[msg.sender];
        ManagerLike manager = ManagerLike(mcdManager);
        address urn = manager.urns(_vaultNum);
        address vat = manager.vat();
        bytes32 ilk = collateralType[_vaultNum];
        // Calculate dai debt
        uint256 _daiDebt = _getVaultDebt(ilk, urn, vat);
        require(_daiDebt >= _amount, "paying-excess-debt");
        // Approve and join dai in vat
        _joinDai(urn, _amount);
        manager.frob(_vaultNum, 0, _getWipeAmount(ilk, urn, vat));
    }

    /**
     * @notice Borrow DAI.
     * @dev In edge case, when we hit DAI mint limit, we might end up borrowing
     * less than what is being asked.
     * @param _amount Dai amount to borrow. Actual borrow amount may be less than "amount"
     */
    function borrow(uint256 _amount) external override onlyVaultOwner {
        uint256 _vaultNum = vaultNum[msg.sender];
        ManagerLike manager = ManagerLike(mcdManager);
        address vat = manager.vat();
        // Safety check in scenario where current debt and request borrow will exceed max dai limit
        uint256 _maxAmount = _maxAvailableDai(vat, collateralType[_vaultNum]);
        if (_amount > _maxAmount) {
            _amount = _maxAmount;
        }

        // Generates debt in the CDP
        manager.frob(_vaultNum, 0, _getBorrowAmount(vat, manager.urns(_vaultNum), _vaultNum, _amount));
        // Moves the DAI amount (balance in the vat in rad) to pool's address
        manager.move(_vaultNum, address(this), toRad(_amount));
        // Allows adapter to access to pool's DAI balance in the vat
        if (VatLike(vat).can(address(this), mcdDaiJoin) == 0) {
            VatLike(vat).hope(mcdDaiJoin);
        }
        // Exits DAI as a token to user's address
        DaiJoinLike(mcdDaiJoin).exit(msg.sender, _amount);
    }

    /// @dev sweep given ERC20 token to treasury pool
    function sweepErc20(address _fromToken) external {
        require(treasury != address(0), "treasury-not-set");
        uint256 amount = IERC20(_fromToken).balanceOf(address(this));
        IERC20(_fromToken).safeTransfer(treasury, amount);
    }

    /**
     * @dev Get current dai debt of vault.
     * @param _vaultOwner Address of vault owner
     */
    function getVaultDebt(address _vaultOwner) external view override returns (uint256 daiDebt) {
        uint256 _vaultNum = vaultNum[_vaultOwner];
        require(_vaultNum != 0, "invalid-vault-number");
        address _urn = ManagerLike(mcdManager).urns(_vaultNum);
        address _vat = ManagerLike(mcdManager).vat();
        bytes32 _ilk = collateralType[_vaultNum];
        daiDebt = _getVaultDebt(_ilk, _urn, _vat);
    }

    /**
     * @dev Get current collateral balance of vault.
     * @param _vaultOwner Address of vault owner
     */
    function getVaultBalance(address _vaultOwner) external view override returns (uint256 collateralLocked) {
        uint256 _vaultNum = vaultNum[_vaultOwner];
        require(_vaultNum != 0, "invalid-vault-number");
        address _vat = ManagerLike(mcdManager).vat();
        address _urn = ManagerLike(mcdManager).urns(_vaultNum);
        (collateralLocked, ) = VatLike(_vat).urns(collateralType[_vaultNum], _urn);
    }

    /**
     * @dev Calculate state based on withdraw amount.
     * @param _vaultOwner Address of vault owner
     * @param _amount Collateral amount to withdraw.
     */
    function whatWouldWithdrawDo(address _vaultOwner, uint256 _amount)
        external
        view
        override
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        )
    {
        uint256 _vaultNum = vaultNum[_vaultOwner];
        require(_vaultNum != 0, "invalid-vault-number");
        (collateralLocked, daiDebt, collateralUsdRate, collateralRatio, minimumDebt) = getVaultInfo(_vaultOwner);

        GemJoinLike _gemJoin = GemJoinLike(mcdGemJoin[collateralType[_vaultNum]]);
        uint256 _amount18 = convertTo18(_gemJoin.dec(), _amount);
        require(_amount18 <= collateralLocked, "insufficient-collateral-locked");
        collateralLocked = collateralLocked - _amount18;
        collateralRatio = _getCollateralRatio(collateralLocked, collateralUsdRate, daiDebt);
    }

    /**
     * @dev Get vault info
     * @param _vaultOwner Address of vault owner
     */
    function getVaultInfo(address _vaultOwner)
        public
        view
        override
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        )
    {
        uint256 _vaultNum = vaultNum[_vaultOwner];
        require(_vaultNum != 0, "invalid-vault-number");
        (collateralLocked, collateralUsdRate, daiDebt, minimumDebt) = _getVaultInfo(_vaultNum);
        collateralRatio = _getCollateralRatio(collateralLocked, collateralUsdRate, daiDebt);
    }

    /**
     * @notice Get max available DAI safe to borrow for given collateral type.
     * @param _collateralType Collateral type.
     */
    function maxAvailableDai(bytes32 _collateralType) public view returns (uint256) {
        return _maxAvailableDai(ManagerLike(mcdManager).vat(), _collateralType);
    }

    /**
     * @notice Get max available DAI safe to borrow
     * @dev Calculation based on current DAI debt and DAI limit for given collateral type.
     * @param _vat Vat address
     * @param _collateralType Vault collateral type.
     */
    function _maxAvailableDai(address _vat, bytes32 _collateralType) internal view returns (uint256) {
        // Get stable coin Art(debt) [wad], rate [ray], line [rad]
        //solhint-disable-next-line var-name-mixedcase
        (uint256 Art, uint256 rate, , uint256 line, ) = VatLike(_vat).ilks(_collateralType);
        // Calculate total issued debt is Art * rate [rad]
        // Calculate total available dai [wad]
        uint256 _totalAvailableDai = (line - (Art * rate)) / RAY;
        // For safety reason, return 99% of available
        return (_totalAvailableDai * 99) / 100;
    }

    function _joinDai(address _urn, uint256 _amount) internal {
        DaiJoinLike _daiJoin = DaiJoinLike(mcdDaiJoin);
        // Transfer Dai from strategy or pool to here
        IERC20(DAI).safeTransferFrom(msg.sender, address(this), _amount);
        // Approves adapter to move dai.
        IERC20(DAI).safeApprove(mcdDaiJoin, 0);
        IERC20(DAI).safeApprove(mcdDaiJoin, _amount);
        // Joins DAI into the vat
        _daiJoin.join(_urn, _amount);
    }

    function _joinGem(address _adapter, uint256 _amount) internal returns (uint256) {
        GemJoinLike gemJoin = GemJoinLike(_adapter);

        IERC20 token = IERC20(gemJoin.gem());
        // Transfer token from strategy or pool to here
        token.safeTransferFrom(msg.sender, address(this), _amount);
        // Approves adapter to take the Gem amount
        token.safeApprove(_adapter, 0);
        token.safeApprove(_adapter, _amount);
        // Joins Gem collateral into the vat
        gemJoin.join(address(this), _amount);
        // Convert amount to 18 decimal
        return convertTo18(gemJoin.dec(), _amount);
    }

    /**
     * @dev Get borrow dai amount.
     */
    function _getBorrowAmount(
        address _vat,
        address _urn,
        uint256 _vaultNum,
        uint256 _wad
    ) internal returns (int256 amount) {
        // Updates stability fee rate
        uint256 rate = JugLike(mcdJug).drip(collateralType[_vaultNum]);
        // Gets DAI balance of the urn in the vat
        uint256 dai = VatLike(_vat).dai(_urn);
        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < _wad * RAY) {
            // Calculates the needed amt so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            amount = int256(((_wad * RAY) - dai) / rate);
            // This is needed due lack of precision. It might need to sum an extra amt wei (for the given DAI wad amount)
            amount = (uint256(amount) * rate) < (_wad * RAY) ? amount + 1 : amount;
        }
    }

    /// @notice Transfer vault ownership
    function _transferVaultOwnership(
        uint256 _vaultNum,
        address _owner,
        address _newOwner
    ) internal {
        require(_newOwner != address(0), "new-owner-address-is-zero");
        require(vaultNum[_owner] == _vaultNum, "invalid-vault-num");
        require(vaultNum[_newOwner] == 0, "new-owner-owns-another-vault");

        vaultNum[_newOwner] = _vaultNum;
        vaultNum[_owner] = 0;
        emit TransferredVaultOwnership(_vaultNum, _owner, _newOwner);
    }

    /**
     * @dev Get Vault Debt Amount.
     */
    function _getVaultDebt(
        bytes32 _ilk,
        address _urn,
        address _vat
    ) internal view returns (uint256 wad) {
        // Get normalized debt [wad]
        (, uint256 art) = VatLike(_vat).urns(_ilk, _urn);
        // Get stable coin rate [ray]
        (, uint256 rate, , , ) = VatLike(_vat).ilks(_ilk);
        // Get balance from vat [rad]
        uint256 dai = VatLike(_vat).dai(_urn);
        wad = _getVaultDebt(art, rate, dai);
    }

    function _getVaultInfo(uint256 _vaultNum)
        internal
        view
        returns (
            uint256 collateralLocked,
            uint256 collateralUsdRate,
            uint256 daiDebt,
            uint256 minimumDebt
        )
    {
        address _urn = ManagerLike(mcdManager).urns(_vaultNum);
        address _vat = ManagerLike(mcdManager).vat();
        bytes32 _ilk = collateralType[_vaultNum];
        // Get minimum liquidation ratio [ray]
        (, uint256 mat) = SpotterLike(mcdSpot).ilks(_ilk);
        // Get collateral locked and normalized debt [wad] [wad]
        (uint256 ink, uint256 art) = VatLike(_vat).urns(_ilk, _urn);
        // Get stable coin and collateral rate  and min debt [ray] [ray] [rad]
        (, uint256 rate, uint256 spot, , uint256 dust) = VatLike(_vat).ilks(_ilk);

        collateralLocked = ink;
        daiDebt = _getVaultDebt(art, rate, VatLike(_vat).dai(_urn));
        minimumDebt = dust / RAY;
        // Calculate collateral rate in 18 decimals
        collateralUsdRate = rmul(mat, spot) / 10**9;
    }

    /**
     * @dev Get Payback amount.
     * @notice We need to fetch latest art, rate and dai to calculate payback amount.
     */
    function _getWipeAmount(
        bytes32 _ilk,
        address _urn,
        address _vat
    ) internal view returns (int256 amount) {
        // Get normalize debt, rate and dai balance from Vat
        (, uint256 _art) = VatLike(_vat).urns(_ilk, _urn);
        (, uint256 _rate, , , ) = VatLike(_vat).ilks(_ilk);
        uint256 _dai = VatLike(_vat).dai(_urn);

        // Uses the whole dai balance in the vat to reduce the debt
        amount = int256(_dai / _rate);
        // Checks the calculated amt is not higher than urn.art (total debt), otherwise uses its value
        amount = uint256(amount) <= _art ? -amount : -int256(_art);
    }

    /// @notice Get collateral ratio
    function _getCollateralRatio(
        uint256 _collateralLocked,
        uint256 _collateralRate,
        uint256 _daiDebt
    ) internal pure returns (uint256) {
        if (_collateralLocked == 0) {
            return 0;
        }

        if (_daiDebt == 0) {
            return MAX_UINT_VALUE;
        }

        require(_collateralRate != 0, "collateral-rate-is-zero");
        return wdiv(wmul(_collateralLocked, _collateralRate), _daiDebt);
    }

    /// @notice Get vault debt
    function _getVaultDebt(
        uint256 _art,
        uint256 _rate,
        uint256 _dai
    ) internal pure returns (uint256 wad) {
        if (_dai < (_art * _rate)) {
            uint256 rad = ((_art * _rate) - _dai);
            wad = rad / RAY;
            wad = (wad * RAY) < rad ? wad + 1 : wad;
        } else {
            wad = 0;
        }
    }
}
