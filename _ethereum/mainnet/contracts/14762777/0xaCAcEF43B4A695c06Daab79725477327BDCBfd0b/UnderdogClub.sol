pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";

contract UnderdogClub is ERC721A, Ownable {
    using Strings for uint256;

    //declares the maximum amount of tokens that can be minted, total and in presale
    uint256 private maxTotalTokens;

    //initial part of the URI for the metadata
    string private currentBaseURI;
    //defines the uri for when the NFTs have not been yet revealed
    string public unrevealedURI;

    //cost of mints depending on state of sale
    uint256 private mintCostPresale = 1 ether;
    uint256 private mintCostPublicSale = 2 ether;

    //maximum amount of mints allowed per person
    uint256 public maxMintPresale = 4;
    uint256 public maxMintPublicSale = 2;

    //the amount of reserved mints that have currently been executed by creator and giveaways
    uint256 private reservedMints;

    //the maximum amount of reserved mints allowed for creator and giveaways
    uint256 private maxReservedMints = 50;

    //dummy address that we use to sign the mint transaction to make sure it is valid
    address private signerAddress = 0xd4889EEfD61F328B53aC8999E13019a5e6D031da;

    //marks the timestamp of when the respective sales open
    uint256 internal presaleLaunchTime;
    uint256 internal publicSaleLaunchTime;
    uint256 internal revealTime;

    //dictates if sale is paused or not
    bool private paused;

    //amount of mints that each address has executed
    mapping(address => uint256) public mintsPerAddress;

    //current state os sale
    enum State {
        NoSale,
        Presale,
        PublicSale
    }

    constructor() ERC721A("UnderdogClub", "UC") {
        maxTotalTokens = 10000;

        unrevealedURI = "ipfs://QmXEAwsfFqAx5tPUSyxToAVZFzYDFRoEWGzf94779NEk8p";
        currentBaseURI = "ipfs://QmU9wtr6RfMzhUULrFBAZJ8eNb7R4sC2CcRpWfsATHC5kH/";

        //minting 2 legendaries for the opensea sale
        reservedMint(2, msg.sender);
        mintsPerAddress[msg.sender] += 2;
        reservedMints += 2;
    }

    //in case somebody accidentaly sends funds or transaction to contract
    receive() external payable {}

    fallback() external payable {
        revert();
    }

    //visualize baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return currentBaseURI;
    }

    //change baseURI in case needed for IPFS
    function setBaseURI(string memory baseURI_) public onlyOwner {
        currentBaseURI = baseURI_;
    }

    function setUnrevealedURI(string memory unrevealedURI_) public onlyOwner {
        unrevealedURI = unrevealedURI_;
    }

    function switchToPresale() public onlyOwner {
        require(saleState() == State.NoSale, "Sale is already Open!");
        presaleLaunchTime = block.timestamp;
    }

    function switchToPublicSale() public onlyOwner {
        require(saleState() == State.Presale, "Sale must be in Presale!");
        publicSaleLaunchTime = block.timestamp;
    }

    modifier onlyValidAccess(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        require(
            isValidAccessMessage(msg.sender, _v, _r, _s),
            "Invalid Signature"
        );
        _;
    }

    function isValidAccessMessage(
        address _add,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(_add));
        return
            signerAddress ==
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                _v,
                _r,
                _s
            );
    }

    //mint a @param quantity of NFTs in presale
    function presaleMint(
        uint256 quantity,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable onlyValidAccess(_v, _r, _s) {
        require(!paused, "Sale is paused!");
        State saleState_ = saleState();
        require(saleState_ != State.NoSale, "Sale in not open yet!");
        require(
            saleState_ != State.PublicSale,
            "Presale has closed, Check out Public Sale!"
        );
        require(
            totalSupply() + quantity <=
                maxTotalTokens - (maxReservedMints - reservedMints),
            "Not enough NFTs left to mint.."
        );
        require(
            mintsPerAddress[msg.sender] + quantity <= maxMintPresale,
            "Maximum Mints per Address exceeded!"
        );
        require(
            msg.value >= mintCost() * quantity,
            "Not sufficient Ether to mint this amount of NFTs"
        );

        _safeMint(msg.sender, quantity);
        mintsPerAddress[msg.sender] += quantity;
    }

    //mint a @param quantity of NFTs in public sale
    function publicSaleMint(uint256 quantity) public payable {
        require(!paused, "Sale is paused!");
        State saleState_ = saleState();
        require(saleState_ == State.PublicSale, "Public Sale in not open yet!");
        require(
            totalSupply() + quantity <=
                maxTotalTokens - (maxReservedMints - reservedMints),
            "Not enough NFTs left to mint.."
        );
        require(
            mintsPerAddress[msg.sender] + quantity <= maxMintPublicSale,
            "Maximum Mints per Address exceeded!"
        );
        require(
            msg.value >= mintCost() * quantity,
            "Not sufficient Ether to mint this amount of NFTs"
        );

        _safeMint(msg.sender, quantity);
        mintsPerAddress[msg.sender] += quantity;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId_),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealTime == 0 && tokenId_ > 1) {
            return unrevealedURI;
        } else {
            string memory baseURI = _baseURI();
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, tokenId_.toString(), ".json")
                    )
                    : "";
        }
    }

    //reserved NFTs for creator
    function reservedMint(uint256 number, address recipient) public onlyOwner {
        require(
            reservedMints + number <= maxReservedMints,
            "Not enough Reserved NFTs left to mint.."
        );

        _safeMint(recipient, number);
        mintsPerAddress[recipient] += number;
        reservedMints += number;
    }

    //burn the tokens that have not been sold yet
    function burnTokens() public onlyOwner {
        maxTotalTokens = totalSupply();
    }

    //se the current account balance
    function accountBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    //retrieve all funds recieved from minting
    function withdraw() public onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, "No Funds to withdraw, Balance is 0");

        _withdraw(payable(0xaC4f040Aa4b4504ad0dE68e6E1e447ED958AB580), balance);
    }

    //send the percentage of funds to a shareholder´s wallet
    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    //to see the total amount of reserved mints left
    function reservedMintsLeft() public view onlyOwner returns (uint256) {
        return maxReservedMints - reservedMints;
    }

    //see current state of sale
    //see the current state of the sale
    function saleState() public view returns (State) {
        if (presaleLaunchTime == 0) {
            return State.NoSale;
        } else if (publicSaleLaunchTime == 0) {
            return State.Presale;
        } else {
            return State.PublicSale;
        }
    }

    //gets the cost of current mint
    function mintCost() public view returns (uint256) {
        State saleState_ = saleState();
        if (saleState_ == State.NoSale || saleState_ == State.Presale) {
            return mintCostPresale;
        } else {
            return mintCostPublicSale;
        }
    }

    //see when NFTs will be revealed
    function timeOfReveal() public view returns (uint256) {
        require(
            revealTime != 0,
            "NFT Reveal Time has not been determined yet!"
        );
        return revealTime;
    }

    function reveal() public onlyOwner {
        require(revealTime == 0, "Collection has already been revealed!");
        revealTime = block.timestamp;
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    //turn the pause on and off
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    //setting new prices to mint
    function setMintCostPresale(uint256 newCost) public onlyOwner {
        mintCostPresale = newCost;
    }

    function setMintCostPublicSale(uint256 newCost) public onlyOwner {
        mintCostPublicSale = newCost;
    }

    //setting the maxes for mint
    function setMaxMintPresale(uint256 newMax) public onlyOwner {
        maxMintPresale = newMax;
    }

    function setMaxMintPublicSale(uint256 newMax) public onlyOwner {
        maxMintPublicSale = newMax;
    }
}
