// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/*
                                                                             &#&
                                                                        &BP5GB&
                                                                      BY7JG&         PJ&
                               &&##&&&                             #57^!P           G~J
                               #5?!!!!7?YPGB#&                   B?^^^?#         &#5?~^P
                                 #GY7~^:~5GGP55PB#              5!J!^7#     &BGY?!~?Y^:J
                                    #PJ7!~!JB#Y555Y5B&@&#      P7B@J^5  #BBY7~~?YY55!!Y&
                &GB#&&                &GJ7~^~Y~^!?5J^!JP!7G   &!Y5YP!GBJ!J!^:7BY!?Y5B&
                 #5J?7?J5PB#&BGGBBB#&   &GJ!^^^^^^^^^^^^~55YB #~~^^~~!~^^^^^?#7!B          #5&
                   B5?~^^^~~!?J5PG57!7J5G##PJ~^^^^^^^^^^^JB!^JP^^^^^^^^^^^^^7!^#   &&&#&   #?7#
                     &P?~^^^YP5YYY55!^^^^~!?J?^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!5Y??77?5&. BJ!^G &#&&. &&
                        GJ!~75GJ7?JY5J^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^7P&&B57~^^~5J!~~7YP5P&
                 &#BBBBBBB5?~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~?!?!~J7^^^^^^^?P5J!~~?GY^^^:~75B&&
                 BP5Y?!^~7YJ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~GG5PGPB5!^^^^^~^^~Y55YP!^~?P#
             &BPYJ7!~^~5#B57~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~^~!~!?!^^^^^^^^~~~^^^^^!YG#
           &PYY5Y?~^^^P#B&P7~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~JB
            &&BY!^^^^^~!GJ~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~7?J#
           #P?~^^^^^^^^^~^^^^!J!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~^^^^^^^^^^^^^^^^^^^^^!?G&
         #Y7^^^^^^^^^^^^^^^!PG57^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^7G5!^^^^^^^^^^^^^^5Y^^^^^^7G
       &P?~^^~?^^^^^^^^^^^5B57~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!5GG7^^^^^^^^^^^7G5^^^^^^^~J&
       55Y~^!B5!^^^^^^^^~GGJ!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!5#?^^^^^^^^^^Y7^^^^^^^7Y?G
       BJ~^^P###Y57^^^^^PBJ7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~5&~^^^^^^^^^^^^^^^^^^~G
       BJ~^^!~55?!^^^^^~#5?~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~J&!^^^^^^^^^^^^^^^^^?PP
       #J^^^^^^^^^^^^^^!&Y7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^!?YG#BGPYJ77P&~^^^^^^^^^^^^^^^^~5
     &P7^^^^^^^^^^^^^^^5@J!:^~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~7YG#&@@@@@@@@@@@@G^^^^^^^^^^^^^^^^^~J#
    #PPYJP??J7~^^^^^^^^G@5?YB&B5?!~^^^^^^^^^^^^~~^^^^^^^!?YPB&@@@@@@@@B5G&5YYB@?^^^^^^^^^^^^^^^^^^?P
    #&&#&GB. &5!^^^^^^^?@&&@@@@@@@&#PJ7!~^^^^^^5B^^~7YG#&@@@@@@@@&GY!:  .G?:~B#~^^^^^^^^^^^^^^^^^^7J&
              G?^^^^^^^!P@&@&#&@@@@@@@@&&#BGBBB&@PB&@@@@@@@@@@@B~.       ~#~7&J^^^^^^^^^^^^^^^^^^^!J#
              &J~^^^^^^^^BP#P.:^~!?B@@@@@@@@@@@@@@@@@@@@@@@@@@@#         :#!5#~^^^^^^^^^^^^^^^^^^^^5
              &J~^^^^^^^:Y#P#      ?@@@@BY#@@@PB@B~^?@@&!5@@@@@G         7B7&J^^^^^^^^^^^^^^^^^^^^^Y
              B?~^^^^^^^?&#7BY     .P&@@BJ#&5:7#7P5. ~B@#&@@@@P:        ~B?BP^^^^^^^~J55PG5J!^^^YP^JG
              Y7^^^^^^^^P@#7~GP^     :~!!!^..JB7^^JPJ: ^?JJJ?^        ^Y5~Y#~^^^^^!P&@@@@@@@&P~^BP^7J&
             P?^^!!!~^^^!&G7^^?55J!^:....^7YPY~^^^^~?557^.        .^7YP?^7&7^^^^^^B@@@@@@@@@@@B~GG^!J&
            #J!7G&@@#J^^~#P7^^^^~7JYY555YY?!^^^~~~~~^^~7YYYYYJJYYYYY?!^^~BY^^^^^^Y@@@@@@@@@@@@B~G7^!J&
            P?!&@@@@@@?:?&J?^^^^^^^^^^^^^^^^J5PPGGGGP7^^^^^~~~~~~~^^^^^^YB^^^^^^5@@@@@@@@@@@@G~^^^^7Y
            P7~#@@@@@@?:PBJ!^^^^^^^^^^^^^^^7#BBGGGBG#Y^^^^^^^^^^^^^^^^^^GP^^^^^~#@@@@@@@@@@@G~^^^^~JB
            G7^P@@@@@B^~&5?~^^^^^^^^^^^^^^^^J##GG#&BJ~^^^^^^^^^^^^^^^^^^?#~^^^^~#@@@@@@@@@#J^^^^^^?B
            &J~B@@@@B!^7&J!^^^^^^^^^^^^^^^^^^?PGBGP!^^^^^^^^^^^^^^^^^^^^^B?^^^^^P@@@@@@@#J~^^^^^!P&
             G!?BBP?^^^J&J~^^^^^^~!~^^^^^^^^^^^?J!:^^^^^~7?JYY55YJ7!~^^^^GP^^^^^~YB##G57~^^^^^^7B
             &?^^^^^^^^PB?^^^^^?YY5PY777!!!!!!!7???JJY5#&@@@@@@@@@@@#P7^^!#?^^^^^^^~^^^^^^^^^~75#
             &J~^^^^^^^#P7^^^^^YB&@@@@@@#!!!!~!B!~~^:.7@@@@@@@@@@@@@@@@J^^Y&?^^^^^^^^^^^^^^~?P#
              G?!~^^^~?&57^^^^?&@@@@@@@@@J!!!~J#J????Y#@&BGP55G#@@@@@@@&!^~JBG?~^^^^^^^^!7YB
               &B5YY5G&@57^^^^B@@@@@&G5J?77!!!!!!!777?7??JY5BY77P@BB@@@@J^^^~?PGGPP555PB&
                        B?^^^^Y@@@#Y!^^^^^^7^^^^^^^^^^!~^^^:Y&77?@Y7J#@B!^^^^^^~B
                         5!^^^^7J?~^^^^^^^~J5YJJJJJYY55!^^^~BP77?Y?77J@?^^^^^^^J
                          5!^^^^^^^^^^^^^^^^~!7?777!!~^^^^^PB77777777J@?^^^7Y!5
                           P7^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^PB777777??#G~~?GGPB
                            #Y7~^^^^^^^^^^^^^^^^^^^^^^^^^^^~GB5??JJ5#P~^!J?P&
                             #PJ!~^^^^~^^^^^^^^^^^^^^^^^^^^^75PGGP57^^!JG&
                                 #G5?!!555Y7^^^^^^^^^^^^^^^^^::^^~~!?5B&
                                     &#BB5Y?!~~^^^^~~~~~~!!!7?JYPG#
                                           &#BGGGGGGGGGGGGGGGP5YJ5
