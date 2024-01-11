// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./IERC20.sol";
import "./ERC20.sol";
import "./IERC721.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./IERCX.sol";
import "./ERCX.sol";

import "./IPayment.sol";
import "./IvRent.sol";

contract vRent is IvRent, ERC721Holder {
    using SafeERC20 for ERC20;

    IPayment private payment;
    address private admin;
    address payable private beneficiary;
    uint256 private leasingId = 1;
    bool public paused = false;
    IERCX _ERCX;
    ERCX ERCXImp;

    // in bps. so 1000 => 1%
    uint256 public rentFee = 0;

    uint256 private constant SECONDS_IN_DAY = 86400;

    struct Leasing {
        address payable leaserAddress;
        uint8 maxLeaseDuration;
        bytes4 dailyLeasePrice;
        IPayment.PaymentToken paymentToken;
    }

    // single storage slot: 160 bits, 168, 200
    struct Renting {
        address payable renterAddress;
        uint8 rentDuration;
        uint32 rentedAt;
    }

    struct LeasingRenting {
        Leasing Leasing;
        Renting renting;
    }

    mapping(bytes32 => LeasingRenting) private leasingRenting;

    struct CallData {
        address[] nfts;
        uint256[] tokenIds;
        uint8[] maxLeaseDurations;
        bytes4[] dailyLeasePrices;
        uint256[] leasingIds;
        uint8[] rentDurations;
        IPayment.PaymentToken[] paymentTokens;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "vRent::not admin");
        _;
    }

    modifier notPaused() {
        require(!paused, "vRent::paused");
        _;
    }

    constructor(
        address _payment,
        address payable _beneficiary,
        address _admin,
        ERCX ERCX_
    ) {
        _verifyIsNotZeroAddr(_payment);
        _verifyIsNotZeroAddr(_beneficiary);
        _verifyIsNotZeroAddr(_admin);
        payment = IPayment(_payment);
        beneficiary = _beneficiary;
        admin = _admin;
        _ERCX = ERCX_;
        ERCXImp = ERCX_;
    }

    function bundleCall(function(CallData memory) _manager, CallData memory _cd)
        private
    {
        require(_cd.nfts.length > 0, "vRent::no nfts");
        _manager(_cd);
    }

    /**
     * @dev user Lease the nft for earning.
     *
     * Emits an {Lent} event indicating the nft is Leaseed by Leaser.
     *
     * Requirements:
     *
     * - the caller must have allowance for `_tokenIds`'s tokens of at least
     * `_tokenAmounts`.
     * - the caller must have a balance of at least `_tokenAmounts`.
     * - `_dailyLeasePrices` should be between 9999.9999 and 0.0001
     */
    function lease(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint8[] memory _maxLeaseDurations,
        bytes4[] memory _dailyLeasePrices,
        IPayment.PaymentToken[] memory _paymentTokens
    ) external override notPaused {
        bundleCall(
            manageLease,
            _createLeaseCallData(
                _nfts,
                _tokenIds,
                _maxLeaseDurations,
                _dailyLeasePrices,
                _paymentTokens
            )
        );
    }

    /**
     * @dev See {IvRent-rent}.
     *
     * Emits an {Rented} event indicating the nft is rented by renter.
     *
     * Requirements:
     *
     * - caller must have a balance of at least daily rent + collateral amount.
     * - the caller must have allowance for PaymentToken's tokens of at least
     *   dailyLeasePrice + collateral amount.
     */
    function rentNFT(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds,
        uint8[] memory _rentDurations
    ) external override notPaused {
        bundleCall(
            manageRent,
            _createRentCallData(_nfts, _tokenIds, _leasingIds, _rentDurations)
        );
    }

    /**
     * @dev renter returns NFT to vRent contract
     *
     * Emits an {Returned} event indicating the nft returned from renter to contract.
     *
     * Requirements:
     *
     * - caller cannot be the zero address.
     * - caller must have a balance of `_tokenIds`.
     */
    function endRent(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds
    ) external override notPaused {
        bundleCall(
            manageReturn,
            _createActionCallData(_nfts, _tokenIds, _leasingIds)
        );
    }

    /**
     * @dev Leaser gets his nft back from vRent
     *
     * Emits an {LeasingStopped} event indicating nft Leasing stopped.
     *
     * Requirements:
     *
     * - caller cannot be the zero address.
     * - caller must be the one who Leaseed nft.
     */
    function cancelLeasing(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds
    ) external override notPaused {
        bundleCall(
            manageStopLeasing,
            _createActionCallData(_nfts, _tokenIds, _leasingIds)
        );
    }

    // -------------------------------------------------------------------------

    /**
     * deduct the platform fee and transfer it to `beneficiary` address
     */

    function takeFee(uint256 _rent, IPayment.PaymentToken _paymentToken)
        private
        returns (uint256 fee)
    {
        fee = _rent * rentFee;
        fee /= 10000;
        uint8 paymentTokenIx = uint8(_paymentToken);
        verifyTokenNotSentinel(paymentTokenIx);
        ERC20 paymentToken = ERC20(payment.getPaymentToken(paymentTokenIx));
        paymentToken.safeTransfer(beneficiary, fee);
    }

    //   distribute payments
    function distributePayments(
        LeasingRenting storage _LeasingRenting,
        uint256 _secondsSinceRentStart
    ) private {
        uint8 paymentTokenIx = uint8(_LeasingRenting.Leasing.paymentToken);
        verifyTokenNotSentinel(paymentTokenIx);
        address paymentToken = payment.getPaymentToken(paymentTokenIx);
        uint256 decimals = ERC20(paymentToken).decimals();

        uint256 scale = 10**decimals;
        uint256 rentPrice = _unwrapPrice(
            _LeasingRenting.Leasing.dailyLeasePrice,
            scale
        );
        uint256 totalRenterPmtWoCollateral = rentPrice *
            _LeasingRenting.renting.rentDuration;
        uint256 sendLeaserAmt = (_secondsSinceRentStart * rentPrice) /
            SECONDS_IN_DAY;
        require(
            totalRenterPmtWoCollateral > 0,
            "vRent::total payment wo collateral is zero"
        );
        require(sendLeaserAmt > 0, "vRent::Leaser payment is zero");
        uint256 sendRenterAmt = totalRenterPmtWoCollateral - sendLeaserAmt;

        uint256 takenFee = takeFee(
            sendLeaserAmt,
            _LeasingRenting.Leasing.paymentToken
        );

        sendLeaserAmt -= takenFee;

        ERC20(paymentToken).safeTransfer(
            _LeasingRenting.Leasing.leaserAddress,
            sendLeaserAmt
        );
        ERC20(paymentToken).safeTransfer(
            _LeasingRenting.renting.renterAddress,
            sendRenterAmt
        );
    }

    // -------------------------------------------------------------------------
    function manageLease(CallData memory _cd) private {
        for (uint256 i = 0; i < _cd.nfts.length; i++) {
            _verifyIsLeaseable(_cd, i);

            LeasingRenting storage item = leasingRenting[
                keccak256(
                    abi.encodePacked(_cd.nfts[i], _cd.tokenIds[i], leasingId)
                )
            ];

            _verifyIsNull(item.Leasing);
            _verifyIsNull(item.renting);

            item.Leasing = Leasing({
                leaserAddress: payable(msg.sender),
                maxLeaseDuration: _cd.maxLeaseDurations[i],
                dailyLeasePrice: _cd.dailyLeasePrices[i],
                paymentToken: _cd.paymentTokens[i]
            });

            emit Leased(
                _cd.nfts[i],
                _cd.tokenIds[i],
                leasingId,
                msg.sender,
                _cd.maxLeaseDurations[i],
                _cd.dailyLeasePrices[i],
                _cd.paymentTokens[i]
            );

            // set lien
            _ERCX.setLien(leasingId);
            IERC721(_cd.nfts[i]).transferFrom(
                msg.sender,
                address(this),
                _cd.tokenIds[i]
            );
            leasingId++;
        }
    }

    function manageRent(CallData memory _cd) private {
        for (uint256 i = 0; i < _cd.nfts.length; i++) {
            LeasingRenting storage item = leasingRenting[
                keccak256(
                    abi.encodePacked(
                        _cd.nfts[i],
                        _cd.tokenIds[i],
                        _cd.leasingIds[i]
                    )
                )
            ];

            _verifyIsNotNull(item.Leasing);
            _verifyIsNull(item.renting);
            _verifyIsRentable(item.Leasing, _cd, i, msg.sender);

            uint8 paymentTokenIx = uint8(item.Leasing.paymentToken);
            verifyTokenNotSentinel(paymentTokenIx);
            address paymentToken = payment.getPaymentToken(paymentTokenIx);
            uint256 decimals = ERC20(paymentToken).decimals();

            {
                uint256 scale = 10**decimals;
                uint256 rentPrice = _cd.rentDurations[i] *
                    _unwrapPrice(item.Leasing.dailyLeasePrice, scale);

                require(rentPrice > 0, "vRent::rent price is zero");

                ERC20(paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    rentPrice
                );
            }

            item.renting.renterAddress = payable(msg.sender);
            item.renting.rentDuration = _cd.rentDurations[i];
            item.renting.rentedAt = uint32(block.timestamp);

            emit Rented(
                _cd.leasingIds[i],
                msg.sender,
                _cd.rentDurations[i],
                item.renting.rentedAt
            );
            // transfer user ownership 2615
            _ERCX.safeTransferUser(admin, msg.sender, _cd.leasingIds[i]);
        }
    }

    function manageReturn(CallData memory _cd) private {
        for (uint256 i = 0; i < _cd.nfts.length; i++) {
            LeasingRenting storage item = leasingRenting[
                keccak256(
                    abi.encodePacked(
                        _cd.nfts[i],
                        _cd.tokenIds[i],
                        _cd.leasingIds[i]
                    )
                )
            ];

            _verifyIsNotNull(item.Leasing);
            _verifyIsReturnable(item.renting, msg.sender, block.timestamp);

            uint256 secondsSinceRentStart = block.timestamp -
                item.renting.rentedAt;
            distributePayments(item, secondsSinceRentStart);

            emit Returned(_cd.leasingIds[i], uint32(block.timestamp));

            delete item.renting;

            // transfer user role back to owner
            _ERCX.safeTransferUser(msg.sender, admin, _cd.leasingIds[i]);
        }
    }

    function manageStopLeasing(CallData memory _cd) private {
        for (uint256 i = 0; i < _cd.nfts.length; i++) {
            LeasingRenting storage item = leasingRenting[
                keccak256(
                    abi.encodePacked(
                        _cd.nfts[i],
                        _cd.tokenIds[i],
                        _cd.leasingIds[i]
                    )
                )
            ];

            _verifyIsNotNull(item.Leasing);
            _verifyIsNull(item.renting);
            _verifyIsStoppable(item.Leasing, msg.sender);

            emit LeasingStopped(_cd.leasingIds[i], uint32(block.timestamp));

            delete item.Leasing;
            // revoke lien
            _ERCX.revokeLien(_cd.leasingIds[i]);
            IERC721(_cd.nfts[i]).transferFrom(
                address(this),
                msg.sender,
                _cd.tokenIds[i]
            );
        }
    }

    function _createLeaseCallData(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint8[] memory _maxLeaseDurations,
        bytes4[] memory _dailyLeasePrices,
        IPayment.PaymentToken[] memory _paymentTokens
    ) private pure returns (CallData memory cd) {
        cd = CallData({
            nfts: _nfts,
            tokenIds: _tokenIds,
            leasingIds: new uint256[](0),
            rentDurations: new uint8[](0),
            maxLeaseDurations: _maxLeaseDurations,
            dailyLeasePrices: _dailyLeasePrices,
            paymentTokens: _paymentTokens
        });
    }

    function _createRentCallData(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds,
        uint8[] memory _rentDurations
    ) private pure returns (CallData memory cd) {
        cd = CallData({
            nfts: _nfts,
            tokenIds: _tokenIds,
            leasingIds: _leasingIds,
            rentDurations: _rentDurations,
            maxLeaseDurations: new uint8[](0),
            dailyLeasePrices: new bytes4[](0),
            paymentTokens: new IPayment.PaymentToken[](0)
        });
    }

    function _createActionCallData(
        address[] memory _nfts,
        uint256[] memory _tokenIds,
        uint256[] memory _leasingIds
    ) private pure returns (CallData memory cd) {
        cd = CallData({
            nfts: _nfts,
            tokenIds: _tokenIds,
            leasingIds: _leasingIds,
            rentDurations: new uint8[](0),
            maxLeaseDurations: new uint8[](0),
            dailyLeasePrices: new bytes4[](0),
            paymentTokens: new IPayment.PaymentToken[](0)
        });
    }

    /**
     * convert the `dailyLeasePrices` from bytes4 into decimal
     */
    function _unwrapPrice(bytes4 _price, uint256 _scale)
        private
        pure
        returns (uint256)
    {
        _verifyIsUnwrapablePrice(_price, _scale);

        uint16 whole = uint16(bytes2(_price));
        uint16 decimal = uint16(bytes2(_price << 16));
        uint256 decimalScale = _scale / 10000;

        if (whole > 9999) {
            whole = 9999;
        }
        if (decimal > 9999) {
            decimal = 9999;
        }

        uint256 w = whole * _scale;
        uint256 d = decimal * decimalScale;
        uint256 price = w + d;

        return price;
    }

    // -------------------------------------------------------------------------

    /**
     * verify whether caller is zero aaddress or not
     */
    function _verifyIsNotZeroAddr(address _addr) private pure {
        require(_addr != address(0), "vRent::zero address");
    }

    function _verifyIsZeroAddr(address _addr) private pure {
        require(_addr == address(0), "vRent::not a zero address");
    }

    function _verifyIsNull(Leasing memory _Leasing) private pure {
        _verifyIsZeroAddr(_Leasing.leaserAddress);
        require(_Leasing.maxLeaseDuration == 0, "vRent::duration not zero");
        require(_Leasing.dailyLeasePrice == 0, "vRent::rent price not zero");
    }

    function _verifyIsNotNull(Leasing memory _Leasing) private pure {
        _verifyIsNotZeroAddr(_Leasing.leaserAddress);
        require(_Leasing.maxLeaseDuration != 0, "vRent::duration zero");
        require(_Leasing.dailyLeasePrice != 0, "vRent::rent price is zero");
    }

    function _verifyIsNull(Renting memory _renting) private pure {
        _verifyIsZeroAddr(_renting.renterAddress);
        require(_renting.rentDuration == 0, "vRent::duration not zero");
        require(_renting.rentedAt == 0, "vRent::rented at not zero");
    }

    function _verifyIsNotNull(Renting memory _renting) private pure {
        _verifyIsNotZeroAddr(_renting.renterAddress);
        require(_renting.rentDuration != 0, "vRent::duration is zero");
        require(_renting.rentedAt != 0, "vRent::rented at is zero");
    }

    /**
     * verify whether the duration is between the range else user can't Lease nft
     */
    function _verifyIsLeaseable(CallData memory _cd, uint256 _i) private pure {
        require(_cd.maxLeaseDurations[_i] > 0, "vRent::duration is zero");
        require(
            _cd.maxLeaseDurations[_i] <= type(uint8).max,
            "vRent::not uint8"
        );
        require(
            uint32(_cd.dailyLeasePrices[_i]) > 0,
            "vRent::rent price is zero"
        );
    }

    /**
     * verifys the rent duration provided by user
     */
    function _verifyIsRentable(
        Leasing memory _Leasing,
        CallData memory _cd,
        uint256 _i,
        address _msgSender
    ) private pure {
        require(
            _msgSender != _Leasing.leaserAddress,
            "vRent::cant rent own nft"
        );
        require(_cd.rentDurations[_i] <= type(uint8).max, "vRent::not uint8");
        require(_cd.rentDurations[_i] > 0, "vRent::duration is zero");
        require(
            _cd.rentDurations[_i] <= _Leasing.maxLeaseDuration,
            "vRent::rent duration exceeds allowed max"
        );
    }

    /**
     * @dev compare the timestamp and return time and returns
     * whether the NFT is returnable or not
     */
    function _verifyIsReturnable(
        Renting memory _renting,
        address _msgSender,
        uint256 _blockTimestamp
    ) private pure {
        require(_renting.renterAddress == _msgSender, "vRent::not renter");
        require(
            !_isPastReturnDate(_renting, _blockTimestamp),
            "vRent::past return date"
        );
    }

    function _verifyIsStoppable(Leasing memory _Leasing, address _msgSender)
        private
        pure
    {
        require(_Leasing.leaserAddress == _msgSender, "vRent::not Leaser");
    }

    function _verifyIsClaimable(
        Renting memory _renting,
        uint256 _blockTimestamp
    ) private pure {
        require(
            _isPastReturnDate(_renting, _blockTimestamp),
            "vRent::return date not passed"
        );
    }

    function _verifyIsUnwrapablePrice(bytes4 _price, uint256 _scale)
        private
        pure
    {
        require(uint32(_price) > 0, "vRent::invalid price");
        require(_scale >= 10000, "vRent::invalid scale");
    }

    function verifyTokenNotSentinel(uint8 _paymentIx) private pure {
        require(_paymentIx > 0, "vRent::token is sentinel");
    }

    function _isPastReturnDate(Renting memory _renting, uint256 _now)
        private
        pure
        returns (bool)
    {
        require(_now > _renting.rentedAt, "vRent::now before rented");
        return
            _now - _renting.rentedAt > _renting.rentDuration * SECONDS_IN_DAY;
    }

    // -------------------------------------------------------------------------

    /**
     * @dev only Admin can call this function
     * set the platform `rentFee`
     * `+_rentFee` should be less than 100%
     */
    function setRentFee(uint256 _rentFee) external onlyAdmin {
        require(_rentFee < 10000, "vRent::fee exceeds 100pct");
        rentFee = _rentFee;
    }

    /**
     * @dev only admin can call this function
     * replaces the `beneficiary` address to `+_newBeneficiary`
     */
    function setBeneficiary(address payable _newBeneficiary)
        external
        onlyAdmin
    {
        beneficiary = _newBeneficiary;
    }

    /**
     * admin can pause the Lease, rent, returnit or claimCollateral functions
     */
    function setPaused(bool _paused) external onlyAdmin {
        paused = _paused;
    }

    function getleasingId() external view returns (uint256) {
        return leasingId;
    }

    function getLeasing(
        address nft,
        uint256 tokenId,
        uint256 LeaseId
    ) external view returns (Leasing memory) {
        return
            leasingRenting[keccak256(abi.encodePacked(nft, tokenId, LeaseId))]
                .Leasing;
    }

    function getRenting(
        address nft,
        uint256 tokenId,
        uint256 LeaseId
    ) external view returns (Renting memory) {
        return
            leasingRenting[keccak256(abi.encodePacked(nft, tokenId, LeaseId))]
                .renting;
    }
}
