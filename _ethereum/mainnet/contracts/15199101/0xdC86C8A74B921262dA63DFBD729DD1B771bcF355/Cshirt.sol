// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
//import "./console.sol";

/*
 * @title – Cshirt 
 * @website - https://cshirts.io/
 * @description - A generative collection of 8000 jerseys 24x24px that get you multiple perks for the Not Fungible Cup.
 *                It's an NFT game with real prizes in ETH, for real-life sports tournaments.
 *                Tournaments NFTs, represent digital twins of real players, where NFT holders receive prizes based on players’ performances.
 */


/**********************************************************************************************************
                                                                                
                                                                                            
                            @@@@@@@@@@@@@                    @@@@@@@@@@@@@@                
                        @@@             @@@@             @@@              @@@             
                        @@@             @@@@             @@@              @@@             
                    @@@@                    @@@@@@@@@@@@@                    @@@@          
                @@@                                                               @@@      
                @@@                                                               @@@   
                @@@                                                               @@@   
                @@@                                                               @@@      
                    @@@@   @@@                                         @@@@   @@@@          
                        @@@@@@                                         @@@@@@@             
                        @@@@@@                                         @@@@@@@             
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@                                        @@@@                
                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                
                                                                                

***********************************************************************************************************/

contract Cshirt is ERC721A, ERC721AQueryable, ReentrancyGuard, Ownable {

    using ECDSA for bytes32;

    /* ––– PUBLIC VARIABLES ––– */
    /*
     * @notice – Control switch for sale
     * @notice – Set by `setMintStage()`
     * @dev – 0 = PAUSED; 1 = ALLOWLIST, 2 = WAITLIST
     */
    enum MintStage {
        PAUSED,
        ALLOWLIST,
        WAITLIST
    }
    MintStage public _stage = MintStage.PAUSED;

    /*
     * @notice – Mint price in etherd
     * @notice – Set by `setPrice()`
     */
    uint256 public _price = 0.2 ether;

     /*
     * @notice – max nft that can be minted per wallet in waitlist
     * @notice – Set by `setMaxNft()`
     */
    uint256 public _max_nft = 1;

    /*
     * @notice – ECDSA Signer address used for verifying whitelist signatures 
     * @notice – Set by `setSignerAddress()`
     */
    address public _signerAddress;

    /*
     * @notice – Address to the project's gnosis safe
     * @notice – Set by `setSafe()`
     */
    address payable public _safe =
        payable(0x7c5470658805a6De5029808908907B5292150def);

    /*
     * @notice – Maximum token supply
     * @dev – Note this is constant and cannot be changed
     */
    uint256 public constant MAX_SUPPLY = 8000;

    /*
     * @notice – Token URI base
     * @notice – Passed into constructor and also can be set by `setBaseURI()`
     */
    string public baseTokenURI;

    /* ––– END PUBLIC VARIABLES ––– */

    /* ––– INTERNAL FUNCTIONS ––– */
    /*
     * @notice – Internal function that overrides baseURI standard
     * @return – Returns newly set baseTokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /* ––– END INTERNAL FUNCTIONS ––– */

    /* ––– CONSTRUCTOR ––– */
    /*
     * @notice – Contract constructor
     * @param - signerAddress : the address of the signer to use for verifing signatures in whitelist
     * @param - newBaseURI : Token base string for metadata
     */
    constructor(
        address signerAddress,
        string memory newBaseURI

    ) ERC721A("CShirt", "CSHIRT") {
        baseTokenURI = newBaseURI;
        _signerAddress = signerAddress;
    }

    /* ––– END CONSTRUCTOR ––– */

    /* ––– MODIFIERS ––– */
    /*
     * @notice – Smart contract source check
     */
    modifier contractCheck() {
        require(tx.origin == msg.sender, "only_humans");
        _;
    }

    /*
     * @notice – Current mint stage check
     */
    modifier checkSaleActive() {
        require(MintStage.PAUSED != _stage, "sale_not_active");
        _;
    }

    /*
     * @notice – Token max supply boundary check
     */
    modifier checkMaxSupply(uint256 _amount) {
        require(totalSupply() + _amount <= MAX_SUPPLY, "exceeds_total_supply");
        _;
    }

    /*
     * @notice – Transaction value check
     */
    modifier checkTxnValue(uint256 _amount) {
        require(msg.value >= _price * _amount, "invalid_transaction_value");
        _;
    }
 
    /* ––– END MODIFIERS ––– */

    /* ––– OWNER FUNCTIONS ––– */
    /*
     * @notice – Gifts an amount of tokens to a given address
     * @param – _to: Address to send the tokens to
     * @param – _amount: Amount of tokens to send
     */
    function gift(address _to, uint256 _amount)
        public
        onlyOwner
        checkMaxSupply(_amount)
    {
        _mint(_to, _amount);
    }

    /*
     * @notice – Sets the Gnosis safe address
     * @param – _newSafe: New address for the team safe
     */
    function setSafe(address payable _newSafe) public onlyOwner {
        _safe = _newSafe;
    }

    /*
     * @notice – Sets the mint price (in wei)
     * @param – _newPrice: New mint price to set
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    /*
     * @notice – Sets the max nft amount per wallet in whitelist
     * @param – _newmax: count of max nft per  wallet in whitelist
     */
    function setMaxNft(uint256 _newmax) public onlyOwner {
         _max_nft =  _newmax;
    }

    /*
     * @notice – Sets the mint stage
     * @param – _stage: {0 = PAUSED | 1 = ALLOWLIST | 2 = WAITLIST}
     */
    function setMintStage(MintStage _newStage) public onlyOwner {
        _stage = _newStage;
    }

     /*
     * @notice – Sets the signer 
     * @param – _newSigner: address of the signer
     */
    function setSignerAddress(address _newSigner) public onlyOwner {
        _signerAddress = _newSigner;
    }

    /*
     * @notice – Sets the base URI to the given string
     * @param – baseURI: New base URI to set
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    /*
     * @notice – Withdraws the contract balance to the safe
     */
    function withdrawToSafe() public onlyOwner {
        require(address(_safe) != address(0), "safe_address_not_set");

        _safe.transfer(address(this).balance);
    }

    /*
     * @notice – Withdraws the contract balance to the safe
     */
    function withdrawToAny(address payable dest, uint256 amount)
        public
        onlyOwner
    {
        require(address(dest) != address(0), "cannot_withdraw_null_address");
        require(amount > 0, "cannot_withdraw_zero_amount");

        dest.transfer(amount);
    }

    /* ––– END OWNER FUNCTIONS ––– */

    /* ––– PUBLIC FUNCTIONS ––– */
    /*
     * @notice – Mint function in whitelist
     * @param _signature: signature to validate whitelist
     * @param _amount: amount of token to mint
     */
    function mintWaitlist(bytes calldata _signature, uint256 _amount)
        public
        payable
        contractCheck
        checkSaleActive
        checkMaxSupply(_amount)
        checkTxnValue(_amount)
        nonReentrant
    {
        require(_max_nft >= _amount, "exceed_amount");
        require(MintStage.ALLOWLIST != _stage, "waitlist_not_active");
        require(_getAux(msg.sender) + _amount <= _max_nft, "max_purchase_reached");
        require(_signerAddress == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(_signature), "signer_address_mismatch.");
        
        _setAux(msg.sender, _getAux(msg.sender) + uint64(_amount));
        _mint(msg.sender, _amount);
    }

    /*
     * @notice – Mint function in allowlist
     * @param _amount: amount of token to mint
     */
    function mint(uint256 _amount)
        public
        payable
        contractCheck
        checkSaleActive
        checkMaxSupply(_amount)
        checkTxnValue(_amount)
        nonReentrant
    {
        require(MintStage.WAITLIST != _stage, "sale_not_active");
        _mint(msg.sender, _amount);
    }

    /*
     * @notice – returns string if contract is live
     */
    function alive() external pure returns(string memory) {
        return "prot!";
    }

    /* ––– END PUBLIC FUNCTIONS ––– */
}