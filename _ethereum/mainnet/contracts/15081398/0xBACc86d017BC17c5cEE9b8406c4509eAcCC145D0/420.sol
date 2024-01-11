//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract FourTwenty is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public MAX_PRESALE = 200;
    uint256 public maxSupply = 420;

    uint256 public currentSupply = 0;

    uint256 public salePrice = 0.1 ether;
    uint256 public presalePrice = 0.08 ether;

    uint256 public presaleCount;

    //Placeholders
    address private presaleAddress = address(0xdB57294776753479405a6a8aee1f929bdB1F138e);
    address private wallet = address(0x17Ed15ea125055E0234a0022F05a1d942D489877);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmVpY3epUosqxpUggzvVPZ3tWnL97MHGF3TXMi5HYo69cx";

    bool public revealed = false;
    bool public baseLocked = false;
    bool public marketOpened = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        Paused,
        Reveal
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public presaleMintLog;

    constructor()
        ERC721("420", "WEEDS")
    {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        
        payable( wallet ).transfer( _balance );
    }

    //GETTERS
    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function validateSignature( address _addr, bytes memory _s ) internal view returns (bool){
        bytes32 messageHash = keccak256(
            abi.encodePacked( address(this), msg.sender)
        );

        address signer = messageHash.toEthSignedMessageHash().recover(_s);

        if( _addr == signer ) {
            return true;
        } else {
            return false;
        }
    }

    //Batch minting
    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {

        for (uint256 i = 0; i < number; i++) {
            _safeMint(to, baseId + i);
        }

    }

    function presaleMint(
        uint256 amount,
        bytes calldata signature
    ) external payable {
        
        require(
            workflow == WorkflowStatus.Presale,
            "420: Presale is not currently active."
        );

        require(
            validateSignature(
                presaleAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        require(amount > 0, "You must mint at least one token");

        //Price check
        require(
            msg.value >= presalePrice * amount,
            "420: Insuficient ETH amount sent."
        );
        
        require(
            presaleCount + amount <= MAX_PRESALE,
            "420: Selected amount exceeds the max presale supply"
        );

        presaleCount += amount;
        currentSupply += amount;
        presaleMintLog[ msg.sender ] += amount;

        mintBatch(msg.sender, currentSupply - amount, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require( amount > 0, "You must mint at least one NFT.");
        
        uint256 supply = currentSupply;

        require( supply < maxSupply, "420: Sold out!" );
        require( supply + amount <= maxSupply, "420: Selected amount exceeds the max supply.");

        require(
            workflow == WorkflowStatus.Sale,
            "420: Public sale has not active."
        );

        require(
            msg.value >= salePrice * amount,
            "420: Insuficient ETH amount sent."
        );

        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function forceMint(uint256 number, address receiver) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "420: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch( receiver, supply, number);
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "420: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(
            supply + addresses.length <= maxSupply,
            "420: You can't mint more than max supply"
        );

        currentSupply += addresses.length;

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], supply + i);
        }
    }

    function setUpBefore() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    function setMaxPresale( uint256 _amount ) external onlyOwner {
        MAX_PRESALE = _amount;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require( baseLocked == false, "Base URI change has been disabled permanently");

        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        salePrice = _newPrice;
    }
    
    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
    }

    //Once opened, it can not be closed again
    function openMarket() public onlyOwner {
        marketOpened = true;
    }

    // FACTORY
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),'.json'))
                : "";
    }

}