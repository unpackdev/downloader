pragma solidity ^0.6.0;

import "./Initializable.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./EnumerableSetUpgradeable.sol";

import "./IERC721Upgradeable.sol";

import "./IERC1155Upgradeable.sol";

import "./AirPair.sol";

import "./IAirPair.sol";

contract AirFactory is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // // Declare a set state variable
    // EnumerableSetUpgradeable.AddressSet private existingProjects;

    // keep track of nft address to pair address
    mapping(address => address) public nftToAirToken;
    mapping(uint256 => address) public indexToNft;

    uint256 public counter;

    constructor() public {}

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    // @ we need to somehow validate the project name here so we can call it airvnft for example.
    //or have a manual way to change it if someone puts random name with known contract.
    function airPair(
        string calldata name,
        address _nftOrigin,
        uint256 _nftType
    ) external {
        // if pair exists then throw.
        require(
            nftToAirToken[_nftOrigin] == address(0),
            "A token for this NFT already exists"
        ); // this is not good as anyone can create a pair with wrong parameters

        AirPair _airpair = new AirPair();

        _airpair.init(
            string(abi.encodePacked("air ", name)),
            string(abi.encodePacked("a", name)),
            _nftOrigin,
            _nftType
        );
        nftToAirToken[_nftOrigin] = address(_airpair);
        indexToNft[counter] = _nftOrigin;
        counter = counter + 1;
    }

    function getPair(uint256 index)
        public
        view
        returns (
            address _airPair,
            address _originalNft,
            uint256 _type,
            string memory _name,
            string memory _symbol,
            uint256 _supply
        )
    {
        _originalNft = indexToNft[index];
        _airPair = nftToAirToken[_originalNft];
        (_type, _name, _symbol, _supply) = IAirPair(_airPair).getInfos();
    }

    // this is to sset value in case we decided to change tokens given to a tokenizing project.
    function setValue(
        address _pair,
        uint256 _nftType,
        uint256 _nftValue,
        uint256 _fee,
        string calldata _name,
        string calldata _symbol
    ) external onlyOwner {
        IAirPair(_pair).setParams(_nftType, _nftValue, _fee, _name, _symbol);
    }
}
