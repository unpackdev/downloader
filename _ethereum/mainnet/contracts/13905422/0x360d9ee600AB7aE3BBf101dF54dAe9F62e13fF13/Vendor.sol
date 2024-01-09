// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./IManager.sol";
import "./IArchive.sol";

/**
   @title Vendor contract
   @dev This contract handles purchasing Game NFT item (Primary and Secondary)
        + Accept ERC-20 Token - the token contract should be registered in Manager.sol
        + Accept the payment using native coin
        + Purchasing NFT item requires a signature from Verifier to authorize the request
        Fail to do so will likely revert
*/
contract Vendor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant NFT721 = 721;
    uint256 private constant NFT1155 = 1155;
    uint256 private constant PRIMARY = 7746279;
    uint256 private constant SECONDARY = 732663279;
    uint256 public constant FEE_DENOMINATOR = 10**6;

    //  Address of Manager contract
    IManager public manager;

    //  Address of Archive contract
    IArchive public archive;

    struct SaleInfo {
        address seller;
        address nftContract;
        address paymentToken;
        uint256 saleID;
        uint256 nftType;
        uint256 tokenID;
        uint256 onSaleAmt;
        uint256 amount;
        uint256 unitPrice;
        uint256 saleKind;
    }

    struct FeeInfo {
        address royaltyRecv;
        uint256 fee;
        uint256 royalty;
    }

    event PaymentTx(
        uint256 indexed _saleId,
        address indexed _buyer,
        address indexed _seller,
        address _royaltyRecv,
        uint256 _amount,
        uint256 _fee,
        uint256 _royalty
    );

    event NativeCoinPayment(address indexed _to, uint256 _amount);
    event CancelSale(address indexed _seller, uint256 _saleId);

    constructor(address _manager, address _archive) Ownable() {
        manager = IManager(_manager);
        archive = IArchive(_archive);
    }

    /**
        @notice Change a new Manager contract
        @dev Caller must be Owner
        @param _newManager       Address of new Manager contract
    */
    function updateManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "Set zero address");
        manager = IManager(_newManager);
    }

    /**
        @notice Save `_saleId` when Seller cancels 'On Sale' items
        @dev Caller can be ANY
        @param _saleId      An unique identification number of Sale Info
        @param _sig         A signature from Verifier
    */
    function cancelOnSale(uint256 _saleId, bytes calldata _sig) external {
        require(!archive.prevSaleIds(_saleId), "SaleId already recorded");

        address _seller = _msgSender();
        _checkCancelSignature(_saleId, _seller, _sig);
        archive.archive(_saleId);

        emit CancelSale(_seller, _saleId);
    }

    function purchase(SaleInfo calldata _saleInfo, FeeInfo calldata _feeInfo, bytes calldata _sig) external payable nonReentrant {
        //  Checking type of NFT item and type of sale
        require(_saleInfo.nftType == NFT721 || _saleInfo.nftType == NFT1155, "Invalid nft type");
        require(_saleInfo.saleKind == PRIMARY || _saleInfo.saleKind == SECONDARY, "Invalid sale type");

        //  Then, checking the payment info
        //      + validate purchasing amount
        //      + validate payment token
        //      + If payment token is native coin, checking msg.value
        _checkPurchase(_saleInfo.saleID, _saleInfo.nftType, _saleInfo.onSaleAmt, _saleInfo.unitPrice, _saleInfo.amount, _saleInfo.paymentToken);

        //  Validate signature - the signature should be provided by Verifier
        //  to authorize msg.sender sending the request to contract
        _checkSignature(_saleInfo, _feeInfo, _sig);

        //  Make Payment
        if (_saleInfo.saleKind == PRIMARY) {
            _primaryPayment(_saleInfo.paymentToken, _saleInfo.unitPrice, _saleInfo.amount);

            //  Primary Sale -> payment is transffered to Treasury -> `royaltyRecv = address(0)` and `royalty = 0`
            emit PaymentTx(
                _saleInfo.saleID, _msgSender(), _saleInfo.seller, address(0), _saleInfo.amount, _saleInfo.unitPrice * _saleInfo.amount, 0
            );
        } else {
            (uint256 _chargedFee, uint256 _royaltyFee, uint256 _payToSeller) = _calcPayment(
                _saleInfo.unitPrice, _saleInfo.amount, _feeInfo.fee, _feeInfo.royalty
            );
            _secondaryPayment(
                _saleInfo.paymentToken, _saleInfo.seller, _feeInfo.royaltyRecv, 
                _payToSeller, _royaltyFee, _chargedFee
            );

            emit PaymentTx(
                _saleInfo.saleID, _msgSender(), _saleInfo.seller, _feeInfo.royaltyRecv, _saleInfo.amount, _chargedFee, _royaltyFee
            );
        }

        //  transfer NFT item to Buyer
        //  If Seller has not yet setApproveForAll to allow Payment contract
        //  transfer NFT item, this transaction is likely reverted
        _transferItem(_saleInfo.nftContract, _saleInfo.nftType, _saleInfo.seller, _saleInfo.tokenID, _saleInfo.amount);
    }

    function _checkCancelSignature(uint256 _saleId, address _seller, bytes calldata _sig) private view {
        bytes32 _data = keccak256(abi.encodePacked(_saleId, _seller));
        _data = ECDSA.toEthSignedMessageHash(_data);
        require(
            ECDSA.recover(_data, _sig) == manager.verifier(),
            "Invalid params or signature"
        );
    }

    function _checkSignature(SaleInfo calldata _saleInfo, FeeInfo calldata _feeInfo, bytes calldata _sig) private view {
        bytes memory packedAddrs = abi.encodePacked(
            _saleInfo.seller, _saleInfo.nftContract, _saleInfo.paymentToken, _feeInfo.royaltyRecv
        );
        bytes memory packedNumbs = abi.encodePacked(
            _saleInfo.saleID, _saleInfo.nftType, _saleInfo.tokenID, _saleInfo.onSaleAmt, _saleInfo.amount, 
            _saleInfo.unitPrice, _saleInfo.saleKind, _feeInfo.fee, _feeInfo.royalty
        );

        bytes32 _txHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(packedAddrs, packedNumbs)
            )
        );
        //  It doesn't need to record '_txHash' due to these reasons:
        //  - saleID is generated uniquely when Seller requests to put items on market
        //  - After items are purchased, 'onSaleAmt' is also updated -> next purchase of the same item is likely generated a different signature
        //  - Record successful txHash might cause one error in the case that
        //  two Buyer purchase same item with the same amount
        //  Example: 
        //      + NFT1155: Seller puts on sale 10 items
        //  Buyer 1, and Buyer 2 both request to purchase 5 items at the same time, hence '_sig' is the same for both request
        //  Since 'availableOnSale' is 10 items -> Buyer 1, and Buyer 2 should be able to purchase 5 items
        //      + NFT721: the amount is always one. Two requests at the same will eventually end up with only one success
        require(
            ECDSA.recover(_txHash, _sig) == manager.verifier(),
            "Invalid params or signature"
        );
    }

    function _checkPurchase(uint256 _saleId, uint256 _nftType, uint256 _onSaleAmt, uint256 _price, uint256 _amount, address _paymentToken) private {
        //  First, checking whether `_saleId` has been previously canceled
        require(!archive.prevSaleIds(_saleId), "SaleId already canceled");
        
        //  Then, checking purchasing amount
        //  If '_amount' = 0 -> revert
        //  If '_amount' is greater than 'currentOnSale' -> revert
        //  In success, update 'currentOnSale'
        require(_amount > 0, "Purchase zero item");
        require(
            _nftType == NFT721 && _onSaleAmt == 1 ||
            _nftType == NFT1155 && _onSaleAmt != 0,
            "Invalid OnSaleAmt"
        );

        //  If the saleID is firstly purchased, the 'currentOnSale' is updated the new value
        //  then, lock 'OnSale' state
        //  For next following purchases, 'currentOnSale' will be deducted until reaching zero
        //  The 'OnSale' state will bind to the 'saleId' and won't be reset
        uint256 availableOnSale = archive.getCurrentOnSale(_saleId);
        if ( archive.getLocked(_saleId) ) {
            require(availableOnSale >= _amount, "Invalid purchase amount");
        } else {
            archive.setLocked(_saleId);
            availableOnSale = _onSaleAmt;
        }

        archive.setCurrentOnSale(_saleId, availableOnSale - _amount);
        //  Validate paymentToken and payment amount
        if (_paymentToken == address(0)) {
            //  @dev Solidity 0.8.0 has integrated overflow and underflow
            //  Please see https://docs.soliditylang.org/en/v0.8.7/080-breaking-changes.html
            require(
                _price * _amount == msg.value,
                "Insufficient payment"
            );
        } else {
            require(manager.acceptedPayments(_paymentToken), "Invalid payment token");
        }
    }

    function _primaryPayment(address _paymentToken, uint256 _price, uint256 _amount) private {
        //  Primary Sale: the payment is transferred to Treasury
        if (_paymentToken == address(0)) {
            _paymentTransfer(payable(manager.treasury()), _price * _amount);
        } else {
            //  transfer payment to Treasury
            //  If Buyer has not yet set allowance[buyer][operator]
            //  and Buyer has insufficient balances, these transactions are likely reverted
            IERC20(_paymentToken).safeTransferFrom(
                _msgSender(),
                manager.treasury(),
                _price * _amount
            );
        }
    }

    function _secondaryPayment(
        address _paymentToken,
        address _seller,
        address _royaltyRecv,
        uint256 _payToSeller,
        uint256 _royalty,
        uint256 _fee
    ) private {
        if (_paymentToken == address(0)) {
            //  transfer payment to Seller and Treasury
            _paymentTransfer(payable(manager.treasury()), _fee);
            _paymentTransfer(payable(_royaltyRecv), _royalty);
            _paymentTransfer(payable(_seller), _payToSeller);
            
        } else {
            //  transfer payment to Seller and Treasury
            //  If Buyer has not yet set allowance[buyer][operator]
            //  and Buyer has insufficient balances, these transactions are likely reverted
            IERC20(_paymentToken).safeTransferFrom(
                _msgSender(),
                manager.treasury(),
                _fee
            );
            IERC20(_paymentToken).safeTransferFrom(
                _msgSender(),
                _royaltyRecv,
                _royalty
            );
            IERC20(_paymentToken).safeTransferFrom(
                _msgSender(),
                _seller,
                _payToSeller
            );
        }
    }

    function _paymentTransfer(address payable _to, uint256 _amount) private {
        (bool sent, ) = _to.call{ value: _amount }("");
        require(sent, "Payment transfer failed");
        emit NativeCoinPayment(_to, _amount);
    }

    function _transferItem(
        address _nftContract,
        uint256 _nftType,
        address _from,
        uint256 _id,
        uint256 _amount
    ) private {
        if (_nftType == NFT721) {
            IERC721Upgradeable(_nftContract).safeTransferFrom(_from, _msgSender(), _id);
        }else {
            IERC1155Upgradeable(_nftContract).safeTransferFrom(
                _from, _msgSender(), _id, _amount, ""
            );
        }
    }

    function _calcPayment(
        uint256 _price,
        uint256 _amount,
        uint256 _feeRate,
        uint256 _royaltyRate
    ) private pure returns (uint256 _fee, uint256 _royalty, uint256 _payToSeller) {
        //  @dev Solidity 0.8.0 has integrated overflow and underflow
        //  Please see https://docs.soliditylang.org/en/v0.8.7/080-breaking-changes.html
        //  Commission Fee = _fee = _price * _amount * _feeRate / FEE_DENOMINATOR
        //  Royalty fee = _royalty = _price * _amount * _royalty / FEE_DENOMINATOR
        // _payToSeller = _price * _amount - _fee - _royalty
        _fee = (_price * _amount * _feeRate) / FEE_DENOMINATOR;
        _royalty = (_price * _amount * _royaltyRate) / FEE_DENOMINATOR;
        _payToSeller = _price * _amount - _fee - _royalty;
    }
}
