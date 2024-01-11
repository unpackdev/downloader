// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";
import "./base64.sol";

contract TinyPlanet is Ownable, ERC721A, ReentrancyGuard
{
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 constant MAX_TOTAL_TEAM_MINT = 40;
    uint256 constant COLLECTION_SIZE = 4000;
    uint256 constant ANIMATED_PRICE = 0.03 ether;

    uint256 private _tokenCounter = 0;
    uint256 private _devTokenCount = 0;
    uint256 private _animatedMintCount = 0;
    uint256 private _mintSeed = 1;
    address private _signerAddressWhitelist;
    address private _signerAddressFree;
    address private _TinyPlanetsWallet;

    string private _baseTokenURI = "ipfs://Qmca3gdrctHG6rDMwuSxF28LBnpBhAGbDvTwUwQPjqT6rA";

    bool private _isRevealed = false;
    bool private _isPaused = true;
    bool private _isUpdatable = false;
    bool private _isPresale = false;
    bool private _isPublicPhase = false;
    bool private _isAnimatedPhase = false;

    struct Planet
    {
        uint256 seed;
        uint8[2] properties;
        string name;
        string desc;
    }

    string[] LifeConditions = ["Hostile", "Harsh", "Livable", "Good", "Peaceful"];
    string[] MetalsGasOrganic = ["None", "Scarce", "Normal", "Good Quantity", "Abundant"];
    string[] BuildingDifficulty = ["Very difficult", "Uneven Terrain", "Normal Terrain", "Good Terrain", "Even Terrain"];
    string[] PlanetTypes = ["Rocky", "Gas", "Special"];
    string[] RingedPlanet = ["No", "Yes"];

    constructor() ERC721A("TinyPlanet", "TNP"){}

    mapping (address => uint256) private presaleMintList;
    mapping (address => uint256) private quantityMinted;
    mapping (uint256 => uint256) private extensionID;
    mapping (uint256 => Planet) private planetsData;

    modifier checkPause()
    {
        require(_isPaused == false, "Mint Phase is paused");
        _;
    }

    function verifyOGWhitelist(bytes memory _signature) internal view returns (uint256)
    {
        if(_signature.length == 0)
            return 0;

        if(_signerAddressFree == keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", bytes32(uint256(uint160(msg.sender))))).recover(_signature))
            return 1;
        else if(_signerAddressWhitelist == keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", bytes32(uint256(uint160(msg.sender))))).recover(_signature))
            return 2;
        else
            return 0;
    }

    function buyAnimatedPlanet(bytes memory _signature, uint256 _count) external payable nonReentrant checkPause
    {
        require(_isPresale == true, "Presale isn't active");
        require(_isAnimatedPhase == true, "Animated phase is off");
        require(_isPublicPhase == false, "Public sale is active");
        uint256 signedResult = verifyOGWhitelist(_signature);
        require(signedResult > 0, "You are Unauthorized");
        require(_count > 0, "You must mint at least 1 NFT");
        require(_tokenCounter + _count < 1000, "Max animated supply has been reached");
        require(msg.value == ANIMATED_PRICE * _count, "Incorrect Price");

        if(signedResult == 1)
        {
            require(presaleMintList[msg.sender] + _count <= 3, "Minting more than allowed!");
        }
        else if(signedResult == 2)
        {
            require(presaleMintList[msg.sender] + _count <= 2, "Minting more than allowed");
        }

        presaleMintList[msg.sender] += _count;
        _animatedMintCount += _count;
        for(uint i = 0; i < _count; i++)
        {
            generatePlanetData(_signature, _tokenCounter);
            _tokenCounter++;
        }
        _safeMint(msg.sender, _count);

    }

    function devMint(uint256 _count) external onlyOwner
    {
        require(_tokenCounter + _count < COLLECTION_SIZE, "Mint exceeds supply");
        require(_devTokenCount + _count < MAX_TOTAL_TEAM_MINT, "Exceeds max supply allowed for community wallet");

        if(_isAnimatedPhase)
        {
            require(_tokenCounter + _count < 1000, "Mint exceeds animated supply");
            _animatedMintCount += _count;
        }
        
        for(uint i = 0; i < _count; i++)
        {
            generatePlanetData(abi.encodePacked(msg.sender, _mintSeed, _tokenCounter, block.difficulty, i + 1, block.number), _tokenCounter);
            _tokenCounter++;
            _devTokenCount++;
        }
        _safeMint(msg.sender, _count);
    }

    //_signature being 0x for public sale people.
    function buyPlanet(bytes memory _signature, uint256 _count) external payable checkPause
    {
        if(_isPresale == true)
        {
            uint256 signedResult = verifyOGWhitelist(_signature);
            require(_isAnimatedPhase == false, "wrong presale");
            require(signedResult > 0, "You are not yet authorized to mint!");
        }
        else
        {
            require(_isPublicPhase == true, "Public sale isn't active");    
        }

        require(_count > 0, "You must mint at least 1 NFT");
        require(_count <= 2, "Too many NFTs");
        require(_tokenCounter + _count < COLLECTION_SIZE, "Mint exceeds supply");
        require(quantityMinted[msg.sender] + _count <= 2, "Minting more than allowed");

        quantityMinted[msg.sender] += _count;
        for(uint i = 0; i < _count; i++)
        {
            generatePlanetData(abi.encodePacked(msg.sender, _mintSeed, _tokenCounter, block.difficulty, i, block.number), _tokenCounter);
            _tokenCounter++;
        }
        _safeMint(msg.sender, _count);
    }
    
    function changePlanetName(uint256 _tokenID, string memory _newName) external
    {
        require(msg.sender == ownerOf(_tokenID), "You are not owner of this token");
        require(_isUpdatable == true, "Feature not available yet");
        planetsData[_tokenID].name = _newName;
    }

    function changePlanetDesc(uint256 _tokenID, string memory _newDesc) external
    {
        require(msg.sender == ownerOf(_tokenID), "You are not owner of this token");
        require(_isUpdatable == true, "Feature not available yet");
        planetsData[_tokenID].desc = _newDesc;
    }

    function setWallet(address _addr) external onlyOwner
    {
        _TinyPlanetsWallet = _addr;
    }

    function withdraw() external onlyOwner nonReentrant
    {
        uint256 balance = address(this).balance;
        payable(_TinyPlanetsWallet).transfer(balance);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        string memory data = "";
        if(_isRevealed)
        {
            string memory image = string(abi.encodePacked(_baseTokenURI, '/', uint2str(_tokenId), _tokenId > (_animatedMintCount - 1) ? '.png' : '.mp4'));
            bytes memory data1 = abi.encodePacked('{ "description": "', planetsData[_tokenId].desc, '",', 
                                            ' "image": "', image, '",',
                                            ' "name": "', planetsData[_tokenId].name, '", "attributes": [',
                                            '{ "trait_type": "Life Conditions", "value": "', LifeConditions[getPercentage(planetsData[_tokenId].seed % 100)] ,'" }, ',
                                            '{ "trait_type": "Metal Resources", "value": "', MetalsGasOrganic[getPercentage((planetsData[_tokenId].seed / 100) % 100)] ,'" }, ',
                                            '{ "trait_type": "Gas Resources", "value": "', MetalsGasOrganic[getPercentage((planetsData[_tokenId].seed / 10000) % 100)] ,'" }, ');
            bytes memory data2 = abi.encodePacked(
                                            '{ "trait_type": "Organic Resources", "value": "', MetalsGasOrganic[getPercentage((planetsData[_tokenId].seed / 1000000) % 100)] ,'" }, ',
                                            '{ "trait_type": "Building Difficulty", "value": "', BuildingDifficulty[getPercentage((planetsData[_tokenId].seed / 100000000) % 100)] ,'" }, ',
                                            '{ "trait_type": "Ringed Planet", "value": "', RingedPlanet[planetsData[_tokenId].properties[0]] ,'" }, ',
                                            '{ "trait_type": "Planet Type", "value": "', PlanetTypes[planetsData[_tokenId].properties[1]] ,'" }, ',
                                            '{ "trait_type": "Animated", "value": "', _tokenId > (_animatedMintCount - 1) ? "No" : "Yes" ,'" } ',
                                            ']}');

            data = string(bytes.concat(data1, data2));
        }
        else
        {
            data =  string(abi.encodePacked('{ "description": "One of the 4000 procedurally generated Tiny Planets, with millions of possibilities regarding colors, shapes, clouds, ocean, and much more!",', 
                                            ' "image": "', _baseTokenURI, '",',
                                            ' "name": "Tiny Planet #', uint2str(_tokenId), '", "attributes": [',
                                            '{ "trait_type": "Animated", "value": "', _tokenId > (_animatedMintCount - 1) ? "No" : "Yes" ,'" } ',
                                            ']}'));
        }
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(abi.encodePacked(data)))));

    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function getrandomSeed(bytes memory _offset, uint256 _expo) internal view returns (uint256)
    {
        return uint(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.number, _offset, _tokenCounter, _expo)));
    }

    function generatePlanetData(bytes memory _offset, uint256 _id) internal
    {
        planetsData[_id].seed = getrandomSeed(_offset, _id);
        planetsData[_id].properties[0] = 0;
        planetsData[_id].properties[1] = 0;
        planetsData[_id].name = string(abi.encodePacked('Tiny Planet #', uint2str(_tokenCounter)));
    }

    function getPercentage(uint256 _input) internal pure returns (uint8 result)
    {
        if(_input < 10)
            return 4;
        else if(_input < 20)
            return 3;
        else if(_input < 70)
            return 2;
        else if(_input < 90)
            return 1;
        else if(_input < 100)
            return 0;

    }

    function updateMintSeed(uint256 _seed) external onlyOwner
    {
        _mintSeed = _seed;
    }

    function updatePlanetTypes(uint256[] memory _tokens, uint8 _id) external onlyOwner
    {
        for(uint i = 0; i < _tokens.length; i++)
        {
            planetsData[_tokens[i]].properties[1] = _id;
        }
    }

    function updatePlanetRings(uint256[] memory _tokens, uint8  _id) external onlyOwner
    {
        for(uint i = 0; i < _tokens.length; i++)
        {
            planetsData[_tokens[i]].properties[0] = _id;
        }
    }

    function updateUnique(uint256 _tokenId, uint256 seed) external onlyOwner
    {
        planetsData[_tokenId].seed = seed;
    }

        function setSignerAddresses(address _signerWhitelist, address _signerFree) external onlyOwner
    {
        _signerAddressWhitelist = _signerWhitelist;
        _signerAddressFree = _signerFree;
    }

    function setPause() external onlyOwner
    {
        _isPaused = !_isPaused;
    }

    function getPause() external view returns(bool)
    {
        return _isPaused;
    }

    function activateAnimatedPhase() external onlyOwner
    {
        _isPresale = true;
        _isAnimatedPhase = true;
    }

    function getAnimatedState() external view returns(bool)
    {
        return _isAnimatedPhase;
    }

    function activatePresale() external onlyOwner
    {
        _isAnimatedPhase = false;
    }

    function getPresaleState() external view returns(bool)
    {
        return _isPresale;
    }

    function activatePublicSale() external onlyOwner
    {
        _isPresale = false;
        _isPublicPhase = true;
    }

    function getPublicState() external view returns(bool)
    {
        return _isPublicPhase;
    }

    function toggleOffAllSales() external onlyOwner
    {
        _isPresale = false;
        _isAnimatedPhase = false;
        _isPublicPhase = false;
    }

    function toggleUpdateFeature() external onlyOwner
    {
        _isUpdatable = !_isUpdatable;
    }

    function getUpdatableState() external view returns(bool)
    {
        return _isUpdatable;
    }

    function toggleReveal() external onlyOwner
    {
        _isRevealed = true;
    }
    function changeBaseURI(string memory _newBaseURI) external onlyOwner
    {
        _baseTokenURI = _newBaseURI;
    }

    function mintedQuantityOf(address user) external view returns (uint256)
    {
        return quantityMinted[user];
    }
    
}