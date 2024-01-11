pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";

interface IRichMeka {
    function ownerOf(uint256 tokenId) external returns (address);
    function getStakeOfHolderByTokenId(address holder, uint256 tokenId) external returns (uint256, uint256);
}

contract LandSpaceship is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter _landsIds;
    uint16 _maxLandsSupply = 8888;
    uint8 _maxLandsPerMint = 20;
    uint256 _landPriceEther = 0.01 ether;
    uint256 _landPriceSerum = 100000000000000000000000;
    bool _mintForSerumIsEnabled = false;
    IERC20 _serumContract;
    IRichMeka _richMekaContract;
    mapping (address => uint256) _mintedFreeLands;
    mapping (uint256 => bool) _mintedFreeLandsForMekas;

    constructor(address serumContractAddress, address richMekaContractAddress) ERC721("LandSpaceship", "LSSP") {
        _serumContract = IERC20(serumContractAddress);
        _richMekaContract = IRichMeka(richMekaContractAddress);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://metadata.richmeka.com/landspaceship/";
    }

    function totalSupply() public view returns (uint256) {
        return _landsIds.current();
    }

    function setLandPriceEther(uint256 landPriceEther) external onlyOwner {
        _landPriceEther = landPriceEther;
    }

    function setLandPriceSerum(uint256 landPriceSerum) external onlyOwner {
        _landPriceSerum = landPriceSerum;
    }

    function flipMintForSerumIsEnabled() external onlyOwner {
        _mintForSerumIsEnabled = !_mintForSerumIsEnabled;
    }

    function withdrawEther(address recipient, uint256 amount) external onlyOwner {
        payable(recipient).transfer(amount);
    }

    function withdrawSerum(address recipient, uint256 amount) external onlyOwner {
        _serumContract.transfer(recipient, amount);
    }

    function mintFreeLands(address recipient, uint8 numberOfLands) external onlyOwner {
        require(_landsIds.current() + numberOfLands <= _maxLandsSupply, "Mint would exceed max supply of lands");

        for (uint8 i = 0; i < numberOfLands; i++) {
            _landsIds.increment();
            _mint(recipient, _landsIds.current());
        }
    }

    function mintFreeLand() external {
        require(_mintedFreeLands[msg.sender] == 0, "You already minted a free land");
        require(_landsIds.current() + 1 <= _maxLandsSupply, "Mint would exceed max supply of lands");

        _landsIds.increment();
        _mint(msg.sender, _landsIds.current());
        _mintedFreeLands[msg.sender] = _landsIds.current();
    }

    function freeLandIsMinted () view external returns (bool) {
        return _mintedFreeLands[msg.sender] != 0;
    }

    function _senderOwnsMeka(uint256 mekaId) internal returns (bool) {
        try _richMekaContract.ownerOf(mekaId) returns (address owner) {
            if (owner == msg.sender) {
                return true;
            }
            else {
                return false;
            }
        }
        catch Error(string memory) {
            try _richMekaContract.getStakeOfHolderByTokenId(msg.sender, mekaId) returns (uint256, uint256) {
                return true;
            }
            catch Error(string memory) {
                return false;
            }
        }
    }

    function mintFreeMekas(uint256[] memory mekaIds) external {
        require(_landsIds.current() + mekaIds.length * 4 <= _maxLandsSupply, "Mint would exceed max supply of lands");

        for (uint8 i = 0; i < mekaIds.length; i++) {
            require(_senderOwnsMeka(mekaIds[i]), "Sender is not the owner of one of presented mekas");
            require(!_mintedFreeLandsForMekas[mekaIds[i]], "Lands for one of presented mekas were already minted");

            for (uint8 j = 0; j < 4; j++) {
                _landsIds.increment();
                _mint(msg.sender, _landsIds.current());
            }

            _mintedFreeLandsForMekas[mekaIds[i]] = true;
        }
    }

    function landsForMekaAreMinted(uint256 mekaId) view external returns (bool) {
        return _mintedFreeLandsForMekas[mekaId];
    }

    function mintLandsForEther(uint8 numberOfLands) external payable {
        require(msg.value >= _landPriceEther * numberOfLands, "Ether value sent is not correct");
        require(numberOfLands <= _maxLandsPerMint, "Can only mint 20 lands at a time");
        require(_landsIds.current() + numberOfLands <= _maxLandsSupply, "Mint would exceed max supply of lands");

        for (uint8 i = 0; i < numberOfLands; i++) {
            _landsIds.increment();
            _mint(msg.sender, _landsIds.current());
        }
    }

    function mintLandsForSerum(uint8 numberOfLands) external {
        require(_mintForSerumIsEnabled, "Mint of lands for SERUM is not enabled");
        require(numberOfLands <= _maxLandsPerMint, "Can only mint 20 lands at a time");
        require(_landsIds.current() + numberOfLands <= _maxLandsSupply, "Mint would exceed max supply of lands");

        for (uint8 i = 0; i < numberOfLands; i++) {
            _landsIds.increment();
            _mint(msg.sender, _landsIds.current());
        }

        _serumContract.transferFrom(msg.sender, address(this), _landPriceSerum * numberOfLands);
    }
}