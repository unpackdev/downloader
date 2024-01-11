// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";
import "./ITimeCatsLoveEmHateEm.sol";

contract Timbaland is ERC721, Ownable {
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is contract"); // solium-disable-line security/no-tx-origin

        _;
    }

    modifier contractIsNotFrozen() {
        require(_frozen == false, "This contract has been frozen");

        _;
    }

    bytes32 public merkleRoot;
    bytes32 public mintPassMerkleRoot;
    bool public _pause = true;
    bool public _frozen;
    uint256 public price = 0.2 ether;
    uint256 public supply;
    uint16[] private availableTokenIds;
    mapping(address => bool) public hasMinted;

    string private _baseTokenURI = "ipfs://Qmb6uZozUkHFmDprx1ozYHzNVi5VpT27aNKvf3m3SUCwVy/";
    address public mintPassAddress = 0x7581F8E289F00591818f6c467939da7F9ab5A777;

    constructor(bytes32 root, uint256 tokenSupply) ERC721("TIMEPieces x Timbaland: The Beatclub Collection", "TPBC") {
        merkleRoot = root;
        supply = tokenSupply;
        for (uint16 i = 0; i < supply; i++) {
            availableTokenIds.push(i + 1);
        }
    }

    // Only Owner Functions

    /**
     * @dev Sets the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner contractIsNotFrozen {
        price = _mintPrice;
    }

    /**
     * @dev Sets the address of the TIME mint pass smart contract
     */
    function setMintPassAddress(address _mintPassAddress) external onlyOwner contractIsNotFrozen {
        mintPassAddress = _mintPassAddress;
    }

    /**
     * @dev Sets the main merkle root
     */
    function setMainRoot(bytes32 root) external onlyOwner contractIsNotFrozen {
        merkleRoot = root;
    }

    /**
     * @dev Sets the mint with pass merkle root
     */
    function setMintPassRoot(bytes32 root) external onlyOwner contractIsNotFrozen {
        mintPassMerkleRoot = root;
    }


    /**
    *   @dev Sets the baseURI
    */
    function setBaseURI(string memory uri) public onlyOwner contractIsNotFrozen {
        _baseTokenURI = uri;
    }

    /**
     * @dev Sets the pause status for the mint period
     */
    function pauseMint(bool val) public onlyOwner contractIsNotFrozen {
        _pause = val;
    }

    /**
     * @dev Allows for withdraw of Ether from the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeContract() external onlyOwner {
        _frozen = true;
    }

    /**
    *   @dev Dev mint for token airdrop
    */
    function devMint(address[] memory _addresses) public onlyOwner contractIsNotFrozen {
        require(availableTokenIds.length >= _addresses.length, "Not enough tokens available");
        for (uint256 i; i < _addresses.length; i++) {
            uint256 num = getRandomNum(availableTokenIds.length);
            _safeMint(_addresses[i], uint256(availableTokenIds[num]));
            availableTokenIds[num] = availableTokenIds[availableTokenIds.length - 1];
            availableTokenIds.pop();
        }
    }

    // End Only Owner Functions

    /**
    *   @dev The Mint function
    */
    function mint(bytes32[] calldata merkleProof) public payable callerIsUser contractIsNotFrozen {
        require(!_pause, "Mint is paused");
        require(availableTokenIds.length > 0, "Sold out");
        require(msg.value >= price, "Not enough ether");
        require(hasMinted[msg.sender] == false, "User already Minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not on allow list");

        uint256 num = getRandomNum(availableTokenIds.length);
        _safeMint(msg.sender, uint256(availableTokenIds[num]));
        hasMinted[msg.sender] = true;

        availableTokenIds[num] = availableTokenIds[availableTokenIds.length - 1];
        availableTokenIds.pop();
    }

    /**
    *   @dev The mintWithPass function
    */
    function mintWithPass(uint256 mintPassID, bytes32[] calldata merkleProof) public payable callerIsUser contractIsNotFrozen {
        require(!_pause, "Mint is paused");
        require(availableTokenIds.length > 0, "Sold out");
        require(msg.value >= price, "Not enough ether");
        require(hasMinted[msg.sender] == false, "User already Minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, mintPassMerkleRoot, leaf), "Not on allow list");

        // Initialize the mint pass contract interface
        ITimeCatsLoveEmHateEm mintPassContract = ITimeCatsLoveEmHateEm(
            mintPassAddress
        );

        // Check if the mint pass is already used or not
        require(!mintPassContract.isUsed(mintPassID), "Pass is already used");

        // Check if the caller is the owner of the mint pass
        require(msg.sender == mintPassContract.ownerOf(mintPassID), "You dont own this mint pass");

        uint256 num = getRandomNum(availableTokenIds.length);
        _safeMint(msg.sender, uint256(availableTokenIds[num]));

        hasMinted[msg.sender] = true;

        // Set mint pass as used
        mintPassContract.setAsUsed(mintPassID);

        availableTokenIds[num] = availableTokenIds[availableTokenIds.length - 1];
        availableTokenIds.pop();
    }


    /**
    *   @notice function to get remaining supply
    */
    function getRemainingSupply() public view returns (uint256) {
        return availableTokenIds.length;
    }

    /**
     * @dev returns total supply of tokens
     */
    function totalSupply() public view returns (uint256) {
        return supply;
    }

    /**
    * @dev Get if the user has minted
    */
    function getHasMinted(address _owner) public view returns (bool) {
        return hasMinted[_owner];
    }

    /**
    * @dev Gets random number for token distribution
    */
    function getRandomNum(uint256 upper) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.difficulty, msg.sender)));
        return random % upper;
    }

    /**
     * @dev Overridden baseURI getter
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
