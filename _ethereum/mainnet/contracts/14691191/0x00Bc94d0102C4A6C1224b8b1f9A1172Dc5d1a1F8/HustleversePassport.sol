// SPDX-License-Identifier: MIT

//                                                                                        
//         @@@@@@@@@@@@@@@@%@@               @@ @@@@@@@@@@@@@@@@                      
//         @@@@@@@@@@@@@@@@@@@@@@           @@@@@@ @@@@@@@@@ @@@@@%                   
//        ,@@@@@@@@#@@@@@@ @@@@@@@@@        @@@@@@@@@ @@@@@@@@@@@@@@@,                
//        @@@@@@@@@@@     .@@@@@@@@@@       @@@@@@@@@@@     @@@@@@@@@@@               
//        @@@@@@@@@@@     @@@@@@@@@@@      *@@@@@@@@@@      @@@@@@@@@@#               
//        @@@@@@@@@@      @@@@@@@@@@@      @@@@@@@@@@@     %@@@@@@@@@@                
//       @@@@@@@@@@@      @@@@@@@@@@       @@@@@@@@@@@     @@@@@@@@@@@                
//       @@@@@@@@@@@     @@@@@@@@@@@       @@@@@@@@@@      @@@@@@@@@@@                
//       @@@@@@@@@@/       @@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@                 
//      @@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@                 
//      @@@@@@@@@@@              @@@@@@@@@@@@@@@@(@@,     @@@@@@@@@@@                 
//      @@@@@@@@@@@                                       @@@@@@@@@@                  
//     ,@@@@@@@@@@                                       @@@@@@@@@@@                  
//     @@@@@@@@@@@                                       @@@@@@@@@@@                  
//     @@@@@@@@@@@     @@@@@@@@@@@@@@@@@*@               @@@@@@@@@@#                  
//     @@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@           %@@@@@@@@@@                   
//    @@@@@@@@@@@      @@@@@@@#@@@@@@@@@@@@@@@@@        @@@@@@@@@@@                   
//    @@@@@@@@@@@     @@@@@@@@@@@       @@@@@@@@@@      @@@@@@@@@@@                   
//   @@@@@@@@@@/     @@@@@@@@@@@      @@@@@@@@@@@     .@@@@@@@@@@                    
//   @@@@@@@@@@@      @@@@@@@@@@(      @@@@@@@@@@@     @@@@@@@@@@@                    
//   @@@@@@@@@@@     &@@@@@@@@@@       @@@@@@@@@@,     @@@@@@@@@@@                    
//   @@@@@@@@@@@     @@@@@@@@@@@      @@@@@@@@@@@      @@@@@@@@@@                     
//    @@@@@@@@@@@@@@@,@@@@@@@@@@       @@@@@@@@@@@@@@@@,@@@@@@@@@                     
//      *@@@@@@@@@@@@@@@ @@@@@@           @@@@@@@@@@@@@@@@&@@@@@@                     
//         &@@@@@@@@@@@@@@@ @@@              @@@@@@@@@@@@@@@@@@@(                     
//            @@@@@@@@@@@@@@@@.                 @@@@@@@@@@@@@@@&                      
//

pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

/**
 * @title Hustleverse Passport
 * @author @jonathansnow
 * @notice Hustleverse Passport is an ERC721 token that represents access to the Hustleverse.
 */
