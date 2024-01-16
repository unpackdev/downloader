// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./IERC20Query.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./ERC20Burnable.sol";

contract AstaSwapBridge is Context {
    using SafeMath for uint256;
    ERC20Burnable _token;

    mapping(string => bool) private registeredBEP20;
    mapping(bytes32 => bool) public filledOtherChainsTx;

    address payable public owner;
    address public superAdmin;
    address payable public feeReceiver;
    uint256 public swapFee;
    uint256 public burntPercentage;
    uint256 public amountDivisonPercentage;
    uint256 public feePercentageInAsta;
    uint256 private hunderedPercent = 100000000000000000000;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SuperAdminChanged(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin
    );
    event FeeReceiverUpdated(
        address indexed prevFeeReceiver,
        address indexed newFeeReceiver
    );
    event SwapPairRegisterFor(
        address indexed sponsor,
        address indexed eth20Addr,
        string name,
        string symbol,
        uint8 decimals,
        string pair
    );
    event SwapStarted(
        address indexed eth20Addr,
        address indexed fromAddr,
        uint256 amount,
        uint256 feeAmount,
        uint256 swapAmount,
        uint256 feeInAsta,
        uint256 amountToBurn,
        string chain
    );
    event SwapFilled(
        address indexed eth20Addr,
        bytes32 indexed inputTxHash,
        address indexed toAddress,
        uint256 swapAmount,
        uint256 feeInAsta,
        uint256 amountToBurn
    );

    constructor(
        uint256 fee_Native,
        uint256 amount_Division,
        uint256 fee_PerAsta,
        address payable fee_Receiver,
        address super_Admin
    ) {
        swapFee = fee_Native;
        require(
            amount_Division <= hunderedPercent,
            "amountDivisonPercentage: SHould be less then 100"
        );
        amountDivisonPercentage = amount_Division;
        require(
            fee_PerAsta <= hunderedPercent,
            "feePercentageInAsta: SHould be less then 100"
        );
        feePercentageInAsta = fee_PerAsta;
        owner = payable(msg.sender);
        feeReceiver = fee_Receiver;
        superAdmin = super_Admin;
        burntPercentage = hunderedPercent.sub(fee_PerAsta);
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * Throws if called transferOwnership by any account other than the super admin.
     */
    modifier onlySuperAdmin() {
        require(
            superAdmin == _msgSender(),
            "Super Admin: caller is not the super admin"
        );
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed to swap");
        _;
    }

    modifier noProxy() {
        require(msg.sender == tx.origin, "no proxy is allowed");
        _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * Leaves the contract without owner. It will not be possible to call
     * `onlySuperAdmin` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlySuperAdmin {
        emit OwnershipTransferred(owner, address(0));
        owner = payable(0);
    }

    /**
     * Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlySuperAdmin {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * Change Super Admin of the contract to a new account (`newSuperAdmin`).
     * Can only be called by the current super admin.
     */
    function changeSuperAdmin(address newSuperAdmin) public onlySuperAdmin {
        require(
            newSuperAdmin != address(0),
            "Super Admin: new super admin is the zero address"
        );
        emit SuperAdminChanged(superAdmin, newSuperAdmin);
        superAdmin = newSuperAdmin;
    }

    /**
     * Transfers fee receiver to a new account (`newFeeReceiver`).
     * Can only be called by the current owner.
     */
    function changeFeeReceiver(address payable newFeeReceiver)
        public
        onlySuperAdmin
    {
        require(
            newFeeReceiver != address(0),
            "Fee Receiver: new fee receiver address is zero "
        );
        emit FeeReceiverUpdated(feeReceiver, newFeeReceiver);
        feeReceiver = newFeeReceiver;
    }

    /**
     * Returns set minimum swap fee from BEP20 to other chains
     */
    function setSwapFee(uint256 fee) external onlyOwner {
        swapFee = fee;
    }

    /**
     * Set the percentage to divide for swap and (fee, burn)
     */
    function setSwapAmountToDivASTA(uint256 _amountDiv) external onlyOwner {
        require(
            _amountDiv <= hunderedPercent,
            "amountDivisonPercentage: Greater than 100 %"
        );
        amountDivisonPercentage = _amountDiv;
    }

    /**
     * Returns set minimum swap fee in ASTA from BEP20 to other chains
     */
    function setSwapFeePercentageOfASTA(uint256 _feePerAsta)
        external
        onlyOwner
    {
        require(
            _feePerAsta <= hunderedPercent,
            "amountDivisonPercentage: Greater than 100 %"
        );
        feePercentageInAsta = _feePerAsta;
        burntPercentage = hunderedPercent.sub(_feePerAsta);
    }

    /**
     * Register swap pair for chain
     */
    function registerSwapPair(address eth20Addr, string calldata chain)
        external
        onlyOwner
        returns (bool)
    {
        require(
            !registeredBEP20[string(abi.encode(eth20Addr, chain))],
            "already registered"
        );

        string memory name = IERC20Query(eth20Addr).name();
        string memory symbol = IERC20Query(eth20Addr).symbol();
        uint8 decimals = IERC20Query(eth20Addr).decimals();

        require(bytes(name).length > 0, "empty name");
        require(bytes(symbol).length > 0, "empty symbol");

        registeredBEP20[string(abi.encode(eth20Addr, chain))] = true;

        emit SwapPairRegisterFor(
            msg.sender,
            eth20Addr,
            name,
            symbol,
            decimals,
            chain
        );
        return true;
    }

    // function used to calculate the fee and burn amount
    function deductFeeAndBurntAmount(uint256 _amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(_amount > 0, "Amount: Amount must be greater then 0");
        uint256 amountToSwap;
        uint256 feeInAsta;
        uint256 amountToBurn;

        amountToSwap = _amount.mul(amountDivisonPercentage);
        amountToSwap = amountToSwap.div(hunderedPercent);

        uint256 remainingAmount = _amount.sub(amountToSwap);

        feeInAsta = remainingAmount.mul(feePercentageInAsta);
        feeInAsta = feeInAsta.div(hunderedPercent);

        amountToBurn = remainingAmount.sub(feeInAsta);
        return (amountToSwap, feeInAsta, amountToBurn);
    }

    /**
     * Fill swap by BEP20
     */
    function fillSwap(
        bytes32 crossChainTxHash,
        address eth20Addr,
        address toAddress,
        uint256 amount,
        string calldata chain
    ) external onlyOwner returns (bool) {
        require(!filledOtherChainsTx[crossChainTxHash], "tx filled already");
        require(
            registeredBEP20[string(abi.encode(eth20Addr, chain))],
            "not registered token"
        );
        require(amount > 0, "Amount should be greater than 0");
        require(
            amountDivisonPercentage <= hunderedPercent,
            "amountDivisonPercentage: Greater than 100 %"
        );

        uint256 swapAmount = amount;
        uint256 feeInAsta = 0;
        uint256 amountToBurn = 0;

        _token = ERC20Burnable(eth20Addr);
        if (amountDivisonPercentage == hunderedPercent) {
            _token.transfer(toAddress, swapAmount);
        } else {
            (swapAmount, feeInAsta, amountToBurn) = deductFeeAndBurntAmount(
                amount
            );
            _token.transfer(toAddress, swapAmount);
            _token.transfer(feeReceiver, feeInAsta);
            _token.burn(amountToBurn);
        }
        filledOtherChainsTx[crossChainTxHash] = true;

        emit SwapFilled(
            eth20Addr,
            crossChainTxHash,
            toAddress,
            swapAmount,
            feeInAsta,
            amountToBurn
        );
        return true;
    }

    /**
     * Swap BEP20 on other chain
     */
    function swapToken(
        address eth20Addr,
        uint256 amount,
        string calldata chain
    ) external payable notContract noProxy returns (bool) {
        require(
            registeredBEP20[string(abi.encode(eth20Addr, chain))],
            "not registered token"
        );
        require(msg.value >= swapFee, "swap fee is not enough");
        require(amount > 0, "Amount should be greater than 0");
        require(
            amountDivisonPercentage <= hunderedPercent,
            "amountDivisonPercentage: Greater than 100 %"
        );

        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        _token = ERC20Burnable(eth20Addr);

        uint256 swapAmount = amount;
        uint256 feeInAsta = 0;
        uint256 amountToBurn = 0;
        if (amountDivisonPercentage == hunderedPercent) {
            _token.transferFrom(msg.sender, address(this), swapAmount);
        } else {
            (swapAmount, feeInAsta, amountToBurn) = deductFeeAndBurntAmount(
                amount
            );
            _token.transferFrom(msg.sender, address(this), swapAmount);
            _token.transferFrom(msg.sender, feeReceiver, feeInAsta);
            _token.burnFrom(msg.sender, amountToBurn);
        }

        emit SwapStarted(
            eth20Addr,
            msg.sender,
            amount,
            msg.value,
            swapAmount,
            feeInAsta,
            amountToBurn,
            chain
        );
        return true;
    }

    /**
     * Calculate the values for swap, mint and burn
     */
    function calculateDivisonAmount(uint256 amount)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amount > 0, "Amount should be greater than 0");
        require(
            amountDivisonPercentage <= hunderedPercent,
            "amountDivisonPercentage: Greater than 100 %"
        );

        (
            uint256 swapAmount,
            uint256 feeInAsta,
            uint256 amountToBurn
        ) = deductFeeAndBurntAmount(amount);

        return (swapAmount, feeInAsta, amountToBurn);
    }

    /**
     * Check the token pair
     */
    function getRegisteredPairs(address eth20Addr, string calldata chain)
        external
        view
        returns (bool)
    {
        return registeredBEP20[string(abi.encode(eth20Addr, chain))];
    }
}