pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SpaceFlightSimulator is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public MAX_TOKENS = 5555;

    using SafeMath for uint256;

    uint256 public constant price = 50000000000000000; // 0.05 ETH

    string public collectionBaseURI = 'https://spaceflightnft-hvorxsrj4q-uc.a.run.app/res/attribute/';
    bool public baseURILocked = false;

    address public devAddress;
    address public gameDevAddress;
    address public businessAddress;

    uint public constant maxSimulatorPurchase = 20;

    constructor(address _devAddress, address _gameDevAddress, address _businessAddress) ERC721("SpaceFlightSimulator", "SPACE") {
        devAddress = _devAddress;
        gameDevAddress = _gameDevAddress;
        businessAddress = _businessAddress;
    }

    function lockBaseURI() public onlyOwner {
        baseURILocked = true;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        require(baseURILocked == false, "baseURI is locked");
        collectionBaseURI = newURI;
    }

    function _baseURI() override internal view returns (string memory) {
        return collectionBaseURI;
    }

    function withdraw() public {
        uint balance = address(this).balance;

        uint256 devPayment = _calcProportion(20, balance);
        uint256 gameDevPayment = _calcProportion(40, balance);
        uint256 businessPayment = balance - devPayment - gameDevPayment;

        if (devPayment > 0) {
          payable(devAddress).transfer(devPayment);
        }
        if (gameDevPayment > 0) {
          payable(gameDevAddress).transfer(gameDevPayment);
        }
        if (businessPayment > 0) {
          payable(businessAddress).transfer(businessPayment);
        }
    }

    function reserveSimulators(uint numberOfTokens, address recipient) public onlyOwner {
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(recipient, mintIndex);
            }
        }
    }

    function mintSimulators(uint numberOfTokens) public payable {
        require(numberOfTokens <= maxSimulatorPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply");
        require(price.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function _calcProportion(uint256 fee, uint256 _amount)
        internal pure returns (uint256)
    {
        return _amount.mul(fee).div(100);
    }
}