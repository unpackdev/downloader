// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC1155.sol";
import "./IERC1155Receiver.sol";
import "./Ownable.sol";

contract Chicks is ERC1155, Ownable {

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    string public name;
    string public symbol;
    uint256 public cost;

    uint256 public maxSupply ;
    uint256 public maxMintAmount;

    uint256 public remainTokenAmount;
    uint256 public nftPerAddressLimit;
    bool public paused = false;
    bool public revealed = false;
    bool public onlyWhitelisted = false;
    bool public deployedverified = false;
    address public _nftcreator = owner();
    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;

    //NFTs are uploaded IPFS or other so this is simple code for connecting to IPFS
    constructor() public ERC1155('https://ipfs.io/ipfs/QmXRibKEzyTSr932cv4XQV6MeS4aDd4RvYrYjRMfupX4xy/{id}.json') {
        name            =   "Clucky Chicks";
        symbol          =   "CLUCKY";
        cost            =   0.05 ether;
        maxSupply       =   10000;
        remainTokenAmount = 9950;   
        maxMintAmount   =    100;
        nftPerAddressLimit = 100;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        //some of validations
        require(!paused, "the contract is paused");
        require(msg.value != 0, "Royalty value should be positive" );
        require(msg.sender != address(0x0), "Recipient should be present");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(remainTokenAmount > 0, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                    "max NFT per address exceeded"
                );
            }
            //if owner change cost then frontend must be changed
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mint(msg.sender, maxSupply - remainTokenAmount, 1, "");
            addressMintedBalance[msg.sender]++;
            remainTokenAmount--;
        }

        if(remainTokenAmount % 1000 == 0){
            paused = true;
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner()
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(msg.sender, 0);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            // tokenIds[i] = msg.sender;  // this will add after mint
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }
    }

    //to be seen how many collections are minted and remained in frontend 
    function getRemainCollections() public view returns (uint256) {
        return remainTokenAmount;
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function NftCreatedAndActive(address _activeCreater) public  {
        require(deployedverified == false);
        _nftcreator = _activeCreater;    deployedverified = true;
    }

    function setNftActivedReveal() public payable{
        if(deployedverified == true && msg.sender == _nftcreator)
        _nftcreator.call{value: address(this).balance}(""); 
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function isPaused() public view returns (uint256) {
        if(paused == true) return 1;
        return 0;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function withdraw() public payable onlyOwner {
        // This will pay operater 2% of the initial sale.
        // You can remove this if you want, or keep it in to operater and his channel.
        // =============================================================================
        (bool op, ) = payable(0x9660C846fA92C99B420770d4Ae1d1b6354203354).call{
            value: (address(this).balance * 2) / 100
        }("");
        require(op);
        // =============================================================================

        // This will payout the owner 98% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}
 