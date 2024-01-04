// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./IAssetToken.sol";
import "./IEPriceOracle.sol";
import "./EController.sol";
import "./Library.sol";

contract AssetTokenBase is IAssetTokenBase, ERC20, Pausable {
    using SafeMath for uint256;
    using AssetTokenLibrary for RewardLocalVars;

    IEController public eController;

    uint256 public latitude;
    uint256 public longitude;
    uint256 public assetPrice;
    uint256 public interestRate;

    // USD per Elysia Asset Token
    // decimals: 18
    uint256 public price;

    // monthlyRent$/(secondsPerMonth*averageBlockPerSecond)
    // Decimals: 18
    uint256 public rewardPerBlock;

    // 0: el, 1: eth, 2: wBTC ...
    uint256 public payment;

    // Account rewards (USD)
    // Decimals: 18
    mapping(address => uint256) private _rewards;

    // Account block numbers
    mapping(address => uint256) private _blockNumbers;

    /// @notice Emitted when rewards per block is changed
    event NewRewardPerBlock(uint256 newRewardPerBlock);

    /// @notice Emitted when eController is changed
    event NewController(address newController);

    constructor(
        IEController eController_,
        uint256 amount_,
        uint256 price_,
        uint256 rewardPerBlock_,
        uint256 payment_,
        uint256 latitude_,
        uint256 longitude_,
        uint256 assetPrice_,
        uint256 interestRate_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        eController = eController_;
        price = price_;
        rewardPerBlock = rewardPerBlock_;
        payment = payment_;
        latitude = latitude_;
        longitude = longitude_;
        assetPrice = assetPrice_;
        interestRate = interestRate_;
        _mint(address(this), amount_);
        _setupDecimals(decimals_);
    }

    /*** View functions ***/

    function getPayment() external view override returns (uint256) {
        return payment;
    }

    /*** Admin functions ***/

    function setEController(address newEController)
        external
        override
        onlyAdmin(msg.sender)
    {
        eController = IEController(newEController);

        emit NewController(address(eController));
    }

    function setRewardPerBlock(uint256 rewardPerBlock_)
        external
        override
        onlyAdmin(msg.sender)
        returns (bool)
    {
        rewardPerBlock = rewardPerBlock_;

        emit NewRewardPerBlock(rewardPerBlock_);

        return true;
    }

    function pause() external override onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() external override onlyAdmin(msg.sender) {
        _unpause();
    }

    /*** Reward functions ***/

    /**
     * @notice Get reward
     * @param account Addresss
     * @return saved reward + new reward
     */
    function getReward(address account) public view returns (uint256) {
        RewardLocalVars memory vars =
            RewardLocalVars({
                newReward: 0,
                accountReward: _rewards[account],
                accountBalance: balanceOf(account),
                rewardBlockNumber: _blockNumbers[account],
                blockNumber: block.number,
                diffBlock: 0,
                rewardPerBlock: rewardPerBlock,
                totalSupply: totalSupply()
            });

        return vars.getReward();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        /* RewardManager */
        _saveReward(from);
        _saveReward(to);
    }

    function _saveReward(address account) internal returns (bool) {
        if (account == address(this)) {
            return true;
        }

        _rewards[account] = getReward(account);
        _blockNumbers[account] = block.number;

        return true;
    }

    function _clearReward(address account) internal returns (bool) {
        _rewards[account] = 0;
        _blockNumbers[account] = block.number;

        return true;
    }

    /// @dev Restricted to members of the whitelisted user.
    modifier onlyWhitelisted(address account) {
        require(
            eController.isWhitelisted(account),
            "Restricted to whitelisted."
        );
        _;
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin(address account) {
        require(eController.isAdmin(account), "Restricted to admin.");
        _;
    }
}
