/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;


import "./ERC721Enumerable.sol";
import "./ERC721Metadata_URI_autoIncrementID.sol";
import "./ERC721Burnable.sol";
import "./Owned.sol";
import "./MerkleProofLib.sol";
import "./SSTORE2.sol";




contract ERC721Generative is Owned, ERC721Burnable, ERC721Metadata_URI_autoIncrementID,
    ERC721Enumerable
{

    // using BytecodeStorage for string;
    // using BytecodeStorage for address;
    using SSTORE2 for bytes;
    using MerkleProofLib for bytes32[];

    /*----------------------------------------------------------*|
    |*  # CONSTANTS                                             *|
    |*----------------------------------------------------------*/

    
     // Constants
    address private immutable FACTORY; // Address of the factory contract
    address public scriptStorageAddress; // Address of the deployed contract containing the script
    uint256 public dropTime; // Time when the NFT drop will happen
    uint256 public dropDurationAL; // Duration of the AL drop
    uint256 public dropDurationPublic; // Duration of the public drop
    uint256 public ALPrice; // Price for addresses in the allow list
    uint256 public publicPrice; // Price for the public
    uint256 public maxSupply; // Price for the public
    uint16 private constant TOTAL_SHARES = 10_000; // Total shares for royalty calculations
    uint16 private constant DEFAULT_ROYALTY_BPS = 1000; // Default royalty basis points

    
    modifier onlyBeforeDropStart() {
        require(block.timestamp < dropTime);
        _;
    }

    modifier onlyBeforeALDropEnd() {
        require(block.timestamp < dropTime + dropDurationAL);
        _;
    }


    // /*----------------------------------------------------------*|
    // |*  # MINTING                                               *|
    // |*----------------------------------------------------------*/

    bytes32 public merkleRoot; // Merkle root for the whitelist

    /**
 * @dev Function to mint a new NFT.
 * @param _to The address to mint the NFT to.
 * @param _merkleProof The Merkle proof for the address.
 * @param _data Additional data to accompany the mint function.
 */
function mint(address _to, bytes32[] calldata _merkleProof, bytes memory _data) external payable returns(uint256 _tokenId) {
    require(_owners.length < maxSupply);
    if (block.timestamp - dropTime < dropDurationAL) {
        // Verify the merkle proof.
        // This ensures that the address is included in the whitelist.
        bytes32 node = keccak256(abi.encodePacked(_to));
        require(_merkleProof.verify(merkleRoot, node));
        require(msg.value == ALPrice);
    } else if (block.timestamp - dropTime < dropDurationAL + dropDurationPublic) {
        require(msg.value == publicPrice);
    } else {
        revert();
    }

    // Mark it as claimed and mint the NFT.
    // This updates the state of the contract and mints the NFT to the address.
    _tokenId = _mint(_to, _owners.length, _data);
}

    /*----------------------------------------------------------*|
    |*  # ADMIN                                                 *|
    |*----------------------------------------------------------*/

    function withdraw() external {
        payable(owner).transfer(address(this).balance * 8000 / 10000);
        payable(0x229946a96C34edD89c06d23DCcbFA259E9752a7c).transfer(address(this).balance);
    }

    function setScript(bytes calldata _script) external onlyBeforeDropStart onlyOwner {
        scriptStorageAddress = SSTORE2.write(_script);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory baseURI_, address deployedContract_) external onlyOwner {
        _setBaseURI(baseURI_, deployedContract_);
    }

    function setDropTime(uint256 _newDropTime) external onlyOwner onlyBeforeALDropEnd {
        require(block.timestamp < _newDropTime); // New drop time is in the future
          
        dropTime = _newDropTime;
    }

    function setMaxSupply(uint256 maxSupply_) external  onlyOwner onlyBeforeDropStart {
        maxSupply = maxSupply_;
    }

    function setDropDurationAL(uint256 _newDropDurationAL) external onlyOwner onlyBeforeALDropEnd {
        require(block.timestamp <  dropTime + _newDropDurationAL); // AL drop ends in the future

        dropDurationAL = _newDropDurationAL;
    }

    function setDropDurationPublic(uint256 _newDropDurationPublic) external onlyOwner {
        uint256 dropTimePublic = dropTime + dropDurationAL;
        require(block.timestamp < dropTimePublic + dropDurationPublic ); // only before drop ended
        require(block.timestamp <  dropTimePublic + _newDropDurationPublic); // Public drop ends in the future
        
        dropDurationPublic = _newDropDurationPublic;
    }

    function setALPrice(uint256 ALPrice_) external  onlyOwner onlyBeforeDropStart{
        ALPrice = ALPrice_;
    }

    function setPublicPrice(uint256 publicPrice_) external  onlyOwner onlyBeforeDropStart {
        publicPrice = publicPrice_;
    }

    /*----------------------------------------------------------*|
    |*  # VIEW FUNCTIONS                                        *|
    |*----------------------------------------------------------*/

    function royaltyInfo(uint256, uint256 _value) external view returns (address, uint256) {
        return (owner, uint256(DEFAULT_ROYALTY_BPS * _value / TOTAL_SHARES));
    }

    /**
     * @dev same function interface as erc1155, so that external contracts, i.e.
     * the marketplace, can check either erc
     * without requiring an if/else statement
     */
    function exists(uint256 _id) external view returns (bool) {
        return _owners[_id] != ZERO_ADDRESS;
    }

    /*----------------------------------------------------------*|
    |*  # ERC-165                                               *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC165-supportsInterface}.
     * `supportsInterface()` was first implemented by all contracts and later
     * all implementations removed, hardcoding
     * interface IDs in order to save some gas and simplify the code.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x80ac58cd // type(IERC721).interfaceId
            || interfaceId == 0x780e9d63 // type(IERC721Enumerable).interfaceId
            || interfaceId == 0x5b5e139f // type(IERC721Metadata).interfaceId
            || interfaceId == 0x01ffc9a7 // type(IERC165).interfaceId
            || interfaceId == 0x2a55205a; // type(IERC2981).interfaceId
    }

    // Function to read the script from the contract
    function getScript() external view returns (string memory) {
        return string(SSTORE2.read(scriptStorageAddress));
    }

    /*----------------------------------------------------------*|
    |*  # INITIALIZATION                                        *|
    |*----------------------------------------------------------*/

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the _to that
     * deploys the contract.
     *      `MINTER_ROLE` is needed in case the deployer may want to use or
     * allow other accounts to mint on their
     * self-sovereign collection
     */
    function initialize(bytes calldata _data) external {
        require(msg.sender == FACTORY);
        bytes memory _script;
        string memory _baseURI;
        (
            name, 
            symbol,
            _baseURI,
            merkleRoot, 
            dropTime, 
            ALPrice, 
            publicPrice, 
            dropDurationAL, 
            dropDurationPublic, 
            maxSupply,
            _script
        ) = abi.decode(_data, (
            string, 
            string, 
            string,
            bytes32, 
            uint256, 
            uint256, 
            uint256, 
            uint256, 
            uint256, 
            uint256, 
            bytes
        ));

        owner = tx.origin;

        _setBaseURI(_baseURI, address(this));

        scriptStorageAddress = SSTORE2.write(_script);
    }

    /**
     * @param factory_ of the factory contract constant set at deployment of master contract, replaces
     * `initializer` modifier reducing the cost of calling
     * `initialize` from the factory contract whenever a new clone is deployed.
     */
    constructor(address factory_) {
        FACTORY = factory_;
    }
}