contract HustleversePassport is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant TEAM_SUPPLY = 50;
    uint256 public constant MAX_SUPPLY = 1050;
    uint256 public constant MAX_MINT = 2;
    uint256 public constant PRICE = 0.25 ether;

    bytes32 public merkleRoot;

    bool public saleIsActive;

    mapping (address => uint256) public mintBalance;

    // Withdrawal addresses
    address public a1 = 0xd54Dc233A64B01EA506b36eCD3db98Ba17004859;          // Treasury
    address public a2 = 0xf03de03327feec87534272B7DCBB9bA5215Bc110;          // Treasury
    address public constant a3 = 0xb6ba815DC649b7Db1Ed4dA400da9D76688ea8A54; // Dev
    address public constant a4 = 0xCAe379DD33Cc01D276E57b40924C20a8312197AA; // Dev

    // Address for Winter minting
    address public constant winterWallet = 0xd541da4C37e268b9eC4d7D541Df19AdCf564c6A9;

    constructor() ERC721("HustleversePassport", "HSTLV") {
        _nextTokenId.increment();   // Start Token Ids at 1
    }

    /**
     * @notice Public minting function for whitelisted addresses
     * @dev Sale must be active, the sender must be whitelisted, and sender must be within max mint limit.
     * @param quantity the number of tokens to mint
     * @param proof the merkle proof for the address minting
     */
    function mint(uint256 quantity, bytes32[] calldata proof) public payable {
        require(saleIsActive, "Sale is not active yet.");
        require(quantity > 0, "Must mint more than 0.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max available.");
        require(mintBalance[msg.sender] + quantity <= MAX_MINT, "No mints remaining.");
        require(msg.value == quantity * PRICE, "Wrong ETH value sent.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof.");

        mintBalance[msg.sender] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    /**
     * @notice Public minting function for whitelisted addresses using Winter for payments
     * @dev Function is the same as the public mint function, but the sender is the Winter address.
     * @param quantity the number of tokens to mint
     * @param recipient the address to mint to
     * @param proof the merkle proof for the address minting
     */
    function winterMint(uint256 quantity, address recipient, bytes32[] calldata proof) public payable {
        require(msg.sender == winterWallet, "This mint is only for Winter.");
        require(saleIsActive, "Sale is not active yet.");
        require(quantity > 0, "Must mint more than 0.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max available.");
        require(mintBalance[recipient] + quantity <= MAX_MINT, "No mints remaining.");
        require(msg.value == quantity * PRICE, "Wrong ETH value sent.");

        bytes32 leaf = keccak256(abi.encodePacked(recipient));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof.");

        mintBalance[recipient] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(recipient, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    /**
     * @notice Get the number of passes minted
     * @return uint256 number of passes minted
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    /**
     * @notice Get baseURI
     * @dev Overrides default ERC721 _baseURI()
     * @return baseURI the base token URI for the collection
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Update the baseURI
     * @dev URI must include trailing slash
     * @param baseURI the new metadata URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Toggle public sale on/off
     */
    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @notice Update the merkle root used for allowlist management
     * @dev Root string passed must be proceeded by '0x'
     * @param _merkleRoot the new root of the merkle tree
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Admin minting function
     * @dev Allows the team to mint up to 50 passes. Must be minted prior to public sale.
     * @param quantity the number of tokens to mint
     * @param recipient the address to mint the tokens to
     */
    function adminMint(uint256 quantity, address recipient) public onlyOwner {
        require(totalSupply() + quantity <= TEAM_SUPPLY, "Exceeds max team amount.");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(recipient, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    /**
     * @notice Update the Treasury addresses
     * @dev Allows the team to update the addresses they will use to receive funds.
     * @param _newA1Address the primary Treasury address
     * @param _newA2Address the secondary Treasury address
     */
    function updateTreasury(address _newA1Address, address _newA2Address) external onlyOwner {
        a1 = _newA1Address;
        a2 = _newA2Address;
    }

    /**
     * @notice Function to withdraw ETH balance with splits
     * @dev Transfers 90% of the contract ETH balance to be split between the Treasury addresses, 10% to be split
     * between the dev partners. Any ETH remaining after the main transfers will be sent to the a1 Treasury address.
     */
    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;

        _withdraw(a1, (balance * 45) / 100 );   // 45%
        _withdraw(a2, (balance * 45) / 100 );   // 45%
        _withdraw(a3, (balance * 5) / 100 );    // 5%
        _withdraw(a4, (balance * 5) / 100 );    // 5%
        _withdraw(a1, address(this).balance );  // Remainder
    }

    /**
     * @notice Function to send ETH to a specific address
     * @dev Using call to ensure that transfer will succeed for EOA and Gnosis Addresses.
     * @param _address the address to send the ETH to
     * @param _amount the amount to send to the address
     */
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = payable(_address).call{ value: _amount }("");
        require(success, "Transfer failed.");
    }

}