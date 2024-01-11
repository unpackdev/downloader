//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ICandyRobbers.sol";

contract CandyRobbersMint is Ownable, PaymentSplitter, Pausable {
    using Strings for uint256;
    using ECDSA for bytes32;

    ICandyRobbers immutable candyRobbers;

    uint256 public constant price = 0.08 ether;
    uint256 public constant presalePrice = 0.069 ether;

    uint256 public maxSupply = 5000;
    uint256 public maxMintablePerTx = 5;

    address private whitelistAddress =
        0x58c7DBa0f043F5244d55D92EaA399969c59F89fA;

    uint256 public immutable saleStart;

    uint256 public minted = 0;

    bool teamReserved = false;

    bool saleEnded = false;

    mapping(address => uint256) public tokensMinted;

    address[] private team_ = [0x9e9bc682f651c99BA0d7Eeb93eE64a2AD07CE112, 0x11412a492e7ab9F672c83e9586245cE6a70E4388];
    uint256[] private teamShares_ = [97,3];

    constructor(ICandyRobbers _candyRobbers, uint256 _saleStart)
        PaymentSplitter(team_, teamShares_)
    {
        candyRobbers = _candyRobbers;
        saleStart = _saleStart;
    }

    //Change address that needs to sign message
    function setWhitelistAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        whitelistAddress = _newAddress;
    }

    //Set Max supply for this sale (different from CandyRobbers MAX_SUPPLY)
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }


    //Pause the contract in case of an emergency
    function pause() external onlyOwner {
        _pause();
    }

    //Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    //End the sale forever
    function endSale() external onlyOwner {
        saleEnded = true;
    }

    /**
     * @dev Verifies that a message has been signed by a reference address
     * @param referenceAddress The reference address
     * @param messageHash The hashed message
     * @param signature The signature of that hashed message
     */
    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            referenceAddress ==
            messageHash.toEthSignedMessageHash().recover(signature); //Recovers the signature and returns true if the referenceAddress has signed messageHash producing signature
    }

    /**
     * @dev Hash a the message needed to mint
     * @param max The maximum of amount the address is allowed to mint
     * @param sender The actual sender of the transactio 
     */
    function hashMessage(uint256 max, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(max, sender));
    }

    /**
     * @dev Performs a presaleMint (or whitelisted mint). Access to the whitelist is verified with a signed message from `whitelistAddress`
     * @
     */
    function presaleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable whenNotPaused {
        require(!saleEnded, "Sale is ended");
        require(
            saleStart > 0 && block.timestamp >= saleStart,
            "Whitelist mint is not started yet!"
        );
        require(
            tokensMinted[msg.sender] + amount <= max,
            "You can't mint more NFTs!"
        );
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                whitelistAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(minted + amount <= maxSupply, "SOLD OUT!");
        require(
            msg.value >= presalePrice * amount,
            "Insuficient funds"
        );

        tokensMinted[msg.sender] += amount;
        minted += amount;

        candyRobbers.mintTo(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable whenNotPaused {
        require(!saleEnded, "Sale is ended");
        require(
            saleStart > 0 && block.timestamp >= saleStart,
            "Public sale not started."
        );
        require(
            amount <= maxMintablePerTx,
            "Mint too large"
        );
        require(amount > 0, "You must mint at least one NFT.");
        require(minted + amount <= maxSupply, "Sold out!");
        require(
            msg.value >= price * amount,
            "Insuficient funds"
        );

        minted += amount;

        candyRobbers.mintTo(msg.sender, amount);
    }


}
