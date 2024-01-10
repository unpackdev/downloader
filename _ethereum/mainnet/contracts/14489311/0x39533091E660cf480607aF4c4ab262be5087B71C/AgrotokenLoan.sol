/*
SPDX-License-Identifier: UNLICENSED
(c) Developed by AgroToken
This work is unlicensed.
*/
pragma solidity 0.8.7;
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";

contract AgrotokenLoan is Initializable, OwnableUpgradeable {
    mapping(IERC20Upgradeable => bool) public allowedTokens;

    mapping(bytes32 => address) public lender;
    mapping(bytes32 => address) public beneficiary;
    mapping(bytes32 => IERC20Upgradeable) public collateral;
    mapping(bytes32 => uint256) public collateralAmount;
    mapping(bytes32 => LoanState) public state;

    uint256 public constant DECIMAL_FACTOR = 10**4;

    enum LoanState {
        NOT_EXISTENT,
        CREATED,
        COLLATERALIZED,
        ENDED,
        CANCELED
    }

    event LoanStatusUpdate(bytes32 indexed loanHash, LoanState indexed status);

    function initialize(address owner_, IERC20Upgradeable[] memory allowedTokens_) external initializer {
        __Ownable_init();
        _transferOwnership(owner_);
        for (uint256 i = 0; i < allowedTokens_.length; i++) {
            allowedTokens[allowedTokens_[i]] = true;
        }
    }

    function updateAllowedToken(IERC20Upgradeable token, bool allowed) external onlyOwner {
        // adminOnly
        require(token != IERC20Upgradeable(address(0)), "Token address cannot be zero address");
        allowedTokens[token] = allowed;
    }

    function createLoan(
        bytes32 hash,
        address beneficiary_,
        IERC20Upgradeable collateral_,
        uint256 collateralAmount_
    ) external {
        require(allowedTokens[collateral_], "Token not allowed");
        require(state[hash] == LoanState.NOT_EXISTENT, "Loan already registered");
        require(beneficiary_ != address(0), "Beneficiary cannot be zero address");
        require(beneficiary_ != msg.sender, "Beneficiary is invalid");
        require(collateralAmount_ != 0, "Amounts cannot be zero");

        lender[hash] = msg.sender;
        collateral[hash] = collateral_;
        beneficiary[hash] = beneficiary_;
        collateralAmount[hash] = collateralAmount_;
        state[hash] = LoanState.CREATED;

        emit LoanStatusUpdate(hash, state[hash]);
    }

    function acceptLoan(bytes32 hash) external {
        require(beneficiary[hash] == msg.sender, "Invalid sender");
        require(state[hash] == LoanState.CREATED, "Invalid loan state");
        state[hash] = LoanState.COLLATERALIZED;

        emit LoanStatusUpdate(hash, state[hash]);

        require(collateral[hash].transferFrom(msg.sender, address(this), collateralAmount[hash]), "Unable to transfer");
    }

    function distributeCollateral(bytes32 hash, uint256 lenderAmount) public {
        require(lender[hash] == msg.sender, "Invalid sender");
        require(state[hash] == LoanState.COLLATERALIZED, "Invalid state");
        require(collateralAmount[hash] >= lenderAmount, "Invalid amount");

        state[hash] = LoanState.ENDED;
        emit LoanStatusUpdate(hash, state[hash]);

        if (lenderAmount > 0) {
            require(collateral[hash].transfer(lender[hash], lenderAmount), "Unable to transfer to lender");
        }

        uint256 beneficiaryAmount = collateralAmount[hash] - lenderAmount;
        if (beneficiaryAmount > 0) {
            require(
                collateral[hash].transfer(beneficiary[hash], beneficiaryAmount),
                "Unable to transfer to beneficiary"
            );
        }
    }

    function releaseCollateral(bytes32 hash) external {
        distributeCollateral(hash, 0);
    }

    function cancelLoan(bytes32 hash) external {
        require(lender[hash] == msg.sender, "Invalid sender");
        require((state[hash] == LoanState.CREATED) || (state[hash] == LoanState.COLLATERALIZED), "Invalid state");

        emit LoanStatusUpdate(hash, LoanState.CANCELED);

        if (state[hash] == LoanState.COLLATERALIZED) {
            state[hash] = LoanState.CANCELED;
            require(
                collateral[hash].transfer(beneficiary[hash], collateralAmount[hash]),
                "Unable to transfer to beneficiary"
            );
        } else {
            state[hash] = LoanState.CANCELED;
        }
    }
}