*/

contract Delinquentz is ERC721A, Ownable {
    using Strings for uint256;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 6666; // Total amount of Delinquentz
    uint256 public constant MAX_PRESALE_SUPPLY = 4000; // Total amount of Delinquentz available during presale

    uint256 public constant MAX_PER_WALLET_PRESALE = 6; // Max amount of Delinquentz per wallet during whitelist period

    uint256 public constant MAX_PER_TX = 6; // Max amount of Delinquentz per transaction
    uint256 public constant MAX_PER_WALLET_PUBLIC = 6; // Max amount of Delinquentz per wallet during public sale

    uint256 public constant PRICE = 0.0666 ether; // Price of a Delinquent

    // Team addresses -
    // ------------------------------------------------------------------------
    
    address private constant _a1 = 0xa7EefBCf03046Eb390ecD8f36A9eeE4D989B2313;
    address private constant _a2 = 0x73be80089799f019D54d611935dBB09e382DC218;
    address private constant _a3 = 0x6cD2eC6b05b3c0980e1CC06B6CAF9003b7b04612;
    address private constant _a4 = 0xE8b1FC3d7111EF10ff5aD0fc2dDf6f6bA30aB998;
    address private constant _a5 = 0xD9Cc4f2925faC37c76C552F59e3B618ccBB1FfC1;
    address private constant _a6 = 0xfECe19c7CCc76Ec878869E7Ff5B466995b1418C2;
    address private constant _a7 = 0xC38ec4336654B8B5e6c123D415F6F2918CEbF4a4;
    address private constant _a8 = 0xCaDA28340725dfcEd87C2039DfA96e9A4dbebF8C;
    address private constant _a9 = 0x589a49056f9F9EAd802907FE3F9Fc61294FC38C2;
    address private constant _communityFund = 0x386ef5CCbA968cEFA176f380F02387539Ca6EaF6;
    

    // State variables
    // ------------------------------------------------------------------------
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;


    // Presale mappings
    // ------------------------------------------------------------------------
    mapping(address => uint256) private _presaleClaimed;
    mapping(address => uint256) private _publicSaleClaimed;

    function countClaimedPresale(address addr) external view returns (uint256) {
        require(addr != address(0), "Null Address");
        return _presaleClaimed[addr];
    }

    function countClaimedPublicSale(address addr) external view returns (uint256) {
        require(addr != address(0), "Null Address");
        return _publicSaleClaimed[addr];
    }

    // URI variables
    // ------------------------------------------------------------------------
    string private _contractURI;
    string private _baseTokenURI;

    // Merkle Root Hash
    // ------------------------------------------------------------------------
    bytes32 private _merkleRoot;

    // Events
    // ------------------------------------------------------------------------
    event BaseTokenURIChanged(string baseTokenURI);
    event ContractURIChanged(string contractURI);

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyPresale() {
        require(isPresaleActive, "Presale is not active");
        _;
    }

    modifier onlyPublicSale() {
        require(isPublicSaleActive, "Public sale is not active");
        _;
    }

    // Modifier to ensure that the call is coming from an externally owned account, not a contract
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Contract caller must be externally owned account");
        _;
    }

    modifier onlyValidQuantity(uint256 quantity) {
        require(quantity > 0, "Quantity cannot be zero"); // require that the transaction quantity > 0
        require(quantity <= MAX_PER_TX, "Quantity exceeds max quantity per transaction"); // require that the transaction quantity is less than the max per transaction
        _;
    }

    // Constructor
    // ------------------------------------------------------------------------
    constructor() ERC721A("Delinquentz", "DLNQNTZ") {}

    // Presale functions
    // ------------------------------------------------------------------------

    // check if a merkle proof and the sender is eligible for presale
    function isEligibleForPresaleMerkle(bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); // hash the address of the sender
        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf); // verify that the sender's address is valid for the merkle proof   
    }

    function togglePresaleStatus() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    // Mint functions
    // ------------------------------------------------------------------------

    // Presale Mint using merkle proof
    function claimPresaleDelinquentMerkle(bytes32[] calldata _merkleProof, uint256 quantity) external payable onlyPresale onlyEOA onlyValidQuantity(quantity) {
        // require that the buyer is eligible for presale using the merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); // hash the address of the sender
        require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf), "Wallet is not eligible for presale"); // verify that the sender's address is valid for the merkle proof        
        
        require(totalSupply() < MAX_PRESALE_SUPPLY, "Delinquentz presale sold out");      
        require(totalSupply() + quantity <= MAX_PRESALE_SUPPLY, "Quantity exceeds maximum presale supply");

        require(_presaleClaimed[msg.sender] < MAX_PER_WALLET_PRESALE, "Wallet has already claimed presale limit");
        require(_presaleClaimed[msg.sender] + quantity <= MAX_PER_WALLET_PRESALE, "Quantity exceeds max quantity per wallet during presale"); // require that the buyer has not claimed their presale limit

        require(PRICE * quantity == msg.value, "Invalid ETH amount provided");

        _presaleClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity); // using ERC721A we can mint multiple tokens using _safeMint
    }

    // Public Sale mint
    function claimPublicSaleDelinquent(uint256 quantity) external payable onlyPublicSale onlyEOA onlyValidQuantity(quantity) {
        
        require(totalSupply() < MAX_SUPPLY, "Delinquentz sold out");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Quantity exceeds maximum supply");

        require(_publicSaleClaimed[msg.sender] < MAX_PER_WALLET_PUBLIC, "Wallet has already claimed public sale limit");
        require(_publicSaleClaimed[msg.sender] + quantity <= MAX_PER_WALLET_PUBLIC, "Quantity exceeds max quantity per wallet during public sale");
        
        require(PRICE * quantity == msg.value, "Invalid ETH amount provided");

        _publicSaleClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity); // using ERC721A we can mint multiple tokens using _safeMint
    }

    // Contract URI Functions
    // ------------------------------------------------------------------------

    // Set the contract URI - must set to a URL which can return a JSON of metadata for the contract
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
        emit ContractURIChanged(URI);
    }

    // Return the contract URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Base URI Functions
    // ------------------------------------------------------------------------
    
    // set the base token URI
    function setBaseTokenURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
        emit BaseTokenURIChanged(URI);
    }
    
    // override the _baseURI() method in the ERC721 contract 
    // the tokenURI() method below will call the tokenURI() method in the ERC721A contract, which will need the _baseURI set above
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // allow the owner of the contract to set the Merkle Root
    function setMerkleRoot(bytes32 rootHash) external onlyOwner {
        _merkleRoot = rootHash;
    }

    // Withdrawal functions -- NEED TO UPDATE WITH INFORMATION FOR WITHDRAWALS
    // ------------------------------------------------------------------------
    
    function withdrawAll() external onlyOwner {
        uint _a1amount = address(this).balance * 23/100;
        uint _a2amount = address(this).balance * 23/100;
        uint _a3amount = address(this).balance * 15/200;
        uint _a4amount = address(this).balance * 15/200;
        uint _a5amount = address(this).balance * 20/100;
        uint _a6amount = address(this).balance * 1/100;
        uint _a7amount = address(this).balance * 1/100;
        uint _a8amount = address(this).balance * 1/100;
        uint _a9amount = address(this).balance * 1/100;
        uint _communityFundAmount = address(this).balance * 15/100;

        require(payable(_a1).send(_a1amount), "Failed to send to a1");
        require(payable(_a2).send(_a2amount), "Failed to send to a2");
        require(payable(_a3).send(_a3amount), "Failed to send to a3");
        require(payable(_a4).send(_a4amount), "Failed to send to a4");
        require(payable(_a5).send(_a5amount), "Failed to send to a5");
        require(payable(_a6).send(_a6amount), "Failed to send to a6");
        require(payable(_a7).send(_a7amount), "Failed to send to a7");
        require(payable(_a8).send(_a8amount), "Failed to send to a8");
        require(payable(_a9).send(_a9amount), "Failed to send to a9");
        require(payable(_communityFund).send(_communityFundAmount), "Failed to send to Community Fund");
    }   
    

    function emergencyWithdraw() external onlyOwner {
        payable(_communityFund).transfer(address(this).balance);
    }
    
    
}
