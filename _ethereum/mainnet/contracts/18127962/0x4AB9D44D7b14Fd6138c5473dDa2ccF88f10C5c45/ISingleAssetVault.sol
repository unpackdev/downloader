pragma solidity ^0.8.20;

interface ISingleAssetVault {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event VaultAdded(address vault);
    event VaultRemoved(address vault);
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    struct CallData {
        address to;
        bytes data;
        uint256 value;
    }

    function addVault(address vault) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function asset() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function call(CallData[] memory calls) external;
    function computeScoreDeviationInPpm(address vaultAddress) external view returns (int256);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function getVault(uint256 index) external view returns (address);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function name() external view returns (string memory);
    function oracle() external view returns (address);
    function owner() external view returns (address);
    function previewRedeem(uint256 shares) external returns (uint256 assets);
    function previewRedeemHelper(uint256 shares) external;
    function pricePerToken() external view returns (uint256);
    function rebalance(address sourceVault, address destinationVault, uint256 shares) external;
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function removeVault(address vault) external;
    function renounceOwnership() external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function totalAssets() external view returns (uint256);
    function totalPortfolioScore() external view returns (uint256 total);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transferOwnership(address newOwner) external;
    function vaultsLength() external view returns (uint256);
}

