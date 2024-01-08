// SPDX-License-Identifier: MIT
// Mad Dog Mafia Solidity Smart Contract
pragma solidity >= 0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IBone.sol";

contract MadDogMafia is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public cost = 0.069420 ether;
    uint256 public maxMintedSupply = 10000; // we will mint 10000 Mad Dogs MAX
    uint256 public maxMintQuantity = 3;
    uint256 public maxWhiteListCount = 300;
    uint256 public whiteListCount = 0;
    bool public paused = false;
    bool public presale = true;
    bool public initialSale = true;
    mapping(address => bool) public whitelisted;

    address boneAddress;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(
        string memory initBaseURI
    ) ERC721("Mad Dog Mafia", "MDM") {
        setBaseURI(initBaseURI);
        whitelisted[msg.sender] = true;
    }

    // Internal methods
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the current $BONE cost of minting.
     */
    function currentBoneCost() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply <= 2000) return 0;
        if (_totalSupply > 2000 && _totalSupply <= 4000)
            return 2000000000000000000;
        if (_totalSupply > 4000 && _totalSupply <= 6000)
            return 4000000000000000000;
        if (_totalSupply > 6000 && _totalSupply <= 8000)
            return 6000000000000000000;
        if (_totalSupply > 8000 && _totalSupply <= 10000)
            return 8000000000000000000;

        revert();
    }

    //Public methods
    function mint(address toAddress, uint256 quantity) public payable {
        require(!paused, "Minting is currently paused!");
        require(quantity > 0, "You can't mint zero Mad Dogs!");
        require(msg.sender == owner() || quantity <= maxMintQuantity, "You can only mint 3 Mad Dogs at one time!");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxMintedSupply, "There isn't enough Mad Dogs left to mint that many!");

        require(!initialSale || (supply + quantity <= 2000), "There's not enough Mad Dogs left in the initial 2000 to mint that many.");

        // presale is only for whitelist members
        require(!presale || whitelisted[msg.sender], "We are currently in presale, which is only for whitelisted members!");

        // if you're not the owner and bone cost is still 0, check for payment amount in msg
        if (msg.sender != owner() && initialSale) {
            require(msg.value >= cost * quantity, "You have to pay for your NFTs!");
        }

        uint256 boneCost = currentBoneCost();
        for (uint256 i = 1; i <= quantity; i++) {
            mintMadDog(toAddress, supply + i, boneCost);
        }

        if (supply + quantity == 2000) initialSale = false;
    }

    function mintMadDog(address toAddress, uint256 tokenId, uint256 boneCost) internal {
        // burn bone from sender if necessary
        if (boneCost > 0) IBone(boneAddress).burnFrom(msg.sender, boneCost);

        _safeMint(toAddress, tokenId);
    }

    function walletOfOwner(address _owner) 
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) 
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address reciever, uint256 royaltyAmount) {
        if (_salePrice > 0) return (owner(), (_salePrice * 400) / 1000); // 4%
        else return (address(0), 0);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {

        if (interfaceId == _INTERFACE_ID_ERC2981) return true;

        return super.supportsInterface(interfaceId);
    }

    /*
  ______          ___   _ ______ _____    ______ _    _ _   _  _____ _______ _____ ____  _   _  _____ 
 / __ \ \        / / \ | |  ____|  __ \  |  ____| |  | | \ | |/ ____|__   __|_   _/ __ \| \ | |/ ____|
| |  | \ \  /\  / /|  \| | |__  | |__) | | |__  | |  | |  \| | |       | |    | || |  | |  \| | (___  
| |  | |\ \/  \/ / | . ` |  __| |  _  /  |  __| | |  | | . ` | |       | |    | || |  | | . ` |\___ \ 
| |__| | \  /\  /  | |\  | |____| | \ \  | |    | |__| | |\  | |____   | |   _| || |__| | |\  |____) |
 \____/   \/  \/   |_| \_|______|_|  \_\ |_|     \____/|_| \_|\_____|  |_|  |_____\____/|_| \_|_____/ 
    */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setMaxMintQuantity(uint256 newMaxMintQuantity) public onlyOwner {
        maxMintQuantity = newMaxMintQuantity;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function pause(bool state) public onlyOwner {
        paused = state;
    }

    function whiteListUser(address user) public onlyOwner {
        require(whiteListCount + 1 <= maxWhiteListCount, "The whitelist is full!");
        whitelisted[user] = true;
        whiteListCount++;
    }

    function removeWhiteListedUser(address user) public onlyOwner {
        if (whitelisted[user]) {
            whiteListCount--;
        }
        whitelisted[user] = false;
    }

    function widthdraw() public onlyOwner {
        // get the current eth balance of this contract
        uint currentBalance = address(this).balance;

        // send the entire balance to the owner
        // the msg sender is the owner as this function is an onlyOwner function
        (bool success, ) = payable(msg.sender).call{value: currentBalance}("");
        require(success);
    }

    function setBoneAddress(address newBoneAddress) public onlyOwner {
        boneAddress = newBoneAddress;
    }

    function changePresale(bool _presale) public onlyOwner {
        presale = _presale;
    }
}