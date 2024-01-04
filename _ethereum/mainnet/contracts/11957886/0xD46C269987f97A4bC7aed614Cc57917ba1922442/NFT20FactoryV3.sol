pragma solidity ^0.6.0;

import "./Initializable.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";
import "./AddressUpgradeable.sol";

import "./INFT20Pair.sol";

import "./BeaconProxy.sol";

contract NFT20FactoryV3 is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // keep track of nft address to pair address
    mapping(address => address) public nftToToken;
    mapping(uint256 => address) public indexToNft;

    uint256 public counter;
    uint256 public fee;

    event pairCreated(
        address indexed originalNFT,
        address newPair,
        uint256 _type
    );

    using AddressUpgradeable for address;
    address public logic;

    constructor() public {}

    function nft20Pair(
        string memory name,
        address _nftOrigin,
        uint256 _nftType
    ) public payable {
        require(nftToToken[_nftOrigin] == address(0));
        bytes memory initData =
            abi.encodeWithSignature(
                "init(string,string,address,uint256)",
                string(abi.encodePacked("NFT20 ", name)),
                string(abi.encodePacked(name, "20")),
                _nftOrigin,
                _nftType
            );

        address instance = address(new BeaconProxy(logic, ""));

        instance.functionCallWithValue(initData, msg.value);

        nftToToken[_nftOrigin] = instance;
        indexToNft[counter] = _nftOrigin;
        counter = counter + 1;
        emit pairCreated(_nftOrigin, instance, _nftType);
    }

    function getPairByNftAddress(uint256 index)
        public
        view
        returns (
            address _nft20pair,
            address _originalNft,
            uint256 _type,
            string memory _name,
            string memory _symbol,
            uint256 _supply
        )
    {
        _originalNft = indexToNft[index];
        _nft20pair = nftToToken[_originalNft];
        (_type, _name, _symbol, _supply) = INFT20Pair(_nft20pair).getInfos();
    }

    // this is to sset value in case we decided to change tokens given to a tokenizing project.
    function setValue(
        address _pair,
        uint256 _nftType,
        string calldata _name,
        string calldata _symbol,
        uint256 _value
    ) external onlyOwner {
        INFT20Pair(_pair).setParams(_nftType, _name, _symbol, _value);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function changeLogic(address _newLogic) external onlyOwner {
        logic = _newLogic;
    }

    function fix() external onlyOwner {
        nftToToken[
            address(0xC2C747E0F7004F9E8817Db2ca4997657a7746928)
        ] = address(0xc2BdE1A2fA26890c8E6AcB10C91CC6D9c11F4a73);
        counter = counter - 1;
    }
}
