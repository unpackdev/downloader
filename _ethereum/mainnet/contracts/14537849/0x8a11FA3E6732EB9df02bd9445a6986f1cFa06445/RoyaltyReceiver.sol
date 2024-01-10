// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721.sol";
import "./OwnableUpgradeable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./UUPSUpgradeable.sol";
import "./ECDSA.sol";

import "./console.sol";
import "./DerivedERC2981Royalty.sol";

contract RoyaltyReceiver is OwnableUpgradeable, UUPSUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    using ECDSA for bytes32;

    // TODO uncomment those original addresses
    address constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address constant MAYC = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;

    address BAYC_override;
    address MAYC_override;
    
    // local node addresses, comment it for production
    // address constant BAYC = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
    // address constant MAYC = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;

    struct Pay {
        uint256 id;
        uint256 timestamp;
    }

    struct ERC20Payment {
        bytes32 TX;
        uint amount;
        address erc20;
        // we use code to save storage slot and save GAS
        // 1 = BAYC, 2 = MAYC 
        uint8 erc721code;
        uint tokenId;

    }

    struct ETHPayment {
        bytes32 TX;
        uint amount;
        // we use code to save storage slot and save GAS
        // 1 = BAYC, 2 = MAYC 
        uint8 erc721code;
        uint tokenId;
    }

    struct ERC20toPay {
        address erc20;
        uint stlAmount;
        uint niftyAmount;
        uint userAmount;
    }

    struct ETHtoPay {
        uint amount;
        uint stlAmount;
        uint niftyAmount;
        uint userAmount;
    }

    // TX or some unique bytes32 -> amount
    mapping(bytes32 => uint256) private _ETHPaid;

    mapping(bytes32 => ETHtoPay) private _ETHpayments;
    // list of paid and unpaid royaties
    mapping(bytes32 => ERC20toPay) private _erc20payments;

    address private _tokenDetector;
    
    address public nifty;
    address public smartTokensLabs;
    
    uint256 public niftyPercentage;
    uint256 public smartTokensLabsPercentage;
   
    event RoyaltyPaid(bytes32 indexed tx, address indexed receiver, uint256 sum);
    event RoyaltyPaidERC20(bytes32 indexed tx, address indexed erc20, address indexed receiver, uint256 sum);

    event TokenDetectorSet(
        address indexed previousAddress, 
        address indexed newAddress
        );

    event ReceiversDataSet(
        address indexed niftyAddr, 
        uint256 niftyPercent, 
        address indexed stlAddr, 
        uint256 stlPercent
    );

    function initialize(address tokenDetector_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _tokenDetector = tokenDetector_;
    }

    // use for tests
    function setBaycMayc(address bayc_, address mayc_) external {
        BAYC_override = bayc_;
        MAYC_override = mayc_;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getContractAddress(uint8 i) internal view returns (address) {
        if (i == 1) {
            if (BAYC_override != address(0)){
                return BAYC_override;
            } 
            return BAYC;
        } else if (i == 2) {
            if (MAYC_override != address(0)){
                return MAYC_override;
            } 

            return MAYC;
        } else {
            revert("Unknown Contract ID");
        }
    }

    /*
    returns object in format
    {
        stlAmount: BigNumber { value: "240" },
        niftyAmount: BigNumber { value: "540" },
        userAmount: BigNumber { value: "0" },
        erc20: '0xb79A899dfB642bd3Ea01B5cBF6872bE03D05DFee'
    }
    */
    function getERC20txData(bytes32 _tx) view external returns (ERC20toPay memory) {
        require(_erc20payments[_tx].erc20 != address(0), "TX not exists");
        return _erc20payments[_tx];
    }

    function getETHtxData(bytes32 _tx) view external returns (ETHtoPay memory) {
        require(_ETHpayments[_tx].amount != 0, "TX not exists");
        return _ETHpayments[_tx];
    }

    // internal function. dont waste gas and dont save current user amount . just save rest of users amounts
    function saveTxDataAndGetRequestorAmount(ERC20Payment memory txData) internal returns (uint currentUserSum) {

        (uint256 STLPart, uint256 niftyPart, uint256 UserPart) = getRoyaltyValues(txData.amount);

        // if TX already exists then return amount to withdraw and clear saved amount for current user in the _erc20payments list
        ERC20toPay memory savedTxData = _erc20payments[txData.TX];
        
        if ( savedTxData.erc20 != address(0) ) {

            require(savedTxData.erc20 == txData.erc20, "Wrong ERC20 for TX");

            if (_msgSender() == nifty && niftyPart == savedTxData.niftyAmount) {
                currentUserSum = savedTxData.niftyAmount;
                _erc20payments[txData.TX].niftyAmount = 0;
            } else if (_msgSender() == smartTokensLabs && STLPart == savedTxData.stlAmount ) {
                currentUserSum = savedTxData.stlAmount;
                _erc20payments[txData.TX].stlAmount = 0;
            } else {
                currentUserSum = savedTxData.userAmount;
                _erc20payments[txData.TX].userAmount = 0;
            }
            return currentUserSum;
        }

        // if its a new TX then save TX data except of the msg.sender amount, because we will pay it immediately
        if (_msgSender() == nifty) {
            currentUserSum = niftyPart;
            niftyPart = 0;
        } else if (_msgSender() == smartTokensLabs) {
            currentUserSum = STLPart;
            STLPart = 0;
        } else {
            currentUserSum = UserPart;
            UserPart = 0;
        }

        _erc20payments[txData.TX] = ERC20toPay(txData.erc20, STLPart, niftyPart, UserPart);

    }


    function saveTxDataAndGetRequestorAmountETH(ETHPayment memory txData) internal returns (uint currentUserSum) {

        (uint256 STLPart, uint256 niftyPart, uint256 UserPart) = getRoyaltyValues(txData.amount);

        // if TX already exists then return amount to withdraw and clear saved amount for current user in the _ETHpayments list
        ETHtoPay memory savedTxData = _ETHpayments[txData.TX];
        if ( savedTxData.amount > 0 ) {

            require(savedTxData.amount == txData.amount, "Wrong Amount for TX");

            if (_msgSender() == nifty && niftyPart == savedTxData.niftyAmount) {
                currentUserSum = savedTxData.niftyAmount;
                _ETHpayments[txData.TX].niftyAmount = 0;
            } else if (_msgSender() == smartTokensLabs && STLPart == savedTxData.stlAmount ) {
                currentUserSum = savedTxData.stlAmount;
                _ETHpayments[txData.TX].stlAmount = 0;
            } else {
                currentUserSum = savedTxData.userAmount;
                _ETHpayments[txData.TX].userAmount = 0;
            }
            return currentUserSum;
        }

        // if its a new TX then save TX data except of the msg.sender amount, because we will pay it immediately
        if (_msgSender() == nifty) {
            currentUserSum = niftyPart;
            niftyPart = 0;
        } else if (_msgSender() == smartTokensLabs) {
            currentUserSum = STLPart;
            STLPart = 0;
        } else {
            currentUserSum = UserPart;
            UserPart = 0;
        }

        _ETHpayments[txData.TX] = ETHtoPay(txData.amount, STLPart, niftyPart, UserPart);

    }

    // validate signature and parse input data
    function convertValidateERC20Input(bytes calldata payload, bytes memory signature) internal view returns (
        // address receiver, 
        ERC20Payment[] memory _erc20paymetsData) {
        validateSignature(payload, signature);
        _erc20paymetsData = abi.decode(payload, (ERC20Payment[]));
        
    }

    // validate signature and parse input data
    function convertValidateETHInput(bytes calldata payload, bytes memory signature) internal view returns (ETHPayment[] memory _ETHpaymetsData) {

        validateSignature(payload, signature);
        _ETHpaymetsData = abi.decode(payload, (ETHPayment[]));

    }


    // it should be nifty / stl / NFT owner
    function validateOwner(uint8 erc721code, uint tokenId) view internal {

        if ((_msgSender() != nifty) && (_msgSender() != smartTokensLabs)) {

            ERC721 erc721c = ERC721(getContractAddress(erc721code));
    
            address owner = erc721c.ownerOf(tokenId);

            require(_msgSender() == owner, "Requestor not allowed");

        }
        
    }

    function getPonter(address c, uint256 tokenId) internal pure returns (uint256) {
        require(tokenId < (1 << 96), "Too big tokenId");
        return (uint256(uint160(c)) << (256-20*8)) + tokenId ;
    }

    /**
    withdraw multiple ERC20 payments with single TX. payload should signed by SERVICE 
    and user/nifty/stl can run transaction. It will send funds to the requestor and save 
    other parties data to the storage.

    In the input should be full royalty values. to save GAS send data, sorted by ERC20 contract 
    TXes will be saved to avoid double spending
     */
    function withdrawERC20(bytes calldata payload, bytes memory signature) public {

        // (address receiver, ERC20Payment[] memory _erc20paymetsData) = convertValidateERC20Input( payload, signature);
        (ERC20Payment[] memory _erc20paymetsData) = convertValidateERC20Input( payload, signature);

        uint _collectedAmount;
        uint currentAmount;

        for (uint i = 0; i < _erc20paymetsData.length; i++ ){
            // if next erc20 payment related to the same ERC20 contract then collect amounts, related to the current requestor 

            currentAmount = saveTxDataAndGetRequestorAmount(_erc20paymetsData[i]);
            require(currentAmount > 0, "TX already paid");
            _collectedAmount += currentAmount;

            validateOwner(_erc20paymetsData[i].erc721code, _erc20paymetsData[i].tokenId);

            emit RoyaltyPaidERC20(_erc20paymetsData[i].TX, _erc20paymetsData[i].erc20,  _msgSender(),  currentAmount);

            if ((_erc20paymetsData.length == i + 1) || (_erc20paymetsData[i].erc20 != _erc20paymetsData[i + 1].erc20)) {
                
                payERC20(_erc20paymetsData[i], _collectedAmount);
                _collectedAmount = 0;
            }
        }
     
    }

    function withdrawETH(bytes calldata payload, bytes memory signature) public {

        (ETHPayment[] memory _ETHpaymetsData) = convertValidateETHInput( payload, signature);

        uint _collectedAmount;
        uint currentAmount;

        for (uint i = 0; i < _ETHpaymetsData.length; i++ ){
            // if next erc20 payment related to the same ERC20 contract then collect amounts, related to the current requestor 

            currentAmount = saveTxDataAndGetRequestorAmountETH(_ETHpaymetsData[i]);
            require(currentAmount > 0, "TX already paid");
            _collectedAmount += currentAmount;

            validateOwner(_ETHpaymetsData[i].erc721code, _ETHpaymetsData[i].tokenId);

            emit RoyaltyPaid(_ETHpaymetsData[i].TX, _msgSender(),  currentAmount);

        }

        _pay(_collectedAmount, _msgSender());
     
    }

    /*
    Its just a combine of ERC20 withdraw and ETH withdraw
    */
    function combinedWithdrawUserRoyalty(bytes calldata erc20payload, bytes memory erc20signature, bytes calldata payload, bytes memory signature) external {
        withdrawERC20(erc20payload, erc20signature);
        withdrawETH(payload, signature);
    }

    function payERC20(ERC20Payment memory txData, uint amount) internal {
        
        IERC20Upgradeable erc20c = IERC20Upgradeable(txData.erc20);

        // validation disabled to save 3k gas

        // get this contract balabce to avoid overflow
        // uint balance = erc20c.balanceOf(address(this));
        // throw error if it requests more that in the contract balance
        // require(balance >= amount, "Dont have enough funds");
        require(amount > 0, "Nothing to pay here");

        erc20c.safeTransfer(_msgSender(), amount);

    }

    function getRoyaltyValues(uint amount) internal view returns (uint stl, uint nifty, uint user) {
        nifty = amount * niftyPercentage / 10000;
        stl = amount * smartTokensLabsPercentage / 10000;
        user = amount - stl - nifty;
    }

    receive() external payable {
    }

    function _pay(uint256 amount, address receiver) internal {
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function validateSignature(bytes calldata payload, bytes memory signature) internal view {
        address signerAddress = keccak256(payload).toEthSignedMessageHash().recover(signature);
               
        require(signerAddress == _tokenDetector, "Payload must be signed");
    }

    function setTokenDetector(address addr) external onlyOwner {
        _setTokenDetector(addr);
    }

    function _setTokenDetector(address addr) internal {
        emit TokenDetectorSet(_tokenDetector, addr);
        _tokenDetector = addr;

    }

    function setReceiversData(address niftyAddr, uint256 niftyPercent, address stlAddr, uint256 stlPercent) external onlyOwner {

        require((niftyPercent + stlPercent) < 10000, "Too big commission.");
        nifty = niftyAddr;
        smartTokensLabs = stlAddr;
    
        niftyPercentage = niftyPercent;
        smartTokensLabsPercentage = stlPercent;

        emit ReceiversDataSet(niftyAddr, niftyPercent, stlAddr, stlPercent);

    }

}