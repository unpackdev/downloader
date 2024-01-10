// SPDX-License-Identifier: MIT
// To view Artie’s license agreement, please visit artie.com/general-terms
/*****************************************************************************************************************************************************
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@                &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@        @@        .@@@@@@@@@@@@@@@         @         @@                       @@,        @@@@@@@@@,                  @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@        @@@@         @@@@@@@@@@@@@@                   @@                       @@,        @@@@@@@                        @@@@@@@@@@@@
 @@@@@@@@@@@@@@@        @@@@@@         @@@@@@@@@@@@@                   @@                       @@,        @@@@@          (@@@@@@          @@@@@@@@@@@
 @@@@@@@@@@@@@(        @@@@@@@@         @@@@@@@@@@@@          @@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@@         @@@@@@@@@@@         @@@@@@@@@@
 @@@@@@@@@@@@         @@@@@@@@@@         @@@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@&%         @@@@@@@@@
 @@@@@@@@@@@                              @@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@@                                @@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@                                  @@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@                                    @@@@@@@         @@@@@@@@@@@@@@@@@@          @@@@@@@@@.        @@@@         @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
 @@@@@@@         @@@@@@@@@@@@@@@@@@@@         @@@@@@         @@@@@@@@@@@@@@@@@@                 @@,        @@@@@            @@@@@         @@@@@@@@@@@@
 @@@@@@         @@@@@@@@@@@@@@@@@@@@@@         @@@@@         @@@@@@@@@@@@@@@@@@@                @@,        @@@@@@@                         @@@@@@@@@@@
 @@@@@         @@@@@@@@@@@@@@@@@@@@@@@@         @@@@         @@@@@@@@@@@@@@@@@@@@               @@,        @@@@@@@@@@                   @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     (@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*****************************************************************************************************************************************************/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Artie.sol";
import "./ECDSA.sol";


contract ArtieSeason01 is Ownable {
    using ECDSA for bytes32;

    uint256 public constant PURCHASE_LIMIT = 3;

    address public signingAddress;
    mapping(bytes16 => bool) public usedNonces;

    uint256 public constant MAX_TOKEN = 4478;

    uint256 public constant price = 0.2 ether;

    uint256 public current = 0;

    bool public saleStarted;

    Artie public immutable artie;

    address payable public withdrawalAddress;

    event Season01Mint(
        address to,
        uint256 amount,
        uint256 current
    );

    constructor(address payable artieCharAddress, address payable withdrawAddress, address signer) {
        artie = Artie(artieCharAddress);
        withdrawalAddress = withdrawAddress;
        signingAddress = signer;
    }

    modifier saleIsOpen() {
        require(saleStarted, "SALE_NOT_STARTED");
        _;
    }

    modifier onlyWallets() {
        require(tx.origin == msg.sender, "NO_CONTRACTS_ALLOWED");
        _;
    }

    function hashRequest(bytes16 nonce, address to, uint256 numRequested, uint256 transactionNumber) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(nonce, to, numRequested, transactionNumber));
    }

    function _verify(bytes32 hash, bytes memory signature, address validator) private pure returns (bool) {
        return hash.recover(signature) == validator;
    }

    function mint(bytes16 nonce, uint256 numberOfTokens, uint256 transactionNumber, bytes memory signature) external payable saleIsOpen onlyWallets{
        require(_verify(hashRequest(nonce, msg.sender, numberOfTokens, transactionNumber).toEthSignedMessageHash(), signature, signingAddress), "NO DIRECT MINTING ALLOWED");
        require(!usedNonces[nonce], "NONCE USED");

        require(price * numberOfTokens == msg.value, "INCORRECT_ETH_AMOUNT");
        require(current + numberOfTokens <= MAX_TOKEN, "MAX_TOKENS_EXCEEDED");
        require(numberOfTokens <= PURCHASE_LIMIT, "PURCHASE_LIMIT_EXCEEDED");

        usedNonces[nonce] = true;
        uint256 tokenId = current;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenId++;
            artie.safeMint(msg.sender, tokenId);
        }
        current = tokenId;
        emit Season01Mint(msg.sender, numberOfTokens, current);
    }

    // ----- Sale functions --------
    

    function startSale() external onlyOwner {
        saleStarted = true;
    }

    function stopSale() external onlyOwner {
        saleStarted = false;
    }


    // ------ Withdrawal functions ------------------ 

    function setWithdrawalAddress(address payable givenWithdrawalAddress) external onlyOwner {
        withdrawalAddress = givenWithdrawalAddress;
    }

    function withdrawEth() external onlyOwner {
        require(withdrawalAddress != address(0), 'WITHDRAWAL_ADDRESS_ZERO');
        Address.sendValue(withdrawalAddress, address(this).balance);
    }


    // ------ Signer Address Modifier --------------

    function setSignerAddress(address signer) external onlyOwner {
        signingAddress = signer;
    }

}