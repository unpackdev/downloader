// SPDX-License-Identifier: Apache-2.0

/// @dev ToonSquad

/*******************************************************************************
.                                            ////                              .
.                                          //////@                             .
.                                  ////   /////////                            .
.                           //&    @/////@////////////                         .
.                            @////@@//////////////////// @                     .
.                    /  .////@/////////////////////////// //@                  .
.                    ///@ ////////////////////////////////////                 .
.                    @/////////////////////////////////////////                .
.                      ////////////////////////////////////////                .
.                    @  ///////////////////////////////////////                .
.                      .///////@//////////////////////////////                 .
.                       ///////////@@//////////////////////(                   .
.                       %/////////@                       ,@                   .
.                       .////////@     ********       *****,                   .
.                        /////////        ,..,        ,.., ,                   .
.                         ////////     ,,,    ,,.   ,,     ,,                  .
.                         @//////@    ,,    O   ,, ,,   O   ,,                 .
.                        ,,    &@     ,,        ,, ,,       ,,                 .
.                       , ,,,#         ,,,    ,,,   ,,,    ,,                  .
.                        , ,@,,           ''''         ** ,                    .
.                         ,  ,,                      **   ,                    .
.                           ,%%.                         ,                     .
.                           ///,                        ,                      .
.                           ///#,            (-__     _)                       .
.                           @////,               ¨^^^¨                         .
.                          /&#/@,                  ,'                          .
.                           %@  ,              .,,,                            .
.                               ,               ,                              .
.                              ,               ,                               .
.                            @                 ,                               .
.                         ,, //@                 /.                            .
.                       ,     (//                 /@,                          .
.                     ,        @//                 /@ ,                        .
.                   ,           //@                @/  ,                       .
.                  ,            @//          .     ,/&  ,                      .
.                 ,,             //@    @@     @   %//   ,                     .
.                 ,         /   @/////////////////////   ,                     .
.                 ,         /    //////////////////////   ,                    .
.                ,         /  @///////////////////////    ,                    .
.                ,         ///////////////////////////    ,                    .
.                ,         ///////////////////////////     ,    TOON SQUAD !   .
********************************************************************************/

pragma solidity 0.8.10;


import "./PaymentSplitter.sol";
import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./Provenance.sol";
import "./IBaseToken.sol";


contract Minter is AccessControlEnumerable, Provenance, PaymentSplitter {


    /* --------------------------------- Globals -------------------------------- */

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public tokenContract;      // Token to be minted.
    address public mintSigner;         // Signer who may approve addresses to mint.
    uint256 public price;              // Ether price per token.
    uint256 public maxWalletPurchase;  // Total max that may be purchased by one address.
    bool public saleIsActive;          // Sale live toggle.
    bool public signedMintIsActive;    // Presale signed mint live toggle.

    mapping (address => uint256) public totalMinted;  // Track per minter total they minted.


    /* --------------------------------- Events --------------------------------- */

    event LogPriceUpdated(uint256 newPrice);

    /* -------------------------------- Modifiers ------------------------------- */

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "onlyAdmin: caller is not the admin");
        _;
    }

    /* ------------------------------- Constructor ------------------------------ */

    constructor(
        address _tokenContract,
        address[] memory payees,
        uint256[] memory shares_
    ) PaymentSplitter(payees, shares_) {

        tokenContract = _tokenContract;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }


    /* ------------------------------ Admin Methods ----------------------------- */

    function setPrice(uint256 newPrice) public onlyAdmin {
        price = newPrice;
        emit LogPriceUpdated(newPrice);
    }

    function setProvenance(bytes32 provenanceHash) public onlyAdmin {
        _setProvenance(provenanceHash);
    }

    function setRevealTime(uint256 timestamp) public onlyAdmin {
        _setRevealTime(timestamp);
    }

    function setMaxWalletPurchase(uint256 newMax) public onlyAdmin {
        maxWalletPurchase = newMax;
    }

    function setMintSigner(address signer) public onlyAdmin {
        mintSigner = signer;
    }

    function reserveTokens(uint256 num) public onlyAdmin {
        for (uint256 i = 0; i < num; i++) {
            IBaseToken(tokenContract).mint(msg.sender);
        }
    }

    function flipSignedMintState() public onlyAdmin {
        signedMintIsActive = !signedMintIsActive;
    }

    function flipSaleState() public onlyAdmin {
        saleIsActive = !saleIsActive;
    }

    function sweep(address token, address to, uint256 amount)
        external
        onlyAdmin
        returns (bool)
    {    
        return IERC20(token).transfer(to, amount);
    }


    /* ------------------------------ Public Reveal ----------------------------- */

    function finalizeReveal() public {
        _finalizeStartingIndex(IBaseToken(tokenContract).maxSupply());
    }


    /* ------------------------------- Signed Mint ------------------------------ */

    function signedMint(
        uint256 numberOfTokens,
        uint256 maxPermitted,
        bytes memory signature
    ) 
        public
        payable
    {

        require(signedMintIsActive, "Minter: signedMint is not active");
        require(maxWalletPurchase > 0, "Minter: Max per wallet required for signedMint");
        require(numberOfTokens <= maxPermitted, "Minter: numberOfTokens exceeds maxPermitted");

        bool signatureIsValid = SignatureChecker.isValidSignatureNow(
            mintSigner,
            hashTransaction(msg.sender, maxPermitted),
            signature
        );
        require(signatureIsValid, "Minter: invalid signature");
        require(
            (totalMinted[msg.sender] + numberOfTokens) <= maxPermitted,
            "Minter: combined totalMinted exceeds maxPermitted"
        );

        sharedMintBehavior(numberOfTokens);
    }


    /* ------------------------------- Public Mint ------------------------------ */

    function mint(uint256 numberOfTokens) public payable {

        require(saleIsActive, "Minter: Sale is not active");

        sharedMintBehavior(numberOfTokens);

        _setStartingBlock(
            IBaseToken(tokenContract).totalMinted(),
            IBaseToken(tokenContract).maxSupply()
        );
    }


    /* --------------------------------- Signing -------------------------------- */
    
    function hashTransaction(
        address sender,
        uint256 numberOfTokens
    )
        public
        view
        returns(bytes32)
    {
        return ECDSA.toEthSignedMessageHash(
            keccak256(abi.encode(address(this), sender, numberOfTokens))
        );
    }


    /* ------------------------------ Internal ----------------------------- */

    function sharedMintBehavior(uint256 numberOfTokens)
        internal
    {

        require(numberOfTokens > 0, "Minter: numberOfTokens is 0");
        require(price != 0, "Minter: price not set");

        uint256 expectedValue = price * numberOfTokens;
        require(expectedValue <= msg.value, "Minter: Sent ether value is incorrect");

        // Save gas by failing early.
        uint256 currentTotal = IBaseToken(tokenContract).totalMinted();
        require(
            currentTotal + numberOfTokens <= IBaseToken(tokenContract).maxSupply(),
            "Minter: Purchase would exceed max supply"
        );

        if(maxWalletPurchase != 0) {
            totalMinted[msg.sender] += numberOfTokens;
            require(totalMinted[msg.sender] <= maxWalletPurchase, "Minter: Sender reached mint max");
        }

        for (uint i = 0; i < numberOfTokens; i++) {
            IBaseToken(tokenContract).mint(msg.sender);
        }

        // Return the change.
        if(expectedValue < msg.value) {
            payable(msg.sender).call{value: msg.value-expectedValue}("");
        }
    }

}