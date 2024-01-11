//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC1155Holder.sol";
import "./IERC1155.sol";
import "./AccessControl.sol";
import "./IEscrow.sol";
import "./IdOTC.sol";
import "./INFTdOTC.sol";

contract SwarmDOTCEscrow is ERC1155Holder, IEscrow, AccessControl {
    using SafeMath for uint256;

    uint256 public constant BPSNUMBER = 10**27;
    bool public isFrozen = false;
    address internal dOTC;
    address internal nftDOTC;
    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    bytes32 public constant NFT_ESCROW_MANAGER_ROLE = keccak256("NFT_ESCROW_MANAGER_ROLE");

    struct Deposit {
        uint256 offerId;
        address maker;
        uint256 amountDeposited;
        uint256[] nftIds;
        uint256[] nftAmounts;
        bool isFrozen;
    }
    // This  determine is the escrow is frozen
    mapping(uint256 => Deposit) private deposits;
    mapping(uint256 => Deposit) private nftDeposits;

    event offerFrozen(uint256 indexed offerId, address indexed offerOwner, address frozenBy);
    event offerUnFrozen(uint256 indexed offerId, address indexed offerOwner, address frozenBy);
    event EscrowFrozen(address indexed frozenBy, address calledBy);
    event UnFreezeEscrow(address indexed unFreezeBy, address calledBy);
    event offerRemove(uint256 indexed offerId, address indexed offerOwner, uint256 amountReverted, address frozenBy);
    event Withdraw(uint256 indexed offerId, uint256 indexed orderId, address indexed taker, uint256 amount);
    event WithdrawNFT(uint256 indexed nftOfferId, uint256 indexed nftOrderId, address indexed taker);
    event canceledNftDeposit(uint256 indexed nftOfferId, address nftAddress, address canceledBy);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Grants ESCROW_MANAGER_ROLE to `_escrowManager`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setEscrowManager(address _escrowManager) public {
        grantRole(ESCROW_MANAGER_ROLE, _escrowManager);
    }

    /**
     * @dev Grants ESCROW_MANAGER_ROLE to `_escrowManager`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setNFTEscrowManager(address _escrowManager) public {
        grantRole(NFT_ESCROW_MANAGER_ROLE, _escrowManager);
    }

    /**
     *   @dev setMakerDeposit initial the deposit of the maker.
     *   @param _offerId uint256 the offer ID
     */
    function setMakerDeposit(uint256 _offerId) external override isEscrowFrozen onlyEscrowManager {
        uint256[] memory emptyArray;
        deposits[_offerId] = Deposit(
            _offerId,
            IdOTC(dOTC).getOfferOwner(_offerId),
            IdOTC(dOTC).getOffer(_offerId).amountIn,
            emptyArray,
            emptyArray,
            false
        );
    }

    /**
     *   @dev setNFTDeposit initial the deposit of the maker.
     *   @param _offerId uint256 the offer ID
     */
    function setNFTDeposit(uint256 _offerId) external override isEscrowFrozen onlyNftEscrowManager {
        nftDeposits[_offerId] = Deposit(
            _offerId,
            INFTdOTC(nftDOTC).getNftOfferOwner(_offerId),
            0,
            INFTdOTC(nftDOTC).getNftOffer(_offerId).nftIds,
            INFTdOTC(nftDOTC).getNftOffer(_offerId).nftAmounts,
            false
        );
    }

    /**
     *   @dev withdrawDeposit from the Escrow to to the taker address
     *   @param offerId the Id of the offer
     *   @param orderId the order id
     */

    function withdrawDeposit(uint256 offerId, uint256 orderId)
        external
        override
        isEscrowFrozen
        isDepositFrozen(offerId)
        onlyEscrowManager
    {
        address token = IdOTC(dOTC).getOffer(offerId).tokenInAddress;
        address _receiver = IdOTC(dOTC).getTakerOrders(orderId).takerAddress;
        uint256 standardAmount = IdOTC(dOTC).getTakerOrders(orderId).amountToReceive;
        uint256 minExpectedAmount = IdOTC(dOTC).getTakerOrders(orderId).minExpectedAmount;
        uint256 _amount = unstandardisedNumber(standardAmount, token);
        require(deposits[offerId].amountDeposited >= standardAmount, "Invalid Amount");
        require(minExpectedAmount <= standardAmount, "Invalid Transaction");
        deposits[offerId].amountDeposited -= standardAmount;
        safeInternalTransfer(token, _receiver, _amount);
        emit Withdraw(offerId, orderId, _receiver, _amount);
    }

    /**
     *   @dev withdrawNftDeposit from the Escrow to to the taker address
     *   @param _nftOfferId the Id of the offer
     *   @param _nftOrderId the order id
     */

    function withdrawNftDeposit(uint256 _nftOfferId, uint256 _nftOrderId)
        external
        override
        isEscrowFrozen
        isNftDepositFrozen(_nftOfferId)
        onlyNftEscrowManager
    {
        address _receiver = INFTdOTC(nftDOTC).getNftOrders(_nftOrderId).takerAddress;
        address _nftAddress = INFTdOTC(nftDOTC).getNftOffer(_nftOfferId).nftAddress;
        IERC1155(_nftAddress).setApprovalForAll(nftDOTC, true);
        emit WithdrawNFT(_nftOfferId, _nftOrderId, _receiver);
    }

    function cancelNftDeposit(uint256 nftOfferId) external override isEscrowFrozen onlyNftEscrowManager {
        address nftAddress = INFTdOTC(nftDOTC).getNftOffer(nftOfferId).nftAddress;
        IERC1155(nftAddress).setApprovalForAll(nftDOTC, true);
        emit canceledNftDeposit(nftOfferId, nftAddress, msg.sender);
    }

    /**
    *   @dev cancelDeposit 

    */
    function cancelDeposit(
        uint256 offerId,
        address token,
        address maker,
        uint256 _amountToSend
    ) external override onlyEscrowManager returns (bool status) {
        deposits[offerId].amountDeposited = 0;
        safeInternalTransfer(token, maker, _amountToSend);
        return true;
    }

    /**
     *   @dev safeInternalTransfer Asset from the escrow; revert transaction if failed
     *   @param token address
     *   @param _receiver address
     *   @param _amount uint256
     */
    function safeInternalTransfer(
        address token,
        address _receiver,
        uint256 _amount
    ) internal {
        require(_amount != 0, "Amount is 0");
        require(ERC20(token).transfer(_receiver, _amount), "Transfer failed and reverted.");
    }

    /**
     *   @dev freezeEscrow this hibernate the escrow smart contract
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *   @return status bool
     */

    function freezeEscrow(address _account) external override onlyEscrowManager returns (bool status) {
        isFrozen = true;
        emit EscrowFrozen(msg.sender, _account);
        return true;
    }

    /**
     *   @dev unFreezeEscrow this set the escorw to active
     *   Requirments:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *   @param _account address
     *   @return status bool
     */
    function unFreezeEscrow(address _account) external override onlyEscrowManager returns (bool status) {
        isFrozen = false;
        emit UnFreezeEscrow(msg.sender, _account);
        return true;
    }

    /**
     *   @dev setdOTCAddress
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE
     *   @return status bool
     */
    function setdOTCAddress(address _token) external override onlyEscrowManager returns (bool status) {
        dOTC = _token;
        return true;
    }

    /**
     *   @dev setNFTDOTCAddress
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE
     *   @return status bool
     */
    function setNFTDOTCAddress(address _token) external override onlyNftEscrowManager returns (bool status) {
        nftDOTC = _token;
        return true;
    }

    /**
     *   @dev freezeOneDeposit this freeze a singular offer on the escrow smart contract
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE
     *   @param offerId uin2t256
     *   @return status bool
     */
    function freezeOneDeposit(uint256 offerId, address _account)
        external
        override
        onlyEscrowManager
        returns (bool status)
    {
        deposits[offerId].isFrozen = true;
        emit offerFrozen(offerId, deposits[offerId].maker, _account);
        return true;
    }

    /**
     *   @dev unFreezeOneDeposit this unfreeze a singular offer on the escrow smart contract
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE
     *   @param offerId uin2t256
     *   @return status bool
     */
    function unFreezeOneDeposit(uint256 offerId, address _account)
        external
        override
        onlyEscrowManager
        returns (bool status)
    {
        deposits[offerId].isFrozen = false;
        emit offerUnFrozen(offerId, deposits[offerId].maker, _account);
        return true;
    }

    /**
     *   @dev removeOffer this return the funds from the escrow to the maker
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE
     *   @param offerId uin2t256
     *   @return status bool
     */
    function removeOffer(uint256 offerId, address _account) external override onlyEscrowManager returns (bool status) {
        uint256 _amount = deposits[offerId].amountDeposited;
        deposits[offerId].isFrozen = true;
        deposits[offerId].amountDeposited = 0;
        safeInternalTransfer(IdOTC(dOTC).getOffer(offerId).tokenInAddress, deposits[offerId].maker, _amount);
        emit offerRemove(offerId, deposits[offerId].maker, _amount, _account);
        return true;
    }

    function standardiseNumber(uint256 amount, address _token) internal view returns (uint256) {
        uint8 decimal = ERC20(_token).decimals();
        return amount.mul(BPSNUMBER).div(10**decimal);
    }

    function unstandardisedNumber(uint256 _amount, address _token) internal view returns (uint256) {
        uint8 decimal = ERC20(_token).decimals();
        return _amount.mul(10**decimal).div(BPSNUMBER);
    }

    modifier isEscrowFrozen() {
        require(isFrozen == false, "Escrow is Frozen");
        _;
    }

    modifier onlyEscrowManager() {
        require(hasRole(ESCROW_MANAGER_ROLE, _msgSender()), "must have escrow manager role");
        _;
    }

    modifier onlyNftEscrowManager() {
        require(hasRole(NFT_ESCROW_MANAGER_ROLE, _msgSender()), "must have escrow manager role");
        _;
    }

    modifier isDepositFrozen(uint256 offerId) {
        require(deposits[offerId].isFrozen == false, "offer is frozen");
        _;
    }

    modifier isNftDepositFrozen(uint256 offerId) {
        require(nftDeposits[offerId].isFrozen == false, "offer is frozen");
        _;
    }
}
