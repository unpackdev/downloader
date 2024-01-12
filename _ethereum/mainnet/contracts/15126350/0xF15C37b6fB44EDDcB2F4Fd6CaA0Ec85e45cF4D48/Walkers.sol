// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ECDSA.sol";
import "./ERC721AQueryable.sol";
import "./IWalkers.sol";

/* 
....................................................................................................
....................................................................................................
..........................................................:^~!77777!~^:.............................
.............................................:::::::..:!?5PGGGGGGGGGGPPY?~..........................
.....................................:^^~~!7?JYYYJJ7?5PGGGGGGGGGGGGGGGGGGGY^........................
.................................^~!!!!!~?YYYYJJJY5GGGGGGGGGGGGGGGGGGGGGGGGP^.......................
..............................^~!!!~~~~~JYJJJJJJ5GGGGGGGGGGGGGGGGGGGGGGGGGGGJ.......................
...........................:~!!~~~~~~~~?YJJJJJYPGGGGGGGGGGGGGGGGGGGGGGGGGGGG5.......................
..........................~7!~~~~~~~~~~JYJJJYPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG5.......................
........................:7!~~~~~~~~~~~~!YYJ5GGGGGGGGGGPPGGGGGGP55PGGGGGGGGGG?.......................
.......................:7!~~~~~~~~~~~~~~!5GGGGGGGGGG5YYYY5GGPYYYYYYGGGGGGGGG^.......................
......................:7~~~~~~~~~~~~~!7J5GGGGGGGGGG5YYYYYYPPYYYYYY5PYYYY5GB?........................
......................7!~~~~~~~~~!?JJYPGGGGGGGPGP5YYYYYYY55YYYYYY5PYYYYYYG5.........................
.....................^?~~~~~~~7?YYYYPGGPP555YYYYYYYYYYYYYYYYYYYY55YYYYYYPP:.........................
.....................!!~~~~!?YYYYY5PP5YYYYYYYYYYYYYYYYYYYYYYYYYYYYY55555P:..........................
.....................?~~~!JYYYY555YYYYYYYYY55JJYYYYYYYYYYYYYYYYYYJJ?7?5Y5^..........................
.....................?~!JYYY555YYYYYYYYYY55J!~~~~~~!!!!!!!!!!!!!~~~~~~?55~..........................
.....................?7YYY555YYYY5YYYYYJJ7!~~!77777!!~~~~~~!77!!!!!~~~~Y5:..........................
.....................?5J55YYYYYYY5~~~~~~~~~~~~!!!~~!!~~~~~~!~!!!!~~~~~~7?...........................
.....................!555YYYYYYY5Y~~~~~~~~~!!^:.:^~~!!~~~~~!!^:.:~~~!!~~7...........................
.....................:55YYYYYYYY57~~~~~~~~7~    ~G&B:^7~~~7:    ?B&5.!!~?:..........................
....................::YYY55YYY557~~~~~~~~~7     .!@@~ !!7!~     .J@#. 7~?^..........................
..................^!!!!!!!7J55J!~~~~~~~~~~7:.:^^JGB#!.7~!?7.:^^~5GBG:^7~7~..........................
.................!!~!7!!??!~!7~~~~~~~~~~~~~??!~~~~~~7?!~~~!??!~~~~~!??~~7~..........................
................~7~~~~!?77??~~~~~~~~~~~~~~~~!7!~~~~~!~~~~~~~J?~~~~~~!~~~!!..........................
................!!~~~~!!!!!?!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~?!~~~~~~~~~~~7..........................
................^7~~~~~~~~~~~~~~~~~~~~~~~~~~~!7!~~~~~~~~~~!7!~~~~~~~~~~~~?..........................
.................~7!~~~~~~~~~~~~~~~~~~~~~~~~?7~?Y7~!!~~~!7!~~~~~~~~~~~~~~7..........................
..................:~!!!!!~~~~~~~~~~~~~~~~~~~7^?BBY^:^~~~~!~~!~~~~~~~~~~~!~..........................
.....................::~?~~~~~~~~~~~~~~~~~~~~~7PYYYY?7!!~~^~55~7!~~~~~~~?:..........................
........................~7~~~~~~~~~~~~~~~~~~~~~7JYYYYY5BBBBBBP~?!~~~~~~7~...........................
.........................~7~~~~~~~~~~~~~~~~~~~~~~!?JYYYGBBGPJ~77~~~~~~7!............................
..........................:!!~~~~~~~~~~~~~~~~~~~~~~~~!!777!~~~~~~~~~~7~.............................
............................^!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!:..............................
..............................:^~!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!~:................................
..................................:^~!!!~~~~~~~~~~~~~~~~~~!!!!!~:...................................
.......................................7~~~~~~~~~~!77777J~^^:.......................................
.......................................?!~~~~~~~~~~~!!77J:..........................................
......................................!!^^^~~~~~~~~~~^~^~7..........................................
..............................::^^~~!?J!!!~~~^^^^^~~~~!!!?J!~^^^:...................................
...........................^~!!!!!!7?!!?!~!!!!!!!!!!!!!~~?77?7!!!!~^................................
........................:~!?7!!~~7?!~~~!?7~~~~~~~~~~~~~~~J~~~!77!!7?7^..............................
......................:~7!~~~!!77!~~~~~~~7?~~~~~~~~~~~~~7?~~~~~!7!!~~7!.............................
.....................:7!~~~~~~~~~~~~~~~~~~7?~~~~~~~~~~~~?!~~~~~~~~~~~~7~............................
.....................7!~~~~~77~~~~~~~~~~~~~7?~~!~~~~~~~!J~~~~~~~~~~~~~~?:...........................
.....................?~~~~~7!~7~~~~~~~~~~~~~7?~~~~~~~~~77~~~~~~~~~~~~~~7~...........................
.....................?~~~~7!~~~7~~~~~~~~~~~~~?7~~~~~~~~J!~~~~~~~~~~~~~~!7...........................
*/

