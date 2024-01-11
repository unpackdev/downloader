// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// Relevant Libraries
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract PetRock is ERC721, Ownable {
    // Wallets
    address payable public devWallet =
        payable(0xf21df340812629D44264474d478be0215Ea60eb6);
    address payable public founderWallet =
        payable(0xe657861C0FcE19231D34328e699ffB972E048773);
    address payable public communityWallet =
        payable(0x0b4aCc4AbcC2974Ef6500FD2A7c4890c2f51Ac0D);
    address payable public artistWallet =
        payable(0xE6c55F0FB3fD257aB367c9d9Df0F84C00a7Ae4f0);

    // Utils Used
    using Strings for uint256;
    using SafeMath for uint8;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Properties
    bool public publicSale;
    uint256 public mintPrice;
    uint16 public maxAmount;
    uint256 public mintLimit;
    string _chosenUri;
    string[] public uriList;
    bool uriSwitch;
    bytes32 public immutable root =
        0x4699f37b384f7a213e23d6cc5f786edd77db11a90c5307dcc20d218ee6dbc473;

    // Mappings
    mapping(uint256 => string) tokenChoice;
    mapping(address => bool) whitelistClaimed;

    //Modifiers

    // Modifies free mint function to add specific parameters
    modifier mintConfig() {
        _;
        //Makes sure value sent is
        // 1. under the amount needed for 4 rocks
        // 2. that at least one rock can be purchased
        require(
            publicSale == true &&
                msg.value < 0.07 ether &&
                msg.value % 0.02 ether <= 0.02 ether
        );
    }

    // Modifies whitelist free mint function to incorporate MerkleProof
    modifier whitelistConfig(bytes32[] calldata _proof) {
        _;
        // Takes MerkleProof from frontend call
        // Finds leaf by hashing sender address
        // Verifies using the MerkleProof Util
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, root, leaf),
            "Account is not whitelisted."
        );
    }

    constructor() ERC721("Pet Rock", "ROCK") {
        // Instantiates properties
        mintPrice = 0.02 ether;
        maxAmount = 1600;
        publicSale = false;
        uriSwitch = false;
    }

    Counters.Counter private _tokenIdTracker;

    // Whitelist Free Mint Function
    function freeRock(bytes32[] calldata _proof)
        public
        whitelistConfig(_proof)
    {
        // Checks whitelist has not already been claimed
        require(
            whitelistClaimed[msg.sender] == false,
            "Whitelist has already been claimed."
        );

        // Records claiming for every wallet
        whitelistClaimed[msg.sender] = true;

        // Checks that the number of free rocks is not exceeded
        require(
            (_tokenIdTracker.current().add(2)) < 800,
            "Current Free Mint limit reached."
        );

        for (uint8 counter = 0; counter < 2; counter++) {
            // 1.Mints the NFT to the current tokenID
            // 2. Maps the current tokenChoice to the current URI
            // 3. Adds one to tokenIDtracker
            super._mint(msg.sender, _tokenIdTracker.current());
            tokenChoice[_tokenIdTracker.current()] = _chosenUri;
            _tokenIdTracker.increment();
        }
    }

    // Public Mint Function
    function rock() public payable mintConfig {
        uint256 _amount = 0;
        uint256 _balance = msg.value;

        // Uses the balance sent to generate set number of NFTs
        while (_balance >= 0.02 ether) {
            _balance = _balance.sub(0.02 ether);
            _amount = _amount.add(1);
        }

        // Limits the TokenID
        require(
            (_tokenIdTracker.current().add(_amount)) <= maxAmount,
            "Current Mint Limit Reached. Try minting less."
        );

        // Runs a for loop to continue minting for the set amount asked.
        for (uint8 counter = 0; counter < _amount; counter++) {
            // 1.Mints the NFT to the current tokenID
            // 2. Maps the current tokenChoice to the current URI
            // 3. Adds one to tokenIDtracker
            super._mint(msg.sender, _tokenIdTracker.current());
            tokenChoice[_tokenIdTracker.current()] = _chosenUri;
            _tokenIdTracker.increment();
        }
    }

    // Switches sale to public
    function switchToPublic() public onlyOwner {
        bool current = publicSale;
        publicSale = !current;
    }

    // Allows for PetRock Owner to set mintPrice in ETH
    function setMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    // Set BaseURI Method
    function setBaseUri(uint256 x) public onlyOwner {
        _chosenUri = uriList[x];
    }

    // 1. Allows for Owner to add a  new URI to URI list
    // 2. Updates URI to the newest URI
    function addUri(string memory _newUri) public onlyOwner {
        uriList.push(_newUri);
        _chosenUri = _newUri;
    }

    // Toggles Uri Switch to allow for art switching
    function toggleUriSwitch() public onlyOwner {
        bool current = uriSwitch;
        uriSwitch = !current;
    }

    // Overrides current BaseUri to show chosenURI
    // Keep in mind chosenURI can be modified using the addUri & setBaseUri methods
    function _baseURI() internal view virtual override returns (string memory) {
        return _chosenUri;
    }

    // Returns the token URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // Checks whether Owner has enabled URI Switching
        if (uriSwitch) {
            // URI Switching enabled by allowing for URI mapped to token to be enabled
            return
                string(
                    abi.encodePacked(
                        tokenChoice[tokenId],
                        Strings.toString(tokenId),
                        ".json"
                    )
                );
        } else {
            return
                // TokenURI returns URI using _chosenURI set by Owner
                string(
                    abi.encodePacked(
                        _chosenUri,
                        Strings.toString(tokenId),
                        ".json"
                    )
                );
        }
    }

    //Allows token owner's to update metadata
    function updateTokenArt(uint256 x, uint256 _tokenId) public {
        require(uriSwitch, "Art switching is not yet available.");
        require(msg.sender == ownerOf(_tokenId));
        tokenChoice[_tokenId] = uriList[x];
    }

    // For withdrawal of balance and distributes it
    function withdraw() public onlyOwner {
        // Requires that the balance is more than 0ETH
        uint256 _balance = address(this).balance;
        require(_balance > 0, "Balance is 0 ETH");
        uint256 _balancePortion = _balance.div(10);

        // Divides the money accordingly
        devWallet.transfer(_balancePortion);
        founderWallet.transfer(_balancePortion.mul(2));
        communityWallet.transfer(_balancePortion.mul(3));

        // Rest of money (OR 40%) is sent to artist wallet
        uint256 _newBalance = address(this).balance;
        artistWallet.transfer(_newBalance);
    }
}
