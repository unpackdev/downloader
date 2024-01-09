// SPDX-License-Identifier: Apache-2.0

/// @dev WE_ARE_KLOUD
///      KLOUD is the artistical embodiment of limitless
///      creativity in anonymity. With this NFT drop, the collector enters the
///      KLOUD, owning a unique visual & musical art piece derived from the
///      generative algorithm that is KLOUD x HOOKER x COMPUTER.
///
///      Genesis SoundMint Drop.

/*******************************************************************************
 *                                     ::::cllllccc:                           *
 *                                 .:lollc:::;;;:ccc::                         *
 *                              cc;......'          ',:::                      *
 *                            :cl:.....               .,:::                    *
 *                           :;... ....                 .;:                    *
 *                         cl:.........                  .;:                   *
 *                        coc'.........                  .,:                   *
 *                       :c:,''........                   .;:                  *
 *                      ::;,...........                   .';                  *
 *                      ::,.............                   ';                  *
 *                      ::,'............                   ';                  *
 *                       :;'',,'........                   ':                  *
 *                      ::;;::,.........                   .;                  *
 *                      ::::;'.''........                  .;                  *
 *                         :;,,::,.......                  .;                  *
 *                          :::od:''''''..                 .:                  *
 *                           :cclc;''......                .;                  *
 *                               xdc,......................':                  *
 *                    :cc:;:oO0 NKNXkc..........'',;::;;;;;::                  *
 *                 :ccc:,',cc:coxOKNNO:.......'',;:                            *
 *                 col;'....',,;lodk0KKx;......'',                             *
 *               ;cl:'.......',:coxkOOOxl:;'..';;;:lc:;                        *
 *               ;::;'........,;;:lxkdccodddolldxdc:::                         *
 *              ;;,,;,....   ..,,;codoc;,;cxKK0OO0kl;cc:;;                     *
 *             ;;,'';,...........,cll:cc,'',lkO0000kdooc;;;                    *
 *             ,,,'';,...'.......':ll:cc,...';oOOOO00kddo:;,                   *
 *              ,,'';,..........',;cl:::,''''';oxkkkO0Okxxc;,                  *
 *             ,,,'',,.......',;:loddc,,'.',;;:ldxxkkO0Okkko;,                 *
 *              '''',,.......'':lodxdc,'....';:clodxkOO0OxkOl,'                *
 *              '''''.......','.;loddc,''....',;clodxkkO0OxOkc'                *
 *              '.............,,':oxko;,'''.....';codxkkOOxx0x;                *
 *                .............,;;cdko;;,,''......,cldxkOOkxO0l                *
 *               ...'....''....':clxo;;,,,''......,codxkOkdk0d                 *
 *               ....'....';,....,codo;,,,,'''.....':odxkOOxxO                 *
 *               ......'........',,;lxl;;;,,'''....',:lodxkkxx                 *
 *               ......'.........';;;ol::;;,;cc;;cooc;;codkOk                  *
 *               ...............'';col;;,'',;lodkkdlc:;lxddkx:                 *
 *              .......'........;:cldo:,,,,'.'cx0Okdoc:ldc:xx;                 *
 *******************************************************************************/

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
    uint256 public maxBlockPurchase;   // Max that may be purchased per block by one address.
    uint256 public maxWalletPurchase;  // Total max that may be purchased by one address.
    bool public saleIsActive;          // Sale live toggle.
    bool public signedMintIsActive;    // Whitelist/presale signed mint live toggle.

    mapping (address => uint256) lastBlock;    // Track per minter which block they last minted.
    mapping (address => uint256) totalMinted;  // Track per minter total they minted.
    mapping (bytes32 => bool) public nonces;   // Track consumed non-sequential nonces.


    /* --------------------------------- Events --------------------------------- */

    event LogPriceUpdated(uint256 newPrice);
    event LogMint(address indexed sender, uint256 indexed price, uint256 numberMinted, uint256 totalMinted);

    /* -------------------------------- Modifiers ------------------------------- */

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
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
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
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

    function setMaxBlockPurchase(uint256 newMax) public onlyAdmin {
        maxBlockPurchase = newMax;
    }

    function setMintSigner(address signer) public onlyAdmin {
        mintSigner = signer;
    }

    function reserveTokens(uint256 num) public onlyAdmin {
        for (uint256 i = 0; i < num; i++) {
            IBaseToken(tokenContract).mint(_msgSender());
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


    /* ----------------------------- Whitelist Mint ----------------------------- */

    function signedMint(
        uint256 numberOfTokens,
        uint256 maxPermitted,
        bytes memory signature,
        bytes32 nonce
    ) 
        public
        payable
    {

        require(signedMintIsActive, "Minter: signedMint is not active");
        require(numberOfTokens <= maxPermitted, "Minter: numberOfTokens exceeds maxPermitted");

        bool signatureIsValid = SignatureChecker.isValidSignatureNow(
            mintSigner,
            hashTransaction(msg.sender, maxPermitted, nonce),
            signature
        );
        require(signatureIsValid, "Minter: invalid signature");
        require(!nonces[nonce], "Minter: nonce already used");

        nonces[nonce] = true;

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
        uint256 numberOfTokens,
        bytes32 nonce
    )
        public
        view
        returns(bytes32)
    {
        return ECDSA.toEthSignedMessageHash(
            keccak256(abi.encode(address(this), sender, numberOfTokens, nonce))
        );
    }


    /* ------------------------------ Internal ----------------------------- */

    function maxPurchaseBehavior(uint256 numberOfTokens, uint256 maxPerBlock, uint256 maxPerWallet) internal {
        // Reentrancy check.
        require(lastBlock[msg.sender] != block.number, "Minter: Sender already minted this block");
        lastBlock[msg.sender] = block.number;

        if(maxPerBlock != 0) {
            require(numberOfTokens <= maxPerBlock, "Minter: maxBlockPurchase exceeded");
        }

        if(maxPerWallet != 0) {
            totalMinted[msg.sender] += numberOfTokens;
            require(totalMinted[msg.sender] <= maxPerWallet, "Minter: Sender reached mint max");
        }
    }

    function sharedMintBehavior(uint256 numberOfTokens)
        internal
    {

        require(numberOfTokens > 0, "Minter: numberOfTokens is 0");
        require(price != 0, "Minter: price not set");
        
        uint256 expectedValue = price * numberOfTokens;
        require(expectedValue <= msg.value, "Minter: Sent ether value is incorrect");

        // Save gas by failing early.
        uint256 currentTotal = IBaseToken(tokenContract).totalMinted();
        require(currentTotal + numberOfTokens <= IBaseToken(tokenContract).maxSupply(), "Minter: Purchase would exceed max supply");

        // Reentrancy check DO NOT MOVE.
        maxPurchaseBehavior(numberOfTokens, maxBlockPurchase, maxWalletPurchase);

        for (uint i = 0; i < numberOfTokens; i++) {
            IBaseToken(tokenContract).mint(msg.sender);
        }

        emit LogMint(msg.sender, price, numberOfTokens, IBaseToken(tokenContract).totalMinted());

        // Return the change.
        if(expectedValue < msg.value) {
            payable(_msgSender()).call{value: msg.value-expectedValue}("");
        }
    }

}