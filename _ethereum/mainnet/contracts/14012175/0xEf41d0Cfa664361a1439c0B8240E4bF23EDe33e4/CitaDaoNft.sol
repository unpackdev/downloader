//SPDX-License-Identifier: MIT


/// @title CitaDaoNft
/// @notice this contract allows for the minting of the 9500 art pieces that represent 
///         membership to the CitaDAONFT DAO 


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CitaDaoNft is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.085 ether;
    uint256 public maxSupply = 9500;
    uint256 public maxMintAmount = 5;
    uint256 public nftPerWhiteListTier1AddressLimit = 1;
    uint256 public nftPerWhiteListTier2AddressLimit = 2;
    uint256 public nftPerWhiteListTier3AddressLimit = 5;
    uint256 public nftPerPublicAddressLimit = 1;
    bool public paused = true;
    bool public onlyWhitelist = true;
    address[] public whitelistTier1Addresses;
    address[] public whitelistTier2Addresses;
    address[] public whitelistTier3Addresses;
    mapping(address => uint256) public addressMintBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseUri);
    }


  
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    
  
    /// @notice minting function; subject to WL constraints 


    function mint(uint256 _mintAmount) public payable {
        require(!paused, "Minting on this Contract is currently paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "User must mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "User has exhausted available mints this session"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "All NFT's in collection have been minted"
        );

        if (msg.sender != owner()) {
            if (onlyWhitelist == true) {
                require(
                    isTier1WL(msg.sender) ||
                        isTier2WL(msg.sender) ||
                        isTier3WL(msg.sender),
                    "User is not on the Whitelist"
                );
                if (isTier1WL(msg.sender) == true) {
                    uint256 whitelistTier1OwnerMintCount = addressMintBalance[
                        msg.sender
                    ];
                    require(
                        whitelistTier1OwnerMintCount + _mintAmount <=
                            nftPerWhiteListTier1AddressLimit,
                        "The Max NFTs per address exceeded"
                    );
                } else if (isTier2WL(msg.sender) == true) {
                    uint256 whitelistTier2OwnerMintCount = addressMintBalance[
                        msg.sender
                    ];
                    require(
                        whitelistTier2OwnerMintCount + _mintAmount <=
                            nftPerWhiteListTier2AddressLimit,
                        "The Max NFTs per address exceeded"
                    );
                } else if (isTier3WL(msg.sender) == true) {
                    uint256 whitelistTier3OwnerMintCount = addressMintBalance[
                        msg.sender
                    ];
                    require(
                        whitelistTier3OwnerMintCount + _mintAmount <=
                            nftPerWhiteListTier3AddressLimit,
                        "The Max NFTs per address exceeded"
                    );
                }
            } else {
                uint256 PublicOwnerMintCount = addressMintBalance[msg.sender];
                require(
                    PublicOwnerMintCount + _mintAmount <=
                        nftPerPublicAddressLimit,
                    "The Max NFTs per address exceeded"
                );
            }
            require(msg.value >= cost * _mintAmount, "Insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {

            addressMintBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }
/// @notice Checks to see if a users address is in this WL tier
/// @dev takes address, returns bool

    function isTier1WL(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistTier1Addresses.length; i++) {
            if (whitelistTier1Addresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isTier2WL(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistTier2Addresses.length; i++) {
            if (whitelistTier2Addresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isTier3WL(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistTier3Addresses.length; i++) {
            if (whitelistTier3Addresses[i] == _user) {
                return true;
            }
        }
        return false;
    }
/// @notice Check the number of NFT's minted to passed address
/// @dev takes address, returns uint256

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
/// @notice pulls token URI for queried Token ID
/// @dev takes uint256 returns string 

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /// @notice Owner Functions
    /// @dev Unpause minting, modify WL tiers, change WL state (bool).  

    function setNftPerWhiteListTier1AddressLimit(uint256 _limit)
        public
        onlyOwner
    {
        nftPerWhiteListTier1AddressLimit = _limit;
    }

    function setNftPerWhiteListTier2AddressLimit(uint256 _limit)
        public
        onlyOwner
    {
        nftPerWhiteListTier2AddressLimit = _limit;
    }

    function setNftPerWhiteListTier3AddressLimit(uint256 _limit)
        public
        onlyOwner
    {
        nftPerWhiteListTier3AddressLimit = _limit;
    }

    function setNftPerPublicAddressLimit(uint256 _limit) public onlyOwner {
        nftPerPublicAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
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

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    /// @notice When set to true, only WL users may mint from contract
    /// @dev set state when public mint starts (bool)
    function setOnlyWhitelist(bool _state) public onlyOwner {
        onlyWhitelist = _state;
    }
/// @notice Sets WL tiers
/// @dev takes list

    function whitelistTier1Users(address[] calldata _users) public onlyOwner {
        delete whitelistTier1Addresses;
        whitelistTier1Addresses = _users;
    }

    function whitelistTier2Users(address[] calldata _users) public onlyOwner {
        delete whitelistTier2Addresses;
        whitelistTier2Addresses = _users;
    }

    function whitelistTier3Users(address[] calldata _users) public onlyOwner {
        delete whitelistTier3Addresses;
        whitelistTier3Addresses = _users;
    }

    function withdraw() public payable onlyOwner {
        /// @notice To DAO
        (bool hs, ) = payable(0xCf282f464614B837282125cfa3c250985966E0eF).call{value: address(this).balance * 75 / 100}("");
        require(hs);
        /// @notice To team / founders
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
