// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                                  +
+  ####### #     # ######     #     # #     # ####### ####### ###### ######       #####  #####   ##### ##### ###### ####### #   #  +
+     #    #     # #          # #   # #     #    #       #    #      #     #     #      #     # #        #   #         #     # #   +
+     #    ####### ####       #   # # #     #    #       #    ####   #     #      ####  #     # #        #   ####      #      #    +
+     #    #     # #          #    ## #     #    #       #    #      #     #          # #     # #        #   #         #      #    +
+     #    #     # ######     #     # #######    #       #    ###### ######      #####   #####   ##### ##### ######    #      #    +
+                                                                                                                                  +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract TheNuttedSociety is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    string public TNS_PROVENANCE = "";
    bool private PROVENANCE_LOCK = false;
    bool public isAllowListActive = false;
    bool public saleIsActive = false;
    string private _baseURIextended;
    address public proxyRegistryAddress;    // Rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
                                            // Mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1

    uint256 public constant MAX_SUPPLY = 2000;
    uint8 private MAX_PRESALE_MINT = 15;
    uint8 private MAX_PUBLIC_MINT = 25;
    uint8 private MAX_RESERVED = 35;
    uint256 private PRESALE_PRICE_PER_TOKEN = 0.12 ether;
    uint256 private PUBLIC_PRICE_PER_TOKEN = 0.20 ether;
    uint8 private _reservedLeft = 35;

    // The Nutted Society Release Times
    uint256 public presaleStart = 1647561600;    // March 17, 2022 @ 8PM EDT
    uint256 public presaleEnd = 1647820800;      // March 20, 2022 @ 8PM EDT

    mapping(address => uint8) private _allowList;
    mapping(address => bool) public projectProxy;

    constructor(
        string memory initialURI, 
        address _proxyRegistryAddress
    ) ERC721A("The Nutted Society", "TNS", MAX_PRESALE_MINT, MAX_RESERVED, MAX_SUPPLY) 
    {
        _baseURIextended = initialURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // Allows owner to set the proxyRegistryAddress for gasless transactions on e.g. OpenSea
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // Allows owner to toggle the state of the projectProxy for a particular proxyAddress
    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    // Allows proxy account to be used for OpenSea transactions
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    // Get the presale start and end times
    function getSaleTimes() public view returns (uint256, uint256) {
        return (presaleStart, presaleEnd);
    }

    // Set the presale start and end times
    function setSaleTimes(uint256 _presaleStart, uint256 _presaleEnd) external onlyOwner {
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
    }
    
    // This should be set before either presale or public sales open
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        require(PROVENANCE_LOCK == false, "Provenance has already been locked");
        TNS_PROVENANCE = _provenanceHash;
    }

    // Allows owner to lock the provenance hash
    function lockProvenance() external onlyOwner {
        require(PROVENANCE_LOCK == false, "Provenance has already been locked");
        PROVENANCE_LOCK = true;
    }

    // Get the maximum supply of the collection
    function maxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    // Check how many tokens are reserved for contract owner to mint
    function getReservedLeft() public view returns (uint256) {
        return _reservedLeft;
    }

    // Allows contract owner to reserve and mint up to n NFTs
    function reserve(uint8 n) external onlyOwner {
        require(n < _reservedLeft + 1, "That would exceed the max reserved");
        uint256 ts = totalSupply();
        require(ts + n < MAX_SUPPLY + 1, "Reserve minting would exceed max tokens");
        _reservedLeft -= n;
        _safeMint(msg.sender, n);
    }

    // Allows contract owner to reserve, mint and send to addresses up to n NFTs
    function reserveSend(uint8 n, address _receiver) external onlyOwner {
        require(n < _reservedLeft + 1, "That would exceed the max reserved");
        uint256 ts = totalSupply();
        require(ts + n < MAX_SUPPLY + 1, "Reserve minting would exceed max tokens");
        _reservedLeft -= n;
        _safeMint(_receiver, n);
    }

    // Get the current presale mint number
    function getPresaleMintNumber() public view returns (uint8) {
        return MAX_PRESALE_MINT;
    }

    // Make it possible to change the presale mint number: just in case
    function setPresaleMintNumber(uint8 _maxPresaleMint) external onlyOwner {
        MAX_PRESALE_MINT = _maxPresaleMint;
    }

    // Get the current presale price per token
    function getPresalePrice() public view returns (uint256) {
        return PRESALE_PRICE_PER_TOKEN;
    }

    // Make it possible to change the presale price: just in case
    function setPresalePrice(uint256 _newPrice) external onlyOwner {
        PRESALE_PRICE_PER_TOKEN = _newPrice;
    }

    // Sets the number of NFTs that presale addresses can mint
    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint16 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = MAX_PRESALE_MINT;
        }
    }

    // Removes addresses from the presale list
    function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        for (uint16 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't remove the null address");
            _allowList[addresses[i]] = 0;
        }
    }

    // Gets the number of NFTs that a particular presale address can mint
    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    // Sets the boolean to activate presale minting
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    // Allows presale addresses to mint once setIsAllowListActive is activated
    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Presale must be active to mint tokens");
        require(block.timestamp >= presaleStart, "You must wait until presale begins to mint");
        require(block.timestamp < presaleEnd, "Presale is over, you must mint in the public sale");
        require(numberOfTokens > 0, "At least one token should be minted");
        require(numberOfTokens < _allowList[msg.sender] + 1, "Exceeded max available to purchase");
        require(ts + numberOfTokens < MAX_SUPPLY - _reservedLeft + 1, "Not enough tokens left");
        require(PRESALE_PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    // Gets the current baseURI used to reference images
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    // This allows the URI to be updated post-reveal
    function updateURI(string memory updatedURI) external onlyOwner {
        _baseURIextended = updatedURI;
    }

    // Get the current public mint number
    function getPublicMintNumber() public view returns (uint8) {
        return MAX_PUBLIC_MINT;
    }

    // Make it possible to change the public mint number: just in case
    function setPublicMintNumber(uint8 _maxPublicMint) external onlyOwner {
        MAX_PUBLIC_MINT = _maxPublicMint;
    }

    // Get the current public price per token
    function getPublicPrice() public view returns (uint256) {
        return PUBLIC_PRICE_PER_TOKEN;
    }

    // Make it possible to change the public price: just in case
    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        PUBLIC_PRICE_PER_TOKEN = _newPrice;
    }

    // Sets the boolean to activate public minting
    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    // Allows public to mint once setSaleState is activated
    function mint(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(block.timestamp >= presaleEnd, "You must wait until public sale begins to mint");
        require(numberOfTokens > 0, "At least one token should be minted");
        require(numberOfTokens < MAX_PUBLIC_MINT + 1, "Exceeded max token purchase");
        require(ts + numberOfTokens < MAX_SUPPLY - _reservedLeft + 1, "Not enough tokens left");
        require(PUBLIC_PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, numberOfTokens);
    }

    // Get list of tokenIDs owned by wallet owner
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Allows owner to withdraw funds to same contract owner address
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}