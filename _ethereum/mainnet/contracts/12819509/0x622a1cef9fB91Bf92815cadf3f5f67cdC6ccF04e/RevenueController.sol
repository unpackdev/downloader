pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

import "./IxAsset.sol";

/**
 * @title RevenueController
 * @author xToken
 *
 * RevenueController is the management fees charged on xAsset funds. The RevenueController contract
 * claims fees from xAssets, exchanges fee tokens for XTK via 1inch (off-chain api data will need to
 * be passed to permissioned function `claimAndSwap`), and then transfers XTK to Mgmt module
 */
contract RevenueController is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    // Index of xAsset
    uint256 public nextFundIndex;

    // Address of xtk token
    address public constant xtk = 0x7F3EDcdD180Dbe4819Bd98FeE8929b5cEdB3AdEB;
    // Address of Mgmt module
    address public managementStakingModule;
    // Address of OneInchExchange contract
    address public oneInchExchange;
    // Address to indicate ETH
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Manager
    address private manager;
    address private manager2;

    // xAsset to index
    mapping(address => uint256) private _fundToIndex;
    // xAsset to array of asset address that charged as fee
    mapping(address => address[]) private _fundAssets;
    // Index to xAsset
    mapping(uint256 => address) private _indexToFund;

    /* ============ Events ============ */

    event FeesClaimed(address indexed fund, address indexed revenueToken, uint256 revenueTokenAmount);
    event RevenueAccrued(address indexed fund, uint256 xtkAccrued, uint256 timestamp);
    event FundAdded(address indexed fund, uint256 indexed fundIndex);

    /* ============ Modifiers ============ */

    modifier onlyOwnerOrManager {
        require(msg.sender == owner() || msg.sender == manager || msg.sender == manager2, "Non-admin caller");
        _;
    }

    /* ============ Functions ============ */

    function initialize(address _managementStakingModule, address _oneInchExchange) external initializer {
        __Ownable_init();

        nextFundIndex = 1;

        managementStakingModule = _managementStakingModule;
        oneInchExchange = _oneInchExchange;
    }

    /**
     * Withdraw fees from xAsset contract, and swap fee assets into xtk token and send to Mgmt
     *
     * @param _fundIndex    Index of xAsset
     * @param _oneInchData  1inch low-level calldata(generated off-chain)
     */
    function claimAndSwap(uint256 _fundIndex, bytes[] memory _oneInchData) external onlyOwnerOrManager {
        require(_fundIndex > 0 && _fundIndex < nextFundIndex, "Invalid fund index");

        address fund = _indexToFund[_fundIndex];
        address[] memory fundAssets = _fundAssets[fund];

        require(_oneInchData.length == fundAssets.length, "Params mismatch");

        IxAsset(fund).withdrawFees();

        for (uint256 i = 0; i < fundAssets.length; i++) {
            uint256 revenueTokenBalance = getRevenueTokenBalance(fundAssets[i]);

            if (revenueTokenBalance > 0) {
                emit FeesClaimed(fund, fundAssets[i], revenueTokenBalance);
                if (_oneInchData[i].length > 0) {
                    swapAssetToXtk(fundAssets[i], _oneInchData[i]);
                }
            }
        }

        uint256 xtkBalance = IERC20(xtk).balanceOf(address(this));
        IERC20(xtk).safeTransfer(managementStakingModule, xtkBalance);

        emit RevenueAccrued(fund, xtkBalance, block.timestamp);
    }

    function swapOnceClaimed(
        uint256 _fundIndex,
        uint256 _fundAssetIndex,
        bytes memory _oneInchData
    ) external onlyOwnerOrManager {
        require(_fundIndex > 0 && _fundIndex < nextFundIndex, "Invalid fund index");

        address fund = _indexToFund[_fundIndex];
        address[] memory fundAssets = _fundAssets[fund];

        require(_fundAssetIndex < fundAssets.length, "Invalid fund asset index");

        swapAssetToXtk(fundAssets[_fundAssetIndex], _oneInchData);

        uint256 xtkBalance = IERC20(xtk).balanceOf(address(this));
        IERC20(xtk).safeTransfer(managementStakingModule, xtkBalance);

        emit RevenueAccrued(fund, xtkBalance, block.timestamp);
    }

    function swapAssetToXtk(address _fundAsset, bytes memory _oneInchData) private {
        uint256 revenueTokenBalance = getRevenueTokenBalance(_fundAsset);

        bool success;

        if (_fundAsset == ETH_ADDRESS) {
            // execute 1inch swap of ETH for XTK
            (success, ) = oneInchExchange.call{ value: revenueTokenBalance }(_oneInchData);
        } else {
            // execute 1inch swap of token for XTK
            (success, ) = oneInchExchange.call(_oneInchData);
        }

        require(success, "Low-level call with value failed");
    }

    /**
     * Governance function that adds xAssets
     * @param _fund      Address of xAsset
     * @param _assets    Assets charged as fee in xAsset
     */
    function addFund(address _fund, address[] memory _assets) external onlyOwner {
        require(_fundToIndex[_fund] == 0, "Already added");
        require(_assets.length > 0, "Empty fund assets");

        _indexToFund[nextFundIndex] = _fund;
        _fundToIndex[_fund] = nextFundIndex++;
        _fundAssets[_fund] = _assets;

        for (uint256 i = 0; i < _assets.length; ++i) {
            if (_assets[i] != ETH_ADDRESS) {
                IERC20(_assets[i]).safeApprove(oneInchExchange, type(uint256).max);
            }
        }

        emit FundAdded(_fund, nextFundIndex - 1);
    }

    /*
     * @notice manager == alternative admin caller to owner
     */
    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    /*
     * @notice manager2 == alternative admin caller to owner
     */
    function setManager2(address _manager2) public onlyOwner {
        manager2 = _manager2;
    }

    /**
     * Return token/eth balance of contract
     */
    function getRevenueTokenBalance(address _revenueToken) private view returns (uint256) {
        if (_revenueToken == ETH_ADDRESS) return address(this).balance;
        return IERC20(_revenueToken).balanceOf(address(this));
    }

    /**
     * Return index of _fund
     */
    function getFundIndex(address _fund) public view returns (uint256) {
        return _fundToIndex[_fund];
    }

    /**
     * Return fee assets of _fund
     */
    function getFundAssets(address _fund) public view returns (address[] memory) {
        return _fundAssets[_fund];
    }

    /* ============ Fallbacks ============ */

    receive() external payable {}
}
