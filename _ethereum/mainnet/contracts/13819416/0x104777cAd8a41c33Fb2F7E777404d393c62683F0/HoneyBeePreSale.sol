// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Strings.sol";
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

contract HoneyBeePreSale is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    /** ADDRESSES */
    address public ERC721TokenAddress;
    address[] private recipients;

     /** OTHER */
    uint256[] private percentages;

    /** CONTRACTS */
    IHoneyBee public immutable nft;
    
    /** MINT OPTIONS */
    uint256 public MAX_SUPPLY = 500;  
    uint256 constant public MINTS_PER_USER = 1;
    uint256 constant public MINTS_PER_USER_RAISED = 3;
    uint256 constant public MINT_PRICE = 0.1 ether;

    uint256 public ownerReserved = 0;
    uint256 public ownerMaxReserve = 100;

    uint256 public minted = 0;

    /** SCHEDULING */
    uint256 public preSaleOpen = 1639778400;//1639778400;
    uint256 public preSaleRaiseLimit =  30 * 60;
    uint256 public preSaleDuration = 3600 * 24;//3600 * 24;

    /** MERKLE */
    bytes32 public preSaleMerkleRoot = "";
    bytes32 public customLimitMerkleRoot = "";

    /** MAPPINGS  */
    mapping(address => uint256) public mintsPerAddress;

    /** MODIFIERS */
    modifier whenPreStarted() {
        require(block.timestamp >= preSaleOpen, "PRE-SALE HASN'T OPENED YET");
        require(block.timestamp <= preSaleOpen.add(preSaleDuration), "PRE-SALE IS CLOSED");
        require(minted < MAX_SUPPLY, "SOLD OUT");
        _;
    }

   /** EVENTS */
   event ReceivedEther(address sender, uint256 amount);

    constructor(
        address _ERC721TokenAddress
    ) Ownable() {
        ERC721TokenAddress = _ERC721TokenAddress;
        nft = IHoneyBee(_ERC721TokenAddress);
    }    

    function setSaleStart(uint256 timestamp) external onlyOwner {
        preSaleOpen = timestamp;
    }

    function setSaleDuration(uint256 timestamp) external onlyOwner {
        preSaleDuration = timestamp;
    }

    function setPreSaleRaiseLimit(uint256 timestamp) external onlyOwner {
        preSaleRaiseLimit = timestamp;
    }

    function setPreMintMerkleRoot(bytes32 _root) external onlyOwner {
        preSaleMerkleRoot = _root;
    }

    function reserveForOwner(uint256 amount) external onlyOwner {
        require(ownerReserved.add(amount) <= ownerMaxReserve, "Owner max reserve exceeded");
        ownerReserved = ownerReserved.add(amount);
        nft.mintTo(amount, _msgSender());
    }

    function addRecipient(address _newAddress, uint256 _percentage) external onlyOwner {
        recipients.push(_newAddress);
        percentages.push(_percentage);
    }

    function setRecipients(address[] calldata _addresses, uint256[] calldata _percentages) external onlyOwner {
        require(_addresses.length == _percentages.length, "Addresses should equal percentages");

        for (uint i = 0; i < _addresses.length; i++) {
            recipients.push(_addresses[i]);
            percentages.push(_percentages[i]);
        }
    }

    function resetRecipients() external onlyOwner {
        delete recipients;
        delete percentages;
    }

    function amountOfRecipients() external view onlyOwner returns(uint256) {
        return recipients.length;
    }

    function getAddressOfRecipient(uint256 number) external view onlyOwner returns(address)  {
        require(number < recipients.length, "REQUESTING A NON EXISTENT RECIPIENT");
        return recipients[number];
    }

    function getPercentageOfRecipient(uint256 number) external view onlyOwner returns(uint256) {
        require(number < recipients.length, "REQUESTING A NON EXISTENT RECIPIENT");
        return percentages[number];
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        MAX_SUPPLY = amount;
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

    /**
     * @dev allows addresses sent from preSaleAddress to mint 
     * amount of tokens given that they meet the following requirements:
     * - pre sale is active
     * - they should not have minted the maximum amount of tokens that can be minted per address
     * - their mint amount should not exceed the maximum amount of tokens that can be minted in general
     * - they should have sent the correct ether amount for minting their amount of tokens
     *
     * @param amount the amount of tokens to mint
     */
    function preSaleMint(uint256 amount, bytes32[] calldata proof) external payable whenPreStarted { 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, preSaleMerkleRoot, leaf), "INVALID PROOF");
        
        if (block.timestamp < preSaleOpen + preSaleRaiseLimit) {
            require(mintsPerAddress[_msgSender()].add(amount) <= MINTS_PER_USER, "MINT AMOUNT TOO HIGH");
        } else {
            require(mintsPerAddress[_msgSender()].add(amount) <= MINTS_PER_USER_RAISED, "MINT AMOUNT TOO HIGH");
        }

        require(minted.add(amount) <= MAX_SUPPLY, "MAX TOKENS MINTED");
        require(msg.value == MINT_PRICE.mul(amount), "ETHER SENT NOT CORRECT");

        mintsPerAddress[_msgSender()] = mintsPerAddress[_msgSender()].add(amount);
        minted = minted.add(amount);
        nft.mintTo(amount, _msgSender());
    }

    function preSaleMintCustomLimit(uint256 amount, bytes32[] calldata proof) external payable whenPreStarted {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, customLimitMerkleRoot, leaf), "INVALID PROOF");
        
        require(mintsPerAddress[_msgSender()] == 0, "ALREADY MINTED");

        require(minted.add(amount) <= MAX_SUPPLY, "MAX TOKENS MINTED");
        require(msg.value == MINT_PRICE.mul(amount), "ETHER SENT NOT CORRECT");

        mintsPerAddress[_msgSender()] = mintsPerAddress[_msgSender()].add(amount);
        minted = minted.add(amount);
        nft.mintTo(amount, _msgSender());
    }
    

    /**
     * @dev allows the owner of the sales contract or the owner
     * of the NFT to burn their NFT.
     */
    function burn(uint256 tokenId) external onlyOwner {
        nft.burn(tokenId);
    }

    /**
     * @dev Allows the owner to withdraw ether
     */
    //function withdrawEth() external onlyOwner {
     //   (bool success, ) = msg.sender.call{value: address(this).balance}("");
    //    require(success, "ETH Transfer failed");
    //}

    /**
     * @dev pays the addresses in the recipients array
     * the amount of ether proportional to their
     * value in the percentages array.
     */
    function payRecipients() external onlyOwner {
        require(recipients.length > 0, "NO RECIPIENTS");
        uint256 toDistribute = address(this).balance;
        for (uint i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(toDistribute.mul(percentages[i]).div(1000));
        }
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

}