/// @title ERC721 Token for Multiversal Walkers
/// @author ItsCuzzo

contract Walkers is IWalkers, Ownable, ERC721AQueryable, PaymentSplitter {
    using ECDSA for bytes32;

    enum SaleStates {
        PAUSED,
        PUBLIC,
        MULTI
    }

    SaleStates public saleState;

    string private _baseTokenURI;
    address private _signer;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant RESERVED_TOKENS = 55;
    uint256 public constant WALLET_LIMIT = 2;

    uint256 public publicPrice = 0.188 ether;
    uint256 public multiPrice = 0.143 ether;

    /// @dev Sets a soft-cap to be used in the `PUBLIC` sale phase.
    /// In the event of a FCFS mint, set this value to `MAX_SUPPLY`.
    uint256 public publicTokens = 2555;

    event Minted(address indexed receiver, uint256 quantity);
    event SetPublicTokens(address indexed account, uint256 amount);
    event SetSaleState(address indexed account, uint256 saleState);
    event SetTokenURI(address indexed account, string tokenURI);
    event SetSigner(address indexed account, address signer);

    constructor(
        address[] memory payees,
        uint256[] memory shares_,
        address receiver
    ) ERC721A("Multiversal Walkers", "MWALK") PaymentSplitter(payees, shares_) {
        ownerMint(receiver, RESERVED_TOKENS);
    }

    /// @notice Function used to mint tokens during the `PUBLIC` sale state.
    /// @param quantity Desired number of tokens to mint.
    /// @param signature A signed message digest.
    /// @dev No explicit check of `quantity` is required as signatures are created ahead of time.
    function publicMint(uint256 quantity, bytes calldata signature) external payable {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != SaleStates.PUBLIC) revert InvalidSaleState();
        if (msg.value != publicPrice * quantity) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) + quantity > WALLET_LIMIT) revert WalletLimitExceeded();
        
        /// @dev The new total supply of tokens inclusive of `quantity`.
        uint256 newSupply = _totalMinted() + quantity;

        if (newSupply > publicTokens) revert PublicSupplyExceeded();
        if (newSupply > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (!_verifySignature(signature, quantity, 'PUBLIC')) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint tokens during the `MULTI` sale state.
    /// @param quantity Desired number of tokens to mint.
    /// @param signature A signed message digest.
    /// @dev This function may only be called ONCE. No explicit check of `quantity` is
    /// required as signatures are created ahead of time.
    function multilistMint(uint256 quantity, bytes calldata signature) external payable {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != SaleStates.MULTI) revert InvalidSaleState();
        if (msg.value != multiPrice * quantity) revert InvalidEtherAmount();
        if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (_getAux(msg.sender) != 0) revert TokenClaimed();
        if (!_verifySignature(signature, quantity, 'MULTI')) revert InvalidSignature();

        /// @dev Set arbitrary value to acknowledge that the user has claimed.
        _setAux(msg.sender, 1);

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint `quantity` of tokens to `receiver`.
    /// @param receiver The receiving address of the newly minted tokens.
    /// @param quantity Desired number of tokens to mint.
    function ownerMint(address receiver, uint256 quantity) public onlyOwner {
        if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        _mint(receiver, quantity);
    }

    /// @notice Function used to get the `TokenOwnership` data for a specified token.
    /// @param tokenId A Multiversal Walkers token ID.
    /// @return Returns a `TokenOwnership` data type as defined in ERC721A.
    function tokenOwnership(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    /// @notice Function used to get the `aux` value for `account`.
    /// @param account Desired `account` to check the `aux` value for.
    /// @return Returns a value of either 1 or 0. 1 indicates the user has claimed a token
    /// in `multilistMint`, 0 if not.
    function getAux(address account) external view returns (uint64) {
        return _getAux(account);
    }

    /// @notice Function used to check how many tokens `account` has minted.
    /// @param account Desired `account` to check the number of minted tokens.
    /// @return Returns the number of tokens `account` has minted.
    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    /// @notice Function used to get the current `_signer` value.
    /// @return Returns the current `_signer` value.
    function signer() external view returns (address) {
        return _signer;
    }

    /// @notice Function used to set a new `publicTokens` value.
    function setPublicTokens(uint256 newPublicTokens) external onlyOwner {
        if (newPublicTokens > MAX_SUPPLY) revert InvalidTokenAmount();

        publicTokens = newPublicTokens;

        emit SetPublicTokens(msg.sender, newPublicTokens);
    }

    /// @notice Function used to set a new `saleState` value.
    /// @param newSaleState Newly desired `saleState` value.
    /// @dev 0 = PAUSED, 1 = PUBLIC, 2 = MULTI.
    function setSaleState(uint256 newSaleState) external onlyOwner {
        if (newSaleState > uint256(SaleStates.MULTI)) revert InvalidSaleState();

        saleState = SaleStates(newSaleState);

        emit SetSaleState(msg.sender, newSaleState);
    }

    /// @notice Function used to set a new `publicPrice` value.
    /// @param newPublicPrice Newly desired `publicPrice` value.
    /// @dev Use: https://eth-converter.com/
    function setPublicPrice(uint256 newPublicPrice) external onlyOwner {
        publicPrice = newPublicPrice;
    }

    /// @notice Function used to set a new `multiPrice` value.
    /// @param newMultiPrice Newly desired `multiPrice` value.
    function setMultiPrice(uint256 newMultiPrice) external onlyOwner {
        multiPrice = newMultiPrice;
    }

    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;

        emit SetSigner(msg.sender, newSigner);
    }

    function setBaseTokenURI(string memory newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;

        emit SetTokenURI(msg.sender, newBaseTokenURI);
    }

    /// @notice Function used to claim revenue share for `account`.
    /// @param account Desired `account` to release revenue for.
    function release(address payable account) public override {
        if (msg.sender != account) revert AccountMismatch();
        super.release(account);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _verifySignature(
        bytes memory signature,
        uint256 quantity,
        string memory phase
    ) internal view returns (bool) {
        return _signer == keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            bytes32(abi.encodePacked(msg.sender, uint8(quantity), phase))
        )).recover(signature);
    }

}