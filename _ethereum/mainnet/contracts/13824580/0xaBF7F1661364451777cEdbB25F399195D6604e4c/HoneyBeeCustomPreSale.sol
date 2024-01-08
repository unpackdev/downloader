// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract IHoneyBee {
    /** ERC-721 INTERFACE */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** CUSTOM INTERFACE */
    function nextTokenId() public returns(uint256) {}
    function mintTo(uint256 amount, address _to) external {}
    function burn(uint256 tokenId) external {}
}

contract HoneyBeeCustomPreSale is Ownable {
    using SafeMath for uint256;

    /** ADDRESSES */
    address public ERC721TokenAddress;
    address public preSaleAddress;
    
    /** CONTRACTS */
    IHoneyBee public nft;
    
    /** MINT OPTIONS */
    uint256 constant public MINT_PRICE = 0.1 ether;

    uint256 public minted = 0;

    /** SCHEDULING */
    uint256 public preSaleOpen = 1639778400;//1639778400;
    uint256 public preSaleDuration = 3600 * 24;//3600 * 24;

    /** MERKLE */
    bytes32 public customLimitMerkleRoot = "";

    /** MAPPINGS  */
    mapping(address => uint256) public mintsPerAddress;

    /** MODIFIERS */
    modifier whenPreStarted() {
        require(block.timestamp >= preSaleOpen, "PRE-SALE HASN'T OPENED YET");
        require(block.timestamp <= preSaleOpen.add(preSaleDuration), "PRE-SALE IS CLOSED");
        _;
    }

   /** EVENTS */
   event ReceivedEther(address sender, uint256 amount);

    constructor(
        address _ERC721TokenAddress,
        address _preSaleAddress
    ) Ownable() {
        ERC721TokenAddress = _ERC721TokenAddress;
        nft = IHoneyBee(_ERC721TokenAddress);
        preSaleAddress = _preSaleAddress;
    }    

    function setSaleStart(uint256 timestamp) external onlyOwner {
        preSaleOpen = timestamp;
    }

    function setSaleDuration(uint256 timestamp) external onlyOwner {
        preSaleDuration = timestamp;
    }

    function setCustomPreMintMerkleRoot(bytes32 _root) external onlyOwner {
        customLimitMerkleRoot = _root;
    }

    function setPreSaleAddress(address _new) external onlyOwner {
        preSaleAddress = _new;
    }

    function setNFT(address _nft) external onlyOwner {
        nft = IHoneyBee(_nft);
    }

    /**
    * @dev override msgSender to allow for meta transactions on OpenSea.
    */
    function _msgSender()
        override
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    function preSaleMintCustomLimit(uint256 amount, bytes32[] calldata proof) external payable whenPreStarted {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, customLimitMerkleRoot, leaf), "INVALID PROOF");
        
        require(mintsPerAddress[_msgSender()] == 0, "ALREADY MINTED");

        require(msg.value == MINT_PRICE.mul(amount), "ETHER SENT NOT CORRECT");

        mintsPerAddress[_msgSender()] = mintsPerAddress[_msgSender()].add(amount);
        minted = minted.add(amount);
        nft.mintTo(amount, _msgSender());
        payable(preSaleAddress).transfer(address(this).balance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}