// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IAccessControl.sol";
import "./factory.sol";

interface IERC20Extended {
    function decimals() external view returns (uint8);
}

contract Helper {
    ///@dev Admin role
    bytes32 constant ADMIN = keccak256("ADMIN");

    uint8 constant UNIFORM_DECIMALS = 18;

    bytes32 constant operationNameAND = keccak256(abi.encodePacked(("AND")));
    bytes32 constant operationNameOR = keccak256(abi.encodePacked(("OR")));

    uint256 constant EIGHTEEN_DECIMALS = 1e18;

    uint256 constant FLOAT_HANDLER_TEN_4 = 10000;

    struct DAODetails {
        uint256 pricePerToken;
        uint256 distributionAmount;
        uint256 minDepositPerUser;
        uint256 maxDepositPerUser;
        uint256 ownerFeePerDepositPercent;
        uint256 depositCloseTime;
        address depositTokenAddress;
        address gnosisAddress;
        bytes32 merkleRoot;
        bool isDeployedByFactory;
        bool isTokenGatingApplied;
        bool assetsStoredOnGnosis;
    }

    struct ERC20DAOdetails {
        string DaoName;
        string DaoSymbol;
        uint256 quorum;
        uint256 threshold;
        bool isGovernanceActive;
        bool isTransferable;
        bool onlyAllowWhitelist;
        address ownerAddress;
    }

    struct ERC721DAOdetails {
        string DaoName;
        string DaoSymbol;
        uint256 quorum;
        uint256 threshold;
        uint256 maxTokensPerUser;
        bool isTransferable;
        bool isNftTotalSupplyUnlimited;
        bool isGovernanceActive;
        bool onlyAllowWhitelist;
        address ownerAddress;
    }

    enum Operator {
        AND,
        OR
    }
    enum Comparator {
        GREATER,
        BELOW,
        EQUAL
    }

    struct TokenGatingCondition {
        address tokenA;
        address tokenB;
        Operator operator;
        Comparator comparator;
        uint256[] value;
    }

    //implementation contract errors
    error AmountInvalid(string _param, uint256 _amount);
    error NotERC20Template();
    error DepositAmountInvalid(
        uint256 _maxDepositPerUser,
        uint256 _minDepositPerUser
    );
    error DepositClosed();
    error DepositStarted();
    error Max4TokensAllowed(uint256 _length);
    error ArrayLengthMismatch(uint256 _length1, uint256 _length2);
    error AddressInvalid(string _param, address _address);
    error InsufficientFunds();
    error InvalidData();
    error InsufficientAllowance(uint256 required, uint256 current);

    //nft contract errors
    error NotWhitelisted();
    error MaxTokensMinted();
    error NoAccess(address _user);
    error MintingNotOpen();
    error MaxTokensMintedForUser(address _user);

    error RaiseAmountInvalid(
        uint256 _totalRaiseAmount,
        uint256 _maxDepositPerUser
    );

    error InsufficientBalance();

    /// @dev onlyOwner modifier to allow only Owner access to functions
    modifier onlyGnosis(address _factory, address _daoAddress) {
        require(
            Factory(_factory).getDAOdetails(_daoAddress).gnosisAddress ==
                msg.sender,
            "Only Gnosis"
        );
        _;
    }

    modifier onlyGnosisOrDao(address _factory, address _daoAddress) {
        require(
            Factory(_factory).getDAOdetails(_daoAddress).gnosisAddress ==
                msg.sender ||
                _daoAddress == msg.sender,
            "Only Gnosis or Dao"
        );
        _;
    }

    modifier onlyFactory(address _factory) {
        require(msg.sender == _factory);
        _;
    }

    modifier onlyFactoryDeployed(address _factory) {
        require(
            Factory(_factory).getDAOdetails(address(this)).isDeployedByFactory
        );
        _;
    }

    modifier onlyCurrentContract() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyAdmins(address _safe) {
        require(Safe(_safe).isOwner(msg.sender), "Only owner access");
        _;
    }

    /// @dev Change decimal places to `UNIFORM_DECIMALS`.
    function toUniform(
        uint256 amount,
        address token
    ) internal view returns (uint256) {
        return
            changeDecimals(
                amount,
                IERC20Extended(token).decimals(),
                UNIFORM_DECIMALS
            );
    }

    /// @dev Convert decimal places from `UNIFORM_DECIMALS` to token decimals.
    function fromUniform(
        uint256 amount,
        address token
    ) internal view returns (uint256) {
        return
            changeDecimals(
                amount,
                UNIFORM_DECIMALS,
                IERC20Extended(token).decimals()
            );
    }

    /// @dev Change decimal places of number from `oldDecimals` to `newDecimals`.
    function changeDecimals(
        uint256 amount,
        uint8 oldDecimals,
        uint8 newDecimals
    ) internal pure returns (uint256) {
        if (amount == 0) {
            return amount;
        }

        if (oldDecimals < newDecimals) {
            return amount * (10 ** (newDecimals - oldDecimals));
        } else if (oldDecimals > newDecimals) {
            return amount / (10 ** (oldDecimals - newDecimals));
        }
        return amount;
    }
}
