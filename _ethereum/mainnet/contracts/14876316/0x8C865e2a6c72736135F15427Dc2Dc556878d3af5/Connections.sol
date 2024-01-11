pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC721A.sol";

//   THIS IS A                                        
//   ██████╗  █████╗ ███████╗███████╗ ██████╗ ██╗  ██╗
//   ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝ ██║  ██║
//   ██████╔╝███████║███████╗█████╗  ███████╗ ███████║
//   ██╔══██╗██╔══██║╚════██║██╔══╝  ██╔═══██╗╚════██║
//   ██████╔╝██║  ██║███████║███████╗╚██████╔╝     ██║
//   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝      ╚═╝
//                                          PRODUCTION 
//                                  http://base64.tech
contract Connections is ERC721A, Ownable {
   
    uint256 constant public MAX_SUPPLY = 1000;
    uint256 constant public MAX_MINTS_PER_WALLET = 2;
    
    bool public mintIsActive = false;

    mapping(uint256 => bytes32) public mintIndexToHash;
    mapping(address => uint256) public walletToMintCount;

    event tokenIndexHash(uint256 indexed mintIndex, bytes32 indexed tokenHash);    

    string private _tokenBaseURI;

    constructor() ERC721A("Connections", "CONNECTIONS") {
    }
    
    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }
    
    function ownerMint(uint256 numberOfTokens) public onlyOwner {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Not enough tokens left to mint this many");
        uint256 mintIndex = totalSupply();

        for (uint256 i = 0; i < numberOfTokens; i++) {
            setMintIndexToHash(mintIndex);
            mintIndex++;
        }
        _mint(msg.sender, numberOfTokens, "", false);
    }

    function ownerMintToAddress(address _recipient, uint256 numberOfTokens)
        external
        onlyOwner
    {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Not enough tokens left to mint this many");
              uint256 mintIndex = totalSupply();

        for (uint256 i = 0; i < numberOfTokens; i++) {
            setMintIndexToHash(mintIndex);
            mintIndex++;
        }
        _mint(_recipient, numberOfTokens, "", false);
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

    function mint() public {
        require(mintIsActive, "Mint is not active.");
        require(totalSupply() + 1 <= MAX_SUPPLY, "No tokens left to mint");
        require(walletToMintCount[msg.sender] < MAX_MINTS_PER_WALLET, "You have already minted max number of free mints");
       
        walletToMintCount[msg.sender] += 2;
        uint256 mintIndex = totalSupply();
        for (uint256 i = 0; i < 2; i++) {
            setMintIndexToHash(mintIndex);
            mintIndex++;
        }
        _mint(msg.sender, 2, "", false);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      
        string memory base = _tokenBaseURI;
        return string(abi.encodePacked(base,Strings.toString(tokenId), ".json"));
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

}
