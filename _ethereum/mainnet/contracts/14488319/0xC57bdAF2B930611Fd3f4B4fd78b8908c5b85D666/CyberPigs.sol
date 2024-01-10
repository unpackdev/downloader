pragma solidity >=0.8.2;

// to enable certain compiler features

import "./ERC721.sol";
import "./Ownable.sol";

contract CyberPigs is ERC721, Ownable {
    using Strings for uint256;

    //amount of tokens that have been minted so far, in total and in presale
    uint256 private numberOfTotalTokens;

    //declares the maximum amount of tokens that can be minted, total and in presale
    uint256 private maxTotalTokens;

    //initial part of the URI for the metadata
    string private _currentBaseURI = "https://api.cyberpigs.io/api/metadata/";

    //marks the timestamp of when the respective sales open
    uint256 internal presaleLaunchTime;
    uint256 internal publicSaleLaunchTime;
    uint256 internal revealTime;

    uint256 private reservedMints_;
    uint256 private maxReservedMints = 500;

    //if breeding is open or not
    bool private breeding;

    //stores how many breeds each nft has done
    mapping(uint256 => uint256) private breedsPerToken;

    uint256 private maxBreeds = 5;

    uint256 private mintCostPresale = 0.1 ether;
    uint256 private mintCostPublicSale = 0.15 ether;

    uint256 private breedCost_ = 0.1 ether;

    //amount of mints that each address has executed
    mapping(address => uint256) public mintsPerAddress;

    //current state os sale
    enum State {
        NoSale,
        Presale,
        PublicSale
    }

    //defines the uri for when the NFTs have not been yet revealed
    string public unrevealedURI;

    //tokens that have been created from breeding
    uint256 private tokensBreeded;

    //funds from each category
    uint256 private fundsMint;
    uint256 private fundsBreed;

    address private _withdrawAddress =
        0xC91deCE250A0d55CE5febAC6f9951c0c76D3e99f;

    //declaring initial values for variables
    constructor() ERC721("CyberPigs", "PIGLET") {
        maxTotalTokens = 10000;

        unrevealedURI = "https://api.cyberpigs.io/api/unrevealed/";
    }

    //in case somebody accidentaly sends funds or transaction to contract
    receive() external payable {}

    fallback() external payable {
        revert();
    }

    //visualize baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    //change baseURI in case needed for IPFS
    function changeBaseURI(string memory baseURI_) public onlyOwner {
        _currentBaseURI = baseURI_;
    }

    function changeUnrevealedURI(string memory unrevealedURI_)
        public
        onlyOwner
    {
        unrevealedURI = unrevealedURI_;
    }

    //change withdraw funds address
    function changeWithdrawAddress(address newAddress) public onlyOwner {
        _withdrawAddress = newAddress;
    }

    //gets withdraw funds address
    function getWithdrawAddress() public view onlyOwner returns (address) {
        require(
            address(_withdrawAddress) != address(0),
            "Withdraw address is not set yet."
        );

        return _withdrawAddress;
    }

    //gets the tokenID of NFT to be minted
    function tokenId() internal view returns (uint256) {
        uint256 currentId = numberOfTotalTokens;
        bool exists = true;
        while (exists) {
            currentId += 1;
            exists = _exists(currentId);
        }

        return currentId;
    }

    function switchToPresale() public onlyOwner {
        require(saleState() == State.NoSale, "Sale is already Open!");
        presaleLaunchTime = block.timestamp;
    }

    function switchToPublicSale() public onlyOwner {
        require(saleState() == State.Presale, "Sale is already Open!");
        publicSaleLaunchTime = block.timestamp;
    }

    //mint a @param number of NFTs in presale
    function presaleMint(uint256 number) public payable {
        State saleState_ = saleState();
        require(saleState_ == State.Presale, "Presale in not open!");
        require(
            numberOfTotalTokens + number <=
                maxTotalTokens - (maxReservedMints - reservedMints_),
            "Not enough NFTs left to mint.."
        );

        require(
            msg.value >= mintCost() * number,
            "Not sufficient Ether to mint this amount of NFTs"
        );

        for (uint256 i = 0; i < number; i++) {
            uint256 tid = tokenId();
            _safeMint(msg.sender, tid);
            mintsPerAddress[msg.sender] += 1;
            numberOfTotalTokens += 1;
        }

        fundsMint += msg.value;
    }

    //mint a @param number of NFTs in presale
    function publicSaleMint(uint256 number) public payable {
        State saleState_ = saleState();
        require(saleState_ == State.PublicSale, "Sale in not open!");
        require(
            numberOfTotalTokens + number <=
                maxTotalTokens - (maxReservedMints - reservedMints_),
            "Not enough NFTs left to mint.."
        );

        require(
            msg.value >= mintCost() * number,
            "Not sufficient Ether to mint this amount of NFTs"
        );

        for (uint256 i = 0; i < number; i++) {
            uint256 tid = tokenId();
            _safeMint(msg.sender, tid);
            mintsPerAddress[msg.sender] += 1;
            numberOfTotalTokens += 1;
        }

        fundsMint += msg.value;
    }

    //reserved NFTs for creator
    function reservedMint(uint256 number, address recipient) public onlyOwner {
        require(
            reservedMints_ + number <= maxReservedMints,
            "Not enough Reserved NFTs left to mint.."
        );

        for (uint256 i = 0; i < number; i++) {
            uint256 tid = tokenId();
            _safeMint(recipient, tid);
            mintsPerAddress[recipient] += 1;
            numberOfTotalTokens += 1;
            reservedMints_ += 1;
        }
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

        //check to see that 24 hours have passed since beginning of publicsale launch
        if (revealTime == 0) {
            return
                string(
                    abi.encodePacked(
                        unrevealedURI,
                        tokenId_.toString(),
                        ".json"
                    )
                );
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

    //burn the tokens that have not been sold yet
    function burnTokens() public onlyOwner {
        maxTotalTokens =
            numberOfTotalTokens +
            (maxReservedMints - reservedMints_);
    }

    //se the current account balance
    function accountBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    //retrieve all funds recieved from minting
    function withdrawMint() public onlyOwner {
        require(
            address(_withdrawAddress) != address(0),
            "Withdraw address is not set yet."
        );
        require(fundsMint > 0, "No Funds to withdraw, Mint Balance is 0");

        _withdraw(payable(_withdrawAddress), fundsMint); //to avoid dust eth
        fundsMint = 0;
    }

    //retrieve all funds recieved from minting
    function withdrawBreed() public onlyOwner {
        require(
            address(_withdrawAddress) != address(0),
            "Withdraw address is not set yet."
        );

        require(fundsBreed > 0, "No Funds to withdraw, Breed Balance is 0");

        _withdraw(payable(_withdrawAddress), fundsBreed); //to avoid dust eth
        fundsBreed = 0;
    }

    //retrieve all funds
    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Incorrect amount");

        payable(0x653E79D37c39e98977f87a6131b8de456ee396D8).transfer(amount);

        fundsBreed = 0;
        fundsMint = 0;
    }

    //send the percentage of funds to a shareholder´s wallet
    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    //see the total amount of tokens that have been minted
    function totalSupply() public view returns (uint256) {
        return numberOfTotalTokens + tokensBreeded;
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

    //to reveal the nfts
    function reveal() public onlyOwner {
        require(
            revealTime == 0,
            "Can only reveal when current state is unrevealed!"
        );
        revealTime = block.timestamp;
    }

    //shows total amount of tokens that could be minted
    function maxTokens() public view returns (uint256) {
        return maxTotalTokens;
    }

    function breed(uint256 tokenIdParent1, uint256 tokenIdParent2)
        public
        payable
    {
        require(breeding, "Breeding is currently not Open!");
        require(
            msg.sender == ownerOf(tokenIdParent1) &&
                msg.sender == ownerOf(tokenIdParent2),
            "Not the owner of this Token!"
        );
        require(msg.value >= breedCost(), "Insufficient Eth sent to breed!");
        require(
            breedsPerToken[tokenIdParent1] < maxBreeds &&
                breedsPerToken[tokenIdParent2] < maxBreeds,
            "Token has reached max breeds!"
        );

        _safeMint(msg.sender, maxTotalTokens + tokensBreeded + 1);
        breedsPerToken[tokenIdParent1] += 1;
        breedsPerToken[tokenIdParent2] += 1;
        tokensBreeded += 1;
        fundsBreed += msg.value;
    }

    function toggleBreeding() public onlyOwner {
        breeding = !breeding;
    }

    function breedIsOpen() public view returns (bool) {
        return breeding;
    }

    function changeMaxBreeds(uint256 newBreeds) public onlyOwner {
        maxBreeds = newBreeds;
    }

    function breedCost() public view returns (uint256) {
        return breedCost_;
    }

    function changeBreedCost(uint256 newCost) public onlyOwner {
        breedCost_ = newCost;
    }

    function mintCost() public view returns (uint256) {
        State saleState_ = saleState();
        if (saleState_ == State.NoSale || saleState_ == State.Presale) {
            return mintCostPresale;
        } else {
            return mintCostPublicSale;
        }
    }
}
