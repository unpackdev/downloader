// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Pawn.sol";
import "./Locker.sol";

contract PawnMortgage is Pawn {
    constructor(Locker _locker, address payable _beneficiary) {
        require(_beneficiary != address(0), "Initiate:: _beneficiary can not be zero address");
        locker = _locker;
        beneficiary = _beneficiary;
    }

    uint256 public platformFee = 250;
    uint256 public totalLoans = 0;
    uint256 public totalActiveLoans = 0;
    uint256 public maximumLoanDuration = 105 weeks;
    address payable public beneficiary;

    struct Loan {
        uint256 loanId;
        uint256 loanPrincipalAmount;
        uint256 repaymentAmount;
        uint256 nftTokenId; // nft token id
        uint256 loanStartTime; // The block.timestamp when the loan first began (measured in seconds).
        uint256 loanDuration; // The amount of time (measured in seconds) that can elapse before the lender can liquidate the loan and seize the underlying collateral.
        uint256 platformFee;
        address erc721Contract; // nft erc721 contract
        address whitelistedERC20; // whitelisted erc20 token
        address borrower;
    }

    mapping(uint256 => Loan) public loanIdToLoan;
    mapping(uint256 => bool) public loanRepaidOrLiquidated;
    mapping(address => mapping(uint256 => bool)) private _userNonce;
    mapping(address => mapping(uint256 => bool)) private _isOnLend;
    mapping(address => mapping(uint256 => uint256))
        private _loanIdByTokenAddressTokenId;
    mapping(address => bool) public erc20Whitelist;

    Locker public locker;

    // EVENTS
    event PlatformFeeUpdated(uint256 _oldFee, uint256 _newFee);
    event ERC20WhitelistUpdated(
        address _erc20,
        uint256 _when,
        address _who,
        bool _status
    );

    event StartLoan(
        uint256 loanId,
        address borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 repaymentAmount,
        uint256 nfnftTokenId,
        uint256 loanStartTime,
        uint256 loanDuration,
        address nftContract,
        address whitelistedERC20
    );

    event CloseLoan(
        uint256 loanId,
        address borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 nftTokenId,
        uint256 payoffAmount,
        uint256 fee,
        address erc721Contract,
        address whitelistedERC20
    );

    event Liquidated(
        uint256 loanId,
        address borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 nftTokenId,
        uint256 loanMaturityDate,
        uint256 liquidatedOn,
        address erc721Contract
    );

    event ExtendedLoan(
        uint256 loanId,
        uint256 updatedOn,
        uint256 updatedTenure,
        address updatedBy
    );

    event MaxLoanDurationUpdated(uint256 _old, uint256 _new);

    event BeneficiaryUpdated(address oldBeneficiary, address newBeneficiary);

    // Add or Update ERC20 to whitelist
    function updateERC20Whitelist(address _erc20Token, bool _status)
        external
        onlyOwner
    {
        erc20Whitelist[_erc20Token] = _status;
        emit ERC20WhitelistUpdated(
            _erc20Token,
            block.timestamp,
            msg.sender,
            _status
        );
    }

    // Check if a ERC20 token whitelisted or not
    function isERC20Whitelisted(address _erc20Token)
        public
        view
        returns (bool)
    {
        return erc20Whitelist[_erc20Token];
    }

    // Update Platform Fee
    function updatePlatformFee(uint256 _newFee) external onlyOwner {
        require(
            _newFee <= 10000,
            "By definition, basis points cannot exceed 10000"
        );
        uint256 _oldFee = platformFee;
        platformFee = _newFee;
        emit PlatformFeeUpdated(_oldFee, _newFee);
    }

    // Check if a NFT on Lend or not
    function isNFTOnLend(address _erc721Token, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return _isOnLend[_erc721Token][_tokenId];
    }

    // Get Active Loan Id if any
    function getActiveLoanId(address _erc721Token, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return _loanIdByTokenAddressTokenId[_erc721Token][_tokenId];
    }

    // lend - Called by Borrower of ERC20
    function lend(
        uint256 _loanPrincipalAmount,
        uint256 _repaymentAmount,
        uint256 _nftTokenId,
        uint256 _loanDuration,
        uint256 _platformFee,
        uint256[2] memory _borrowerAndLenderNonces,
        address[2] memory _erc721Anderc20contracts,
        address _lender,
        bytes memory _borrowerSig,
        bytes memory _lenderSig
    ) external whenNotPaused nonReentrant {
        address _erc721Contract = _erc721Anderc20contracts[0];
        address _whitelistedERC20 = _erc721Anderc20contracts[1];
        Loan memory loan = Loan({
            loanId: totalLoans, //currentLoanId,
            loanPrincipalAmount: _loanPrincipalAmount,
            repaymentAmount: _repaymentAmount,
            nftTokenId: _nftTokenId,
            loanStartTime: block.timestamp, //_loanStartTime
            loanDuration: _loanDuration,
            platformFee: _platformFee,
            erc721Contract: _erc721Contract,
            whitelistedERC20: _whitelistedERC20,
            borrower: msg.sender //borrower
        });

        require(
            loan.repaymentAmount >= loan.loanPrincipalAmount,
            "lend:: Interest can not be negetive"
        );
        require(
            uint256(loan.loanDuration) <= maximumLoanDuration,
            "lend:: Loan duration can not excceds max loan duration"
        );
        require(
            uint256(loan.loanDuration) != 0,
            "lend:: Tenure can not be zero"
        );
        require(
            uint256(loan.platformFee) == platformFee,
            "lend:: Platform fee has changed since this order was signed."
        );
        require(
            erc20Whitelist[loan.whitelistedERC20],
            "lend:: Invalid whitelisted erc20 token"
        );
        require(
            !_userNonce[msg.sender][_borrowerAndLenderNonces[0]],
            "lend:: Invalid borrower nonce, borrower has either cancelled/begun this loan, or reused this nonce when signing"
        );
        _userNonce[msg.sender][_borrowerAndLenderNonces[0]] = true;
        require(
            !_userNonce[_lender][_borrowerAndLenderNonces[1]],
            "lend:: Invalid lender nonce, lender has either cancelled/begun this loan, or reused this nonce when signing"
        );
        _userNonce[_lender][_borrowerAndLenderNonces[1]] = true;

        _isOnLend[_erc721Contract][_nftTokenId] = true;

        require(
            verifyBorrowerSign(
                loan.nftTokenId,
                _borrowerAndLenderNonces[0], //_borrowerNonce,
                loan.erc721Contract,
                msg.sender,
                _borrowerSig
            ),
            "lend:: Invalid borrower signature"
        );

        require(
            verifyLenderSign(
                loan.loanPrincipalAmount,
                loan.repaymentAmount,
                loan.nftTokenId,
                loan.loanDuration,
                loan.platformFee,
                _borrowerAndLenderNonces[1],
                loan.erc721Contract,
                loan.whitelistedERC20,
                _lender,
                _lenderSig
            ),
            "lend:: Invalid lender sign"
        );

        loanIdToLoan[totalLoans] = loan;
        totalLoans = totalLoans + 1;

        totalActiveLoans = totalActiveLoans + 1;

        IERC721(loan.erc721Contract).transferFrom(
            msg.sender,
            address(locker),
            loan.nftTokenId
        );
        IERC20(loan.whitelistedERC20).transferFrom(
            _lender,
            msg.sender,
            loan.loanPrincipalAmount
        );

        _mint(_lender, loan.loanId);
        _setTokenURI(
            loan.loanId,
            string(abi.encodePacked(_baseURI(), loan.loanId))
        );
        _loanIdByTokenAddressTokenId[_erc721Contract][_nftTokenId] = loan
            .loanId;

        emit StartLoan(
            loan.loanId,
            msg.sender, //borrower,
            _lender,
            loan.loanPrincipalAmount,
            loan.repaymentAmount,
            loan.nftTokenId,
            uint64(block.timestamp), //_loanStartTime
            loan.loanDuration,
            loan.erc721Contract,
            loan.whitelistedERC20
        );
    }

    // payback - Called by Borrower of ERC20
    function payback(uint256 _loanId) external whenNotPaused nonReentrant {
        require(
            !loanRepaidOrLiquidated[_loanId],
            "payback:: Oops loan paid or liquidated"
        );
        Loan memory loan = loanIdToLoan[_loanId];

        require(msg.sender == loan.borrower, "payback:: Unauthorized");
        address lender = ownerOf(_loanId);

        uint256 interestDue = loan.repaymentAmount - loan.loanPrincipalAmount;
        uint256 fee = _computePlatformFee(
            interestDue,
            uint256(loan.platformFee)
        );
        uint256 payoffAmount = (loan.loanPrincipalAmount + interestDue) - fee;

        loanRepaidOrLiquidated[_loanId] = true;

        totalActiveLoans = totalActiveLoans - 1;

        IERC20(loan.whitelistedERC20).transferFrom(
            loan.borrower,
            lender,
            payoffAmount
        );
        IERC20(loan.whitelistedERC20).transferFrom(
            loan.borrower,
            beneficiary,
            fee
        );

        _isOnLend[loan.erc721Contract][loan.nftTokenId] = false;

        locker.release(loan.erc721Contract, loan.nftTokenId, loan.borrower);

        _burn(_loanId);

        emit CloseLoan(
            _loanId,
            loan.borrower,
            lender,
            loan.loanPrincipalAmount,
            loan.nftTokenId,
            payoffAmount,
            fee,
            loan.erc721Contract,
            loan.whitelistedERC20
        );

        delete loanIdToLoan[_loanId];
    }

    // liquidateLoan - Called by Lender of ERC20
    function liquidateLoan(uint256 _loanId) external nonReentrant {
        require(
            !loanRepaidOrLiquidated[_loanId],
            "liquidateLoan:: Oops repaid or liquidated already"
        );

        Loan memory loan = loanIdToLoan[_loanId];

        uint256 loanMaturityDate = uint256(loan.loanStartTime) +
            uint256(loan.loanDuration);
        require(
            block.timestamp > loanMaturityDate,
            "liquidateLoan:: Not yet overdue"
        );

        address lender = ownerOf(_loanId);

        loanRepaidOrLiquidated[_loanId] = true;

        totalActiveLoans = totalActiveLoans - 1;

        locker.release(loan.erc721Contract, loan.nftTokenId, lender);

        _isOnLend[loan.erc721Contract][loan.nftTokenId] = false;

        _burn(_loanId);

        emit Liquidated(
            _loanId,
            loan.borrower,
            lender,
            loan.loanPrincipalAmount,
            loan.nftTokenId,
            loanMaturityDate,
            block.timestamp,
            loan.erc721Contract
        );

        delete loanIdToLoan[_loanId];
    }

    // update lend duration - Called by Lender of ERC20 - _duration (in seconds)
    function extendLoan(uint256 _loanId, uint256 _duration)
        external
        nonReentrant
    {
        require(
            !loanRepaidOrLiquidated[_loanId],
            "ExtendLoan:: Oops repaid or liquidated already"
        );

        Loan memory loan = loanIdToLoan[_loanId];

        address lender = ownerOf(_loanId);

        require(lender == msg.sender, "ExtendLoan:: Only lender can extend");

        loan.loanDuration = loan.loanDuration + _duration;

        emit ExtendedLoan(_loanId, block.timestamp, _duration, msg.sender);
    }

    // Update Nonce Before Loan
    function cancelLoanBeforeLoanHasBegun(uint256 _nonce) external {
        require(
            !_userNonce[msg.sender][_nonce],
            "CancelLoanBeforeLoanHasBegun:: Invalid Nonce, Cancelled or Reused or Loand Started"
        );
        _userNonce[msg.sender][_nonce] = true;
    }

    // Update Max Loan Duration
    function updateMaxLoanDuration(uint256 _newMaximumLoanDuration)
        external
        onlyOwner
    {
        require(
            _newMaximumLoanDuration != 0,
            "updateMaxLoanDuration:: Duration can not be zero"
        );
        uint256 _oldMaximumLoanDuration = maximumLoanDuration;
        maximumLoanDuration = _newMaximumLoanDuration;
        emit MaxLoanDurationUpdated(
            _oldMaximumLoanDuration,
            _newMaximumLoanDuration
        );
    }

    // Nonce Verification or Status Check
    function checkWhetherNonceUsedByUserOrNot(address _user, uint256 _nonce)
        external
        view
        returns (bool)
    {
        return _userNonce[_user][_nonce];
    }

    // Get Pauoff Amount for Loan
    function getPayoffAmount(uint256 _loanId)
        external
        view
        returns (address, uint256)
    {
        Loan storage loan = loanIdToLoan[_loanId];
        return (loan.whitelistedERC20, loan.repaymentAmount);
    }

    // Calculate Plaform Fee
    function _computePlatformFee(uint256 _interestDue, uint256 _fee)
        internal
        pure
        returns (uint256)
    {
        return (_interestDue * (_fee)) / (10000);
    }

    // Generate Lender Message
    function generateLenderMessage(
        uint256 _loanPrincipalAmount,
        uint256 _repaymentAmount,
        uint256 _nftTokenId,
        uint256 _loanDuration,
        uint256 _platformFee,
        uint256 _lenderNonce,
        address _nftContract,
        address _whitelistedERC20,
        address _lender
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _loanPrincipalAmount,
                    _repaymentAmount,
                    _nftTokenId,
                    _loanDuration,
                    _platformFee,
                    _lenderNonce,
                    _nftContract,
                    _whitelistedERC20,
                    _lender,
                    address(this),
                    block.chainid
                )
            );
    }

    // Generate Borrower Message
    function generateBorrowerMessage(
        uint256 _nftTokenId,
        uint256 _borrowerNonce,
        address _nftContract,
        address _borrower
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _nftTokenId,
                    _borrowerNonce,
                    _nftContract,
                    _borrower,
                    address(this),
                    block.chainid
                )
            );
    }

    // Verify Lender Sign
    function verifyLenderSign(
        uint256 _loanPrincipalAmount,
        uint256 _repaymentAmount,
        uint256 _nftTokenId,
        uint256 _loanDuration,
        uint256 _platformFee,
        uint256 _lenderNonce,
        address _nftContract,
        address _whitelistedERC20,
        address _lender,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = generateLenderMessage(
            _loanPrincipalAmount,
            _repaymentAmount,
            _nftTokenId,
            _loanDuration,
            _platformFee,
            _lenderNonce,
            _nftContract,
            _whitelistedERC20,
            _lender
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _lender;
    }

    // Verify Borrower Sign
    function verifyBorrowerSign(
        uint256 _nftTokenId,
        uint256 _borrowerNonce,
        address _nftContract,
        address _borrower,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = generateBorrowerMessage(
            _nftTokenId,
            _borrowerNonce,
            _nftContract,
            _borrower
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _borrower;
    }

    // Recover Signature
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // Get Sign Message Hash
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    // Split Signature
    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "splitSignature:: Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function updateBeneficiary(address payable _newBeneficiary)
        external
        onlyOwner
    {
        require(
            _newBeneficiary != address(0),
            "UpdateBeneficiary:: New Beneficiary can not be Zero Address"
        );
        address _oldBeneficiary = beneficiary;
        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(_oldBeneficiary, _newBeneficiary);
    }
}
