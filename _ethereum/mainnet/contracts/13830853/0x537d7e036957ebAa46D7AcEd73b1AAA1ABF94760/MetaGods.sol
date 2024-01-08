//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
    Copyrights Paladins-Tech
    All rights reserved
    For any commercial use contact us at paladins-tech.eth
 */

import "./ERC1155.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./ECDSA.sol";


contract MetaGods is ERC1155, PaymentSplitter, Ownable {
    string public name = "MetaGods";

    address[] private team_ = [
        0xcCb92E42DAD7cE7E5D9c5B9cabeb1fD6b29fF3b8,
        0xbd1A43403E7E1Aa8DF3BCa2C644b2fC9AA31d068,
        0x0EA9bc05B10835fE48571198E5607BABD5D49989,
        0x1e53780f4F0784B8AA75836Cf763Ff6Bf1535aFd,
        0xC8089c3Ef9bfeF61FaBe588cB2fb54CD7362bbFb,
        0x052C91C406F57Ce8F3fa13338305Ef6e79f35Bf4,
        0xd1E534925CE149a6Ab6343b6Db1d4F8D603be576
    ];
    uint256[] private teamShares_ = [190, 30, 65, 310, 65, 310, 30];

    using Strings for uint256;
    using ECDSA for bytes32;

    //Change and check every value here
    uint256 private constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_SELF_MINT = 3;
    uint256 public constant TEAM_RESERVE = 30;
    uint256 public constant MAX_GIFT = 293;

    //Can be changed to a constant if the price WILL NOT be modified
    uint256 private publicSalePrice = 0.12 ether;

    //Placeholder
    address private presaleAddress = 0xA733610B578833fbAAa4aFe53656eB82BB997545;
    address private giftAddress = 0xb178bBBa6aDe328607Df6D8d897F0C30c836798e;

    uint256 currentSupply;
    uint256 currentGift;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public godsMinted = false;

    bool private teamReserved;


    enum WorkflowStatus {
        Before,
        Raffle,
        Sale,
        SoldOut,
        Paused
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWallet;
    mapping(address => bool) public premintClaimed;

    constructor(string memory _baseUri)
        ERC1155(_baseUri)
        PaymentSplitter(team_, teamShares_)
    {
        workflow = WorkflowStatus.Before;
    }

    //GETTERS

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function getSalePrice() public view returns (uint256) {
        return publicSalePrice;
    }

    //END GETTERS

    //SIGNATURE VERIFICATION

    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            referenceAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(uint256 number, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(number, sender));
    }

    //END SIGNATURE VERIFICATION

    //HELPER FUNCTIONS

    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {

        for (uint256 i = 0; i < number; i++) {
            _mint(to, baseId + i, 1, new bytes(0));
        }
    }

    //END HELPER FUNCTIONS

    //MINT FUNCTIONS

    /**
        Claims tokens for free paying only gas fees
     */
    function preMint(uint256 number, bytes calldata signature) external {
        uint256 supply = currentGift;
        require(
            verifyAddressSigner(
                giftAddress,
                hashMessage(number, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            premintClaimed[msg.sender] == false,
            "MetaGods: You already claimed your premint NFTs."
        );
        require(supply + number <= MAX_GIFT, "MetaGods: Mint too large");

        premintClaimed[msg.sender] = true;
        currentSupply += number;
        currentGift+= number;

        mintBatch(msg.sender, currentSupply - number, number);
    }

    /**
        Mints reserve for the team. Only callable once. Amount fixed.
     */
    function teamReserve() external onlyOwner {
        require(teamReserved == false, "MetaGods: Team already reserved");
        uint256 supply = currentGift;
        require(
            supply + TEAM_RESERVE <= MAX_SUPPLY,
            "MetaGods: Mint too large"
        );

        teamReserved = true;
        currentSupply += TEAM_RESERVE;

        mintBatch(msg.sender, currentSupply - TEAM_RESERVE, TEAM_RESERVE);
    }

    function raffleMint(uint256 max, uint256 amount, bytes calldata signature) external payable {
        require(amount > 0, "You must mint at least one NFT.");
        require(
            verifyAddressSigner(
                presaleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        uint256 supply = currentSupply;
        require(supply + amount <= MAX_SUPPLY, "MetaGods: Sold out!");
        require(
            workflow == WorkflowStatus.Raffle,
            "MetaGods: raffle not started."
        );
        require(
            msg.value >= publicSalePrice * amount,
            "MetaGods: Insuficient funds"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= MAX_SELF_MINT,
            "MetaGods: You can't mint more than 3 NFTs!"
        );

        tokensPerWallet[msg.sender] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require(amount > 0, "You must mint at least one NFT.");
        uint256 supply = currentSupply;
        require(supply + amount <= MAX_SUPPLY, "MetaGods: Sold out!");
        require(
            workflow == WorkflowStatus.Sale,
            "MetaGods: public sale not started."
        );
        require(
            msg.value >= publicSalePrice * amount,
            "MetaGods: Insuficient funds"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= MAX_SELF_MINT,
            "MetaGods: You can't mint more than 3 NFTs!"
        );

        tokensPerWallet[msg.sender] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function forceMint(uint256 number) external onlyOwner {
        uint256 supply = currentGift;
        require(
            supply + number <= MAX_GIFT,
            "MetaGods: You can't mint more than max supply"
        );

        currentSupply += number;
        currentGift+= number;

        mintBatch(msg.sender, currentSupply - number, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentGift;
        require(addresses.length + supply <= MAX_GIFT, "MetaGods: You can't airdrop more than max gift");
        uint256 baseId = currentSupply;
        currentSupply += addresses.length;

        for(uint256 i = 0; i < addresses.length; i++){

            _mint(addresses[i], baseId + i, 1, new bytes(0));
            
        }

    }

    function mintGods() external onlyOwner {
        require(godsMinted == false, "Gods are already minted");
        uint256 supply = currentSupply;
        currentSupply += 7;
        godsMinted = true;

        mintBatch(msg.sender, supply, 7);
    }

    // END MINT FUNCTIONS

    function setUpRaffle() external onlyOwner {
        workflow = WorkflowStatus.Raffle;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    /**
        Automatic reveal is too dangerous : manual reveal is better. It allows much more flexibility and is the reveal is still instantaneous.
        Note that images on OpenSea will take a little bit of time to update. This is OpenSea responsability, it has nothing to do with the contract.    
     */
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setGiftAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        giftAddress = _newAddress;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        publicSalePrice = _newPrice;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!revealed) {
            return notRevealedUri;
        } else {
            return baseURI;
        }
    }
}
