//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Withdrawable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Beatsu is ERC721A, VRFConsumerBaseV2, Ownable, Withdrawable {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab; //(RINKEBY)
    address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; //(RINKEBY)
    bytes32 internal keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc; //(RINKEBY)
    uint32 callbackGasLimit = 50000;
    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    // Get a subscription ID from https://vrf.chain.link/ to use in the constructor during deployment
    uint64 s_subscriptionId;

    enum SaleState {
        Disabled,
        PreSale,
        WhitelistSale,
        PublicSale
    }
    SaleState public saleState = SaleState.Disabled;

    bool public revealEnabled;
    bool public transfersEnabled;
    bool public revealAll;

    uint256[5] public whitelistPrices;

    uint256 public preSalePrice;
    uint256 public preSaleAmount;
    uint256 public preSaleSupplyLeft;
    uint256 public publicPrice;
    uint256 public totalSupplyLeft;
    uint256 public maximumPresaleMintPerWallet;
    uint256 public maximumWhitelistMintPerWallet;
    uint256 public random;

    // Merkle root
    bytes32 public root;

    // The unRevealedUri that new mints use when all are not revealed
    string public unRevealUri;
    // The reveal uri used once a token is revealed or all are revealed
    string public revealUri;

    // Tracks how many tokens a wallet has minted
    mapping(address => uint256) public walletPresaleMintedCount;
    mapping(address => uint256) public walletWhitelistMintedCount;

    // Tracks which tokens have been revealed
    mapping(uint256 => bool) public revealedTokens;

    // Revealed event is triggered whenever a user reveals a token, address is indexed to make it filterable
    event Revealed(address indexed user, uint256 tokenId, uint256 timestamp);
    event SaleStateChanged(uint256 previousState, uint256 nextState, uint256 timestamp);

    constructor(uint64 subscriptionId) ERC721A("Beatsu", "BEAT") VRFConsumerBaseV2(vrfCoordinator) {
        //Chainlink
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_subscriptionId = subscriptionId;
        
        //Defaults
        totalSupplyLeft = 9001; //the initial supply
        revealEnabled = false;
        transfersEnabled = false;
        revealAll = false;

        whitelistPrices = [80000000000000000, 75000000000000000, 70000000000000000, 65000000000000000, 60000000000000000];
        preSalePrice = 50000000000000000;
        publicPrice = 80000000000000000;
        preSaleSupplyLeft = 1000;
        maximumPresaleMintPerWallet = 5;
        maximumWhitelistMintPerWallet = 5;
        preSaleAmount = 5;   
    }

    modifier whenSaleIsActive() {
        require(saleState != SaleState.Disabled, "Sale is not active");
        _;
    }
    modifier whenRevealIsEnabled() {
        require(revealEnabled, "Reveal is not yet enabled");
        _;
    }
    // Check if the whitelist is enabled and the address is part of the whitelist
    modifier isWhitelisted(
        address _address,
        uint256 amount,
        bytes32[] calldata proof
    ) {
        require(
            saleState == SaleState.PublicSale || _verify(_leaf(_address), proof),
            "This address is not whitelisted or has reached maximum mints"
        );
        _;
    }

    //++++++++
    // Public functions
    //++++++++

    // Payable mint function for unrevealed NFTs
    function mint(uint256 amount, bytes32[] calldata proof) external payable whenSaleIsActive isWhitelisted(msg.sender, amount, proof) {
        require(amount <= totalSupplyLeft, "Minting would exceed cap");
        //presale
        if (saleState == SaleState.PreSale) {
            require(amount == preSaleAmount, "Presale must mint a specific amount");
            require(preSalePrice * amount <= msg.value, "Value sent is not correct");
            require(amount <= preSaleSupplyLeft, "There are not enough left for presale");
            require(walletPresaleMintedCount[msg.sender] + amount <= maximumPresaleMintPerWallet, "This wallet has reached the maximum presale mints.");
            preSaleSupplyLeft -= amount;
            walletPresaleMintedCount[msg.sender] += amount;
        }
        //whitelist
        else if (saleState == SaleState.WhitelistSale) {
            require(whitelistPrices[amount - 1] * amount <= msg.value, "Value sent is not correct");
            require(walletWhitelistMintedCount[msg.sender] + amount <= maximumWhitelistMintPerWallet, "This wallet has reached the maximum whitelist mints.");
            walletWhitelistMintedCount[msg.sender] += amount;
        }
        //public
        else if (saleState == SaleState.PublicSale) {
            require(publicPrice * amount <= msg.value, "Value sent is not correct");
        }
        totalSupplyLeft -= amount;
        _safeMint(msg.sender, amount);
    }

    // Reveal the NFT by token owner
    function reveal(uint256 itemId) public whenRevealIsEnabled {
        require(revealAll == false, "All NFTs have already been revealed");
        require(_exists(itemId), "Cannot reveal an NFT that doesn't exist");
        require(ownerOf(itemId) == msg.sender, "Cannot reveal an NFT that you don't own");
        require(revealedTokens[itemId] == false, "Cannot reveal an NFT that has already been revealed");
        revealedTokens[itemId] = true;
        // Reveal event
        emit Revealed(msg.sender, itemId, block.timestamp);
    }

    //++++++++
    // Owner functions
    //++++++++
    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    // Sale functions
    function setSaleState(uint256 _state) external onlyOwner {
        uint256 prevState = uint256(saleState);
        saleState = SaleState(_state);
        emit SaleStateChanged(prevState, _state, block.timestamp);
    }

    function setPresaleAmount(uint256 _amount) external onlyOwner {
        preSaleAmount = _amount;
    }

    function setPreSaleMintPrice(uint256 _mintPrice) external onlyOwner {
        preSalePrice = _mintPrice;
    }

    function setWhitelistMintPrices(uint256[5] memory _mintPrices) external onlyOwner {
        whitelistPrices = _mintPrices;
    }

    function setPublicMintPrice(uint256 _mintPrice) external onlyOwner {
        publicPrice = _mintPrice;
    }

    // Reveal functions
    function toggleRevealState() external onlyOwner {
        revealEnabled = !revealEnabled;
    }

    // Get random for revealed NFTs
    function GetRandom() external onlyOwner {
        require(random == 0, "Random has already been set");
        COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, 1);
    }

    // Change the reveal URI set for new mints, this should be a path to all jsons
    function setRevealUri(string calldata uri) external onlyOwner {
        revealUri = uri;
    }

    // Change the unreveled URI set for new mints, this should be a uri pointing to the unrevealed metadata json
    function setUnRevealUri(string calldata uri) external onlyOwner {
        unRevealUri = uri;
    }

    // Change the maximum mint that a single wallet can do for pre-sale
    function setMaximumPresaleMint(uint256 amount) external onlyOwner {
        maximumPresaleMintPerWallet = amount;
    }
    // Change the maximum mint that a single wallet can do for whitelist
    function setMaximumWhitelistMint(uint256 amount) external onlyOwner {
        maximumWhitelistMintPerWallet = amount;
    }

    // Un-paid mint function for community giveaways
    function mintForCommunity(address to, uint256 amount) external onlyOwner {
        require(amount <= totalSupplyLeft, "Minting would exceed cap");
        require(to != address(0), "Cannot mint to zero address");
        totalSupplyLeft -= amount;
        _safeMint(to, amount);
    }

    function toggleTrasfers() external onlyOwner {
        transfersEnabled = !transfersEnabled;
    }

    function toggleRevealAll() external onlyOwner {
        revealAll = !revealAll;
    }

    //++++++++
    // Internal functions
    //++++++++
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        random = randomWords[0];
    }

    //++++++++
    // Override functions
    //++++++++
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(tokenId < (totalSupplyLeft + totalSupply()), "This token is greater than maxSupply");

        if (revealedTokens[tokenId] == true || revealAll == true) {
            return string(abi.encodePacked(revealUri, Strings.toString((tokenId + random) % (totalSupplyLeft + totalSupply())), ".json"));
        } else {
            return unRevealUri;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(transfersEnabled, "Transfers are currently disabled");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(transfersEnabled, "Transfers are currently disabled");
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}
