// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract WallStreetDads is ERC721, Ownable, VRFConsumerBase {
    using Strings for uint256;

    string public baseURI;
    string public notRevealedURI;
    string public WSD_PROVENANCE;
    string public baseExtension = ".json";

    uint64 public costpresale = 0.05 ether;
    uint64 public cost = 0.1 ether;

    uint16 public totalSupply = 0;
    uint16 public maxSupply = 10000;
    uint8 public maxMintAmount = 10;
    uint8 public maxMintAmountWhiteList = 2;

    bool public paused = true;
    bool public revealed = false;
    bool public onlyWhitelisted = true;

    address[] public whitelistedAddresses;

    bytes32 public keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 public chainlinkFee = 2 * 10**18;
    address public VRF_Coordinator = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    address public LINK_Token = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    uint256 public randomShift;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedURI
    ) ERC721(_name, _symbol) VRFConsumerBase(VRF_Coordinator, LINK_Token) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedURI);
    }

    function mint(uint16 _mintAmount) public payable {
        require(!paused, "Please wait until unpaused");
        require(_mintAmount > 0, "Need to mint more than 0");
        require(
            totalSupply + _mintAmount <= maxSupply,
            "Sorry we're running low on Wall Street Dads! Good thing we still have Wall Street Dad jokes! How do you know if a Wall Street Dad is crazy? He's FOMOing at the mouth."
        );

        if (msg.sender != owner()) {
            require(
                _mintAmount <= maxMintAmount,
                "You can't mint more than 10"
            );

            //if general sale
            if (onlyWhitelisted == false) {
                require(
                    msg.value >= cost * _mintAmount,
                    "Insufficient funds for sale"
                );
            }

            //if presale
            if (onlyWhitelisted == true) {
                require(
                    isWhitelisted(msg.sender),
                    "Sorry no access unless you're whitelisted. How do trees do it? They log in."
                );
                uint256 ownerMintedCount = balanceOf(msg.sender); //addressMintedBalance[msg.sender];
                require(
                    ownerMintedCount + _mintAmount <= maxMintAmountWhiteList,
                    "You can't mint more than 2 during presale"
                );
                require(
                    msg.value >= costpresale * _mintAmount,
                    "Insufficient funds for presale"
                );
            }
        }

        for (uint16 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            incrementTotalSupply();
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint16 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenID does not exist");

        if (revealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        uint256 tokenIdShifted = ((tokenId + randomShift) % maxSupply) + 1;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenIdShifted.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function incrementTotalSupply() internal {
        totalSupply += 1;
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomShift = (randomness % 10000) + 1;
    }

    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= chainlinkFee,
            "Not enough LINK"
        );
        return requestRandomness(keyHash, chainlinkFee);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMaxMintAmountWhiteList(uint8 _limit) public onlyOwner {
        maxMintAmountWhiteList = _limit;
    }

    function setCostPresale(uint64 _newCostPresale) public onlyOwner {
        costpresale = _newCostPresale;
    }

    function setCost(uint64 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint8 _newmaxMintAmount) public onlyOwner {
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
        notRevealedURI = _notRevealedURI;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        WSD_PROVENANCE = _provenanceHash;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
    }

    function setChainlinkFee(uint256 _chainlinkFee) public onlyOwner {
        chainlinkFee = _chainlinkFee;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}
