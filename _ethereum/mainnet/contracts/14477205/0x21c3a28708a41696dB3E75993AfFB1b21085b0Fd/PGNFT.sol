// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// Importing relevant libraries
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract PGNFT is ERC721, Ownable {
    // Instantiating relevant utility lib
    using Strings for uint256;
    using SafeMath for uint8;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Properties
    uint256 mintPrice;
    uint16 mintLimit;
    string _chosenUri;

    // Dev Wallet
    address payable devWallet;

    // Counter to ID NFTs
    Counters.Counter private _tokeIdTracker;

    // Constructing the contract in the blockchain
    constructor() ERC721("Panda Gang NFT", "PGNFT") {
        // Sets the initial mint price to 0.01ETH and developer wallet
        mintPrice = 0.01 ether;
        mintLimit = 8888;
        devWallet = payable(0xf21df340812629D44264474d478be0215Ea60eb6);
    }

    //Set BaseURI Method
    function setBaseUri(string memory _baseUri) public onlyOwner {
        _chosenUri = _baseUri;
    }

    // Returns the token URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_chosenUri, Strings.toString(tokenId), ".json")
            );
    }

    // Overrides current BaseUri to show PGNFTs
    function _baseURI() internal view virtual override returns (string memory) {
        return _chosenUri;
    }

    // Public Mint Function
    function mint(uint256 _amount) public payable {
        // Limits the TokenID
        require(
            (_tokeIdTracker.current().add(_amount)) < mintLimit,
            "Current Mint Limit Reached. Try minting less."
        );

        // Checks mintPrice is paid
        require(msg.value >= (mintPrice.mul(_amount)), "Insufficient Amount.");

        // Runs a while loop to continue minting for the set amount asked.
        for (uint8 counter = 0; counter < _amount; counter++) {
            // Mints the NFT to the current tokenID and adds one
            super._mint(msg.sender, _tokeIdTracker.current());
            _tokeIdTracker.increment();
        }
    }

    // Allows for PGNFT Owner to set mintPrice in ETH
    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price * 1 ether;
    }

    function viewPrice() public view returns (uint256) {
        return mintPrice;
    }

    // Method allows minting for the team members and giveaways
    function teamMint(address _to) public onlyOwner {
        // Mints the NFT and adds one to tokenID
        super._mint(_to, _tokeIdTracker.current());
        _tokeIdTracker.increment();
    }

    function withdraw() public onlyOwner {
        // Requires that the balance is more than 0ETH
        require(address(this).balance > 0 ether);
        uint256 _balance = address(this).balance;
        devWallet.transfer(_balance.div(9));
        uint256 _newBalance = address(this).balance;
        payable(msg.sender).transfer(_newBalance);
    }

    // Method for checking current total supply
    function totalSupply() public view returns (uint256) {
        return _tokeIdTracker.current();
    }
}
