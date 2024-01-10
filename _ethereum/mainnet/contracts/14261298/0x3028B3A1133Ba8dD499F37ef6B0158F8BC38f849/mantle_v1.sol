pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

//Mantle Finance - https://mantlefi.com/
//
//                      ooO
//                     ooOOOo
//                   oOOOOOOoooo
//                 ooOOOooo  oooo
//                /vvv V\
//               /V V   V\ 
//              /V  V    V\          
//             /           \          ALL HAIL LIQUIDITY!!!!!
//            /             \               /
//           /               \   	 o          o
//          /                 \     /-   o     /-
//  /\     /                   \   /\  -/-    /\
//                                     /\

import "./ERC721.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

//Mantle Finance - NFT Collateralized P2P Lending Contract, Part of the logic refers to the contract of https://opensea.io/, https://nftfi.com/, https://looksrare.org/
contract MantleFinanceV1 is Ownable, ERC721, ReentrancyGuard, Pausable {
    using Strings for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    // NOTE: these hashes are derived and verified in the constructor.
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant _EIP_712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256("MantleFinanceV1")
    bytes32 private constant _NAME_HASH = 0xaba6aa90b1d7c4077fcd4112d89757c977ec45dd567696446208806c35fa3fe3;
    // keccak256(bytes("1"))
    bytes32 private constant _VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    bytes32 private constant _BORROWER_TYPEHASH = 0x107182850da2230853efed1dfd0ea3fd85b39a3b9b0a5381ea9fd5dba147aac0;
    bytes32 private constant _LENDER_TYPEHASH = 0x1f0d56b2c9f2a40bbf20b01d1b8dcfe864e4dba64eb65c598bb0de477236473a;


    //This contract complies with the ERC-721 standard, and Lender will get a Promissory Note NFT on each Loan begin. 
    //This NFT is also destroyed during repayment and claimed.
    //Note that transferring this PN means that you no longer have the rights to claim and get repayment.
    constructor() ERC721("Mantle Fianace Promissory Note", "Mantle PN") {
        require(keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)") == _EIP_712_DOMAIN_TYPEHASH, "_EIP_712_DOMAIN_TYPEHASH error");
        require(keccak256(bytes("MantleFinanceV1")) == _NAME_HASH, "_NAME_HASH error");
        require(keccak256(bytes("1")) == _VERSION_HASH, "_VERSION_HASH error");
        require(keccak256("BorrowerOrder(uint256 nftCollateralId,uint256 borrowerNonce,address nftCollateralContract,address borrower,uint256 expireTime,uint256 chainId)") == _BORROWER_TYPEHASH, "_BORROWER_TYPEHASH error");
        require(keccak256("LenderOrder(uint256 loanPrincipalAmount,uint256 repaymentAmount,uint256 nftCollateralId,uint256 loanDuration,uint256 adminFee,uint256 lenderNonce,address nftCollateralContract,address loanERC20,address lender,uint256 expireTime,uint256 chainId)") == _LENDER_TYPEHASH, "_LENDER_TYPEHASH error");
    }

    //Whitelist of NFT projects and ERC-20 
    mapping (address => bool) public whitelistForAllowedERC20;
    mapping (address => bool) public whitelistForAllowedNFT;

    //The current total loan and the ongoing loans in the protocol
    uint256 public totalNumLoans = 0;
    uint256 public totalActiveLoans = 0;

    //This is where the loans are actually stored in the protocol.
    //Note that we separate whether the claimed or repayment have been done. 
    //The content of loanIdToLoan will be deleted during repayment and claimed.
    mapping (uint256 => Loan) public loanIdToLoan;
    mapping (uint256 => bool) public loanRepaidOrClaimed;

    //Royalty Fee Manager, refers to the structure of https://looksrare.org/
    IRoyaltyFeeManager public royaltyFeeManager;

    //The fees charged from the protocol, note: the fees are charged to Lender at the time of repayment. (25 = 0.25%, 100 = 1%)
    uint256 public adminFee = 500;

    //The protocol uses its own Nonce to maintain security, avoid duplication of signatures and reduce gas costs
    mapping (address => mapping (uint256 => bool)) private _nonceOfSigning;

    //Other parameters
    uint256 public maximumLoanDuration = 53 weeks;
    uint256 public maximumNumberOfActiveLoans = 100;

    string private _baseURIExtended;

    struct Loan {
        uint256 loanId;
        uint256 loanPrincipalAmount;
        uint256 repaymentAmount;
        uint256 nftCollateralId;
        uint64 loanStartTime;
        uint32 loanDuration;
        uint32 loanAdminFee;
        address[2] nftCollateralContractAndloanERC20;
        address borrower;
    }

    struct BorrowerOrder {
        uint256 nftCollateralId;
        uint256 borrowerNonce;
        address nftCollateralContract;
        address borrower;
        uint256 expireTime;
        uint256 chainId;
    }

    struct LenderOrder {
        uint256 loanPrincipalAmount;
        uint256 repaymentAmount;
        uint256 nftCollateralId;
        uint256 loanDuration;
        uint256 adminFee;
        uint256 lenderNonce;
        address nftCollateralContract;
        address loanERC20;
        address lender;
        uint256 expireTime;
        uint256 chainId;
    }


    //Events

    event LoanStarted(
        uint256 loanId,
        address borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 maximumRepaymentAmount,
        uint256 nftCollateralId,
        uint256 loanStartTime,
        uint256 loanDuration,
        address nftCollateralContract,
        address loanERC20Denomination
    );

    event LoanRepaid(
        uint256 loanId,
        address borrower,
        address lender,
        uint256[2] loanPrincipalAmountAndRepaymentAmount,
        uint256 nftCollateralId,
        uint256[3] amountPaidToLenderAndAdminFeeAndRoyaltyFee,
        address[2] nftCollateralContractAndloanERC20Denomination
    );

    event LoanClaimed(
        uint256 loanId,
        address borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 nftCollateralId,
        uint256 loanMaturityDate,
        uint256 loanClaimedDate,
        address nftCollateralContract
    );

    event AdminFeeUpdated(
        uint256 newAdminFee
    );

    event NonceUsed(
        address user,
        uint nonce
    );

    event NewRoyaltyFeeManager(
        address indexed royaltyFeeManager
    );

    event RoyaltyPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    //Main function
   
    function beginLoan(
        uint256 _loanPrincipalAmount,
        uint256 _repaymentAmount,
        uint256 _nftCollateralId,
        uint256 _loanDuration,
        uint256 _adminFee,
        uint256[2] memory _borrowerAndLenderNonces,
        address[2] memory _contract,
        address _lender,
        uint256[2] memory _ExpireTime,
        bytes memory _borrowerSignature,
        bytes memory _lenderSignature
    ) public whenNotPaused nonReentrant {

        //Whitelist check
        require(whitelistForAllowedNFT[_contract[0]], 'This NFT project is currently not on the ERC-721 whitelist'); 
        require(whitelistForAllowedERC20[_contract[1]], 'This ERC-20 token is currently not on the ERC-20 whitelist');

        //Lending logic check
        require(maximumLoanDuration >= _loanDuration, 'The loan period must shorter than the protocol limit');
        require(_repaymentAmount >= _loanPrincipalAmount, 'Protocol does not accept negative interest rate loan cases');
        require(_loanDuration >= 0, 'Loan duration needs to be set');
        require(_adminFee == adminFee, 'The admin fee in signature is different from the preset, and lender needs to sign again');

        //Nonce check
        require(_nonceOfSigning[msg.sender][_borrowerAndLenderNonces[0]] == false, 'Borrowers Nonce has been used. The order has been established, or Borrower has cancelled the Offer');
        require(_nonceOfSigning[_lender][_borrowerAndLenderNonces[1]] == false, 'Lenders Nonce has been used. The order has been established, or Lender has cancelled the listing');

        //Set borrower and Lender's Nonce to use state
        _nonceOfSigning[msg.sender][_borrowerAndLenderNonces[0]] = true;
        _nonceOfSigning[_lender][_borrowerAndLenderNonces[1]] = true;

        Loan memory loan = Loan({
            loanId: totalNumLoans, //currentLoanId,
            loanPrincipalAmount: _loanPrincipalAmount,
            repaymentAmount: _repaymentAmount,
            nftCollateralId: _nftCollateralId,
            loanStartTime: uint64(block.timestamp), //_loanStartTime
            loanDuration: uint32(_loanDuration),
            loanAdminFee: uint32(_adminFee),
            nftCollateralContractAndloanERC20: _contract,
            borrower: msg.sender //borrower
        });

        //Check Borrower's signature, double-check if borrower wants to lend this NFT, and check if the signature has expired
        require(isValidBorrowerSignature(
            loan.nftCollateralId,
            _borrowerAndLenderNonces[0],//_borrowerNonce,
            loan.nftCollateralContractAndloanERC20[0],
            msg.sender,      //borrower,
            _ExpireTime[0],
            _borrowerSignature
        ), 'Borrower signature is invalid');

        //Check Lender's signature, confirm again whether lender has Offer this NFT, and confirm whether the signature has expired
        require(isValidLenderSignature(
            loan.loanPrincipalAmount,
            loan.repaymentAmount,
            loan.nftCollateralId,
            loan.loanDuration,
            loan.loanAdminFee,
            _borrowerAndLenderNonces[1],//_lenderNonce,
            loan.nftCollateralContractAndloanERC20,
            _lender,
            _ExpireTime[1],
            _lenderSignature
        ), 'Lender signature is invalid');

        //Put Loan into the mapping
        loanIdToLoan[totalNumLoans] = loan;
        totalNumLoans = totalNumLoans.add(1);
        totalActiveLoans = totalActiveLoans.add(1);
        require(totalActiveLoans <= maximumNumberOfActiveLoans, 'Contract has reached the maximum number of active loans allowed by admins');

        //Transfer fund and collateralized NFT to the protocol
        IERC721(loan.nftCollateralContractAndloanERC20[0]).transferFrom(msg.sender, address(this), loan.nftCollateralId);
        IERC20(loan.nftCollateralContractAndloanERC20[1]).transferFrom(_lender, msg.sender, loan.loanPrincipalAmount);

        //Mint Mantle Fianance 的 Promissory Note
        //Lenders have to be aware that the system will perform claimed and repayment according to the owner of this note
        _mint(_lender, loan.loanId);
        
        emit LoanStarted(
            loan.loanId,
            msg.sender,      //borrower,
            _lender,
            loan.loanPrincipalAmount,
            loan.repaymentAmount,
            loan.nftCollateralId,
            block.timestamp,             //_loanStartTime
            loan.loanDuration,
            loan.nftCollateralContractAndloanERC20[0],
            loan.nftCollateralContractAndloanERC20[1]
        );

        emit NonceUsed(
            msg.sender,
            _borrowerAndLenderNonces[0]
        );

        emit NonceUsed(
            _lender,
            _borrowerAndLenderNonces[1]
        );
    }

    function payBackLoan(uint256 _loanId) external nonReentrant {
        //Check if the loan has been repaid, or claimed
        require(loanRepaidOrClaimed[_loanId] == false, 'Loan has already been repaid or claimed');
        loanRepaidOrClaimed[_loanId] = true;

        //Get detail in the loan
        Loan memory loan = loanIdToLoan[_loanId];
        require(msg.sender == loan.borrower, 'Only the borrower can pay back a loan and reclaim the underlying NFT');

        //Take the final lender of this Loan and repay
        address lender = ownerOf(_loanId);
        uint256 interestDue = (loan.repaymentAmount).sub(loan.loanPrincipalAmount);

        uint256 adminFeePay = _computeAdminFee(interestDue, uint256(loan.loanAdminFee));
        
        (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(loan.nftCollateralContractAndloanERC20[0], loan.nftCollateralId, interestDue);

        if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
            IERC20(loan.nftCollateralContractAndloanERC20[1]).transferFrom(loan.borrower, royaltyFeeRecipient, royaltyFeeAmount);

            emit RoyaltyPayment(loan.nftCollateralContractAndloanERC20[0], loan.nftCollateralId, royaltyFeeRecipient, loan.nftCollateralContractAndloanERC20[1], royaltyFeeAmount);
        }
        
        uint256 payoffAmount = ((loan.loanPrincipalAmount).add(interestDue)).sub(adminFeePay).sub(royaltyFeeAmount);

        //Reduce the amount of ongoing loans in the protocol
        totalActiveLoans = totalActiveLoans.sub(1);

        //Transfer fee and return funds
        IERC20(loan.nftCollateralContractAndloanERC20[1]).transferFrom(loan.borrower, lender, payoffAmount);
        IERC20(loan.nftCollateralContractAndloanERC20[1]).transferFrom(loan.borrower, owner(), adminFeePay);

        //Burn Mantle Finance Promissory Note
        _burn(_loanId);

        //Transfer the collateralized NFT to Borrower
        require(_transferNftToAddress(
            loan.nftCollateralContractAndloanERC20[0],
            loan.nftCollateralId,
            loan.borrower
        ), 'NFT was not successfully transferred');

        emit LoanRepaid(
            _loanId,
            loan.borrower,
            lender,
            [loan.loanPrincipalAmount, loan.repaymentAmount],
            loan.nftCollateralId,
            [payoffAmount, adminFee, royaltyFeeAmount],
            [loan.nftCollateralContractAndloanERC20[0], loan.nftCollateralContractAndloanERC20[1]]
        );

        delete loanIdToLoan[_loanId];
    }

    function claimOverdueLoan(uint256 _loanId) external nonReentrant {
        //Check if the loan has been repaid, or claimeded
        require(loanRepaidOrClaimed[_loanId] == false, 'Loan has already been repaid or claimed');
        loanRepaidOrClaimed[_loanId] = true;

        //Get detail in the loan and check if it's overdue and can be claimed
        Loan memory loan = loanIdToLoan[_loanId];
        uint256 loanMaturityDate = (uint256(loan.loanStartTime)).add(uint256(loan.loanDuration));
        require(block.timestamp > loanMaturityDate, 'Loan is not overdue yet');

        //Reduce the amount of ongoing loans in the protocol
        totalActiveLoans = totalActiveLoans.sub(1);

        //Take the final lender of this Loan and claim nft
        address lender = ownerOf(_loanId);

        require(_transferNftToAddress(
            loan.nftCollateralContractAndloanERC20[0],
            loan.nftCollateralId,
            lender
        ), 'NFT was not successfully transferred');

        //Burn Mantle Finance Promissory Note
        _burn(_loanId);

        emit LoanClaimed(
            _loanId,
            loan.borrower,
            lender,
            loan.loanPrincipalAmount,
            loan.nftCollateralId,
            loanMaturityDate,
            block.timestamp,
            loan.nftCollateralContractAndloanERC20[0]
        );

         delete loanIdToLoan[_loanId];
    }

    function setNonceUsed(uint256 _nonce) external {
        require(_nonceOfSigning[msg.sender][_nonce] == false, 'This Nonce has been used, the order has been established, or the Offer has been cancelled');
        _nonceOfSigning[msg.sender][_nonce] = true;

        emit NonceUsed(
            msg.sender,
            _nonce
        );
    }

    //Admin

    function setWhitelistERC20(address _erc20, bool _bool) external onlyOwner {
        whitelistForAllowedERC20[_erc20] = _bool;
    }

    function setWhitelistNFTContract(address _erc721, bool _bool) external onlyOwner {
        whitelistForAllowedNFT[_erc721] = _bool;
    }

    function updateMaximumLoanDuration(uint256 _newMaximumLoanDuration) external onlyOwner {
        require(_newMaximumLoanDuration <= uint256(~uint32(0)), 'loan duration cannot exceed space alotted in struct');
        maximumLoanDuration = _newMaximumLoanDuration;
    }

    function updateMaximumNumberOfActiveLoans(uint256 _newMaximumNumberOfActiveLoans) external onlyOwner {
        maximumNumberOfActiveLoans = _newMaximumNumberOfActiveLoans;
    }

    function updateAdminFee(uint256 _newAdminFee) external onlyOwner {
        require(_newAdminFee <= 10000, 'By definition, basis points cannot exceed 10000');
        adminFee = _newAdminFee;
        emit AdminFeeUpdated(_newAdminFee);
    }

    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Owner: Cannot be null address");
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    //View

    function isValidBorrowerSignature(
        uint256 _nftCollateralId,
        uint256 _borrowerNonce,
        address _nftCollateralContract,
        address _borrower,
        uint256 _expireTime,
        bytes memory _borrowerSignature
    ) public view returns(bool) {
        if(_borrower == address(0)){
            return false;
        } else {
            uint256 chainId;
            chainId = getChainID();
            BorrowerOrder memory order = BorrowerOrder({
                nftCollateralId: _nftCollateralId,
                borrowerNonce: _borrowerNonce,
                nftCollateralContract: _nftCollateralContract,
                borrower: _borrower,
                expireTime: _expireTime,
                chainId: chainId
            });

            bytes32 messageWithEthSignPrefix = borrowerHashToSign(order);

            if(block.timestamp < _expireTime){
                return (messageWithEthSignPrefix.recover(_borrowerSignature) == _borrower);
            }else{
                return false;
            }
        }
    }

    function isValidLenderSignature(
        uint256 _loanPrincipalAmount,
        uint256 _repaymentAmount,
        uint256 _nftCollateralId,
        uint256 _loanDuration,
        uint256 _adminFee,
        uint256 _lenderNonce,
        address[2] memory _nftCollateralContractAndloanERC20,
        address _lender,
        uint256 _expireTime,
        bytes memory _lenderSignature
    ) public view returns(bool) {
        if(_lender == address(0)){
            return false;
        } else {
            uint256 chainId;
            chainId = getChainID();
            LenderOrder memory order = LenderOrder({
                loanPrincipalAmount: _loanPrincipalAmount,
                repaymentAmount: _repaymentAmount,
                nftCollateralId: _nftCollateralId,
                loanDuration: _loanDuration,
                adminFee: _adminFee,
                lenderNonce: _lenderNonce,
                nftCollateralContract: _nftCollateralContractAndloanERC20[0],
                loanERC20: _nftCollateralContractAndloanERC20[1],
                lender: _lender,
                expireTime: _expireTime,
                chainId: chainId
            });

            bytes32 messageWithEthSignPrefix = lenderHashToSign(order);
            if(block.timestamp < _expireTime){
                return (messageWithEthSignPrefix.recover(_lenderSignature) == _lender);
            }else{
                return false;
            }
        }
    }

    function getNonceIsUsed(address _user, uint256 _nonce) public view returns (bool) {
        return _nonceOfSigning[_user][_nonce];
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    //Internal

    function _computeAdminFee(uint256 _interestDue, uint256 _adminFee) internal pure returns (uint256) {
    	return (_interestDue.mul(_adminFee)).div(10000);
    }

    function _transferNftToAddress(address _nftContract, uint256 _nftId, address _recipient) internal returns (bool) {
        // Agree that the ERC-721 contract is willing to let this contract transfer
        _nftContract.call(abi.encodeWithSelector(IERC721(_nftContract).approve.selector, address(this), _nftId));

        (bool success, ) = _nftContract.call(abi.encodeWithSelector(IERC721(_nftContract).transferFrom.selector, address(this), _recipient, _nftId));
        return success;
    }

    /**
     * @dev Derive the domain separator for EIP-712 signatures.
     * @return The domain separator.
     */
    function _deriveDomainSeparator() private view returns (bytes32) {
        uint256 chainId;
        chainId = getChainID();
        return keccak256(
            abi.encode(
                _EIP_712_DOMAIN_TYPEHASH, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                _NAME_HASH, // keccak256("MantleFinanceV1")
                _VERSION_HASH, // keccak256(bytes("1"))
                chainId, // NOTE: this is fixed, need to use solidity 0.5+ or make external call to support!
                address(this)
            )
        );
    }
    
    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function borrowerHashToSign(BorrowerOrder memory order)
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19\x01", _deriveDomainSeparator(), keccak256(abi.encode(_BORROWER_TYPEHASH,order))
        ));
    }
    
    function lenderHashToSign(LenderOrder memory order)
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19\x01", _deriveDomainSeparator(), keccak256(abi.encode(_LENDER_TYPEHASH,order))
        ));
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    fallback() external payable {
        revert();
    }
}