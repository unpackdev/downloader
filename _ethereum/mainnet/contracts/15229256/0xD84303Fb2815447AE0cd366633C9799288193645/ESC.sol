//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProof.sol";
contract ESC is ERC721A, Ownable, ReentrancyGuard {
    enum Status {
        Waiting,
        Started,
        Finished
    }
    using StringsUpgradeable for uint256;
    bool public isPublicSaleActive = false;
    uint256 public constant PUBLIC_FREE_MAX_MINT = 2;
    uint256 public constant OG_MAX_MINT = 2;
    uint256 public constant FREE_PRICE = 0;
    uint256 public PUBLIC_PRICE = 0.0077 ether;
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant FREE_PUBLIC_SUPPLY = 2500;
    uint256 public freeCounter = 0;
    uint256 public totalCounter = 0;
    bool public isOgLive = false;
    bool public isFreePublicLive = false;
    bool public isPaidPublicLive = false;
    bool public paused = true;
    bool public isRevealed = false;
    bytes32 public root;
    string private baseURI;
    string public notRevealedUri = "ipfs://QmeQfCvWxMuMtsG4sajtuPzGbXx34YXMNR5R4h9948fHRA";

    mapping(address => uint256) public addressMintedBalance;
    mapping(address => uint256) public addressMintedBalanceOG;

    event Minted(address minter, uint256 amount);

    constructor(string memory initBaseURI) ERC721A("Exclusive Shark Club", "ESC") {
        baseURI = initBaseURI;

    }
    function reveal() external onlyOwner {
        isRevealed = true;

    }
     function setNotReveal(string memory _notRevealed) external onlyOwner{
         notRevealedUri = _notRevealed;
     }
  

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function startOgSale() external onlyOwner {
        isOgLive = true;
        isFreePublicLive = false;
        isPaidPublicLive = false;
        paused = false;
    }
    function endOgSale() external onlyOwner {
        isOgLive = false;
        isFreePublicLive = true;
        isPaidPublicLive = false;

    }

    function startPaidPublicSale() internal onlyOwner {
        //This function is only called after 1.5k free tokens are minted
        isFreePublicLive = false;
        isPaidPublicLive = true;


    }
    function manualStartPaid() external onlyOwner {
        //just incase the internal function does not work.
        //This function should not be called by owner.
        isFreePublicLive = false;
        isPaidPublicLive = true;
        isOgLive = false;

    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
         if(!isRevealed){
             return notRevealedUri;
        }
        return
            string(
                abi.encodePacked(baseURI, "/", _tokenId.toString(), ".json")
            );
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
    function publicMintPaid(uint256 quantity )external payable nonReentrant {
        require(isPaidPublicLive, "There are still free mints left!");
        require(quantity <= 10, "You can only mint a maximum of 10 tokens per transaction");
        require(msg.value >= PUBLIC_PRICE * quantity, "You don't have enough ether to mint this amount of tokens");
        require(totalCounter <= MAX_SUPPLY);
        _safeMint(msg.sender, quantity);
        totalCounter = totalCounter + quantity;
    }

    function freeMintPublic(uint256 quantity ) external payable nonReentrant {
        require(!paused, "Minting is paused");
        require(quantity <= 2);
        require(isFreePublicLive, "Free public not live");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + quantity <= PUBLIC_FREE_MAX_MINT, "You have already minted the maximum amount of tokens during the free public sale");
        require(freeCounter + quantity <= FREE_PUBLIC_SUPPLY, "Free mints are sold out");
        _safeMint(msg.sender, quantity);
        totalCounter = totalCounter + quantity;
        addressMintedBalance[msg.sender] = ownerMintedCount + quantity;
         emit Minted(msg.sender, quantity);
        freeCounter = freeCounter + quantity;
        if (freeCounter >= FREE_PUBLIC_SUPPLY) {
            startPaidPublicSale();
        }
    }

    function ogMint (uint256 quantity, bytes32[] calldata _merkleProof)external payable nonReentrant{
        require(quantity <= 2);
        require(isOgLive, "OG sale is not live!");
        uint256 ownerMintedCountOg = addressMintedBalanceOG[msg.sender];
        require( ownerMintedCountOg + quantity <= OG_MAX_MINT, "Exceeded maximum amount. 2 or less per wallet");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, root, leaf), "Incorrect proof");
        _safeMint(msg.sender, quantity);
        totalCounter = totalCounter + quantity;
        addressMintedBalanceOG[msg.sender] = ownerMintedCountOg + quantity;
        emit Minted(msg.sender, quantity);
    }

    function withdraw(address payable recipient) external onlyOwner nonReentrant{
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "-Withdraw failed-");
    }
    function escAdminMint() external onlyOwner nonReentrant {
        //These mints are for the mysteryboxes, giveaways, and marketing
        _safeMint(msg.sender, 150);
        totalCounter = totalCounter + 150;
    }




}
