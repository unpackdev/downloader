// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./AccessControl.sol";


interface IAccountRegistry{
    function account(
        uint256 chainId,
        address tokenCollection,
        uint256 tokenId
    ) external view returns (address);
}

contract GenesisGoldEcoSpherePassNFT is ERC721, Ownable, IERC2981 {
    // using Address for address;

    uint256 public _nextTokenId = 1;
    mapping(address => bool) public whitelistedAddress;
    bool public thirdRoundActive;
    address public _registry;
    mapping(address=>uint[]) public userTokenIds;
    mapping(address=>bool) public hasMinted;
    uint256 immutable public totalSupply = 3333;

    uint256 private _royaltyPercentage; // 2.5% royalties
    constructor(address initialOwner, address registry)
        ERC721("Genesis Gold EcoSphere Pass", "GPassNFT")
        Ownable(initialOwner)
    {
        _registry = registry;
        mintNFTsAdmin(1);
    }

    function getHasMinted(address _user) public view returns(bool){
        return hasMinted[_user];
    }

    function setThirdRound(bool activation) public onlyOwner{
        thirdRoundActive = activation;
    }

    function computeAccountAddress(uint256 tokenId) public view returns (address){
       return IAccountRegistry(_registry).account(1, address(this), tokenId);
    }

    function setAccountRegistry(address registry) public onlyOwner{
        _registry = registry;
    }

    function whitelist(address[] memory userAddresses) public onlyOwner{
        for(uint i=0; i<userAddresses.length; i++){
            whitelistedAddress[userAddresses[i]] = true;
        }
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721)
        returns (address)
    {
        require(to != computeAccountAddress(tokenId), "Can't transfer the parent NFT");
        userTokenIds[to].push(tokenId);
        return super._update(to, tokenId, auth);
    }

    function blacklistAddress(address[] memory userAddresses) public onlyOwner{
         for(uint i=0; i<userAddresses.length; i++){
            whitelistedAddress[userAddresses[i]] = false;
        }
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view override(IERC2981) returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (_salePrice * _royaltyPercentage) / 10000; // Calculate royalties as a percentage of the sale price
    }

    function setRoyaltyPercentage(uint256 percentage) external onlyOwner {
        _royaltyPercentage = percentage;
    }

    function _baseURI() internal pure override returns (string memory) {
        // return "https://teal-obvious-tahr-119.mypinata.cloud/ipfs/QmZKZi9karpAiM19EmZQgqTgndoda3XSeJ51ujxfPLP1Qn/";
        return "https://teal-obvious-tahr-119.mypinata.cloud/ipfs/QmTRHFCZd1uQSxHmbpcGCNBsAik2w9PSvDitHrYHj5BaWP/";

    }

    function mintNFTsAdmin(uint256 number) public onlyOwner{
        for(uint i; i<number; i++){
            uint256 tokenId = _nextTokenId++;
            require(tokenId <= totalSupply, "Total Supply Reached");
            _safeMint(owner(), tokenId);
        }
        hasMinted[owner()] = true;
    }

    function safeMint() public {
        require(!hasMinted[msg.sender],"User can only mint 1 NFT");
        if(!thirdRoundActive){
            require(whitelistedAddress[msg.sender],"You are not whitelisted for this round");
        }
        uint256 tokenId = _nextTokenId++;
        require(tokenId <= totalSupply, "Total Supply Reached");
        _safeMint(msg.sender, tokenId);
        hasMinted[msg.sender] = true;
    }
}
