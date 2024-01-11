// SPDX-License-Identifier: MIT

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@  @  @    @@        @@@@@@  @  @    @           @@@@@@@@@@
// @@@@@@@@@ @@@@@@@@   @@  /@@    @@            @@@   @@    @@           @@@@@@@@@
// @@@@@@@@@    @@@@    @@  @@@@   @@    @@@ @    @@@ @@@@@   @@@@@@     @@@@@@@@@@
// @@@@@@@@@@    @@    @@    @@@    @    @@@@@@   @    @@@@   @@@@    @ @@@@@@@@@@@
// @@@@@@@@@@@        @@@    @@@   @@    @@@@     @    @@@    @@    @@@@@@@@@@@@@@@
// @@@@@@@@@@@@       @@@     @    @@           @@@     @@    @            @@@@@@@@
// @@@@@@@@@@@@@@    @@@@@@@     @@@@@@   @ @@@@@@@@@*     @@@@@@          @@@@@@@@
// @@@@@@@@@@@@@@@@ @@@@@@@@  @@@@@@@@@  @@@@@@@@@@@@@@ @@ @@@@@@ @@ @@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

//Arist: ZΞΞT - https://twitter.com/ZEET_ART
//Production Studio: VUDUZ, Inc. - https://twitter.com/theVUDUZ
//Coder: Orion Solidified, Inc. - https://twitter.com/DevOrionNFTs


pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract VuduzPass is ERC721, Ownable {

    uint256 public totalSupply;
    uint256 public maxSupply;

    bool public claimingPaused;
    bool public mintingPaused;

    string internal baseTokenUri;
    string public hiddenMetadataUri;
    bool public isRevealed;

    uint256 public mintCost;
    address public withdrawWallet;

    mapping(address => uint256) public WalletMints;
    mapping(address => uint256) public DevList;

    constructor() payable ERC721('Vuduz Pass', 'VDZP') {
        totalSupply = 0;
        maxSupply = 690;

        mintingPaused = true;
        claimingPaused = true;

        setHiddenMetadataUri("https://orion.mypinata.cloud/ipfs/QmVR2sMFkv5r5VQewcjmbEepRoZxVFqroaNWSTVMQmTFVY/hidden.json");
        isRevealed = false;

        mintCost = 0 ether;
        withdrawWallet = 0x0F574D45D73F5c8F4189CCf4D98Cd22eaDFA9532;


    }

    modifier callerIsAWallet() {
        require(tx.origin ==msg.sender, "Another contract detected");
        _;
    }

    // Futureproofing Maximum Supply
    function setMaxSupply(uint256 maxSupply_) public onlyOwner() {
        maxSupply = maxSupply_;
    }

    // Futureproofing Minting Cost
    function setPrice(uint256 mintCost_) public onlyOwner() {
        mintCost = mintCost_;
    }

    //Change Wallets - Failsafe
    function changeWithdrawWallet(address withdrawWallet_) external onlyOwner {
        withdrawWallet = withdrawWallet_;
    }

    //Add Addresses for Dev Mint
    function addToDevList(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            DevList[addresses[i]] = 50;
        }
    }

    //Update Hidden Metadata URI
    function setHiddenMetadataUri(string memory hiddenMetadataUri_) public onlyOwner {
        hiddenMetadataUri = hiddenMetadataUri_;
    }

    //Token URI change - More utility is coming!
    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {

        if (isRevealed == false) {
            return hiddenMetadataUri;
            }

        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    string private customContractURI = "https://orion.mypinata.cloud/ipfs/QmfY2t8fibUV1aGW16qzRFticc2u4rWor1pLYmCPHrNoNy/metadata.json";

    function setContractURI(string memory customContractURI_) external onlyOwner {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }    

    //Vuduz Pass Free Claim
    function claim() public callerIsAWallet {
        uint256 quantity = 1;
        uint256 newTokenId = totalSupply + quantity;

        require(!claimingPaused, 'claiming is paused');
        require(totalSupply + quantity <= maxSupply, 'sold out');
        require(WalletMints[msg.sender] < quantity, 'exceed max wallet');
        
        WalletMints[msg.sender]++;
        totalSupply++;

        _safeMint(msg.sender,newTokenId);
    }

    //Vuduz Pass Future
    function mint(uint256 quantity_) public payable callerIsAWallet {

        require(!mintingPaused, 'minting is paused');
        require(msg.value >= quantity_ * mintCost, 'wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        
        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;

            WalletMints[msg.sender]++;
            totalSupply++;
            
            _safeMint(msg.sender, newTokenId);
        }
    }


    function DevListMint(uint256 quantity_) public callerIsAWallet {

        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(DevList[msg.sender] > 0, "not eligible for DevList mint");

        

        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;

            WalletMints[msg.sender]++;
            DevList[msg.sender]--;
            totalSupply++;
            
            _safeMint(msg.sender, newTokenId);
        }
    }

    function pauseClaiming() public onlyOwner {
        claimingPaused = !claimingPaused;
    }

    function pauseMinting() public onlyOwner {
        mintingPaused = !mintingPaused;
    }


    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{ value: address(this).balance }('');
        require(success, 'withdraw failed');
    }
 
}