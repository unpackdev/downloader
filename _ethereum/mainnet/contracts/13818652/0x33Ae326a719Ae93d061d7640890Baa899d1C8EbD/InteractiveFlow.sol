pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

//   THIS IS A                                        
//   ██████╗  █████╗ ███████╗███████╗ ██████╗ ██╗  ██╗
//   ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝ ██║  ██║
//   ██████╔╝███████║███████╗█████╗  ███████╗ ███████║
//   ██╔══██╗██╔══██║╚════██║██╔══╝  ██╔═══██╗╚════██║
//   ██████╔╝██║  ██║███████║███████╗╚██████╔╝     ██║
//   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝      ╚═╝
//                                          PRODUCTION 
//                                  http://base64.tech
contract InteractiveFlow is ERC721Enumerable, Ownable {
   
    uint256 constant public MAX_SUPPLY = 1000;
    uint256 constant public FREE_MINT_MAX_SUPPLY = 100;
    uint256 constant public TOKEN_PRICE = 0.05 ether;
    uint256 constant public MAX_TOKENS_PURCHASE = 3;
    uint256 constant public MAX_FREE_MINTS_PER_WALLET = 1;
    uint256 constant public c3VwZXJTcGVjaWFs_MINT_MAX_SUPPLY = 4;

    address constant DOTDOTDOT_CONTRACT = 0xcE25E60A89F200B1fA40f6c313047FFe386992c3;
    address constant BRUSHSTROKES_CONTRACT = 0xc789858e3b777aa6b7B209921d9368C4E898167e;
    address constant DOJI_CONTRACT = 0x5e9dC633830Af18AA43dDB7B042646AADEDCCe81;

    bool public mintIsActive = false;
    uint256 public freeMintCount = 0;
    uint256 public c3VwZXJTcGVjaWFsMintCount = 0;
    string public animationSourceCode; 

    IERC721 public dotdotdotContract;
    IERC721 public brushstrokesContract;
    IERC721 public dojiContract;
    IERC721 public c3VwZXJTcGVjaWFsMintKeyContract;
    
    mapping(uint256 => bytes32) public mintIndexToHash;
    mapping(address => uint256) public walletToFreeMintCount;

    event tokenIndexHash(uint256 indexed mintIndex, bytes32 indexed tokenHash);    
    event c3VwZXJTcGVjaWFsIndex(uint256 indexed mintIndex); 

    string private _tokenBaseURI;


    constructor() ERC721("InteractiveFlow", "INTERACTIVEFLOW") {
        dotdotdotContract = IERC721(DOTDOTDOT_CONTRACT);
        brushstrokesContract = IERC721(BRUSHSTROKES_CONTRACT);
        dojiContract = IERC721(DOJI_CONTRACT);
    }
    
    function setAnimationSourceCode(string memory sourceCode) public onlyOwner {
        animationSourceCode = sourceCode;
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function ownerMint(uint256 numberOfTokens) public onlyOwner {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Not enough tokens left to mint this many");
        
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            setMintIndexToHash(mintIndex);
            _safeMint(msg.sender, mintIndex);
        }
    }

    function setMintIndexToHash(uint256 mintIndex) internal {
        bytes32 hash = keccak256(abi.encodePacked(block.number, block.timestamp, msg.sender, mintIndex));
        mintIndexToHash[mintIndex]=hash;
        emit tokenIndexHash(mintIndex, hash);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(uint256 numberOfTokens) public payable {
        require(mintIsActive, "Mint is not active.");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY-4+c3VwZXJTcGVjaWFsMintCount, "Not enough tokens left to mint this many");
        require(numberOfTokens <= MAX_TOKENS_PURCHASE, "You went over max tokens per transaction.");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "You sent the incorrect amount of ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            setMintIndexToHash(mintIndex);
            _safeMint(msg.sender, mintIndex);
        }
    }

    function freeMint() public {
        require(mintIsActive, "Mint is not active.");
        require(totalSupply() + 1 <= MAX_SUPPLY-4+c3VwZXJTcGVjaWFsMintCount, "No tokens left to mint");
        require(freeMintCount < FREE_MINT_MAX_SUPPLY, "No more free mints available");
        require(walletToFreeMintCount[msg.sender] < MAX_FREE_MINTS_PER_WALLET, "You have already minted max number of free mints");
        require(dotdotdotContract.balanceOf(msg.sender) > 0 || brushstrokesContract.balanceOf(msg.sender) > 0 || dojiContract.balanceOf(msg.sender) > 0, "Your wallet does not hold DotDotDots, 0xCulture Brushtrokes, or DojiCrew NFTs");

        uint256 mintIndex = totalSupply();
        setMintIndexToHash(totalSupply());
        walletToFreeMintCount[msg.sender] = walletToFreeMintCount[msg.sender] + 1;
        freeMintCount++;
        _safeMint(msg.sender, mintIndex);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      
        string memory base = _tokenBaseURI;
        return string(abi.encodePacked(base,Strings.toString(tokenId)));
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    //Rm9yIG1vcmUgaW5mb3JtYXRpb24gYWJvdXQgd2hhdCB0aGlzIGZ1bmN0aW9uIGlzIGZvciwgam9pbiB0aGUgI2ludGVyYWN0aXZlZmxvdyBjaGFubmVsIGluIG91ciBkaXNjb3JkLiBMaW5rIGZvciBkaXNjb3JkIGNhbiBiZSBmb3VuZCBoZXJlIGh0dHA6Ly9pbnRlcmFjdGl2ZWZsb3cuYmFzZTY0LnRlY2g=
    function c3VwZXJTcGVjaWFsMint() public {
        require(totalSupply() >= 250, "c3VwZXJTcGVjaWFs mint not available yet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Not enough tokens left to mint this many");
        require(c3VwZXJTcGVjaWFsMintCount < c3VwZXJTcGVjaWFs_MINT_MAX_SUPPLY, "No more c3VwZXJTcGVjaWFs mints available");
        require(c3VwZXJTcGVjaWFsMintKeyContract.ownerOf(c3VwZXJTcGVjaWFsMintCount) == msg.sender,  "Your wallet does not hold the key to performing a c3VwZXJTcGVjaWFsMint");
 
        uint256 mintIndex = totalSupply();
        c3VwZXJTcGVjaWFsMintCount++;
        _safeMint(msg.sender, mintIndex);
        emit c3VwZXJTcGVjaWFsIndex(mintIndex);
    }

    function setc3VwZXJTcGVjaWFsKeyNFTContract(address contractAddress) public onlyOwner {
        c3VwZXJTcGVjaWFsMintKeyContract = IERC721(contractAddress);
    }
}
