// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./IERC20Metadata.sol";

import "./IController.sol";
import "./IVault.sol";


contract Vault is IVault, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    IERC20Metadata public asset;

    string public constant version = "3.0";

    address public controller;

    uint256 public maxDeposit;

    uint256 public maxWithdraw;

    bool public paused;

    event Deposit(
        address indexed asset,
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed asset,
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint256 fee
    );

    event SetMaxDeposit(uint256 maxDeposit);

    event SetMaxWithdraw(uint256 maxWithdraw);

    event SetController(address controller);

    receive() external payable {}

    modifier unPaused() {
        require(!paused, "PAUSED");
        _;
    }

    modifier onlyStrategy() {
        require(
            IController(controller).isSubStrategy(_msgSender()),
            "NOT_SUBSTRATEGY"
        );
        _;
    }


    constructor(
        IERC20Metadata _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        asset = _asset;
        maxDeposit = type(uint256).max;
        maxWithdraw = type(uint256).max;
    }

    function deposit(uint256 amount,uint256 minShares,address receiver)external virtual override nonReentrant unPaused returns (uint256 shares)
    {
        require(amount != 0, "ZERO_ASSETS");
        require(receiver != address(0), "ZERO_ADDRESS");
        require(amount <= maxDeposit, "EXCEED_ONE_TIME_MAX_DEPOSIT");

        // Need to transfer before minting or ERC777s could reenter.
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        // Total Assets amount until now
        return _deposit(amount,minShares,receiver);
    }
    function _deposit(uint256 amount,uint256 minShares,address receiver)internal returns (uint256 shares){
        uint256 totalDeposit = IController(controller).totalAssets();
        uint256 total = totalSupply();

        // Calls Deposit function on controller
        uint256 newDeposit = IController(controller).deposit(amount);

        require(newDeposit > 0, "INVALID_DEPOSIT_SHARES");

        // Calculate share amount to be mint
        shares = total == 0 || totalDeposit == 0
            ? amount.mulDiv(
                10 ** decimals(),
                10 ** asset.decimals(),
                Math.Rounding.Down
            )
            : newDeposit.mulDiv(
                total,
                totalDeposit,
                Math.Rounding.Down
            );
        require(shares != 0 && shares >= minShares, "INVALID_DEPOSIT_SHARES");
        // Mint INDEX token to receiver
        _mint(receiver, shares);

        emit Deposit(address(asset), msg.sender, receiver, amount, shares);
    }
    function mint(uint256 amount,address account) external override onlyStrategy {
        _mint(account, amount);
    }

    function withdraw(uint256 assets,uint256 minWithdraw,address receiver)external virtual nonReentrant unPaused returns (uint256 shares)
    {
        require(assets != 0, "ZERO_ASSETS");
        require(receiver != address(0), "ZERO_ADDRESS");
        require(assets <= maxWithdraw, "EXCEED_ONE_TIME_MAX_WITHDRAW");
        // Calculate share amount to be burnt
        shares =
            (totalSupply() * assets) /
            IController(controller).totalAssets();

        require(shares > 0, "INVALID_WITHDRAW_SHARES");
        _withdraw(assets, shares,minWithdraw, receiver);
    }

    function redeem(uint256 shares,uint256 minWithdraw, address receiver) external virtual nonReentrant unPaused returns (uint256 assets)
    {
        require(shares != 0, "ZERO_SHARES");
        require(receiver != address(0), "ZERO_ADDRESS");
        assets =
            (shares * IController(controller).totalAssets()) /
            totalSupply();

        require(assets <= maxWithdraw, "EXCEED_ONE_TIME_MAX_WITHDRAW");

        // Withdraw asset
        _withdraw(assets, shares,minWithdraw, receiver);
    }

    function totalAssets() public view virtual returns (uint256) {
        return IController(controller).totalAssets();
    }

    function assetsPerShare() external view returns (uint256) {
        return IController(controller).totalAssets()*1e18 / totalSupply();
    }

    function convertToShares(
        uint256 assets
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    ///////////////////////////////////////////////////////////////
    //                 SET CONFIGURE LOGIC                       //
    ///////////////////////////////////////////////////////////////


    function setMaxDeposit(uint256 _maxDeposit) external onlyOwner {
        require(_maxDeposit > 0, "INVALID_MAX_DEPOSIT");
        maxDeposit = _maxDeposit;

        emit SetMaxDeposit(maxDeposit);
    }

    function setMaxWithdraw(uint256 _maxWithdraw) external onlyOwner {
        require(_maxWithdraw > 0, "INVALID_MAX_WITHDRAW");
        maxWithdraw = _maxWithdraw;

        emit SetMaxWithdraw(maxWithdraw);
    }

    function setController(address _controller) external onlyOwner {
        require(controller == address(0), "CONTROLLER_ALREADY");
        require(_controller != address(0), "INVALID_ZERO_ADDRESS");
        controller = _controller;
        IERC20(asset).safeApprove(_controller,type(uint256).max);
        emit SetController(controller);
    }

    ////////////////////////////////////////////////////////////////////
    //                      PAUSE/RESUME                              //
    ////////////////////////////////////////////////////////////////////

    function pause() external onlyOwner {
        require(!paused, "CURRENTLY_PAUSED");
        paused = true;
    }

    function resume() external onlyOwner {
        require(paused, "CURRENTLY_RUNNING");
        paused = false;
    }

    ////////////////////////////////////////////////////////////////////
    //                      INTERNAL                                  //
    ////////////////////////////////////////////////////////////////////

    function _withdraw(uint256 assets,uint256 shares,uint256 minWithdraw,address receiver) internal returns(uint256) {
        require(shares != 0, "SHARES_TOO_LOW");
        // Calls Withdraw function on controller
        (uint256 withdrawn, uint256 fee) = IController(controller).withdraw(
            assets,
            receiver
        );
        require(withdrawn > 0 && withdrawn-fee > minWithdraw, "INVALID_WITHDRAWN_SHARES");

        // Burn shares amount
        _burn(msg.sender, shares);

        emit Withdraw(
            address(asset),
            msg.sender,
            receiver,
            withdrawn,
            shares,
            fee
        );
        return withdrawn-fee;
    }
}
